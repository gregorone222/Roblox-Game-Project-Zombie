-- MapBuilderVillage.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/MapBuilderVillage.lua
-- Script Place: ACT 1: Village
-- Theme: Cursed Village (Foggy, Ruined, Eerie)

local MapBuilder = {}

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- === CONFIGURATION ===
local MAP_SIZE = 400
local HOUSE_COUNT = 12
local TREE_COUNT = 40

local COLORS = {
	-- "Cozy Apocalypse" Palette - Warm, Hopeful, Bittersweet
	Grass = Color3.fromRGB(70, 100, 55), -- Overgrown grass (alive, not dead)
	Dirt = Color3.fromRGB(100, 80, 60), -- Warm earth tone
	WoodDark = Color3.fromRGB(80, 55, 40), -- Weathered wood
	WoodLight = Color3.fromRGB(150, 110, 70), -- Warm wood planks
	Roof = Color3.fromRGB(90, 60, 50), -- Terracotta/warm brown roof
	Fog = Color3.fromRGB(200, 160, 130), -- Golden hour mist
	Window = Color3.fromRGB(40, 35, 30), -- Dark but not pitch black
	Light = Color3.fromRGB(255, 190, 120), -- Warm sunset orange

	-- NEW: Overgrown/Nature colors
	Moss = Color3.fromRGB(60, 80, 50), -- Green moss on surfaces
	Ivy = Color3.fromRGB(50, 90, 45), -- Climbing ivy
	Rust = Color3.fromRGB(140, 70, 40), -- Rusted metal
	Fabric = Color3.fromRGB(180, 150, 120), -- Old cloth/canvas
}

-- === HELPERS ===
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
	return p
end

local function createMeshPart(meshId, size, cframe, parent)
	-- Fallback to Part if MeshId not available/valid in script context (using simple shapes)
	return createPart("MeshProp", size, cframe, parent, COLORS.WoodDark, Enum.Material.Wood)
end

-- === STRUCTURES ===

local function buildHouse(cframe, parent)
	local house = Instance.new("Model")
	house.Name = "RuinedHouse"
	house.Parent = parent

	local width = math.random(15, 25)
	local depth = math.random(15, 25)
	local height = 12

	-- Walls (Broken)
	local function makeWall(cf, sz)
		if math.random() > 0.8 then return end -- 20% chance wall is missing entirely
		createPart("Wall", sz, cf, house, COLORS.WoodLight, Enum.Material.WoodPlanks)
	end

	-- Floor
	createPart("Floor", Vector3.new(width, 1, depth), cframe, house, COLORS.WoodDark, Enum.Material.WoodPlanks)

	-- 4 Walls
	makeWall(cframe * CFrame.new(0, height/2, depth/2), Vector3.new(width, height, 1))
	makeWall(cframe * CFrame.new(0, height/2, -depth/2), Vector3.new(width, height, 1))
	makeWall(cframe * CFrame.new(width/2, height/2, 0), Vector3.new(1, height, depth))
	makeWall(cframe * CFrame.new(-width/2, height/2, 0), Vector3.new(1, height, depth))

	-- Roof (Triangle Prism Approximation)
	local roofHeight = 6
	local wedge = Instance.new("WedgePart")
	wedge.Size = Vector3.new(width/2 + 2, roofHeight, depth + 2)
	wedge.CFrame = cframe * CFrame.new(width/4, height + roofHeight/2, 0) * CFrame.Angles(0, math.pi, 0)
	wedge.Color = COLORS.Roof
	wedge.Material = Enum.Material.Slate
	wedge.Anchored = true
	wedge.Parent = house

	local wedge2 = wedge:Clone()
	wedge2.CFrame = cframe * CFrame.new(-width/4, height + roofHeight/2, 0)
	wedge2.Parent = house

	-- Furniture / Debris inside
	if math.random() > 0.3 then
		local table = createPart("Table", Vector3.new(4, 2, 4), cframe * CFrame.new(0, 2, 0) * CFrame.Angles(math.random(), math.random(), math.random()), house, COLORS.WoodDark, Enum.Material.Wood)
		-- Tag as Destructible
		local baseModel = Instance.new("Model")
		baseModel.Name = "DestructibleTable"
		baseModel.Parent = house
		table.Parent = baseModel

		baseModel:SetAttribute("Destructible", true)
		baseModel:SetAttribute("Health", 100)
		baseModel:SetAttribute("Health", 100)
		baseModel:SetAttribute("MaxHealth", 100)
	end

	-- Chairs (More common)
	if math.random() > 0.3 then
		local numChairs = math.random(1, 2)
		for k = 1, numChairs do
			local offset = Vector3.new(math.random(-3,3), 1, math.random(-3,3))
			local chairCFrame = cframe * CFrame.new(offset) * CFrame.Angles(0, math.random()*math.pi*2, 0)

			local chairModel = Instance.new("Model")
			chairModel.Name = "DestructibleChair"
			chairModel.Parent = house
			chairModel:SetAttribute("Destructible", true)
			chairModel:SetAttribute("Health", 50) -- Weaker than table
			chairModel:SetAttribute("MaxHealth", 50)

			-- Seat
			createPart("Seat", Vector3.new(2, 0.2, 2), chairCFrame * CFrame.new(0, 1, 0), chairModel, COLORS.WoodLight, Enum.Material.Wood)
			-- Back
			createPart("Back", Vector3.new(2, 2, 0.2), chairCFrame * CFrame.new(0, 2, 1), chairModel, COLORS.WoodLight, Enum.Material.Wood)
			-- Legs
			createPart("Leg1", Vector3.new(0.2, 1, 0.2), chairCFrame * CFrame.new(0.9, 0.5, 0.9), chairModel, COLORS.WoodDark, Enum.Material.Wood)
			createPart("Leg2", Vector3.new(0.2, 1, 0.2), chairCFrame * CFrame.new(-0.9, 0.5, 0.9), chairModel, COLORS.WoodDark, Enum.Material.Wood)
			createPart("Leg3", Vector3.new(0.2, 1, 0.2), chairCFrame * CFrame.new(0.9, 0.5, -0.9), chairModel, COLORS.WoodDark, Enum.Material.Wood)
			createPart("Leg4", Vector3.new(0.2, 1, 0.2), chairCFrame * CFrame.new(-0.9, 0.5, -0.9), chairModel, COLORS.WoodDark, Enum.Material.Wood)
		end
	end

	-- Spawn Point for Scavenge (Hint)
	local spawnHint = Instance.new("Attachment")
	spawnHint.Name = "Spawn_Gas"
	spawnHint.Position = cframe.Position + Vector3.new(0, 2, 0)
	spawnHint.Parent = house
end

local function buildRadioTower(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "RadioTower"
	model.Parent = parent

	-- Objective Zone
	local defZone = Instance.new("Attachment")
	defZone.Name = "Zone_Defend"
	defZone.Position = cframe.Position
	defZone.Parent = model

	-- Base
	createPart("Base", Vector3.new(8, 1, 8), cframe, model, COLORS.Roof, Enum.Material.Concrete)

	-- Mast
	local mastHeight = 40
	local mast = createPart("Mast", Vector3.new(2, mastHeight, 2), cframe * CFrame.new(0, mastHeight/2, 0), model, Color3.fromRGB(100, 100, 100), Enum.Material.DiamondPlate)

	-- Dish
	local dish = createPart("Dish", Vector3.new(8, 8, 2), cframe * CFrame.new(0, mastHeight, 0) * CFrame.Angles(math.rad(-30), 0, 0), model, Color3.fromRGB(200, 200, 200), Enum.Material.Metal)

	-- Blinking Light
	local lightPart = createPart("Blinker", Vector3.new(1,1,1), cframe * CFrame.new(0, mastHeight+4, 0), model, Color3.new(1,0,0), Enum.Material.Neon)

	task.spawn(function()
		while model.Parent do
			lightPart.Transparency = 0
			task.wait(0.5)
			lightPart.Transparency = 1
			task.wait(1)
		end
	end)
end

local function buildTree(cframe, parent)
	local tree = Instance.new("Model")
	tree.Name = "OvergrownTree" -- Changed from DeadTree
	tree.Parent = parent

	local height = math.random(12, 20)

	-- Trunk with moss patches
	local trunk = createPart("Trunk", Vector3.new(2, height, 2), cframe * CFrame.new(0, height/2, 0), tree, Color3.fromRGB(70, 55, 40), Enum.Material.Wood)

	-- Add moss patches on trunk (random placement)
	if math.random() > 0.3 then
		local mossPatch = createPart("Moss", Vector3.new(2.1, height * 0.4, 2.1), cframe * CFrame.new(0, height * 0.3, 0), tree, COLORS.Moss, Enum.Material.Grass)
		mossPatch.Transparency = 0.3
	end

	-- Branches with leaves (not dead!)
	for i = 1, math.random(3, 5) do
		local branchLen = math.random(4, 8)
		local branchAngle = CFrame.Angles(math.rad(math.random(-60, -20)), math.rad(math.random(0, 360)), 0)
		local branchCFrame = cframe * CFrame.new(0, height * 0.7 + (i * 1.5), 0) * branchAngle

		-- Branch
		createPart("Branch", Vector3.new(0.8, branchLen, 0.8), branchCFrame, tree, Color3.fromRGB(70, 55, 40), Enum.Material.Wood)

		-- Leaf cluster at end of branch
		local leafSize = math.random(4, 7)
		local leafPos = branchCFrame * CFrame.new(0, branchLen/2 + leafSize/3, 0)
		local leaves = createPart("Leaves", Vector3.new(leafSize, leafSize * 0.7, leafSize), leafPos, tree, COLORS.Ivy, Enum.Material.Grass)
		leaves.Shape = Enum.PartType.Ball
	end

	-- Main canopy (big leaf ball at top)
	local canopySize = math.random(8, 12)
	local canopy = createPart("Canopy", Vector3.new(canopySize, canopySize * 0.8, canopySize), cframe * CFrame.new(0, height + canopySize/3, 0), tree, COLORS.Ivy, Enum.Material.Grass)
	canopy.Shape = Enum.PartType.Ball

	-- Hanging ivy (occasional)
	if math.random() > 0.5 then
		local ivyHeight = math.random(3, 6)
		createPart("HangingIvy", Vector3.new(0.3, ivyHeight, 0.3), cframe * CFrame.new(math.random(-2, 2), height - ivyHeight/2, math.random(-2, 2)), tree, COLORS.Ivy, Enum.Material.Grass)
	end
end

-- === NOSTALGIC OBJECTS (Cozy Apocalypse) ===

local function buildSwing(cframe, parent)
	local swing = Instance.new("Model")
	swing.Name = "EmptySwing"
	swing.Parent = parent

	-- Frame (A-frame wood structure)
	local frameHeight = 10
	local frameWidth = 8

	-- Left post
	createPart("LeftPost", Vector3.new(0.5, frameHeight, 0.5), cframe * CFrame.new(-frameWidth/2, frameHeight/2, 0) * CFrame.Angles(0, 0, math.rad(10)), swing, COLORS.WoodDark, Enum.Material.Wood)
	-- Right post
	createPart("RightPost", Vector3.new(0.5, frameHeight, 0.5), cframe * CFrame.new(frameWidth/2, frameHeight/2, 0) * CFrame.Angles(0, 0, math.rad(-10)), swing, COLORS.WoodDark, Enum.Material.Wood)
	-- Top bar
	createPart("TopBar", Vector3.new(frameWidth + 1, 0.4, 0.4), cframe * CFrame.new(0, frameHeight - 0.5, 0), swing, COLORS.WoodDark, Enum.Material.Wood)

	-- Seat (hanging)
	local seatHeight = 3
	createPart("Seat", Vector3.new(2, 0.3, 1), cframe * CFrame.new(0, seatHeight, 0), swing, COLORS.WoodLight, Enum.Material.Wood)

	-- Rope (simplified as thin parts)
	createPart("RopeL", Vector3.new(0.1, frameHeight - seatHeight - 1, 0.1), cframe * CFrame.new(-0.8, (frameHeight + seatHeight)/2, 0), swing, COLORS.Fabric, Enum.Material.Fabric)
	createPart("RopeR", Vector3.new(0.1, frameHeight - seatHeight - 1, 0.1), cframe * CFrame.new(0.8, (frameHeight + seatHeight)/2, 0), swing, COLORS.Fabric, Enum.Material.Fabric)
end

local function buildTeddyBear(cframe, parent)
	local teddy = Instance.new("Model")
	teddy.Name = "AbandonedTeddy"
	teddy.Parent = parent

	local bodyColor = Color3.fromRGB(150, 120, 90) -- Faded brown

	-- Body (ball)
	local body = createPart("Body", Vector3.new(1.5, 1.8, 1.2), cframe * CFrame.new(0, 0.9, 0), teddy, bodyColor, Enum.Material.Fabric)
	-- Head
	createPart("Head", Vector3.new(1.2, 1.2, 1.2), cframe * CFrame.new(0, 2.2, 0), teddy, bodyColor, Enum.Material.Fabric)
	-- Ears
	createPart("EarL", Vector3.new(0.4, 0.4, 0.2), cframe * CFrame.new(-0.5, 2.8, 0), teddy, bodyColor, Enum.Material.Fabric)
	createPart("EarR", Vector3.new(0.4, 0.4, 0.2), cframe * CFrame.new(0.5, 2.8, 0), teddy, bodyColor, Enum.Material.Fabric)
	-- Arms
	createPart("ArmL", Vector3.new(0.4, 1, 0.4), cframe * CFrame.new(-1, 1.2, 0) * CFrame.Angles(0, 0, math.rad(30)), teddy, bodyColor, Enum.Material.Fabric)
	createPart("ArmR", Vector3.new(0.4, 1, 0.4), cframe * CFrame.new(1, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-30)), teddy, bodyColor, Enum.Material.Fabric)
	-- Legs
	createPart("LegL", Vector3.new(0.5, 0.8, 0.5), cframe * CFrame.new(-0.4, 0.4, 0.3), teddy, bodyColor, Enum.Material.Fabric)
	createPart("LegR", Vector3.new(0.5, 0.8, 0.5), cframe * CFrame.new(0.4, 0.4, 0.3), teddy, bodyColor, Enum.Material.Fabric)
end

local function buildOldRadio(cframe, parent)
	local radio = Instance.new("Model")
	radio.Name = "OldRadio"
	radio.Parent = parent

	-- Main body
	local body = createPart("Body", Vector3.new(3, 2, 1.5), cframe * CFrame.new(0, 1, 0), radio, Color3.fromRGB(60, 50, 45), Enum.Material.Wood)
	-- Speaker grill
	createPart("Speaker", Vector3.new(1.5, 1.5, 0.2), cframe * CFrame.new(-0.5, 1, 0.65), radio, Color3.fromRGB(40, 35, 30), Enum.Material.Fabric)
	-- Dial
	createPart("Dial", Vector3.new(0.8, 0.8, 0.1), cframe * CFrame.new(0.8, 1.2, 0.7), radio, COLORS.Rust, Enum.Material.Metal)
	-- Antenna
	createPart("Antenna", Vector3.new(0.1, 2, 0.1), cframe * CFrame.new(1.2, 3, 0) * CFrame.Angles(0, 0, math.rad(-15)), radio, COLORS.Rust, Enum.Material.Metal)
end

local function buildBrokenBike(cframe, parent)
	local bike = Instance.new("Model")
	bike.Name = "BrokenBike"
	bike.Parent = parent

	-- Frame (simplified triangle)
	createPart("Frame1", Vector3.new(0.2, 2, 0.2), cframe * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(20)), bike, COLORS.Rust, Enum.Material.Metal)
	createPart("Frame2", Vector3.new(0.2, 2.5, 0.2), cframe * CFrame.new(0.8, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-30)), bike, COLORS.Rust, Enum.Material.Metal)

	-- Wheels (cylinders on side)
	local wheel1 = createPart("WheelF", Vector3.new(0.3, 2, 2), cframe * CFrame.new(1.5, 1, 0), bike, Color3.fromRGB(30, 30, 30), Enum.Material.Rubber)
	wheel1.Shape = Enum.PartType.Cylinder
	local wheel2 = createPart("WheelB", Vector3.new(0.3, 2, 2), cframe * CFrame.new(-1, 1, 0), bike, Color3.fromRGB(30, 30, 30), Enum.Material.Rubber)
	wheel2.Shape = Enum.PartType.Cylinder

	-- Handlebar
	createPart("Handlebar", Vector3.new(1.5, 0.2, 0.2), cframe * CFrame.new(1.2, 2.5, 0), bike, COLORS.Rust, Enum.Material.Metal)

	-- Tip it over (fallen)
	bike:PivotTo(cframe * CFrame.Angles(0, math.rad(math.random(0, 360)), math.rad(70)))
end

local function addFallingLeavesParticle(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "FallingLeaves"
	emitter.Texture = "rbxassetid://241876428" -- Leaf texture (generic)
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 140, 60)), -- Green
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 140, 50)), -- Yellow
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 80, 40)) -- Brown
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0.3)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Lifetime = NumberRange.new(5, 8)
	emitter.Rate = 3 -- Slow, gentle
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.Acceleration = Vector3.new(0, -2, 0) -- Slow fall
	emitter.Parent = parent
	return emitter
end

-- === MAIN BUILD FUNCTION ===

function MapBuilder.Build()
	print("MapBuilder: Generating ACT 1: The Cozy Village (Overgrown)...")

	-- Cleanup
	if Workspace:FindFirstChild("Map_Village") then
		Workspace.Map_Village:Destroy()
	end

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map_Village"
	mapFolder.Parent = Workspace

	-- 1. TERRAIN
	local ground = createPart("Ground", Vector3.new(MAP_SIZE, 4, MAP_SIZE), CFrame.new(0, -2, 0), mapFolder, COLORS.Grass, Enum.Material.Grass)

	-- Invisible Walls
	local wallHeight = 50
	createPart("BarrierN", Vector3.new(MAP_SIZE, wallHeight, 2), CFrame.new(0, wallHeight/2, -MAP_SIZE/2), mapFolder, Color3.new(0,0,0), Enum.Material.ForceField).Transparency = 1
	createPart("BarrierS", Vector3.new(MAP_SIZE, wallHeight, 2), CFrame.new(0, wallHeight/2, MAP_SIZE/2), mapFolder, Color3.new(0,0,0), Enum.Material.ForceField).Transparency = 1
	createPart("BarrierE", Vector3.new(2, wallHeight, MAP_SIZE), CFrame.new(MAP_SIZE/2, wallHeight/2, 0), mapFolder, Color3.new(0,0,0), Enum.Material.ForceField).Transparency = 1
	createPart("BarrierW", Vector3.new(2, wallHeight, MAP_SIZE), CFrame.new(-MAP_SIZE/2, wallHeight/2, 0), mapFolder, Color3.new(0,0,0), Enum.Material.ForceField).Transparency = 1

	-- 2. TOWN SQUARE (Center)
	local squareSize = 80
	createPart("SquarePavement", Vector3.new(squareSize, 0.2, squareSize), CFrame.new(0, 0.1, 0), mapFolder, COLORS.Dirt, Enum.Material.Concrete)
	buildRadioTower(CFrame.new(0, 0, 0), mapFolder)

	-- 3. HOUSES (Ring around square)
	local radius = 70
	local angleStep = (math.pi * 2) / HOUSE_COUNT

	for i = 1, HOUSE_COUNT do
		local angle = i * angleStep
		local x = math.cos(angle) * radius + math.random(-10, 10)
		local z = math.sin(angle) * radius + math.random(-10, 10)
		local rot = CFrame.lookAt(Vector3.new(x,0,z), Vector3.new(0,0,0))
		buildHouse(rot, mapFolder)
	end

	-- 4. FORESTS (Outer Ring) - Now Overgrown!
	for i = 1, TREE_COUNT do
		local r = math.random(100, MAP_SIZE/2 - 10)
		local theta = math.random() * math.pi * 2
		local x = math.cos(theta) * r
		local z = math.sin(theta) * r
		buildTree(CFrame.new(x, 0, z), mapFolder)

		-- Random Retrieve Spawns near trees
		if math.random() > 0.8 then
			local att = Instance.new("Attachment")
			att.Name = "Spawn_Sample"
			att.Position = Vector3.new(x, 1, z) + Vector3.new(math.random(-2,2), 0, math.random(-2,2))
			att.Parent = mapFolder
		end
	end

	-- 5. NOSTALGIC OBJECTS (Cozy Apocalypse storytelling)
	-- Empty swing near town square
	buildSwing(CFrame.new(35, 0, 25), mapFolder)

	-- Abandoned teddy bear by a house
	buildTeddyBear(CFrame.new(-50, 0, 40), mapFolder)
	buildTeddyBear(CFrame.new(60, 0, -30), mapFolder) -- Another one across map

	-- Old radio near the radio tower
	buildOldRadio(CFrame.new(15, 0, -10), mapFolder)

	-- Broken bikes scattered
	buildBrokenBike(CFrame.new(-40, 0, -50), mapFolder)
	buildBrokenBike(CFrame.new(45, 0, 55), mapFolder)

	-- 6. PARTICLES (Falling Leaves)
	-- Create invisible emitter parts at various heights
	for i = 1, 5 do
		local emitterPart = createPart("LeafEmitter" .. i, Vector3.new(60, 1, 60), 
			CFrame.new(math.random(-80, 80), 30, math.random(-80, 80)), 
			mapFolder, Color3.new(1,1,1), Enum.Material.Air)
		emitterPart.Transparency = 1
		emitterPart.CanCollide = false
		addFallingLeavesParticle(emitterPart)
	end

	-- 7. LIGHTING (Atmosphere) - Start at Morning (Wave 1)
	-- NOTE: GameManager handles progressive day cycle from morning to golden hour
	-- We set initial morning values here, GameManager will update per wave
	Lighting.ClockTime = 6 -- 6 AM (Sunrise/Morning start)
	Lighting.Brightness = 1.5
	Lighting.Ambient = Color3.fromRGB(120, 100, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 120, 100)
	Lighting.FogColor = Color3.fromRGB(200, 180, 160) -- Warm morning mist
	Lighting.FogStart = 20
	Lighting.FogEnd = 400 -- Morning visibility

	-- Street Lamps (Sparse but warm)
	for i = 1, 4 do
		local angle = (i/4) * math.pi * 2
		local pos = Vector3.new(math.cos(angle)*40, 0, math.sin(angle)*40)
		local pole = createPart("LampPost", Vector3.new(1, 15, 1), CFrame.new(pos + Vector3.new(0, 7.5, 0)), mapFolder, Color3.fromRGB(50, 40, 35), Enum.Material.Metal)
		local bulb = createPart("Bulb", Vector3.new(2,1,2), CFrame.new(pos + Vector3.new(0, 14, 0)), mapFolder, COLORS.Light, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = COLORS.Light
		light.Range = 50 -- Warmer, wider range
		light.Brightness = 2
		light.Parent = bulb
	end

	print("MapBuilder: Act 1 Cozy Village Generated. ✨")
end

return MapBuilder
