-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- DestructibleManager.lua (Script)
-- Path: ServerScriptService/Script/DestructibleManager.lua
-- Manages damage and destruction for non-humanoid objects (Barricades, Furniture)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- === CONFIGURATION ===
local DEBRIS_LIFETIME = 5
local FLASH_COLOR = Color3.fromRGB(255, 100, 100) -- Red flash on hit

-- === SETUP EVENTS ===
local BindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")
local ObjectDamagedEvent = BindableEvents:FindFirstChild("ObjectDamaged")

if not ObjectDamagedEvent then
	ObjectDamagedEvent = Instance.new("BindableEvent")
	ObjectDamagedEvent.Name = "ObjectDamaged"
	ObjectDamagedEvent.Parent = BindableEvents
end

-- === HELPER FUNCTIONS ===

local function spawnDebris(model, position)
	-- Simple effect: Clone parts as unanchored debris
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			local d = part:Clone()
			d.CanCollide = true
			d.Anchored = false
			d.Parent = workspace
			d.CFrame = part.CFrame
			d.Velocity = Vector3.new(math.random(-20,20), math.random(10,30), math.random(-20,20))
			d.RotVelocity = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10))
			Debris:AddItem(d, DEBRIS_LIFETIME)
		end
	end
	
	-- Explosion Effect (Optional)
	local exp = Instance.new("Explosion")
	exp.Position = model:GetPivot().Position
	exp.BlastRadius = 0 -- Visual only
	exp.BlastPressure = 0
	exp.Parent = workspace
end

local function flashObject(model)
	-- Hit feedback
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local originalColor = part.Color
			local tween = TweenService:Create(part, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true), {Color = FLASH_COLOR})
			tween:Play()
		end
	end
end

local function destroyObject(model)
	print("DestructibleManager: Object Destroyed -> " .. model.Name)
	spawnDebris(model)
	model:Destroy()
end

-- === EVENT HANDLER ===

ObjectDamagedEvent.Event:Connect(function(hitModel, damageAmount, hitPosition)
	if not hitModel then return end
	
	-- Check if valid destructible
	local isDestructible = hitModel:GetAttribute("Destructible")
	if not isDestructible then return end
	
	local currentHealth = hitModel:GetAttribute("Health") or 100
	local maxHealth = hitModel:GetAttribute("MaxHealth") or 100
	
	-- Apply Damage
	local newHealth = currentHealth - damageAmount
	hitModel:SetAttribute("Health", newHealth)
	
	-- Feedback
	flashObject(hitModel)
	
	-- Destruction Check
	if newHealth <= 0 then
		destroyObject(hitModel)
	end
end)

