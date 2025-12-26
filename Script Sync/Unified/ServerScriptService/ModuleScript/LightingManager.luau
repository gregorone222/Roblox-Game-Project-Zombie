-- LightingManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LightingManager.lua
-- Manages Atmospheric Lighting, Fog, and Time of Day

local LightingManager = {}
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- 1. VISUAL PILLAR: ETHEREAL / BITTERSWEET (SUNSET)
LightingManager.BaseSettings = {
	ClockTime = 17.5, -- 17:30 (Sunset/Golden Hour)
	Brightness = 2,
	Ambient = Color3.fromRGB(80, 70, 100), -- Deep Purple
	OutdoorAmbient = Color3.fromRGB(80, 70, 100), -- Deep Purple
	FogColor = Color3.fromRGB(180, 140, 180), -- Pink/Lavender Fog
	FogStart = 10,
	FogEnd = 300
}

LightingManager.DarkSettings = {
	ClockTime = 0, -- Midnight
	Brightness = 1,
	Ambient = Color3.fromRGB(20, 20, 30),
	OutdoorAmbient = Color3.fromRGB(10, 10, 15),
	FogColor = Color3.fromRGB(20, 20, 30),
	FogStart = 0,
	FogEnd = 150
}

LightingManager.BloodSettings = {
	ClockTime = 0,
	Brightness = 0.8,
	Ambient = Color3.fromRGB(50, 0, 0),
	OutdoorAmbient = Color3.fromRGB(40, 0, 0),
	FogColor = Color3.fromRGB(50, 10, 10),
	FogStart = 0,
	FogEnd = 200
}

-- === NEW: Time-of-Day Presets for Progressive Day Cycle ===
LightingManager.TimePresets = {
	-- Early Morning (6-8 AM) - Sunrise, warm and misty
	Morning = {
		Brightness = 1.5,
		Ambient = Color3.fromRGB(120, 100, 80),
		OutdoorAmbient = Color3.fromRGB(140, 120, 100),
		FogColor = Color3.fromRGB(200, 180, 160), -- Warm morning mist
		FogStart = 20,
		FogEnd = 400
	},
	-- Midday (10-14) - Bright and clear
	Midday = {
		Brightness = 3,
		Ambient = Color3.fromRGB(150, 150, 160),
		OutdoorAmbient = Color3.fromRGB(180, 180, 190),
		FogColor = Color3.fromRGB(220, 230, 240), -- Light blue haze
		FogStart = 100,
		FogEnd = 600
	},
	-- Afternoon (14-17) - Warm, longer shadows
	Afternoon = {
		Brightness = 2.5,
		Ambient = Color3.fromRGB(130, 110, 90),
		OutdoorAmbient = Color3.fromRGB(160, 140, 110),
		FogColor = Color3.fromRGB(200, 180, 150), -- Warm afternoon
		FogStart = 50,
		FogEnd = 450
	},
	-- Golden Hour (17-18) - Beautiful victory atmosphere
	GoldenHour = {
		Brightness = 2,
		Ambient = Color3.fromRGB(150, 100, 80),
		OutdoorAmbient = Color3.fromRGB(180, 130, 100),
		FogColor = Color3.fromRGB(220, 160, 120), -- Golden mist
		FogStart = 30,
		FogEnd = 350
	},
	-- Victory (Wave 50 complete) - Extra beautiful
	Victory = {
		Brightness = 2.5,
		Ambient = Color3.fromRGB(180, 120, 90),
		OutdoorAmbient = Color3.fromRGB(200, 150, 110),
		FogColor = Color3.fromRGB(240, 180, 140), -- Warm golden glow
		FogStart = 20,
		FogEnd = 300
	}
}

-- Ensure Atmosphere and ColorCorrection exist
local function setupEffects()
	-- Atmosphere
	local atmosphere = Lighting:FindFirstChild("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "Atmosphere"
	atmosphere.Parent = Lighting
	atmosphere.Density = 0.35
	atmosphere.Offset = 0
	atmosphere.Haze = 2 -- High haze for dreamy look
	atmosphere.Glare = 0.5
	atmosphere.Color = Color3.fromRGB(180, 150, 180) -- Pinkish
	atmosphere.Decay = Color3.fromRGB(100, 80, 100) -- Purple

	-- ColorCorrection
	local cc = Lighting:FindFirstChild("ColorCorrection") or Instance.new("ColorCorrectionEffect")
	cc.Name = "ColorCorrection"
	cc.Parent = Lighting
	cc.Contrast = 0.1
	cc.Saturation = 0.2 -- Boost colors slightly
	cc.TintColor = Color3.fromRGB(255, 230, 255) -- Subtle warm tint

	-- SunRays
	local sunrays = Lighting:FindFirstChild("SunRays") or Instance.new("SunRaysEffect")
	sunrays.Name = "SunRays"
	sunrays.Parent = Lighting
	sunrays.Intensity = 0.1
	sunrays.Spread = 0.8

	-- Bloom
	local bloom = Lighting:FindFirstChild("Bloom") or Instance.new("BloomEffect")
	bloom.Name = "Bloom"
	bloom.Parent = Lighting
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 0.8
end

function LightingManager.Init()
	setupEffects()
	LightingManager.ApplySettings(LightingManager.BaseSettings, 0)
	-- print removed
end

function LightingManager.ApplySettings(settings, duration)
	duration = duration or 0

	local goal = {
		ClockTime = settings.ClockTime,
		Brightness = settings.Brightness,
		Ambient = settings.Ambient,
		OutdoorAmbient = settings.OutdoorAmbient,
		FogColor = settings.FogColor,
		FogStart = settings.FogStart,
		FogEnd = settings.FogEnd
	}

	-- Handle day cycle wrapping
	if duration > 0 and goal.ClockTime < Lighting.ClockTime then
		goal.ClockTime = goal.ClockTime + 24
	end

	if duration <= 0 then
		for prop, val in pairs(goal) do
			Lighting[prop] = val
		end
		-- Also update Atmosphere color to match Fog
		local atm = Lighting:FindFirstChild("Atmosphere")
		if atm then atm.Color = settings.FogColor end
	else
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenService:Create(Lighting, tweenInfo, goal):Play()

		-- Tween Atmosphere color separately
		local atm = Lighting:FindFirstChild("Atmosphere")
		if atm then
			TweenService:Create(atm, tweenInfo, {Color = settings.FogColor}):Play()
		end
	end
end

-- === NEW: Progressive Day Cycle Functions ===

-- Get the appropriate preset based on clock time
function LightingManager.GetPresetForTime(clockTime)
	if clockTime < 8 then
		return LightingManager.TimePresets.Morning
	elseif clockTime < 12 then
		return LightingManager.TimePresets.Midday
	elseif clockTime < 16 then
		return LightingManager.TimePresets.Afternoon
	else
		return LightingManager.TimePresets.GoldenHour
	end
end

-- Calculate time of day based on wave number
function LightingManager.CalculateTimeForWave(waveNum, startTime, endTime, totalWaves)
	startTime = startTime or 6
	endTime = endTime or 18
	totalWaves = totalWaves or 50

	local progress = math.clamp((waveNum - 1) / (totalWaves - 1), 0, 1)
	return startTime + (progress * (endTime - startTime))
end

-- Set time of day with smooth transition
function LightingManager.SetTimeOfDay(clockTime, duration)
	duration = duration or 10

	-- Get appropriate preset for this time
	local preset = LightingManager.GetPresetForTime(clockTime)

	-- Create settings with the exact clock time and preset values
	local settings = {
		ClockTime = clockTime,
		Brightness = preset.Brightness,
		Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient,
		FogColor = preset.FogColor,
		FogStart = preset.FogStart,
		FogEnd = preset.FogEnd
	}

	LightingManager.ApplySettings(settings, duration)
	print(string.format("LightingManager: Time set to %.1f (Duration: %.1fs)", clockTime, duration))
end

-- Special victory lighting with enhanced effects
function LightingManager.ApplyVictoryLighting(duration)
	duration = duration or 5

	local victory = LightingManager.TimePresets.Victory
	local settings = {
		ClockTime = 18,
		Brightness = victory.Brightness,
		Ambient = victory.Ambient,
		OutdoorAmbient = victory.OutdoorAmbient,
		FogColor = victory.FogColor,
		FogStart = victory.FogStart,
		FogEnd = victory.FogEnd
	}

	LightingManager.ApplySettings(settings, duration)

	-- Enhance sun rays for victory
	local sunrays = Lighting:FindFirstChild("SunRays")
	if sunrays then
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine)
		TweenService:Create(sunrays, tweenInfo, {Intensity = 0.3, Spread = 1}):Play()
	end

	-- Enhance bloom for victory
	local bloom = Lighting:FindFirstChild("Bloom")
	if bloom then
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine)
		TweenService:Create(bloom, tweenInfo, {Intensity = 0.6, Size = 32}):Play()
	end

	print("LightingManager: Victory lighting applied! ✨")
end

return LightingManager
