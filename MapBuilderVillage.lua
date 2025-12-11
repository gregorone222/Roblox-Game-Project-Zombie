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
	Grass = Color3.fromRGB(30, 40, 30), -- Dead grass
	Dirt = Color3.fromRGB(45, 40, 35), -- Mud
	WoodDark = Color3.fromRGB(50, 40, 30),
	WoodLight = Color3.fromRGB(90, 70, 50),
	Roof = Color3.fromRGB(30, 30, 35),
	Fog = Color3.fromRGB(20, 25, 20),
	Window = Color3.fromRGB(20, 20, 20),
	Light = Color3.fromRGB(255, 150, 50) -- Dim orange streetlights
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
		createPart("Table", Vector3.new(4, 2, 4), cframe * CFrame.new(0, 2, 0) * CFrame.Angles(math.random(), math.random(), math.random()), house, COLORS.WoodDark, Enum.Material.Wood)
	end

	-- Spawn Point for Scavenge (Hint)
	local spawnHint = Instance.new("Part")
	spawnHint.Name = "ItemSpawn"
	spawnHint.Transparency = 1
	spawnHint.CanCollide = false
	spawnHint.Anchored = true
	spawnHint.Position = cframe.Position + Vector3.new(0, 2, 0)
	spawnHint.Parent = house
end

local function buildRadioTower(cframe, parent)
	local model = Instance.new("Model")
	model.Name = "RadioTower"
	model.Parent = parent

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
	tree.Name = "DeadTree"
	tree.Parent = parent

	local height = math.random(15, 25)
	local trunk = createPart("Trunk", Vector3.new(2, height, 2), cframe * CFrame.new(0, height/2, 0), tree, Color3.fromRGB(30, 25, 20), Enum.Material.Wood)

	-- Branches
	for i = 1, 4 do
		local branchLen = math.random(5, 10)
		local branch = createPart("Branch", Vector3.new(1, branchLen, 1),
			cframe * CFrame.new(0, height * 0.7, 0) * CFrame.Angles(math.random(), math.random()*math.pi*2, math.random()),
			tree, Color3.fromRGB(30, 25, 20), Enum.Material.Wood
		)
	end
end

-- === MAIN BUILD FUNCTION ===

function MapBuilder.Build()
	print("MapBuilder: Generating ACT 1: The Cursed Village...")

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

	-- 4. FORESTS (Outer Ring)
	for i = 1, TREE_COUNT do
		local r = math.random(100, MAP_SIZE/2 - 10)
		local theta = math.random() * math.pi * 2
		local x = math.cos(theta) * r
		local z = math.sin(theta) * r
		buildTree(CFrame.new(x, 0, z), mapFolder)
	end

	-- 5. LIGHTING (Atmosphere)
	Lighting.ClockTime = 0 -- Midnight
	Lighting.Brightness = 0.5
	Lighting.Ambient = COLORS.Fog
	Lighting.OutdoorAmbient = COLORS.Fog
	Lighting.FogColor = COLORS.Fog
	Lighting.FogStart = 10
	Lighting.FogEnd = 150 -- Thick fog

	-- Street Lamps (Sparse)
	for i = 1, 4 do
		local angle = (i/4) * math.pi * 2
		local pos = Vector3.new(math.cos(angle)*40, 0, math.sin(angle)*40)
		local pole = createPart("LampPost", Vector3.new(1, 15, 1), CFrame.new(pos + Vector3.new(0, 7.5, 0)), mapFolder, Color3.new(0.1,0.1,0.1), Enum.Material.Metal)
		local bulb = createPart("Bulb", Vector3.new(2,1,2), CFrame.new(pos + Vector3.new(0, 14, 0)), mapFolder, COLORS.Light, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = COLORS.Light
		light.Range = 40
		light.Brightness = 1.5
		light.Parent = bulb
	end

	print("MapBuilder: Act 1 Village Generated.")
end

return MapBuilder
