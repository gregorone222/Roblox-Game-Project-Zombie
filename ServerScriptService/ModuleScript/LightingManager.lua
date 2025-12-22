-- LightingManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/LightingManager.lua
-- Manages Atmospheric Lighting, Fog, and Time of Day

local LightingManager = {}
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- 1. VISUALA PILLAR: ETHEREAL / BITTERSWEET (SUNSET)
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
	print("LightingManager: Initialized Ethereal Sunset Environment.")
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

return LightingManager
