-- LobbyBuilderSubway.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LobbyBuilder_Subway.lua
-- Script Place: Lobby
-- Theme: Abandoned Subway Station (Survivor Shelter) - EXPANDED & POLISHED

local LobbyBuilder = {}

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Constants (Expanded Size)
local STATION_LENGTH = 300 
local STATION_WIDTH = 120
local STATION_HEIGHT = 45 -- Slightly higher for hanging cables
local PLATFORM_WIDTH = 70 
local PLATFORM_HEIGHT = 6

-- Palette: Grittier, Darker
local COLORS = {
	Concrete = Color3.fromRGB(50, 50, 55),
	ConcreteDark = Color3.fromRGB(35, 35, 40),
	Tiles = Color3.fromRGB(160, 160, 155), -- Dirty tiles
	TilesDark = Color3.fromRGB(110, 110, 115),
	SafetyYellow = Color3.fromRGB(200, 160, 0), -- Dimmed yellow
	RustyMetal = Color3.fromRGB(90, 60, 50),
	DarkMetal = Color3.fromRGB(40, 45, 50),
	TrainBody = Color3.fromRGB(45, 55, 65),
	TrainStripe = Color3.fromRGB(140, 40, 40), -- Faded red
	MedicalWhite = Color3.fromRGB(220, 220, 215), -- Dirty white
	Wood = Color3.fromRGB(80, 60, 50),
}

-- Asset IDs (Standard Roblox Assets)
local SOUNDS = {
	AmbientHum = "rbxassetid://130972023", -- Low industrial hum
	DrippingWater = "rbxassetid://130972023", -- Placeholder (Generic Hum used if specific drip not found, recommend replacing)
	Wind = "rbxassetid://9043813636", -- Hollow wind
}

local TEXTURES = {
	-- Can add texture IDs here if needed
}

-- Helper Functions
local function createPart(name, size, cframe, parent, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Parent = parent
	p.Color = color or COLORS.Concrete
	p.Material = material or Enum.Material.Concrete
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	return p
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

local function createParticle(name, parent, texture, colorSeq, sizeSeq)
	local att = Instance.new("Attachment")
	att.Name = name .. "Att"
	att.Parent = parent

	local pe = Instance.new("ParticleEmitter")
	pe.Name = name
	pe.Texture = texture or "rbxassetid://243953493" -- Generic smoke/dust
	pe.Color = colorSeq or ColorSequence.new(Color3.new(0.5,0.5,0.5))
	pe.Size = sizeSeq or NumberSequence.new(1)
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.8), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(5, 10)
	pe.Rate = 5
	pe.Speed = NumberRange.new(1, 3)
	pe.Parent = att
	return pe
end

-- Detail Functions
local function createDebris(parent, origin, radius, count)
	for i = 1, count do
		local offset = Vector3.new(math.random(-radius, radius), 1, math.random(-radius, radius))
		local size = Vector3.new(math.random(1,3), math.random(1,2), math.random(1,3))
		local p = createPart("Rubble", size, origin * CFrame.new(offset) * CFrame.Angles(math.random(), math.random(), math.random()), parent, COLORS.Concrete, Enum.Material.Slate)
		p.CanCollide = false
	end
end

local function createCables(parent, startPos, endPos, segments)
	local dist = (endPos - startPos).Magnitude
	local segmentLen = dist / segments
	local currentPos = startPos
	local drop = 2 -- How much it sags

	local folder = Instance.new("Folder")
	folder.Name = "CableGroup"
	folder.Parent = parent

	for i = 1, segments do
		local t = i / segments
		local nextPos = startPos:Lerp(endPos, t)
		-- Parabola sag
		nextPos = nextPos - Vector3.new(0, math.sin(t * math.pi) * drop, 0)

		local mid = (currentPos + nextPos) / 2
		local vec = nextPos - currentPos
		local len = vec.Magnitude

		local p = createPart("Cable", Vector3.new(0.2, 0.2, len), CFrame.lookAt(mid, nextPos), folder, Color3.new(0.1,0.1,0.1), Enum.Material.Plastic)
		p.CanCollide = false
		currentPos = nextPos
	end
end

-- NPC Spawner Helper
local function spawnNPC(name, cframe, parent, appearanceColor)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local hrp = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), cframe, model, appearanceColor, Enum.Material.Fabric)
	hrp.Transparency = 1
	local head = createPart("Head", Vector3.new(1, 1, 1), cframe * CFrame.new(0, 1.5, 0), model, Color3.fromRGB(255, 200, 180), Enum.Material.SmoothPlastic)
	local torso = createPart("Torso", Vector3.new(2, 2, 1), cframe, model, appearanceColor, Enum.Material.Fabric)

	local hum = Instance.new("Humanoid")
	hum.Parent = model
	model.PrimaryPart = hrp

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 100, 0, 50)
	bg.StudsOffset = Vector3.new(0, 2.5, 0)
	bg.AlwaysOnTop = true
	bg.Parent = head

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.Text = name
	txt.TextColor3 = Color3.new(1,1,1)
	txt.TextStrokeTransparency = 0
	txt.Font = Enum.Font.SpecialElite
	txt.TextSize = 20
	txt.Parent = bg

	return model
end

-- Interaction Part Helper
local function createInteraction(name, cframe, size, promptText, parent)
	local part = createPart(name, size, cframe, parent, Color3.new(0,1,0), Enum.Material.Neon)
	part.Transparency = 1
	part.CanCollide = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = promptText
	prompt.ActionText = "Interact"
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	return part
end

function LobbyBuilder.Build()
	print("LobbyBuilder: Constructing POLISHED Subway Shelter...")

	if Workspace:FindFirstChild("LobbyEnvironment") then
		Workspace.LobbyEnvironment:Destroy()
	end

	local env = Instance.new("Folder")
	env.Name = "LobbyEnvironment"
	env.Parent = Workspace

	-- 1. STATION SHELL
	-- Floor with texture variation
	local floor = createPart("TrackFloor", Vector3.new(STATION_LENGTH, 1, STATION_WIDTH), CFrame.new(0, 0, 0), env, COLORS.ConcreteDark, Enum.Material.Slate)

	-- Platform (Textured)
	local platformZ = (STATION_WIDTH - PLATFORM_WIDTH)/2 + (PLATFORM_WIDTH/2)
	local platformPos = Vector3.new(0, PLATFORM_HEIGHT/2, 20)
	local platform = createPart("Platform", Vector3.new(STATION_LENGTH, PLATFORM_HEIGHT, PLATFORM_WIDTH), CFrame.new(platformPos), env, COLORS.Concrete, Enum.Material.Concrete)

	-- Safety Line (Diamond Plate)
	local safetyZ = 20 - (PLATFORM_WIDTH/2) + 1 
	createPart("SafetyLine", Vector3.new(STATION_LENGTH, 0.1, 2), CFrame.new(0, PLATFORM_HEIGHT + 0.1, safetyZ), env, COLORS.SafetyYellow, Enum.Material.DiamondPlate)

	-- Walls & Ceiling (Tiled but dirty)
	createPart("WallBack", Vector3.new(STATION_LENGTH, STATION_HEIGHT, 2), CFrame.new(0, STATION_HEIGHT/2, STATION_WIDTH/2), env, COLORS.Tiles, Enum.Material.Brick)
	createPart("WallFront", Vector3.new(STATION_LENGTH, STATION_HEIGHT, 2), CFrame.new(0, STATION_HEIGHT/2, -STATION_WIDTH/2), env, COLORS.TilesDark, Enum.Material.Brick)
	createPart("Ceiling", Vector3.new(STATION_LENGTH, 1, STATION_WIDTH), CFrame.new(0, STATION_HEIGHT, 0), env, COLORS.ConcreteDark, Enum.Material.Slate)

	-- Pillars (Support Beams)
	for x = -100, 100, 40 do
		local pillar = createPart("Pillar", Vector3.new(4, STATION_HEIGHT, 4), CFrame.new(x, STATION_HEIGHT/2, 25), env, COLORS.DarkMetal, Enum.Material.CorrodedMetal)
		-- Add hanging cables between pillars
		if x < 100 then
			createCables(env, Vector3.new(x, STATION_HEIGHT-2, 25), Vector3.new(x+40, STATION_HEIGHT-2, 25), 10)
		end
	end

	-- 2. LIGHTING & ATMOSPHERE
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(20, 20, 25) -- Very Dark
	Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 15)
	Lighting.FogColor = Color3.fromRGB(15, 15, 20)
	Lighting.FogEnd = 150 -- Close fog for claustrophobia

	-- Campfire (Center) - WARMTH
	local firePos = Vector3.new(0, PLATFORM_HEIGHT + 0.5, 30)
	local campfire = createPart("CampfireBase", Vector3.new(6, 1, 6), CFrame.new(firePos), env, COLORS.Wood, Enum.Material.Wood)
	local fire = Instance.new("Fire")
	fire.Size = 12
	fire.Color = Color3.fromRGB(255, 100, 50)
	fire.SecondaryColor = Color3.fromRGB(100, 50, 0)
	fire.Parent = campfire
	createLight(campfire, Vector3.new(0, 6, 0), Color3.fromRGB(255, 130, 40), 50, 2.0)
	createSoundEmitter("FireSound", campfire, "rbxassetid://9075030806", 0.6, true, 40) -- Crackling fire

	-- Ambient Tube Lights (Cold, Flickering)
	for x = -120, 120, 40 do
		local lightPart = createPart("TubeLight", Vector3.new(2, 0.5, 10), CFrame.new(x, STATION_HEIGHT-2, 0), env, Color3.new(0.8, 0.9, 1), Enum.Material.Neon)
		local point = createLight(lightPart, Vector3.new(0, -1, 0), Color3.fromRGB(200, 220, 255), 45, 0.5)

		-- Random flicker script
		task.spawn(function()
			while lightPart.Parent do
				if math.random() > 0.95 then
					point.Brightness = 0
					lightPart.Material = Enum.Material.Glass
					task.wait(math.random(0.05, 0.2))
					point.Brightness = 0.5
					lightPart.Material = Enum.Material.Neon
				end
				task.wait(0.1)
			end
		end)
	end

	-- Global Ambiance
	local ambientSound = createSoundEmitter("StationHum", env, SOUNDS.AmbientHum, 0.3, true, 500)

	-- 3. ZONES & DETAILS

	-- A. TRACKS & TRAINS
	-- Rubble on tracks
	for x = -140, 140, 20 do
		createDebris(env, CFrame.new(x, 1, -10), 15, 3)
	end

	-- Train Cars
	local trainZ = -20
	for i = -1, 1 do
		local xOffset = i * 75
		local trainPos = CFrame.new(xOffset, 5, trainZ)

		-- Car Body
		local car = createPart("TrainCar_"..i, Vector3.new(70, 13, 12), trainPos, env, COLORS.TrainBody, Enum.Material.Metal)
		createPart("Stripe_"..i, Vector3.new(70, 1, 12.2), trainPos, env, COLORS.TrainStripe, Enum.Material.CorrodedMetal)

		-- Shop Car (Center)
		if i == 0 then
			local qmPos = trainPos * CFrame.new(0, -4.5, 0)
			spawnNPC("Quartermaster", qmPos * CFrame.Angles(0, math.rad(180), 0), env, COLORS.Wood)

			-- Shop Decor
			createPart("Counter", Vector3.new(10, 3, 3), qmPos * CFrame.new(0, 0, 3), env, COLORS.Wood, Enum.Material.WoodPlanks)
			createLight(car, Vector3.new(0, 0, 0), Color3.fromRGB(255, 200, 100), 20, 1) -- Warm shop light

			createInteraction("APShop", qmPos * CFrame.new(-6, 0, 5), Vector3.new(5, 5, 5), "Achievement Exchange", env)
			createInteraction("MPShop", qmPos * CFrame.new(6, 0, 5), Vector3.new(5, 5, 5), "Mission Exchange", env)
		end
	end

	-- B. PLATFORM ZONES
	-- Spawn Area
	local spawn = Instance.new("SpawnLocation")
	spawn.CFrame = CFrame.new(0, PLATFORM_HEIGHT + 1, 40)
	spawn.Size = Vector3.new(30, 0.5, 30)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Parent = env

	-- Mission Board Area (Alexander)
	local boardPos = CFrame.new(0, PLATFORM_HEIGHT + 6, STATION_WIDTH/2 - 2)
	local mapBoard = createPart("MapBoard", Vector3.new(20, 10, 1), boardPos, env, COLORS.Concrete, Enum.Material.Wood)
	-- Posters on board
	for j = -1, 1 do
		createPart("Poster", Vector3.new(4, 5, 0.1), boardPos * CFrame.new(j*5, 0, -0.6), env, Color3.new(1,1,1), Enum.Material.SmoothPlastic)
	end

	local alexPos = boardPos * CFrame.new(-12, -3, -10)
	spawnNPC("Alexander", alexPos * CFrame.Angles(0, math.rad(180), 0), env, COLORS.ConcreteDark)
	createInteraction("LobbyRoom", alexPos, Vector3.new(6, 6, 6), "Discuss Mission", env)

	-- C. SHOPS & UTILITIES
	-- Booster Shop (Medical Tent)
	local tentPos = CFrame.new(100, PLATFORM_HEIGHT + 5, 30)
	local tent = createPart("MedTent", Vector3.new(18, 10, 18), tentPos, env, COLORS.MedicalWhite, Enum.Material.Fabric)
	-- Tent poles
	createPart("Pole", Vector3.new(1, 10, 1), tentPos * CFrame.new(8,0,8), env, COLORS.DarkMetal, Enum.Material.Metal)
	createPart("Pole", Vector3.new(1, 10, 1), tentPos * CFrame.new(-8,0,8), env, COLORS.DarkMetal, Enum.Material.Metal)
	createInteraction("BoosterShop", tentPos, Vector3.new(10, 10, 10), "Medical Supplies", env)

	-- Daily Reward (Supply Drop)
	local stashPos = CFrame.new(-100, PLATFORM_HEIGHT + 3, 30)
	local crate = createPart("SupplyCrate", Vector3.new(8, 8, 8), stashPos, env, COLORS.RustyMetal, Enum.Material.CorrodedMetal)
	createInteraction("DailyReward", stashPos, Vector3.new(9, 9, 9), "Open Supply Drop", env)

	-- Gacha (Vending Machine)
	local gachaPos = stashPos * CFrame.new(0, 2, -20)
	local vm = createPart("VendingMachine", Vector3.new(6, 12, 6), gachaPos, env, Color3.fromRGB(50, 50, 150), Enum.Material.Metal)
	local screen = createPart("VMScreen", Vector3.new(4, 4, 0.1), gachaPos * CFrame.new(0, 2, -3), env, Color3.fromRGB(100, 255, 255), Enum.Material.Neon)
	createLight(screen, Vector3.new(0,0,-1), Color3.fromRGB(100, 255, 255), 10, 0.8)
	createInteraction("Gacha", gachaPos, Vector3.new(8, 12, 8), "Mystery Cache", env)

	-- 4. PARTICLES
	-- Dust motes near lights
	for x = -100, 100, 50 do
		local dustPart = Instance.new("Part")
		dustPart.Transparency = 1
		dustPart.Anchored = true
		dustPart.CanCollide = false
		dustPart.Position = Vector3.new(x, STATION_HEIGHT - 10, 20)
		dustPart.Parent = env
		createParticle("Dust", dustPart)
	end

	print("LobbyBuilder: Polished Station Built.")
end

return LobbyBuilder
