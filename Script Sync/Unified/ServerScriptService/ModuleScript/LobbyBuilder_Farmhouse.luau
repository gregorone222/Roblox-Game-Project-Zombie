-- LobbyBuilder_Farmhouse.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LobbyBuilder_Farmhouse.lua
-- Script Place: Lobby
-- Theme: Abandoned Farmhouse (Survivor Basecamp) - COZY APOCALYPSE

-- PlaceId Guard: Only execute in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then
	return {} -- Return empty module for other places
end

local LobbyBuilder = {}

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- === CONFIGURATION ===
local MAP_SIZE = 200
local GROUND_LEVEL = 0

-- Cozy Apocalypse Palette (Warm, Hopeful)
local COLORS = {
	-- Woods
	WoodDark = Color3.fromRGB(70, 50, 35),
	WoodLight = Color3.fromRGB(140, 100, 65),
	WoodWeathered = Color3.fromRGB(100, 75, 55),
	WoodRed = Color3.fromRGB(120, 50, 40), -- Barn red (faded)

	-- Nature
	Grass = Color3.fromRGB(80, 110, 60),
	Dirt = Color3.fromRGB(100, 80, 60),
	Stone = Color3.fromRGB(120, 115, 110),
	Ivy = Color3.fromRGB(50, 90, 45),

	-- Fabric/Cloth
	Canvas = Color3.fromRGB(200, 185, 160),
	CanvasDirty = Color3.fromRGB(170, 155, 135),
	Blanket = Color3.fromRGB(150, 80, 70),

	-- Metal
	RustyMetal = Color3.fromRGB(130, 70, 50),
	DarkMetal = Color3.fromRGB(50, 50, 55),

	-- Lighting
	WarmLight = Color3.fromRGB(255, 190, 120),
	FireLight = Color3.fromRGB(255, 130, 50),
	StringLight = Color3.fromRGB(255, 220, 150),
}

-- === HELPER FUNCTIONS ===

local function createPart(name, size, cframe, parent, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Parent = parent
	p.Color = color or COLORS.WoodDark
	p.Material = material or Enum.Material.Wood
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	return p
end

local function createWedge(name, size, cframe, parent, color, material)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cframe
	w.Parent = parent
	w.Color = color or COLORS.WoodDark
	w.Material = material or Enum.Material.Wood
	w.Anchored = true
	return w
end

local function createLight(parent, position, color, range, brightness)
	local att = Instance.new("Attachment")
	att.Position = position
	att.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = true
	light.Parent = att
	return light
end

local function createSoundEmitter(name, parent, soundId, vol, loop, distance)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = vol or 0.5
	sound.Looped = loop or true
	sound.RollOffMaxDistance = distance or 100
	sound.Parent = parent
	if loop then sound:Play() end
	return sound
end

local function createFire(parent, size, color, secondaryColor)
	local fire = Instance.new("Fire")
	fire.Size = size or 8
	fire.Color = color or Color3.fromRGB(255, 100, 50)
	fire.SecondaryColor = secondaryColor or Color3.fromRGB(150, 60, 20)
	fire.Parent = parent
	return fire
end

-- === NPC SPAWNER ===

local function spawnNPC(name, cframe, parent, fallbackColor)
	local model
	local head

	local npcFolder = ServerStorage:FindFirstChild("NPC")
	local prefab = npcFolder and npcFolder:FindFirstChild(name)

	if prefab then
		model = prefab:Clone()
		model.Parent = parent
		if model.PrimaryPart then
			model:PivotTo(cframe)
		else
			model:PivotTo(cframe)
		end
		head = model:FindFirstChild("Head")
	else
		-- Fallback blocky NPC
		model = Instance.new("Model")
		model.Name = name
		model.Parent = parent

		local hrp = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), cframe, model, fallbackColor, Enum.Material.Fabric)
		hrp.Transparency = 1
		head = createPart("Head", Vector3.new(1, 1, 1), cframe * CFrame.new(0, 1.5, 0), model, Color3.fromRGB(255, 200, 180), Enum.Material.SmoothPlastic)
		createPart("Torso", Vector3.new(2, 2, 1), cframe, model, fallbackColor, Enum.Material.Fabric)

		local hum = Instance.new("Humanoid")
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.Parent = model
		model.PrimaryPart = hrp
	end

	-- Disable default name tag
	local prefabHum = model:FindFirstChild("Humanoid")
	if prefabHum then
		prefabHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	-- Add custom name tag
	if head and not head:FindFirstChild("BillboardGui") and name ~= "Alexander" then
		local bg = Instance.new("BillboardGui")
		bg.Size = UDim2.new(0, 100, 0, 50)
		bg.StudsOffset = Vector3.new(0, 2.5, 0)
		bg.AlwaysOnTop = true
		bg.Parent = head

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Text = name
		txt.TextColor3 = Color3.new(1, 1, 1)
		txt.TextStrokeTransparency = 0
		txt.Font = Enum.Font.SpecialElite
		txt.TextSize = 20
		txt.Parent = bg
	end

	-- Anchor all parts
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = true
		end
	end

	return model
end

-- === INTERACTION HELPER ===

local function createInteraction(name, cframe, size, promptText, parent)
	local part = createPart(name, size, cframe, parent, Color3.new(0, 1, 0), Enum.Material.Neon)
	part.Transparency = 1
	part.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = promptText
	prompt.ActionText = "Interact"
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	return part
end

-- === STRUCTURE BUILDERS ===

local function buildMainHouse(parent, origin)
	local house = Instance.new("Model")
	house.Name = "MainHouse"
	house.Parent = parent

	local width, depth, height = 40, 25, 12
	local floorY = origin.Y

	-- Floor
	createPart("Floor", Vector3.new(width, 1, depth), CFrame.new(origin.X, floorY, origin.Z), house, COLORS.WoodDark, Enum.Material.WoodPlanks)

	-- Walls with gaps for windows/doors
	-- Front wall (with door gap)
	createPart("WallFront_L", Vector3.new(15, height, 1), CFrame.new(origin.X - 12.5, floorY + height/2, origin.Z - depth/2), house, COLORS.WoodWeathered, Enum.Material.WoodPlanks)
	createPart("WallFront_R", Vector3.new(15, height, 1), CFrame.new(origin.X + 12.5, floorY + height/2, origin.Z - depth/2), house, COLORS.WoodWeathered, Enum.Material.WoodPlanks)
	createPart("WallFront_Top", Vector3.new(10, 4, 1), CFrame.new(origin.X, floorY + height - 2, origin.Z - depth/2), house, COLORS.WoodWeathered, Enum.Material.WoodPlanks)

	-- Back wall
	createPart("WallBack", Vector3.new(width, height, 1), CFrame.new(origin.X, floorY + height/2, origin.Z + depth/2), house, COLORS.WoodWeathered, Enum.Material.WoodPlanks)

	-- Side walls
	createPart("WallLeft", Vector3.new(1, height, depth), CFrame.new(origin.X - width/2, floorY + height/2, origin.Z), house, COLORS.WoodWeathered, Enum.Material.WoodPlanks)
	createPart("WallRight", Vector3.new(1, height, depth), CFrame.new(origin.X + width/2, floorY + height/2, origin.Z), house, COLORS.WoodWeathered, Enum.Material.WoodPlanks)

	-- Roof (A-frame) - Sloped parts with gap in middle for ridge
	local roofSlopeWidth = width/2 - 2  -- Shorter so they don't overlap
	local roofPeakHeight = 8
	local roofAngle = math.rad(22)  -- Fixed angle for consistency

	-- Left roof - positioned to end before center
	local roofL = createPart("RoofLeft", Vector3.new(roofSlopeWidth, 2, depth + 4), 
		CFrame.new(origin.X - width/4 - 3, floorY + height + 3, origin.Z) 
			* CFrame.Angles(0, 0, roofAngle), 
		house, COLORS.WoodDark, Enum.Material.Slate)

	-- Right roof - mirror, ends before center
	local roofR = createPart("RoofRight", Vector3.new(roofSlopeWidth, 2, depth + 4), 
		CFrame.new(origin.X + width/4 + 3, floorY + height + 3, origin.Z) 
			* CFrame.Angles(0, 0, -roofAngle), 
		house, COLORS.WoodDark, Enum.Material.Slate)

	-- Ridge cap - wide enough to cover center gap
	createPart("RoofRidge", Vector3.new(12, 3, depth + 4), 
		CFrame.new(origin.X, floorY + height + roofPeakHeight - 2, origin.Z), 
		house, COLORS.WoodDark, Enum.Material.Slate)

	-- Porch
	local porchDepth = 8
	createPart("Porch", Vector3.new(width + 4, 0.5, porchDepth), CFrame.new(origin.X, floorY, origin.Z - depth/2 - porchDepth/2), house, COLORS.WoodLight, Enum.Material.WoodPlanks)

	-- Porch pillars
	createPart("PorchPillarL", Vector3.new(1.5, height - 2, 1.5), CFrame.new(origin.X - width/2 + 2, floorY + (height-2)/2, origin.Z - depth/2 - porchDepth + 2), house, COLORS.WoodDark, Enum.Material.Wood)
	createPart("PorchPillarR", Vector3.new(1.5, height - 2, 1.5), CFrame.new(origin.X + width/2 - 2, floorY + (height-2)/2, origin.Z - depth/2 - porchDepth + 2), house, COLORS.WoodDark, Enum.Material.Wood)

	-- Porch roof
	createPart("PorchRoof", Vector3.new(width + 4, 0.5, porchDepth + 2), CFrame.new(origin.X, floorY + height - 2, origin.Z - depth/2 - porchDepth/2), house, COLORS.WoodDark, Enum.Material.Slate)

	-- === INTERIOR PROPS ===

	-- Fireplace
	local fpX, fpZ = origin.X, origin.Z + depth/2 - 3
	createPart("FireplaceBase", Vector3.new(8, 6, 4), CFrame.new(fpX, floorY + 3.5, fpZ), house, COLORS.Stone, Enum.Material.Brick)
	local firePart = createPart("FirePit", Vector3.new(4, 1, 2), CFrame.new(fpX, floorY + 1.5, fpZ - 1.5), house, Color3.new(0.1, 0.1, 0.1), Enum.Material.Slate)
	createFire(firePart, 10)
	createLight(firePart, Vector3.new(0, 2, 0), COLORS.FireLight, 40, 2)
	createSoundEmitter("FireCrackle", firePart, "rbxassetid://9075030806", 0.5, true, 30)

	-- Sofa (damaged)
	createPart("SofaBase", Vector3.new(8, 2, 3), CFrame.new(origin.X - 10, floorY + 1.5, origin.Z + 5), house, COLORS.Blanket, Enum.Material.Fabric)
	createPart("SofaBack", Vector3.new(8, 3, 0.5), CFrame.new(origin.X - 10, floorY + 4, origin.Z + 6.5), house, COLORS.Blanket, Enum.Material.Fabric)

	-- Coffee table
	createPart("CoffeeTable", Vector3.new(4, 1.5, 2.5), CFrame.new(origin.X - 10, floorY + 1, origin.Z + 2), house, COLORS.WoodLight, Enum.Material.Wood)

	-- Old radio on table
	createPart("OldRadio", Vector3.new(1.5, 1, 0.8), CFrame.new(origin.X - 10, floorY + 2.3, origin.Z + 2), house, Color3.fromRGB(60, 50, 45), Enum.Material.Wood)

	-- Rug
	local rug = createPart("Rug", Vector3.new(10, 0.1, 8), CFrame.new(origin.X - 8, floorY + 0.6, origin.Z + 2), house, Color3.fromRGB(120, 80, 60), Enum.Material.Fabric)

	-- Bookshelf
	createPart("Bookshelf", Vector3.new(6, 8, 1.5), CFrame.new(origin.X + 15, floorY + 4.5, origin.Z + depth/2 - 2), house, COLORS.WoodDark, Enum.Material.Wood)

	return house, Vector3.new(origin.X, floorY + 1, origin.Z - depth/2 - porchDepth/2) -- Return porch center for spawn
end

local function buildBarn(parent, origin)
	local barn = Instance.new("Model")
	barn.Name = "Barn"
	barn.Parent = parent

	local width, depth, height = 35, 30, 18
	local floorY = origin.Y

	-- Floor
	createPart("BarnFloor", Vector3.new(width, 1, depth), CFrame.new(origin.X, floorY, origin.Z), barn, COLORS.Dirt, Enum.Material.Ground)

	-- Walls (barn red, weathered)
	createPart("WallFront", Vector3.new(width, height, 1), CFrame.new(origin.X, floorY + height/2, origin.Z - depth/2), barn, COLORS.WoodRed, Enum.Material.WoodPlanks)
	createPart("WallBack", Vector3.new(width, height, 1), CFrame.new(origin.X, floorY + height/2, origin.Z + depth/2), barn, COLORS.WoodRed, Enum.Material.WoodPlanks)
	createPart("WallLeft", Vector3.new(1, height, depth), CFrame.new(origin.X - width/2, floorY + height/2, origin.Z), barn, COLORS.WoodRed, Enum.Material.WoodPlanks)
	-- Right wall has opening
	createPart("WallRight_Top", Vector3.new(1, 6, depth), CFrame.new(origin.X + width/2, floorY + height - 3, origin.Z), barn, COLORS.WoodRed, Enum.Material.WoodPlanks)

	-- Barn door opening (right side)

	-- Roof - Barn A-frame with gap for ridge
	local roofSlopeWidth = width/2 - 2
	local roofPeakHeight = 10
	local roofAngle = math.rad(20)

	-- Left roof slope - ends before center
	local barnRoofL = createPart("BarnRoofL", Vector3.new(roofSlopeWidth, 2, depth + 4), 
		CFrame.new(origin.X - width/4 - 3, floorY + height + 4, origin.Z) 
			* CFrame.Angles(0, 0, roofAngle), 
		barn, COLORS.WoodDark, Enum.Material.Slate)

	-- Right roof slope - ends before center
	local barnRoofR = createPart("BarnRoofR", Vector3.new(roofSlopeWidth, 2, depth + 4), 
		CFrame.new(origin.X + width/4 + 3, floorY + height + 4, origin.Z) 
			* CFrame.Angles(0, 0, -roofAngle), 
		barn, COLORS.WoodDark, Enum.Material.Slate)

	-- Roof ridge cap - covers center gap
	createPart("BarnRoofRidge", Vector3.new(14, 3, depth + 4), 
		CFrame.new(origin.X, floorY + height + roofPeakHeight - 2, origin.Z), 
		barn, COLORS.WoodDark, Enum.Material.Slate)

	-- === INTERIOR: QUARTERMASTER AREA ===

	-- Workbench
	local benchPos = CFrame.new(origin.X, floorY + 2, origin.Z)
	createPart("Workbench", Vector3.new(10, 3, 4), benchPos, barn, COLORS.WoodLight, Enum.Material.WoodPlanks)
	-- Tools on bench
	createPart("ToolBox", Vector3.new(2, 1.5, 1.5), benchPos * CFrame.new(-3, 2, 0), barn, COLORS.RustyMetal, Enum.Material.Metal)
	createPart("Hammer", Vector3.new(0.3, 1.5, 0.3), benchPos * CFrame.new(2, 2, 0.5) * CFrame.Angles(0, 0, math.rad(30)), barn, COLORS.WoodDark, Enum.Material.Wood)

	-- Weapon rack
	createPart("WeaponRack", Vector3.new(1, 8, 6), CFrame.new(origin.X - width/2 + 3, floorY + 5, origin.Z - 5), barn, COLORS.WoodDark, Enum.Material.Wood)

	-- Barrels
	for i = 1, 3 do
		local barrel = createPart("Barrel" .. i, Vector3.new(3, 4, 3), CFrame.new(origin.X + 10 + (i * 4), floorY + 2.5, origin.Z + 8), barn, COLORS.RustyMetal, Enum.Material.Metal)
		barrel.Shape = Enum.PartType.Cylinder
		barrel.CFrame = barrel.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end

	-- Hay bales
	createPart("HayBale1", Vector3.new(4, 3, 3), CFrame.new(origin.X - 10, floorY + 2, origin.Z + 10), barn, Color3.fromRGB(180, 160, 80), Enum.Material.Grass)
	createPart("HayBale2", Vector3.new(4, 3, 3), CFrame.new(origin.X - 6, floorY + 2, origin.Z + 10), barn, Color3.fromRGB(180, 160, 80), Enum.Material.Grass)

	-- Lanterns
	local lantern1 = createPart("Lantern1", Vector3.new(1, 1.5, 1), CFrame.new(origin.X - 3, floorY + 5, origin.Z - depth/2 + 3), barn, COLORS.RustyMetal, Enum.Material.Metal)
	createLight(lantern1, Vector3.new(0, 0, 0), COLORS.WarmLight, 25, 1.5)

	local lantern2 = createPart("Lantern2", Vector3.new(1, 1.5, 1), CFrame.new(origin.X + 3, floorY + 5, origin.Z - depth/2 + 3), barn, COLORS.RustyMetal, Enum.Material.Metal)
	createLight(lantern2, Vector3.new(0, 0, 0), COLORS.WarmLight, 25, 1.5)

	return barn
end

local function buildMedicalTent(parent, origin)
	local tent = Instance.new("Model")
	tent.Name = "MedicalTent"
	tent.Parent = parent

	local width, depth, height = 16, 12, 10
	local floorY = origin.Y

	-- Ground tarp
	createPart("Tarp", Vector3.new(width + 4, 0.1, depth + 4), CFrame.new(origin.X, floorY, origin.Z), tent, COLORS.CanvasDirty, Enum.Material.Fabric)

	-- Tent poles
	createPart("PoleL", Vector3.new(0.5, height, 0.5), CFrame.new(origin.X - width/2, floorY + height/2, origin.Z), tent, COLORS.WoodDark, Enum.Material.Wood)
	createPart("PoleR", Vector3.new(0.5, height, 0.5), CFrame.new(origin.X + width/2, floorY + height/2, origin.Z), tent, COLORS.WoodDark, Enum.Material.Wood)
	createPart("PoleCenter", Vector3.new(0.5, height + 3, 0.5), CFrame.new(origin.X, floorY + (height + 3)/2, origin.Z), tent, COLORS.WoodDark, Enum.Material.Wood)

	-- Ridge pole
	createPart("Ridge", Vector3.new(width + 2, 0.4, 0.4), CFrame.new(origin.X, floorY + height + 2, origin.Z), tent, COLORS.WoodDark, Enum.Material.Wood)

	-- Tent fabric - Sloped canvas with LARGE gap for ridge
	local canvasWidth = width/2 - 4  -- Much shorter to avoid overlap
	local roofAngle = math.rad(40)

	-- Left canvas slope - positioned far from center
	local canvasL = createPart("CanvasL", Vector3.new(canvasWidth, 0.3, depth + 2), 
		CFrame.new(origin.X - width/4 - 3, floorY + height/2, origin.Z) 
			* CFrame.Angles(0, 0, roofAngle), 
		tent, COLORS.Canvas, Enum.Material.Fabric)

	-- Right canvas slope - positioned far from center
	local canvasR = createPart("CanvasR", Vector3.new(canvasWidth, 0.3, depth + 2), 
		CFrame.new(origin.X + width/4 + 3, floorY + height/2, origin.Z) 
			* CFrame.Angles(0, 0, -roofAngle), 
		tent, COLORS.Canvas, Enum.Material.Fabric)

	-- Canvas ridge cap - WIDE (8 studs) to cover large center gap
	createPart("CanvasRidge", Vector3.new(8, 0.5, depth + 2), 
		CFrame.new(origin.X, floorY + height + 0.5, origin.Z), 
		tent, COLORS.Canvas, Enum.Material.Fabric)

	-- Back wall
	createPart("TentBack", Vector3.new(width, height - 2, 0.2), CFrame.new(origin.X, floorY + (height - 2)/2 + 1, origin.Z + depth/2), tent, COLORS.Canvas, Enum.Material.Fabric)

	-- Red cross decal
	local crossV = createPart("CrossV", Vector3.new(0.5, 3, 0.3), CFrame.new(origin.X, floorY + 5, origin.Z + depth/2 - 0.2), tent, Color3.fromRGB(200, 50, 50), Enum.Material.SmoothPlastic)
	local crossH = createPart("CrossH", Vector3.new(2, 0.5, 0.3), CFrame.new(origin.X, floorY + 5, origin.Z + depth/2 - 0.2), tent, Color3.fromRGB(200, 50, 50), Enum.Material.SmoothPlastic)

	-- Stretcher
	createPart("Stretcher", Vector3.new(3, 0.3, 6), CFrame.new(origin.X - 4, floorY + 1.5, origin.Z), tent, Color3.fromRGB(50, 100, 50), Enum.Material.Fabric)
	createPart("StretcherLegs", Vector3.new(2.5, 1.2, 5.5), CFrame.new(origin.X - 4, floorY + 0.7, origin.Z), tent, COLORS.DarkMetal, Enum.Material.Metal)

	-- Medical crates
	createPart("MedCrate1", Vector3.new(2.5, 2, 2), CFrame.new(origin.X + 4, floorY + 1.5, origin.Z - 2), tent, COLORS.Canvas, Enum.Material.Plastic)
	createPart("MedCrate2", Vector3.new(2.5, 2, 2), CFrame.new(origin.X + 4, floorY + 1.5, origin.Z + 2), tent, COLORS.Canvas, Enum.Material.Plastic)

	-- Lantern
	local lantern = createPart("TentLantern", Vector3.new(0.8, 1.2, 0.8), CFrame.new(origin.X, floorY + height - 1, origin.Z), tent, COLORS.RustyMetal, Enum.Material.Metal)
	createLight(lantern, Vector3.new(0, -1, 0), COLORS.WarmLight, 20, 1)

	return tent
end

local function buildCampfire(parent, origin)
	local fire = Instance.new("Model")
	fire.Name = "Campfire"
	fire.Parent = parent

	local floorY = origin.Y

	-- Stone ring
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local x = math.cos(angle) * 3
		local z = math.sin(angle) * 3
		createPart("Stone" .. i, Vector3.new(1.5, 1, 1.5), CFrame.new(origin.X + x, floorY + 0.5, origin.Z + z), fire, COLORS.Stone, Enum.Material.Slate)
	end

	-- Fire pit
	local firePit = createPart("FirePit", Vector3.new(4, 0.5, 4), CFrame.new(origin.X, floorY + 0.3, origin.Z), fire, Color3.new(0.1, 0.05, 0.02), Enum.Material.Slate)

	-- Logs
	createPart("Log1", Vector3.new(0.8, 0.8, 3), CFrame.new(origin.X, floorY + 0.8, origin.Z) * CFrame.Angles(0, math.rad(30), 0), fire, COLORS.WoodDark, Enum.Material.Wood)
	createPart("Log2", Vector3.new(0.8, 0.8, 3), CFrame.new(origin.X, floorY + 0.8, origin.Z) * CFrame.Angles(0, math.rad(-50), 0), fire, COLORS.WoodDark, Enum.Material.Wood)

	-- Fire
	createFire(firePit, 12, Color3.fromRGB(255, 120, 40), Color3.fromRGB(180, 60, 20))
	createLight(firePit, Vector3.new(0, 3, 0), COLORS.FireLight, 50, 2.5)
	createSoundEmitter("CampfireSound", firePit, "rbxassetid://9075030806", 0.6, true, 50)

	-- Cooking pot
	local pot = createPart("CookingPot", Vector3.new(2, 1.5, 2), CFrame.new(origin.X + 1, floorY + 2, origin.Z), fire, COLORS.DarkMetal, Enum.Material.Metal)

	-- Seating (log benches)
	for i = 0, 3 do
		local angle = (i / 4) * math.pi * 2 + math.rad(45)
		local x = math.cos(angle) * 6
		local z = math.sin(angle) * 6
		local bench = createPart("LogBench" .. i, Vector3.new(5, 1.5, 1.5), 
			CFrame.new(origin.X + x, floorY + 0.8, origin.Z + z) * CFrame.Angles(0, angle + math.rad(90), 0), 
			fire, COLORS.WoodWeathered, Enum.Material.Wood)
	end

	return fire
end

local function buildLeaderboardArea(parent, origin)
	local area = Instance.new("Model")
	area.Name = "LeaderboardArea"
	area.Parent = parent

	-- Wooden frame wall for leaderboards
	createPart("BoardWall", Vector3.new(50, 15, 2), CFrame.new(origin.X, origin.Y + 8, origin.Z + 20), area, COLORS.WoodWeathered, Enum.Material.WoodPlanks)

	-- Create leaderboard screens folder
	local lbFolder = Workspace:FindFirstChild("Leaderboard")
	if lbFolder then
		lbFolder:ClearAllChildren()
	else
		lbFolder = Instance.new("Folder")
		lbFolder.Name = "Leaderboard"
		lbFolder.Parent = Workspace
	end

	local boards = {
		"KillLeaderboard",
		"TDLeaderboard",
		"APLeaderboard",
		"LVLeaderboard",
		"MPLeaderboard",
		"GlobalMission"
	}

	local spacing = 8
	local startX = origin.X - (#boards - 1) * spacing / 2

	for i, boardName in ipairs(boards) do
		local x = startX + (i - 1) * spacing
		-- Screen positioned 2 studs in front of wall to avoid z-fighting
		local screen = createPart(boardName, Vector3.new(6, 10, 0.5), CFrame.new(x, origin.Y + 8, origin.Z + 17), lbFolder, Color3.fromRGB(30, 35, 30), Enum.Material.Glass)
	end

	-- Decorative tree with string lights
	local treePos = Vector3.new(origin.X - 30, origin.Y, origin.Z + 10)
	createPart("TreeTrunk", Vector3.new(3, 15, 3), CFrame.new(treePos.X, treePos.Y + 8, treePos.Z), area, Color3.fromRGB(70, 55, 40), Enum.Material.Wood)
	local canopy = createPart("TreeCanopy", Vector3.new(15, 12, 15), CFrame.new(treePos.X, treePos.Y + 18, treePos.Z), area, COLORS.Ivy, Enum.Material.Grass)
	canopy.Shape = Enum.PartType.Ball

	-- String lights on tree
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local radius = 6 + math.random() * 2
		local x = treePos.X + math.cos(angle) * radius
		local z = treePos.Z + math.sin(angle) * radius
		local y = treePos.Y + 14 + math.random() * 4
		local lightBulb = createPart("StringLight" .. i, Vector3.new(0.4, 0.4, 0.4), CFrame.new(x, y, z), area, COLORS.StringLight, Enum.Material.Neon)
		createLight(lightBulb, Vector3.new(0, 0, 0), COLORS.StringLight, 8, 0.8)
	end

	-- Fireflies particle emitter
	local fireflyPart = createPart("FireflyEmitter", Vector3.new(30, 10, 30), CFrame.new(origin.X, origin.Y + 8, origin.Z + 15), area, Color3.new(1, 1, 1), Enum.Material.Air)
	fireflyPart.Transparency = 1
	fireflyPart.CanCollide = false

	local fireflyEmitter = Instance.new("ParticleEmitter")
	fireflyEmitter.Name = "Fireflies"
	fireflyEmitter.Texture = "rbxassetid://292289455" -- Glow particle
	fireflyEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 255, 100))
	fireflyEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	fireflyEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	fireflyEmitter.LightEmission = 1
	fireflyEmitter.LightInfluence = 0
	fireflyEmitter.Lifetime = NumberRange.new(3, 6)
	fireflyEmitter.Rate = 5
	fireflyEmitter.Speed = NumberRange.new(1, 3)
	fireflyEmitter.SpreadAngle = Vector2.new(180, 180)
	fireflyEmitter.Parent = fireflyPart

	return area
end

local function buildNostalgicProps(parent, origin)
	local props = Instance.new("Model")
	props.Name = "NostalgicProps"
	props.Parent = parent

	-- Empty Swing
	local swingPos = Vector3.new(origin.X + 60, origin.Y, origin.Z - 20)
	local swingFrame = Instance.new("Model")
	swingFrame.Name = "EmptySwing"
	swingFrame.Parent = props

	createPart("SwingPostL", Vector3.new(0.5, 10, 0.5), CFrame.new(swingPos.X - 4, swingPos.Y + 5, swingPos.Z) * CFrame.Angles(0, 0, math.rad(10)), swingFrame, COLORS.WoodDark, Enum.Material.Wood)
	createPart("SwingPostR", Vector3.new(0.5, 10, 0.5), CFrame.new(swingPos.X + 4, swingPos.Y + 5, swingPos.Z) * CFrame.Angles(0, 0, math.rad(-10)), swingFrame, COLORS.WoodDark, Enum.Material.Wood)
	createPart("SwingBar", Vector3.new(10, 0.4, 0.4), CFrame.new(swingPos.X, swingPos.Y + 9, swingPos.Z), swingFrame, COLORS.WoodDark, Enum.Material.Wood)
	createPart("SwingSeat", Vector3.new(2, 0.2, 1), CFrame.new(swingPos.X, swingPos.Y + 3, swingPos.Z), swingFrame, COLORS.WoodLight, Enum.Material.Wood)
	createPart("RopeL", Vector3.new(0.1, 6, 0.1), CFrame.new(swingPos.X - 0.8, swingPos.Y + 6, swingPos.Z), swingFrame, Color3.fromRGB(150, 130, 100), Enum.Material.Fabric)
	createPart("RopeR", Vector3.new(0.1, 6, 0.1), CFrame.new(swingPos.X + 0.8, swingPos.Y + 6, swingPos.Z), swingFrame, Color3.fromRGB(150, 130, 100), Enum.Material.Fabric)

	-- Abandoned Teddy Bear
	local teddyPos = Vector3.new(origin.X + 50, origin.Y, origin.Z + 30)
	local teddy = Instance.new("Model")
	teddy.Name = "AbandonedTeddy"
	teddy.Parent = props
	local bodyColor = Color3.fromRGB(150, 120, 90)
	createPart("TeddyBody", Vector3.new(1.5, 1.8, 1.2), CFrame.new(teddyPos.X, teddyPos.Y + 0.9, teddyPos.Z), teddy, bodyColor, Enum.Material.Fabric)
	createPart("TeddyHead", Vector3.new(1.2, 1.2, 1.2), CFrame.new(teddyPos.X, teddyPos.Y + 2.2, teddyPos.Z), teddy, bodyColor, Enum.Material.Fabric)

	-- Broken Bicycle
	local bikePos = Vector3.new(origin.X - 50, origin.Y, origin.Z - 30)
	local bike = Instance.new("Model")
	bike.Name = "BrokenBike"
	bike.Parent = props
	createPart("BikeFrame", Vector3.new(0.2, 2, 0.2), CFrame.new(bikePos.X, bikePos.Y + 1.5, bikePos.Z) * CFrame.Angles(0, 0, math.rad(20)), bike, COLORS.RustyMetal, Enum.Material.Metal)
	local wheel1 = createPart("WheelF", Vector3.new(0.3, 2, 2), CFrame.new(bikePos.X + 1.5, bikePos.Y + 1, bikePos.Z), bike, Color3.fromRGB(30, 30, 30), Enum.Material.Rubber)
	wheel1.Shape = Enum.PartType.Cylinder
	local wheel2 = createPart("WheelB", Vector3.new(0.3, 2, 2), CFrame.new(bikePos.X - 1, bikePos.Y + 1, bikePos.Z), bike, Color3.fromRGB(30, 30, 30), Enum.Material.Rubber)
	wheel2.Shape = Enum.PartType.Cylinder
	bike:PivotTo(CFrame.new(bikePos) * CFrame.Angles(0, math.rad(45), math.rad(70)))

	-- Old Pickup Truck (rusted, overgrown)
	local truckPos = Vector3.new(origin.X - 70, origin.Y, origin.Z + 40)
	local truck = Instance.new("Model")
	truck.Name = "OldPickupTruck"
	truck.Parent = props
	createPart("TruckBody", Vector3.new(12, 5, 6), CFrame.new(truckPos.X, truckPos.Y + 3, truckPos.Z), truck, COLORS.RustyMetal, Enum.Material.CorrodedMetal)
	createPart("TruckCab", Vector3.new(6, 4, 5.5), CFrame.new(truckPos.X - 3, truckPos.Y + 6.5, truckPos.Z), truck, COLORS.RustyMetal, Enum.Material.CorrodedMetal)
	createPart("TruckBed", Vector3.new(6, 2, 5.5), CFrame.new(truckPos.X + 3, truckPos.Y + 4, truckPos.Z), truck, COLORS.RustyMetal, Enum.Material.CorrodedMetal)
	-- Wheels (flat)
	for i, offset in ipairs({{-4, -3}, {-4, 3}, {4, -3}, {4, 3}}) do
		local w = createPart("TruckWheel" .. i, Vector3.new(1, 2.5, 2.5), CFrame.new(truckPos.X + offset[1], truckPos.Y + 1.3, truckPos.Z + offset[2]), truck, Color3.fromRGB(30, 30, 30), Enum.Material.Rubber)
		w.Shape = Enum.PartType.Cylinder
		w.CFrame = w.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end
	-- Ivy growing on truck
	createPart("TruckIvy", Vector3.new(4, 3, 4), CFrame.new(truckPos.X + 2, truckPos.Y + 5, truckPos.Z), truck, COLORS.Ivy, Enum.Material.Grass)

	return props
end

local function buildGachaMachine(parent, origin)
	local machine = Instance.new("Model")
	machine.Name = "Gacha"
	machine.Parent = parent
	
	local floorY = origin.Y
	
	-- Main body (retro vending machine style)
	local bodyWidth, bodyDepth, bodyHeight = 6, 4, 10
	
	-- Base platform
	createPart("GachaBase", Vector3.new(bodyWidth + 2, 1, bodyDepth + 2), 
		CFrame.new(origin.X, floorY + 0.5, origin.Z), 
		machine, COLORS.DarkMetal, Enum.Material.Metal)
	
	-- Main cabinet - store reference for ProximityPrompt
	local body = createPart("GachaBody", Vector3.new(bodyWidth, bodyHeight, bodyDepth), 
		CFrame.new(origin.X, floorY + 1 + bodyHeight/2, origin.Z), 
		machine, Color3.fromRGB(40, 45, 50), Enum.Material.Metal)
	
	-- Glass display front
	local glass = createPart("GachaGlass", Vector3.new(bodyWidth - 1, bodyHeight - 3, 0.3), 
		CFrame.new(origin.X, floorY + 1 + bodyHeight/2 + 1, origin.Z - bodyDepth/2 + 0.2), 
		machine, Color3.fromRGB(100, 200, 200), Enum.Material.Glass)
	glass.Transparency = 0.5
	
	-- Neon accent strips
	createPart("GachaNeonTop", Vector3.new(bodyWidth + 0.5, 0.3, bodyDepth + 0.5), 
		CFrame.new(origin.X, floorY + 1 + bodyHeight + 0.2, origin.Z), 
		machine, Color3.fromRGB(0, 255, 255), Enum.Material.Neon)
	createPart("GachaNeonMid", Vector3.new(bodyWidth + 0.2, 0.2, 0.2), 
		CFrame.new(origin.X, floorY + 1 + bodyHeight/2, origin.Z - bodyDepth/2), 
		machine, Color3.fromRGB(0, 255, 255), Enum.Material.Neon)
	
	-- Top decoration (capsule dome)
	local dome = createPart("GachaDome", Vector3.new(4, 4, 4), 
		CFrame.new(origin.X, floorY + 1 + bodyHeight + 2.5, origin.Z), 
		machine, Color3.fromRGB(200, 50, 50), Enum.Material.Glass)
	dome.Shape = Enum.PartType.Ball
	dome.Transparency = 0.3
	
	-- Light inside dome
	createLight(dome, Vector3.new(0, 0, 0), Color3.fromRGB(255, 100, 100), 15, 1.5)
	
	-- Interior light (cyan glow)
	local interiorLight = createPart("InteriorGlow", Vector3.new(1, 1, 1), 
		CFrame.new(origin.X, floorY + 1 + bodyHeight/2, origin.Z), 
		machine, Color3.fromRGB(0, 255, 255), Enum.Material.Neon)
	interiorLight.Transparency = 1
	createLight(interiorLight, Vector3.new(0, 0, 0), Color3.fromRGB(0, 255, 255), 12, 1)
	
	-- Text sign
	local sign = createPart("GachaSign", Vector3.new(5, 2, 0.2), 
		CFrame.new(origin.X, floorY + 1 + bodyHeight - 1.5, origin.Z - bodyDepth/2 - 0.5), 
		machine, Color3.fromRGB(20, 25, 30), Enum.Material.SmoothPlastic)
	
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.Parent = sign
	
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "GACHA"
	signText.TextColor3 = Color3.fromRGB(0, 255, 255)
	signText.Font = Enum.Font.Arcade
	signText.TextScaled = true
	signText.Parent = signGui
	
	-- Proximity Prompt - attach to GachaBody Part (ProximityPrompt requires BasePart parent)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GachaPrompt"
	prompt.ObjectText = "Gacha Machine"
	prompt.ActionText = "Open"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = body -- Attach to GachaBody Part
	
	print("[LobbyBuilder] Gacha machine built with ProximityPrompt on " .. body:GetFullName())
	
	return machine
end

-- === MAIN BUILD FUNCTION ===

function LobbyBuilder.Build()
	print("LobbyBuilder: Constructing Abandoned Farmhouse (Cozy Apocalypse)...")

	-- Cleanup
	if Workspace:FindFirstChild("LobbyEnvironment") then
		Workspace.LobbyEnvironment:Destroy()
	end

	local env = Instance.new("Folder")
	env.Name = "LobbyEnvironment"
	env.Parent = Workspace

	-- 1. GROUND
	local ground = createPart("Ground", Vector3.new(MAP_SIZE, 4, MAP_SIZE), CFrame.new(0, -2, 0), env, COLORS.Grass, Enum.Material.Grass)

	-- Dirt path
	createPart("DirtPath", Vector3.new(15, 0.2, 80), CFrame.new(0, 0.1, -20), env, COLORS.Dirt, Enum.Material.Ground)

	-- 2. STRUCTURES
	local houseOrigin = Vector3.new(0, GROUND_LEVEL + 0.5, 0)
	local house, spawnPos = buildMainHouse(env, houseOrigin)

	local barnOrigin = Vector3.new(-55, GROUND_LEVEL + 0.5, 10)
	buildBarn(env, barnOrigin)

	local tentOrigin = Vector3.new(55, GROUND_LEVEL + 0.5, 10)
	buildMedicalTent(env, tentOrigin)

	local campfireOrigin = Vector3.new(0, GROUND_LEVEL + 0.5, 35)
	buildCampfire(env, campfireOrigin)

	local lbOrigin = Vector3.new(0, GROUND_LEVEL + 0.5, 60)
	buildLeaderboardArea(env, lbOrigin)

	-- 3. NOSTALGIC PROPS
	buildNostalgicProps(env, Vector3.new(0, GROUND_LEVEL, 0))

	-- 4. SPAWN POINT
	local spawn = Instance.new("SpawnLocation")
	spawn.CFrame = CFrame.new(spawnPos + Vector3.new(0, 1, -5))
	spawn.Size = Vector3.new(20, 0.5, 20)
	spawn.Transparency = 1
	spawn.Duration = 0
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Parent = env

	-- 5. NPCs
	-- Alexander (on porch/gazebo area behind campfire)
	local alexPos = CFrame.new(0, GROUND_LEVEL + 1, 75) * CFrame.Angles(0, math.rad(180), 0)
	spawnNPC("Alexander", alexPos, env, COLORS.WoodDark)

	-- Create gazebo/teras for Alexander
	local gazebo = Instance.new("Model")
	gazebo.Name = "AlexanderGazebo"
	gazebo.Parent = env
	createPart("GazeboFloor", Vector3.new(15, 0.5, 10), CFrame.new(0, GROUND_LEVEL + 0.3, 80), gazebo, COLORS.WoodLight, Enum.Material.WoodPlanks)
	createPart("GazeboPillar1", Vector3.new(1, 8, 1), CFrame.new(-6, GROUND_LEVEL + 4.5, 75), gazebo, COLORS.WoodDark, Enum.Material.Wood)
	createPart("GazeboPillar2", Vector3.new(1, 8, 1), CFrame.new(6, GROUND_LEVEL + 4.5, 75), gazebo, COLORS.WoodDark, Enum.Material.Wood)
	createPart("GazeboPillar3", Vector3.new(1, 8, 1), CFrame.new(-6, GROUND_LEVEL + 4.5, 85), gazebo, COLORS.WoodDark, Enum.Material.Wood)
	createPart("GazeboPillar4", Vector3.new(1, 8, 1), CFrame.new(6, GROUND_LEVEL + 4.5, 85), gazebo, COLORS.WoodDark, Enum.Material.Wood)
	createPart("GazeboRoof", Vector3.new(17, 0.5, 12), CFrame.new(0, GROUND_LEVEL + 9, 80), gazebo, COLORS.WoodDark, Enum.Material.Slate)

	-- Command table with paper map
	local commandTable = createPart("CommandTable", Vector3.new(8, 2.5, 5), CFrame.new(0, GROUND_LEVEL + 1.8, 78), gazebo, COLORS.WoodLight, Enum.Material.Wood)
	
	-- Mission Briefing ProximityPrompt (for LobbyRoomUI)
	local missionPrompt = Instance.new("ProximityPrompt")
	missionPrompt.Name = "MissionBriefingPrompt"
	missionPrompt.ObjectText = "Mission Briefing"
	missionPrompt.ActionText = "View Assignments"
	missionPrompt.HoldDuration = 0
	missionPrompt.RequiresLineOfSight = false
	missionPrompt.MaxActivationDistance = 8
	missionPrompt.Parent = commandTable
	
	createPart("PaperMap", Vector3.new(6, 0.1, 4), CFrame.new(0, GROUND_LEVEL + 3.2, 78), gazebo, Color3.fromRGB(220, 200, 170), Enum.Material.SmoothPlastic)

	-- Old Radio
	createPart("CommandRadio", Vector3.new(1.5, 1, 1), CFrame.new(3, GROUND_LEVEL + 3.5, 78), gazebo, Color3.fromRGB(50, 45, 40), Enum.Material.Wood)

	-- Rocking Chair
	createPart("RockingChair", Vector3.new(3, 3, 3), CFrame.new(-4, GROUND_LEVEL + 2, 82), gazebo, COLORS.WoodWeathered, Enum.Material.Wood)

	-- Quartermaster NPC (in barn)
	local qmPos = CFrame.new(-55, GROUND_LEVEL + 1, 5) * CFrame.Angles(0, math.rad(180), 0)
	spawnNPC("Quartermaster", qmPos, env, COLORS.WoodDark)

	-- Doc NPC (in medical tent)
	local docPos = CFrame.new(tentOrigin.X, GROUND_LEVEL + 1, tentOrigin.Z) * CFrame.Angles(0, math.rad(180), 0)
	spawnNPC("Doc", docPos, env, Color3.fromRGB(80, 120, 80))

	-- Rosco NPC (near campfire, sitting on log bench)
	local roscoPos = CFrame.new(campfireOrigin.X - 5, GROUND_LEVEL + 1, campfireOrigin.Z + 4) * CFrame.Angles(0, math.rad(45), 0)
	spawnNPC("Rosco", roscoPos, env, Color3.fromRGB(150, 120, 80))

	-- Gramps NPC (on main house porch, in rocking chair area)
	local grampsPos = CFrame.new(spawnPos.X - 8, GROUND_LEVEL + 1, spawnPos.Z) * CFrame.Angles(0, math.rad(0), 0)
	spawnNPC("Gramps", grampsPos, env, Color3.fromRGB(100, 90, 80))

	-- 6. INTERACTION POINTS
	createInteraction("DialogueAlexander", alexPos * CFrame.new(0, 0, 2), Vector3.new(6, 6, 6), "Talk", env)
	createInteraction("BoosterShop", CFrame.new(tentOrigin.X, tentOrigin.Y + 2, tentOrigin.Z), Vector3.new(10, 6, 8), "Medical Supplies", env)
	createInteraction("APShop", CFrame.new(barnOrigin.X - 5, barnOrigin.Y + 2, barnOrigin.Z), Vector3.new(6, 6, 6), "Achievement Exchange", env)
	createInteraction("MPShop", CFrame.new(barnOrigin.X + 5, barnOrigin.Y + 2, barnOrigin.Z), Vector3.new(6, 6, 6), "Mission Exchange", env)
	
	-- Gacha Machine (near leaderboard area)
	local gachaMachine = buildGachaMachine(env, Vector3.new(lbOrigin.X + 35, GROUND_LEVEL + 0.5, lbOrigin.Z))

	-- StartPart for voting system
	local startPart = createPart("StartPart", Vector3.new(5, 5, 5), alexPos, env, Color3.new(1, 0, 0), Enum.Material.Neon)
	startPart.Transparency = 1
	startPart.CanCollide = false

	-- 7. LIGHTING & ATMOSPHERE (Sunset/Golden Hour)
	Lighting.ClockTime = 17.5
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(100, 80, 60)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 100, 70)
	Lighting.FogColor = Color3.fromRGB(200, 160, 130)
	Lighting.FogStart = 50
	Lighting.FogEnd = 400

	-- Setup atmosphere effects
	local atmosphere = Lighting:FindFirstChild("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "Atmosphere"
	atmosphere.Parent = Lighting
	atmosphere.Density = 0.3
	atmosphere.Haze = 1.5
	atmosphere.Glare = 0.3
	atmosphere.Color = Color3.fromRGB(200, 170, 140)
	atmosphere.Decay = Color3.fromRGB(150, 100, 80)

	-- Color correction for warm tones
	local cc = Lighting:FindFirstChild("ColorCorrection") or Instance.new("ColorCorrectionEffect")
	cc.Name = "ColorCorrection"
	cc.Parent = Lighting
	cc.Contrast = 0.05
	cc.Saturation = 0.15
	cc.TintColor = Color3.fromRGB(255, 240, 220)

	-- Sun rays
	local sunrays = Lighting:FindFirstChild("SunRays") or Instance.new("SunRaysEffect")
	sunrays.Name = "SunRays"
	sunrays.Parent = Lighting
	sunrays.Intensity = 0.15
	sunrays.Spread = 0.8

	-- Bloom
	local bloom = Lighting:FindFirstChild("Bloom") or Instance.new("BloomEffect")
	bloom.Name = "Bloom"
	bloom.Parent = Lighting
	bloom.Intensity = 0.3
	bloom.Size = 20
	bloom.Threshold = 0.9

	-- 8. AMBIENT SOUNDS
	createSoundEmitter("Crickets", ground, "rbxassetid://9043813636", 0.2, true, 300)
	createSoundEmitter("Wind", ground, "rbxassetid://9043813636", 0.15, true, 400)

	-- 8.5. THEMED LIGHT FIXTURES (Lanterns & Torches for night)
	-- These will be toggled by LobbyTimeManager

	-- Helper function for creating lantern
	local function createLantern(name, cframe, parent)
		local lantern = Instance.new("Model")
		lantern.Name = name
		lantern.Parent = parent

		-- Lantern body (rustic oil lantern)
		local body = createPart(name .. "_Body", Vector3.new(0.8, 1.2, 0.8), cframe, lantern, COLORS.RustyMetal, Enum.Material.Metal)
		-- Glass chamber
		local glass = createPart(name .. "_Glass", Vector3.new(0.5, 0.8, 0.5), cframe * CFrame.new(0, 0.1, 0), lantern, Color3.fromRGB(255, 200, 100), Enum.Material.Neon)
		glass.Transparency = 0.3
		-- Top cap
		createPart(name .. "_Cap", Vector3.new(0.6, 0.2, 0.6), cframe * CFrame.new(0, 0.7, 0), lantern, COLORS.RustyMetal, Enum.Material.Metal)
		-- Light
		createLight(glass, Vector3.new(0, 0, 0), COLORS.WarmLight, 20, 1.5)

		return lantern
	end

	-- Helper function for creating torch
	local function createTorch(name, cframe, parent)
		local torch = Instance.new("Model")
		torch.Name = name
		torch.Parent = parent

		-- Torch pole
		local pole = createPart(name .. "_Pole", Vector3.new(0.4, 6, 0.4), cframe, torch, COLORS.WoodDark, Enum.Material.Wood)
		-- Fire holder
		local holder = createPart(name .. "_Holder", Vector3.new(0.8, 1.5, 0.8), cframe * CFrame.new(0, 3.5, 0), torch, COLORS.RustyMetal, Enum.Material.Metal)
		-- Fire
		createFire(holder, 6, Color3.fromRGB(255, 150, 50), Color3.fromRGB(200, 80, 20))
		-- Light
		createLight(holder, Vector3.new(0, 1, 0), COLORS.FireLight, 25, 2)

		return torch
	end

	-- Lanterns on porch pillars
	createLantern("PorchLanternL", CFrame.new(-18, GROUND_LEVEL + 8, -20), env)
	createLantern("PorchLanternR", CFrame.new(18, GROUND_LEVEL + 8, -20), env)

	-- Lanterns near campfire area
	createLantern("CampLantern1", CFrame.new(-8, GROUND_LEVEL + 4, 30), env)
	createLantern("CampLantern2", CFrame.new(8, GROUND_LEVEL + 4, 30), env)

	-- Lanterns in barn
	createLantern("BarnLantern1", CFrame.new(-60, GROUND_LEVEL + 6, 5), env)
	createLantern("BarnLantern2", CFrame.new(-50, GROUND_LEVEL + 6, 15), env)

	-- Lanterns near medical tent
	createLantern("TentLantern1", CFrame.new(50, GROUND_LEVEL + 4, 5), env)
	createLantern("TentLantern2", CFrame.new(60, GROUND_LEVEL + 4, 15), env)

	-- Torches at gate entrance
	createTorch("GateTorchL", CFrame.new(-18, GROUND_LEVEL + 3, -95), env)
	createTorch("GateTorchR", CFrame.new(18, GROUND_LEVEL + 3, -95), env)

	-- Torches along barricade (every 30 studs)
	for z = -60, 60, 40 do
		createTorch("BarricadeTorchL" .. z, CFrame.new(-93, GROUND_LEVEL + 3, z), env)
		createTorch("BarricadeTorchR" .. z, CFrame.new(93, GROUND_LEVEL + 3, z), env)
	end

	-- Lanterns near Alexander's gazebo
	createLantern("GazeboLantern1", CFrame.new(-5, GROUND_LEVEL + 5, 75), env)
	createLantern("GazeboLantern2", CFrame.new(5, GROUND_LEVEL + 5, 75), env)

	-- 9. FALLING LEAVES PARTICLES
	for i = 1, 3 do
		local emitterPart = createPart("LeafEmitter" .. i, Vector3.new(50, 1, 50), 
			CFrame.new(math.random(-50, 50), 25, math.random(-20, 60)), 
			env, Color3.new(1, 1, 1), Enum.Material.Air)
		emitterPart.Transparency = 1
		emitterPart.CanCollide = false

		local leafEmitter = Instance.new("ParticleEmitter")
		leafEmitter.Name = "FallingLeaves"
		leafEmitter.Texture = "rbxassetid://241876428"
		leafEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 160, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 150, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 90, 40))
		})
		leafEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0.4)
		})
		leafEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		leafEmitter.Lifetime = NumberRange.new(6, 10)
		leafEmitter.Rate = 2
		leafEmitter.Speed = NumberRange.new(1, 3)
		leafEmitter.SpreadAngle = Vector2.new(180, 180)
		leafEmitter.Rotation = NumberRange.new(0, 360)
		leafEmitter.RotSpeed = NumberRange.new(-20, 20)
		leafEmitter.Acceleration = Vector3.new(0, -3, 0)
		leafEmitter.Parent = emitterPart
	end

	-- 10. BARRICADE WALLS (Survivor Perimeter)
	-- VERY tall wooden walls so camera can't see outside
	local barricadeHeight = 60  -- EXTREMELY tall to completely block camera view
	local barricadeWidth = 95
	local barricadeDepth = 95
	local gateWidth = 30  -- Width of entrance
	local gateHeight = 15  -- Height of gate opening (shorter than wall)

	-- Helper for barricade section with variation
	local function createBarricadeSection(name, length, cframe, parent)
		-- Main wall planks
		local wall = createPart(name, Vector3.new(length, barricadeHeight, 3), cframe, parent, COLORS.WoodWeathered, Enum.Material.WoodPlanks)

		-- Support posts at regular intervals
		local postCount = math.floor(length / 20)
		for i = 0, postCount do
			local offset = -length/2 + (i * (length / postCount))
			local postCF = cframe * CFrame.new(offset, 0, 0)
			createPart(name .. "_Post" .. i, Vector3.new(2, barricadeHeight + 3, 2), postCF * CFrame.new(0, 1.5, 0), parent, COLORS.WoodDark, Enum.Material.Wood)
		end

		-- Reinforcement beam at top
		createPart(name .. "_TopBeam", Vector3.new(length, 2, 1), cframe * CFrame.new(0, barricadeHeight/2 - 1, -1.5), parent, COLORS.WoodDark, Enum.Material.Wood)

		-- Reinforcement beam at middle
		createPart(name .. "_MidBeam", Vector3.new(length, 1.5, 1), cframe * CFrame.new(0, 0, -1.5), parent, COLORS.WoodDark, Enum.Material.Wood)

		-- Reinforcement beam at bottom
		createPart(name .. "_BotBeam", Vector3.new(length, 1.5, 1), cframe * CFrame.new(0, -barricadeHeight/2 + 2, -1.5), parent, COLORS.WoodDark, Enum.Material.Wood)

		return wall
	end

	-- Create barricade folder
	local barricade = Instance.new("Model")
	barricade.Name = "SurvivorBarricade"
	barricade.Parent = env

	-- North wall (back, behind leaderboards)
	createBarricadeSection("BarricadeN", barricadeWidth * 2, 
		CFrame.new(0, GROUND_LEVEL + barricadeHeight/2, barricadeDepth), barricade)

	-- South wall (front, with entrance gap)
	-- Left section
	createBarricadeSection("BarricadeS_L", barricadeWidth - gateWidth/2, 
		CFrame.new(-barricadeWidth/2 - gateWidth/4, GROUND_LEVEL + barricadeHeight/2, -barricadeDepth), barricade)
	-- Right section
	createBarricadeSection("BarricadeS_R", barricadeWidth - gateWidth/2, 
		CFrame.new(barricadeWidth/2 + gateWidth/4, GROUND_LEVEL + barricadeHeight/2, -barricadeDepth), barricade)

	-- Wall above gate
	createPart("BarricadeS_Top", Vector3.new(gateWidth, barricadeHeight - gateHeight, 3), 
		CFrame.new(0, GROUND_LEVEL + gateHeight + (barricadeHeight - gateHeight)/2, -barricadeDepth), barricade, COLORS.WoodWeathered, Enum.Material.WoodPlanks)

	-- Gate posts for entrance (taller, thicker)
	createPart("GatePostL", Vector3.new(4, barricadeHeight + 5, 4), 
		CFrame.new(-gateWidth/2 - 2, GROUND_LEVEL + barricadeHeight/2 + 2.5, -barricadeDepth), barricade, COLORS.WoodDark, Enum.Material.Wood)
	createPart("GatePostR", Vector3.new(4, barricadeHeight + 5, 4), 
		CFrame.new(gateWidth/2 + 2, GROUND_LEVEL + barricadeHeight/2 + 2.5, -barricadeDepth), barricade, COLORS.WoodDark, Enum.Material.Wood)

	-- Gate header beam
	createPart("GateHeader", Vector3.new(gateWidth + 8, 3, 3), 
		CFrame.new(0, GROUND_LEVEL + gateHeight, -barricadeDepth), barricade, COLORS.WoodDark, Enum.Material.Wood)

	-- === GATE DOORS ===
	-- Left door - wider to close gap
	createPart("GateDoorL", Vector3.new(gateWidth/2 + 1, gateHeight - 1, 2), 
		CFrame.new(-gateWidth/4, GROUND_LEVEL + (gateHeight - 1)/2, -barricadeDepth), barricade, COLORS.WoodDark, Enum.Material.WoodPlanks)
	-- Right door - wider to close gap
	createPart("GateDoorR", Vector3.new(gateWidth/2 + 1, gateHeight - 1, 2), 
		CFrame.new(gateWidth/4, GROUND_LEVEL + (gateHeight - 1)/2, -barricadeDepth), barricade, COLORS.WoodDark, Enum.Material.WoodPlanks)
	-- Door reinforcement X pattern (left)
	createPart("DoorBraceL1", Vector3.new(0.5, gateHeight * 1.3, 0.5), 
		CFrame.new(-gateWidth/4 - 0.5, GROUND_LEVEL + (gateHeight - 1)/2, -barricadeDepth + 1) * CFrame.Angles(0, 0, math.rad(25)), 
		barricade, COLORS.RustyMetal, Enum.Material.Metal)
	createPart("DoorBraceL2", Vector3.new(0.5, gateHeight * 1.3, 0.5), 
		CFrame.new(-gateWidth/4 - 0.5, GROUND_LEVEL + (gateHeight - 1)/2, -barricadeDepth + 1) * CFrame.Angles(0, 0, math.rad(-25)), 
		barricade, COLORS.RustyMetal, Enum.Material.Metal)
	-- Door reinforcement X pattern (right)
	createPart("DoorBraceR1", Vector3.new(0.5, gateHeight * 1.3, 0.5), 
		CFrame.new(gateWidth/4 + 0.5, GROUND_LEVEL + (gateHeight - 1)/2, -barricadeDepth + 1) * CFrame.Angles(0, 0, math.rad(25)), 
		barricade, COLORS.RustyMetal, Enum.Material.Metal)
	createPart("DoorBraceR2", Vector3.new(0.5, gateHeight * 1.3, 0.5), 
		CFrame.new(gateWidth/4 + 0.5, GROUND_LEVEL + (gateHeight - 1)/2, -barricadeDepth + 1) * CFrame.Angles(0, 0, math.rad(-25)), 
		barricade, COLORS.RustyMetal, Enum.Material.Metal)
	-- Door handles
	createPart("HandleL", Vector3.new(0.3, 2, 0.3), 
		CFrame.new(-1, GROUND_LEVEL + gateHeight/2, -barricadeDepth + 2), barricade, COLORS.RustyMetal, Enum.Material.Metal)
	createPart("HandleR", Vector3.new(0.3, 2, 0.3), 
		CFrame.new(1, GROUND_LEVEL + gateHeight/2, -barricadeDepth + 2), barricade, COLORS.RustyMetal, Enum.Material.Metal)

	-- East wall
	createBarricadeSection("BarricadeE", barricadeDepth * 2, 
		CFrame.new(barricadeWidth, GROUND_LEVEL + barricadeHeight/2, 0) * CFrame.Angles(0, math.rad(90), 0), barricade)

	-- West wall
	createBarricadeSection("BarricadeW", barricadeDepth * 2, 
		CFrame.new(-barricadeWidth, GROUND_LEVEL + barricadeHeight/2, 0) * CFrame.Angles(0, math.rad(90), 0), barricade)

	-- Corner watchtowers (simple platforms)
	local corners = {
		{x = -barricadeWidth, z = -barricadeDepth},
		{x = barricadeWidth, z = -barricadeDepth},
		{x = -barricadeWidth, z = barricadeDepth},
		{x = barricadeWidth, z = barricadeDepth}
	}
	for i, corner in ipairs(corners) do
		-- Tower platform
		createPart("WatchtowerPlatform" .. i, Vector3.new(8, 1, 8), 
			CFrame.new(corner.x, GROUND_LEVEL + barricadeHeight + 2, corner.z), barricade, COLORS.WoodDark, Enum.Material.WoodPlanks)
		-- Tower railing
		createPart("WatchtowerRail" .. i .. "A", Vector3.new(8, 3, 0.5), 
			CFrame.new(corner.x, GROUND_LEVEL + barricadeHeight + 4, corner.z + 3.75), barricade, COLORS.WoodWeathered, Enum.Material.Wood)
		createPart("WatchtowerRail" .. i .. "B", Vector3.new(8, 3, 0.5), 
			CFrame.new(corner.x, GROUND_LEVEL + barricadeHeight + 4, corner.z - 3.75), barricade, COLORS.WoodWeathered, Enum.Material.Wood)
	end

	-- Sandbag clusters at entrance (defensive)
	for i = -1, 1, 2 do
		local sbX = i * 10
		createPart("Sandbag" .. i, Vector3.new(4, 2, 2), 
			CFrame.new(sbX, GROUND_LEVEL + 1, -barricadeDepth + 5), barricade, Color3.fromRGB(130, 115, 85), Enum.Material.Fabric)
		createPart("Sandbag" .. i .. "_2", Vector3.new(3, 2, 2), 
			CFrame.new(sbX + i, GROUND_LEVEL + 1, -barricadeDepth + 7), barricade, Color3.fromRGB(120, 105, 80), Enum.Material.Fabric)
	end

	print("LobbyBuilder: Farmhouse Lobby Built! 🏠✨")
end

return LobbyBuilder
