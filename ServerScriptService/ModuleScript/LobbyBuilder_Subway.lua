-- LobbyBuilderSubway.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LobbyBuilder_Subway.lua
-- Script Place: Lobby
-- Theme: Abandoned Subway Station (Survivor Shelter) - EXPANDED & POLISHED

local LobbyBuilder = {}

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	GreenPhosphor = Color3.fromRGB(50, 255, 50),
	ScreenBlack = Color3.fromRGB(10, 15, 10),
}

-- Asset IDs (Standard Roblox Assets)
local SOUNDS = {
	AmbientHum = "rbxassetid://130972023", -- Low industrial hum
	DrippingWater = "rbxassetid://130972023", -- Placeholder (Generic Hum used if specific drip not found, recommend replacing)
	Wind = "rbxassetid://9043813636", -- Hollow wind
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

local function createWedge(name, size, cframe, parent, color, material)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cframe
	w.Parent = parent
	w.Color = color or COLORS.Concrete
	w.Material = material or Enum.Material.Concrete
	w.Anchored = true
	return w
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
	local model
	local head

	-- [UPDATED] Check for Prefab Model in ServerStorage
	local npcFolder = ServerStorage:FindFirstChild("NPC")
	local prefab = npcFolder and npcFolder:FindFirstChild(name)

	if prefab then
		-- Clone from ServerStorage
		model = prefab:Clone()
		model.Parent = parent
		-- Position logic
		if model.PrimaryPart then
			model:PivotTo(cframe)
		else
			model:PivotTo(cframe) -- Hope for the best with default pivot
		end
		head = model:FindFirstChild("Head")
	else
		-- Fallback: Blocky Construction
		model = Instance.new("Model")
		model.Name = name
		model.Parent = parent

		local hrp = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), cframe, model, appearanceColor, Enum.Material.Fabric)
		hrp.Transparency = 1
		head = createPart("Head", Vector3.new(1, 1, 1), cframe * CFrame.new(0, 1.5, 0), model, Color3.fromRGB(255, 200, 180), Enum.Material.SmoothPlastic)
		local torso = createPart("Torso", Vector3.new(2, 2, 1), cframe, model, appearanceColor, Enum.Material.Fabric)

		local hum = Instance.new("Humanoid")
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- [UPDATED] Hide default name tag
		hum.Parent = model
		model.PrimaryPart = hrp
	end

	-- Disable default name tag on prefab if it has a humanoid
	local prefabHum = model:FindFirstChild("Humanoid")
	if prefabHum then
		prefabHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	-- Add Name Tag if Head exists and doesn't have one
    -- [UPDATED] Only create if NOT Alexander (Alexander has built-in tag), needed for Quartermaster
	if head and not head:FindFirstChild("BillboardGui") and name ~= "Alexander" then
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
	end

	-- Force Anchor
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = true -- Optional: Player collision
		end
	end

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

local function createLeaderboardScreen(name, cframe, parent)
	-- Industrial Frame
	local frameHeight = 16
	local frameWidth = 10
	local frameDepth = 1.5

	-- Main Support Frame
	local model = Instance.new("Model")
	model.Name = name .. "_Mount"
	model.Parent = parent

	local frame = createPart("Frame", Vector3.new(frameWidth, frameHeight, frameDepth), cframe, model, COLORS.DarkMetal, Enum.Material.CorrodedMetal)

	-- The Screen Surface (Part that holds the UI)
	local screen = createPart(name, Vector3.new(frameWidth - 1, frameHeight - 1, 0.2), cframe * CFrame.new(0, 0, frameDepth/2 + 0.1), parent, COLORS.ScreenBlack, Enum.Material.Glass)
	screen.Color = Color3.fromRGB(20, 25, 20)

	-- Cables Hanging down
	createCables(model, frame.Position + Vector3.new(0, frameHeight/2, 0), frame.Position + Vector3.new(0, 20, 0), 5)

	-- Base Support (Floor Mount)
	createPart("BaseL", Vector3.new(1, 4, 2), cframe * CFrame.new(-frameWidth/2 + 0.5, -frameHeight/2 - 2, 0), model, COLORS.DarkMetal, Enum.Material.DiamondPlate)
	createPart("BaseR", Vector3.new(1, 4, 2), cframe * CFrame.new(frameWidth/2 - 0.5, -frameHeight/2 - 2, 0), model, COLORS.DarkMetal, Enum.Material.DiamondPlate)

	return screen
end

local function BuildLeaderboardArea(env, originCFrame)
	-- Create dedicated folder in Workspace for Leaderboard Client to find parts
	local lbFolder = Workspace:FindFirstChild("Leaderboard")

	-- RACE CONDITION FIX:
	-- Instead of destroying the folder (which breaks client references if they grabbed it early),
	-- we simply reuse it and clear its contents.
	if lbFolder then
		lbFolder:ClearAllChildren()
	else
		lbFolder = Instance.new("Folder")
		lbFolder.Name = "Leaderboard"
		lbFolder.Parent = Workspace
	end

	-- Configuration matches LeaderboardConfig.lua
	local boards = {
		"KillLeaderboard",
		"TDLeaderboard",
		"APLeaderboard",
		"LVLeaderboard",
		"MPLeaderboard",
		"GlobalMission" -- Added missing GlobalMission board
	}

	-- Arrange in a semi-circle
	local radius = 25
	local angleStep = 25 -- degrees
	local startAngle = -((#boards - 1) * angleStep) / 2

	for i, boardName in ipairs(boards) do
		local angle = math.rad(startAngle + (i-1) * angleStep)
		local offset = Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius)

		-- Position relative to origin, facing INWARDS to origin
		local pos = originCFrame:PointToWorldSpace(offset)
		local lookAt = originCFrame.Position
		local boardCFrame = CFrame.lookAt(pos, lookAt)

		-- Adjust height
		boardCFrame = boardCFrame + Vector3.new(0, 8, 0)

		createLeaderboardScreen(boardName, boardCFrame, lbFolder)
	end

	-- Add some ambient light for the screens area
	local lightPart = createPart("LeaderboardAmbient", Vector3.new(1,1,1), originCFrame * CFrame.new(0, 15, 10), env, Color3.new(1,1,1), Enum.Material.Neon)
	lightPart.Transparency = 1
	createLight(lightPart, Vector3.new(0,-1,0), Color3.fromRGB(50, 255, 100), 40, 0.5)
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
	-- [UPDATED] WallBack split into two to create entrance for Leaderboard Room
	local wallGap = 60
	local wallLen = (STATION_LENGTH - wallGap) / 2
	local wallOffset = wallGap/2 + wallLen/2

	createPart("WallBackLeft", Vector3.new(wallLen, STATION_HEIGHT, 2), CFrame.new(-wallOffset, STATION_HEIGHT/2, STATION_WIDTH/2), env, COLORS.Tiles, Enum.Material.Brick)
	createPart("WallBackRight", Vector3.new(wallLen, STATION_HEIGHT, 2), CFrame.new(wallOffset, STATION_HEIGHT/2, STATION_WIDTH/2), env, COLORS.Tiles, Enum.Material.Brick)

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
	-- Configured via LightingManager
	-- Lighting.ClockTime = 0
	-- Lighting.Brightness = 0
	-- Lighting.Ambient = Color3.fromRGB(20, 20, 25) -- Very Dark
	-- Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 15)
	-- Lighting.FogColor = Color3.fromRGB(15, 15, 20)
	-- Lighting.FogEnd = 150 -- Close fog for claustrophobia

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

		-- Shop Car (Center) - Quartermaster Area
		if i == 0 then
			local qmPos = trainPos * CFrame.new(0, -4.5, 0)
			spawnNPC("Quartermaster", qmPos * CFrame.Angles(0, math.rad(180), 0), env, COLORS.Wood)

			-- Quartermaster Decor: Workbench
			local benchPos = qmPos * CFrame.new(0, 0, 3)
			local bench = createPart("Workbench", Vector3.new(12, 3, 4), benchPos, env, COLORS.Wood, Enum.Material.WoodPlanks)
			-- Tools on bench (simple blocks)
			createPart("ToolBox", Vector3.new(2, 1, 1), benchPos * CFrame.new(-4, 2, 0), env, COLORS.RustyMetal, Enum.Material.Metal)
			createPart("Blueprint", Vector3.new(3, 0.1, 2), benchPos * CFrame.new(2, 1.55, 0), env, Color3.new(1,1,1), Enum.Material.SmoothPlastic)

			-- Weapon Rack (Empty slots)
			local rackPos = qmPos * CFrame.new(-10, 0, 4)
			local rack = createPart("WeaponRack", Vector3.new(1, 6, 8), rackPos, env, COLORS.DarkMetal, Enum.Material.Metal)

			createLight(car, Vector3.new(0, 0, 0), Color3.fromRGB(255, 200, 100), 20, 1) -- Warm shop light

			-- Interaction Points for Shops (Now integrated with the workbench area)
			createInteraction("APShop", benchPos * CFrame.new(-3, 0, 2), Vector3.new(5, 5, 5), "Achievement Exchange", env)
			createInteraction("MPShop", benchPos * CFrame.new(3, 0, 2), Vector3.new(5, 5, 5), "Mission Exchange", env)
		end
	end

	-- B. PLATFORM ZONES
	-- Spawn Area
	local spawn = Instance.new("SpawnLocation")
	spawn.CFrame = CFrame.new(0, PLATFORM_HEIGHT + 1, 40)
	spawn.Size = Vector3.new(30, 0.5, 30)
	spawn.Transparency = 1
	spawn.Duration = 0 -- Disable ForceField
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Parent = env

	-- BUILD LEADERBOARDS (Dedicated Room)
	-- Constructing the "Hall of Fame" Room behind the spawn
	local roomZStart = STATION_WIDTH/2 -- 60
	local roomDepth = 50
	local roomWidth = 60
	local roomCenterZ = roomZStart + roomDepth/2
	local roomFloorY = PLATFORM_HEIGHT

	-- Room Floor
	createPart("LBRoomFloor", Vector3.new(roomWidth, 1, roomDepth), CFrame.new(0, roomFloorY - 0.5, roomCenterZ), env, COLORS.Concrete, Enum.Material.Concrete)

	-- Room Walls
	createPart("LBRoomWallL", Vector3.new(2, STATION_HEIGHT, roomDepth), CFrame.new(-roomWidth/2, STATION_HEIGHT/2, roomCenterZ), env, COLORS.Tiles, Enum.Material.Brick)
	createPart("LBRoomWallR", Vector3.new(2, STATION_HEIGHT, roomDepth), CFrame.new(roomWidth/2, STATION_HEIGHT/2, roomCenterZ), env, COLORS.Tiles, Enum.Material.Brick)
	createPart("LBRoomWallBack", Vector3.new(roomWidth, STATION_HEIGHT, 2), CFrame.new(0, STATION_HEIGHT/2, roomZStart + roomDepth), env, COLORS.Tiles, Enum.Material.Brick)

	-- Room Ceiling
	createPart("LBRoomCeiling", Vector3.new(roomWidth, 1, roomDepth), CFrame.new(0, STATION_HEIGHT, roomCenterZ), env, COLORS.ConcreteDark, Enum.Material.Slate)

	-- Room Lighting (Dramatic)
	local roomLightPart = createPart("LBRoomLight", Vector3.new(roomWidth-2, 1, 2), CFrame.new(0, 20, roomCenterZ), env, Color3.new(0,0,0), Enum.Material.Neon)
	roomLightPart.Transparency = 1
	createLight(roomLightPart, Vector3.new(0,-1,0), Color3.fromRGB(50, 255, 100), 60, 0.8)

	-- Steps connecting Platform to Room (gap filler)
	createPart("LBRoomSteps", Vector3.new(roomWidth, 1, 10), CFrame.new(0, roomFloorY - 0.5, roomZStart - 2), env, COLORS.Concrete, Enum.Material.DiamondPlate)

	-- Position Leaderboards inside the room
	-- [UPDATED] Fixed orientation: Origin moved closer to entrance, rotation removed so boards face entrance
	local lbOrigin = CFrame.new(0, roomFloorY + 1, roomCenterZ - 10)
	BuildLeaderboardArea(env, lbOrigin)

	-- Mission Command Center (Alexander) - REVISED FOR STORY
	local boardPos = CFrame.new(0, PLATFORM_HEIGHT + 6, STATION_WIDTH/2 - 2)

	-- Command Table (Map of The Village)
	local tablePos = boardPos * CFrame.new(0, -6, -15)
	local tableBase = createPart("CommandTable", Vector3.new(12, 1, 8), tablePos, env, COLORS.DarkMetal, Enum.Material.Metal)
	createPart("TableLeg1", Vector3.new(1, 3, 1), tablePos * CFrame.new(5, -2, 3), env, COLORS.DarkMetal, Enum.Material.Metal)
	createPart("TableLeg2", Vector3.new(1, 3, 1), tablePos * CFrame.new(-5, -2, 3), env, COLORS.DarkMetal, Enum.Material.Metal)
	createPart("TableLeg3", Vector3.new(1, 3, 1), tablePos * CFrame.new(5, -2, -3), env, COLORS.DarkMetal, Enum.Material.Metal)
	createPart("TableLeg4", Vector3.new(1, 3, 1), tablePos * CFrame.new(-5, -2, -3), env, COLORS.DarkMetal, Enum.Material.Metal)

	-- Holographic Map (Visual)
	local mapPart = createPart("HoloMap", Vector3.new(10, 0.1, 6), tablePos * CFrame.new(0, 0.6, 0), env, Color3.fromRGB(0, 50, 0), Enum.Material.Neon)
	local mapLight = createLight(mapPart, Vector3.new(0, 1, 0), Color3.fromRGB(50, 255, 50), 10, 2)

	-- Strategic Map Board (Wall)
	local mapBoard = createPart("MapBoard", Vector3.new(24, 12, 1), boardPos, env, COLORS.Concrete, Enum.Material.Slate)
	-- Act 1: Village Zone (Highlighted)
	local villageZone = createPart("VillageZone", Vector3.new(8, 6, 0.2), boardPos * CFrame.new(-6, 0, -0.6), env, Color3.fromRGB(200, 50, 50), Enum.Material.Plastic)
	local villageLabel = Instance.new("SurfaceGui")
	villageLabel.Face = Enum.NormalId.Front
	villageLabel.Parent = villageZone
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1,1)
	txt.BackgroundTransparency = 1
	txt.Text = "ACT 1: THE VILLAGE\n(GROUND ZERO)"
	txt.TextColor3 = Color3.new(1,1,1)
	txt.TextSize = 40
	txt.Font = Enum.Font.Sarpanch
	txt.Parent = villageLabel

	-- Act 2: Locked Zone
	local cityZone = createPart("CityZone", Vector3.new(8, 6, 0.2), boardPos * CFrame.new(6, 0, -0.6), env, Color3.fromRGB(50, 50, 50), Enum.Material.DiamondPlate)
	local lockLabel = Instance.new("SurfaceGui")
	lockLabel.Face = Enum.NormalId.Front
	lockLabel.Parent = cityZone
	local txt2 = Instance.new("TextLabel")
	txt2.Size = UDim2.fromScale(1,1)
	txt2.BackgroundTransparency = 1
	txt2.Text = "ACT 2: ???\n(LOCKED)"
	txt2.TextColor3 = Color3.fromRGB(150, 0, 0)
	txt2.TextSize = 40
	txt2.Font = Enum.Font.Sarpanch
	txt2.Parent = lockLabel

	-- Alexander NPC (Commanding Position)
	local alexPos = tablePos * CFrame.new(0, 2, 6) * CFrame.Angles(0, math.rad(180), 0)
	spawnNPC("Alexander", alexPos, env, COLORS.ConcreteDark)

	-- Radio Equipment
	createPart("RadioSet", Vector3.new(2, 1, 1), tablePos * CFrame.new(4, 0.6, 2), env, Color3.new(0.2, 0.2, 0.2), Enum.Material.Plastic)
	createSoundEmitter("RadioChatter", tableBase, "rbxassetid://9063255294", 0.4, true, 20) -- Static chatter

	-- Interaction Point
	-- createInteraction("LobbyRoom", alexPos, Vector3.new(8, 8, 8), "Mission Briefing", env) -- REMOVED: Now integrated into dialogue
	createInteraction("DialogueAlexander", alexPos, Vector3.new(6, 6, 6), "Talk", env)

	-- C. SHOPS & UTILITIES
	-- Booster Shop (Medical Tent Area)
	local tentPos = CFrame.new(100, PLATFORM_HEIGHT, 30) -- On Platform floor

	-- Medical Tent Structure (Wedges for roof)
	local tentSize = Vector3.new(20, 10, 20)
	local tentCenter = tentPos + Vector3.new(0, 5, 0)

	-- Tent Roof
	local roofL = createWedge("RoofLeft", Vector3.new(2, 12, 22), tentPos * CFrame.new(5, 10, 0) * CFrame.Angles(0, 0, math.rad(45)), env, COLORS.MedicalWhite, Enum.Material.Fabric)
	local roofR = createWedge("RoofRight", Vector3.new(2, 12, 22), tentPos * CFrame.new(-5, 10, 0) * CFrame.Angles(0, math.rad(180), math.rad(45)), env, COLORS.MedicalWhite, Enum.Material.Fabric)

	-- Tent Walls (Partial)
	createPart("TentWallBack", Vector3.new(20, 10, 1), tentPos * CFrame.new(0, 5, 10), env, COLORS.MedicalWhite, Enum.Material.Fabric)

	-- Medical Furniture: Stretcher
	local bedPos = tentPos * CFrame.new(5, 1, -5)
	createPart("StretcherMat", Vector3.new(4, 0.5, 8), bedPos, env, Color3.fromRGB(50, 100, 50), Enum.Material.Fabric)
	createPart("StretcherFrame", Vector3.new(4.2, 0.2, 8.2), bedPos * CFrame.new(0, -0.3, 0), env, COLORS.DarkMetal, Enum.Material.Metal)

	-- Medical Crates
	createPart("MedCrate1", Vector3.new(2, 2, 2), tentPos * CFrame.new(-6, 1, -5), env, COLORS.MedicalWhite, Enum.Material.Plastic)
	local decalPart = createPart("CrossIcon", Vector3.new(0.5, 0.5, 0.1), tentPos * CFrame.new(-6, 1, -3.9), env, Color3.fromRGB(200, 0, 0), Enum.Material.Neon)

	-- Booster Interaction (Near the crate)
	createInteraction("BoosterShop", tentPos * CFrame.new(-6, 2, -5), Vector3.new(8, 8, 8), "Medical Supplies", env)

	-- Daily Reward (Physical Supply Crate)
	local stashPos = CFrame.new(-100, PLATFORM_HEIGHT + 1.5, 30)

	-- Crate Model (Constructed from Parts)
	local crate = createPart("SupplyCrate", Vector3.new(6, 4, 4), stashPos, env, Color3.fromRGB(50, 70, 50), Enum.Material.DiamondPlate)
	-- Lid (Separate part for animation)
	local lid = createPart("Lid", Vector3.new(6.2, 0.5, 4.2), stashPos * CFrame.new(0, 2.25, 0), crate, Color3.fromRGB(40, 60, 40), Enum.Material.DiamondPlate)
	lid.Anchored = true

	-- Glow Effect (Hidden initially)
	local glow = createParticle("Glow", crate, "rbxassetid://292289455", ColorSequence.new(Color3.fromRGB(50, 255, 100)), NumberSequence.new(2))
	glow.Enabled = false

	-- Gacha (Vending Machine) - DETAILED
	local gachaPos = stashPos * CFrame.new(0, 3, -20)
	local vm = createPart("VendingMachine", Vector3.new(6, 12, 6), gachaPos, env, Color3.fromRGB(50, 50, 150), Enum.Material.Metal)
	-- Screen Area
	local screen = createPart("VMScreen", Vector3.new(4, 4, 0.1), gachaPos * CFrame.new(0, 2, -3), env, Color3.fromRGB(100, 255, 255), Enum.Material.Neon)
	createLight(screen, Vector3.new(0,0,-1), Color3.fromRGB(100, 255, 255), 10, 0.8)
	-- Buttons
	for b = -1, 1 do
		createPart("Button"..b, Vector3.new(0.5, 0.5, 0.2), gachaPos * CFrame.new(b*1.5, -1, -3), env, Color3.new(1,0,0), Enum.Material.Plastic)
	end
	-- Dispense Slot
	createPart("Slot", Vector3.new(4, 1, 0.5), gachaPos * CFrame.new(0, -4, -3), env, Color3.new(0.1,0.1,0.1), Enum.Material.Metal)

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

	-- 5. START PART FOR VOTING
	-- This must exist for StartUI.lua to work (Mission Briefing logic)
	-- We create a part named "StartPart" near Alexander
	local startPart = createPart("StartPart", Vector3.new(5, 5, 5), alexPos, env, Color3.new(1,0,0), Enum.Material.Neon)
	startPart.Transparency = 1
	startPart.CanCollide = false

	print("LobbyBuilder: Polished Station Built.")
end

return LobbyBuilder