-- RandomWeaponShopUI.lua (LocalScript)
-- Path: StarterGui/RandomWeaponShopUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage:WaitForChild("ModuleScript")

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local ProximityUIHandler = require(ModuleScriptReplicatedStorage:WaitForChild("ProximityUIHandler"))

local openReplaceUI = RemoteEvents:WaitForChild("OpenReplaceUI")
local replaceChoiceEv = RemoteEvents:WaitForChild("ReplaceChoice")
local purchaseRF = RemoteFunctions:WaitForChild("PurchaseRandomWeapon")
local getCostRF = RemoteFunctions:WaitForChild("GetRandomWeaponCost")

local isUIOpen = false
local pendingReplaceData = nil -- Stores data from server if inventory is full

-- Theme Constants
local COLORS = {
	BACKGROUND = Color3.fromRGB(20, 15, 15), -- Very dark rusty
	PANEL = Color3.fromRGB(35, 30, 30),
	ACCENT_ORANGE = Color3.fromRGB(200, 80, 40), -- Rust/Blood Orange
	ACCENT_GREEN = Color3.fromRGB(80, 160, 60), -- Toxic Green
	TEXT_MAIN = Color3.fromRGB(220, 220, 210), -- Off-white
	TEXT_DIM = Color3.fromRGB(120, 110, 110),
	BORDER = Color3.fromRGB(60, 50, 50),
}

local FONT_HEADER = Enum.Font.SpecialElite
local FONT_BODY = Enum.Font.PatrickHand

-- Create Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RandomWeaponShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Helper: Create a Grunge Background Frame
local function createPanel(parent, size, pos, name)
	local frame = Instance.new("Frame")
	frame.Name = name or "Panel"
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = COLORS.PANEL
	frame.BorderSizePixel = 0
	frame.Parent = parent

	-- Add visual noise/grunge (simulated with strokes and corners)
	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 4)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = COLORS.BORDER
	stroke.Thickness = 2

	return frame
end

-- Helper: Create 3D Viewport
local function createWeaponViewport(weaponName, parentFrame)
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, 0, 1, 0)
	vp.BackgroundTransparency = 1
	vp.Parent = parentFrame

	local cam = Instance.new("Camera")
	vp.CurrentCamera = cam
	cam.Parent = vp

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = vp

	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0
	part.Parent = worldModel

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh

	local data = WeaponModule.Weapons[weaponName]
	if data and data.Skins and data.Skins["Default Skin"] then
		mesh.MeshId = data.Skins["Default Skin"].MeshId
		mesh.TextureId = data.Skins["Default Skin"].TextureId
		mesh.Scale = Vector3.new(1.5, 1.5, 1.5) -- Slightly larger for visibility
	else
		mesh.MeshType = Enum.MeshType.Brick
	end
	mesh.Parent = part
	part.Position = Vector3.new(0, 0, 0)

	cam.CFrame = CFrame.new(Vector3.new(2, 1, 2), Vector3.new(0, 0, 0))

	-- Spin animation
	local rot = 0
	local conn 
	conn = RunService.RenderStepped:Connect(function(dt)
		if not vp:IsDescendantOf(game) then
			conn:Disconnect()
			return
		end
		rot = rot + dt * 1
		part.CFrame = CFrame.Angles(0, rot, 0) * CFrame.Angles(math.rad(-10), 0, 0)
	end)

	return vp
end

-- ============================================================================
-- REPLACE UI (Inventory Full)
-- ============================================================================
local replaceUIOverlay = nil
local cardButtons = {}
local currentSelectionIndex = -1
local replaceBtnRef = nil

local function closeReplaceUI(wasCancelled)
	if wasCancelled then
		replaceChoiceEv:FireServer(-1)
	end

	if replaceUIOverlay then replaceUIOverlay:Destroy() replaceUIOverlay = nil end

	-- Remove global blur
	for _, v in pairs(game.Lighting:GetChildren()) do
		if v:IsA("BlurEffect") and v.Name == "ShopBlur" then
			v:Destroy()
		end
	end

	isUIOpen = false
	pendingReplaceData = nil
end

local function createCard(parent, weaponName, index, onSelect)
	local stats = WeaponModule.Weapons[weaponName] or {}

	local btn = Instance.new("TextButton")
	btn.Name = "Card_" .. index
	btn.Size = UDim2.new(1, 0, 0, 80)
	btn.BackgroundColor3 = COLORS.PANEL
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = parent

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = COLORS.BORDER
	stroke.Thickness = 1
	stroke.Name = "UIStroke"

	-- Icon Viewport
	local iconBg = Instance.new("Frame", btn)
	iconBg.Size = UDim2.new(0, 60, 0, 60)
	iconBg.Position = UDim2.new(0, 10, 0.5, -30)
	iconBg.BackgroundColor3 = Color3.new(0,0,0)
	iconBg.BackgroundTransparency = 0.5
	createWeaponViewport(weaponName, iconBg)

	-- Name
	local nameLabel = Instance.new("TextLabel", btn)
	nameLabel.Size = UDim2.new(0, 200, 0, 25)
	nameLabel.Position = UDim2.new(0, 80, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = stats.DisplayName or weaponName
	nameLabel.TextColor3 = COLORS.TEXT_MAIN
	nameLabel.Font = FONT_BODY
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = btn

	-- Selection Logic
	btn.MouseButton1Click:Connect(function()
		onSelect(index, btn)
	end)

	return btn
end

local function showReplaceUI()
	if not pendingReplaceData then return end
	local currentNames = pendingReplaceData.currentNames
	local newName = pendingReplaceData.newName

	isUIOpen = true

	-- Ensure Blur persists
	local blur = game.Lighting:FindFirstChild("ShopBlur")
	if not blur then
		blur = Instance.new("BlurEffect", game.Lighting)
		blur.Name = "ShopBlur"
		blur.Size = 16
	end

	replaceUIOverlay = Instance.new("Frame")
	replaceUIOverlay.Name = "ReplaceUI"
	replaceUIOverlay.Size = UDim2.new(1, 0, 1, 0)
	replaceUIOverlay.BackgroundTransparency = 1
	replaceUIOverlay.ZIndex = 110
	replaceUIOverlay.Parent = screenGui

	local container = createPanel(replaceUIOverlay, UDim2.new(0.8, 0, 0.8, 0), UDim2.new(0.5, -0.4*screenGui.AbsoluteSize.X, 0.5, -0.4*screenGui.AbsoluteSize.Y), "Container")
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)

	-- Title
	local title = Instance.new("TextLabel", container)
	title.Text = "INVENTORY FULL"
	title.Font = FONT_HEADER
	title.TextSize = 40
	title.TextColor3 = COLORS.ACCENT_ORANGE
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundTransparency = 1
	title.Parent = container

	local sub = Instance.new("TextLabel", container)
	sub.Text = "Scrap the new find, or swap it with an old trusty?"
	sub.Font = FONT_BODY
	sub.TextSize = 20
	sub.TextColor3 = COLORS.TEXT_DIM
	sub.Size = UDim2.new(1, 0, 0, 30)
	sub.Position = UDim2.new(0, 0, 0, 50)
	sub.BackgroundTransparency = 1
	sub.Parent = container

	-- Content Layout (Split Left/Right)
	local content = Instance.new("Frame", container)
	content.Size = UDim2.new(1, -40, 1, -140)
	content.Position = UDim2.new(0, 20, 0, 90)
	content.BackgroundTransparency = 1
	content.Parent = container

	-- Left: New Weapon
	local left = Instance.new("Frame", content)
	left.Size = UDim2.new(0.4, -10, 1, 0)
	left.BackgroundColor3 = Color3.new(0,0,0)
	left.BackgroundTransparency = 0.5
	left.Parent = content

	local newLabel = Instance.new("TextLabel", left)
	newLabel.Text = "NEW ACQUISITION"
	newLabel.Size = UDim2.new(1, 0, 0, 30)
	newLabel.Font = FONT_HEADER
	newLabel.TextColor3 = COLORS.ACCENT_GREEN
	newLabel.BackgroundTransparency = 1
	newLabel.Parent = left

	local vpFrame = Instance.new("Frame", left)
	vpFrame.Size = UDim2.new(0.8, 0, 0.4, 0)
	vpFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
	vpFrame.BackgroundTransparency = 1
	vpFrame.Parent = left
	createWeaponViewport(newName, vpFrame)

	local nameLbl = Instance.new("TextLabel", left)
	nameLbl.Text = (WeaponModule.Weapons[newName] and WeaponModule.Weapons[newName].DisplayName) or newName
	nameLbl.Size = UDim2.new(1, 0, 0, 40)
	nameLbl.Position = UDim2.new(0, 0, 0.6, 0)
	nameLbl.Font = FONT_HEADER
	nameLbl.TextSize = 28
	nameLbl.TextColor3 = COLORS.TEXT_MAIN
	nameLbl.BackgroundTransparency = 1
	nameLbl.Parent = left

	-- Right: Inventory List
	local right = Instance.new("ScrollingFrame", content)
	right.Size = UDim2.new(0.6, -10, 1, 0)
	right.Position = UDim2.new(0.4, 20, 0, 0)
	right.BackgroundTransparency = 1
	right.ScrollBarThickness = 4
	right.Parent = content

	local listLayout = Instance.new("UIListLayout", right)
	listLayout.Padding = UDim.new(0, 10)

	cardButtons = {}

	local function updateSelection(idx, clickedBtn)
		currentSelectionIndex = idx
		for _, btn in ipairs(cardButtons) do
			local s = btn:FindFirstChild("UIStroke")
			if btn == clickedBtn then
				s.Color = COLORS.ACCENT_ORANGE
				s.Thickness = 2
			else
				s.Color = COLORS.BORDER
				s.Thickness = 1
			end
		end
		if replaceBtnRef then
			replaceBtnRef.BackgroundColor3 = COLORS.ACCENT_ORANGE
			replaceBtnRef.TextTransparency = 0
		end
	end

	for i, name in ipairs(currentNames) do
		local btn = createCard(right, name, i, updateSelection)
		table.insert(cardButtons, btn)
	end
	right.CanvasSize = UDim2.new(0, 0, 0, #cardButtons * 90)

	-- Footer Buttons
	local footer = Instance.new("Frame", container)
	footer.Size = UDim2.new(1, -40, 0, 50)
	footer.Position = UDim2.new(0, 20, 1, -60)
	footer.BackgroundTransparency = 1
	footer.Parent = container

	local discardBtn = Instance.new("TextButton", footer)
	discardBtn.Text = "SCRAP NEW (-)"
	discardBtn.Size = UDim2.new(0.45, 0, 1, 0)
	discardBtn.BackgroundColor3 = COLORS.PANEL
	discardBtn.TextColor3 = COLORS.TEXT_DIM
	discardBtn.Font = FONT_HEADER
	discardBtn.TextSize = 20
	discardBtn.Parent = footer

	local replaceBtn = Instance.new("TextButton", footer)
	replaceBtn.Text = "SWAP SELECTED"
	replaceBtn.Size = UDim2.new(0.45, 0, 1, 0)
	replaceBtn.Position = UDim2.new(0.55, 0, 0, 0)
	replaceBtn.BackgroundColor3 = COLORS.PANEL -- Dim until selected
	replaceBtn.TextColor3 = COLORS.TEXT_MAIN
	replaceBtn.TextTransparency = 0.5
	replaceBtn.Font = FONT_HEADER
	replaceBtn.TextSize = 20
	replaceBtn.Parent = footer
	replaceBtnRef = replaceBtn

	-- Stylize buttons
	for _, btn in pairs({discardBtn, replaceBtn}) do
		local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
		local s = Instance.new("UIStroke", btn); s.Color = COLORS.BORDER; s.Thickness = 2; s.Parent = btn
	end

	discardBtn.MouseButton1Click:Connect(function()
		closeReplaceUI(true)
	end)

	replaceBtn.MouseButton1Click:Connect(function()
		if currentSelectionIndex ~= -1 then
			replaceChoiceEv:FireServer(currentSelectionIndex)
			closeReplaceUI(false)
		end
	end)
end

-- ============================================================================
-- MYSTERY CRATE / SPINNING UI
-- ============================================================================
local spinFrame = nil

local function showSpinUI(finalWeaponName, onComplete)
	if spinFrame then spinFrame:Destroy() end
	isUIOpen = true

	-- Blur Background
	local blur = Instance.new("BlurEffect", game.Lighting)
	blur.Name = "ShopBlur"
	blur.Size = 0
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 16}):Play()

	spinFrame = Instance.new("Frame")
	spinFrame.Name = "SpinUI"
	spinFrame.Size = UDim2.new(1, 0, 1, 0)
	spinFrame.BackgroundTransparency = 0.3
	spinFrame.BackgroundColor3 = Color3.new(0,0,0)
	spinFrame.ZIndex = 100
	spinFrame.Parent = screenGui

	local container = createPanel(spinFrame, UDim2.new(0, 400, 0, 300), UDim2.new(0.5, -200, 0.5, -150), "Container")
	container.ClipsDescendants = true

	-- Header
	local header = Instance.new("TextLabel", container)
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundTransparency = 1
	header.Text = "MYSTERY CACHE"
	header.Font = FONT_HEADER
	header.TextSize = 32
	header.TextColor3 = COLORS.ACCENT_ORANGE
	header.Parent = container

	-- The "Reel"
	local reelFrame = Instance.new("Frame", container)
	reelFrame.Size = UDim2.new(0, 200, 0, 150)
	reelFrame.Position = UDim2.new(0.5, -100, 0.3, 0)
	reelFrame.BackgroundColor3 = Color3.new(0,0,0)
	reelFrame.BorderSizePixel = 2
	reelFrame.BorderColor3 = COLORS.ACCENT_GREEN

	local itemLabel = Instance.new("TextLabel", container)
	itemLabel.Size = UDim2.new(1, 0, 0, 40)
	itemLabel.Position = UDim2.new(0, 0, 0.85, 0)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Font = FONT_BODY
	itemLabel.TextSize = 24
	itemLabel.TextColor3 = COLORS.TEXT_MAIN
	itemLabel.Text = "ROLLING..."
	itemLabel.Parent = container

	-- Build a pool of random weapon names for the visual spin
	local pool = {}
	for name, _ in pairs(WeaponModule.Weapons) do
		table.insert(pool, name)
	end

	-- Current VP reference
	local currentVP = nil

	local function showItem(name)
		if currentVP then currentVP:Destroy() end
		currentVP = createWeaponViewport(name, reelFrame)
		itemLabel.Text = (WeaponModule.Weapons[name] and WeaponModule.Weapons[name].DisplayName) or name
	end

	-- Spin Logic
	task.spawn(function()
		local duration = 2.5 -- seconds
		local elapsed = 0
		local speed = 0.05

		-- Ramp down speed
		while elapsed < duration do
			local randName = pool[math.random(1, #pool)]
			showItem(randName)
			task.wait(speed)
			elapsed = elapsed + speed
			speed = speed * 1.1 -- Slow down
		end

		-- LAND ON FINAL
		showItem(finalWeaponName)
		itemLabel.Text = (WeaponModule.Weapons[finalWeaponName] and WeaponModule.Weapons[finalWeaponName].DisplayName) or finalWeaponName
		itemLabel.TextColor3 = COLORS.ACCENT_GREEN

		-- Flash Effect
		local flash = Instance.new("Frame", reelFrame)
		flash.Size = UDim2.new(1,0,1,0)
		flash.BackgroundColor3 = Color3.new(1,1,1)
		flash.BackgroundTransparency = 0
		flash.Parent = reelFrame
		TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

		task.wait(1) -- Show the winner for a second

		-- COMPLETE
		if onComplete then onComplete() end

		-- CLEANUP
		-- We need to check if Replace UI took over (replaceUIOverlay exists)
		if spinFrame then spinFrame:Destroy() spinFrame = nil end

		if replaceUIOverlay and replaceUIOverlay.Parent then
			-- Replace UI is active, keep blur, keep isUIOpen
		else
			-- Done, clean up blur
			if blur then blur:Destroy() end
			isUIOpen = false
		end
	end)
end

-- ============================================================================
-- MAIN LOGIC
-- ============================================================================

local function purchaseRandomWeapon()
	if isUIOpen then return end

	-- Invoke Server
	local success, result = pcall(function() return purchaseRF:InvokeServer() end)

	if not success then
		warn("Purchase failed (Server Error)")
		return
	end

	if result.success == false then
		-- Handle Errors
		if result.message == "Not enough points" then
			-- Flash red visual or sound
			local notify = Instance.new("TextLabel", screenGui)
			notify.Size = UDim2.new(1,0,0,50)
			notify.Position = UDim2.new(0,0,0.8,0)
			notify.BackgroundTransparency = 1
			notify.Text = "NOT ENOUGH CREDITS"
			notify.Font = FONT_HEADER
			notify.TextSize = 30
			notify.TextColor3 = Color3.fromRGB(255, 50, 50)
			notify.Parent = screenGui
			TweenService:Create(notify, TweenInfo.new(2), {TextTransparency = 1}):Play()
			game.Debris:AddItem(notify, 2)
		elseif result.message == "choose" then
			-- Inventory Full Case
			local newWep = result.weaponName
			-- Start Spin. When done, show Replace UI if pending data exists.
			showSpinUI(newWep, function()
				if pendingReplaceData then
					showReplaceUI()
				end
			end)
		end
	elseif result.success == true then
		-- Success Case (Inventory Not Full)
		local newWep = result.weaponName
		showSpinUI(newWep, nil)
	end
end

-- Listener for Replace UI
openReplaceUI.OnClientEvent:Connect(function(currentNames, newName, cost, hasDiscount)
	-- Store the data. DO NOT show UI yet.
	-- `purchaseRandomWeapon` will trigger `showSpinUI`, which will check this data on completion.
	pendingReplaceData = {
		currentNames = currentNames,
		newName = newName,
		cost = cost,
		hasDiscount = hasDiscount
	}
end)

-- Register Proximity Interaction via Module
local randomPart = workspace:WaitForChild("Random", 5)
local promptHandler = nil

if randomPart then
	promptHandler = ProximityUIHandler.Register({
		name = "RandomWeaponShop",
		partName = "Random",
		parent = workspace,
		searchRecursive = true,
		onToggle = function(isOpen)
			if isOpen then
				purchaseRandomWeapon()
				if promptHandler then promptHandler:SetOpen(false) end
			end
		end
	})

	-- Cost Updater (Floating Text)
	task.spawn(function()
		local attachment = randomPart:WaitForChild("Attachment", 10)
		if attachment then
			local prompt = attachment:WaitForChild("RandomPrompt", 10)
			if not prompt then return end

			while task.wait(1) do
				local success, cost = pcall(function() return getCostRF:InvokeServer() end)
				if success and cost then
					prompt.ObjectText = "MYSTERY CACHE [ $" .. cost .. " ]"
				else
					prompt.ObjectText = "MYSTERY CACHE"
				end
			end
		end
	end)
end

-- Cleanup on death
local function onCharacterAdded(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		if isUIOpen then
			closeReplaceUI(true)
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)
