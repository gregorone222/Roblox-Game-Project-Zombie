-- Boss2VFXModule.lua (ReplicatedStorage)
-- Handling Hive Mother Visuals

local Boss2VFX = {}
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Sub-modules
local AcidSpitVFX = require(script.Parent:WaitForChild("AcidSpitVFX"))
local ToxicCloudVFX = require(script.Parent:WaitForChild("ToxicCloudVFX"))
local LarvaSpawnVFX = require(script.Parent:WaitForChild("LarvaSpawnVFX"))
local TransitionVFX = require(script.Parent:WaitForChild("HiveMotherTransitionVFX"))

function Boss2VFX.PlaySkill(skillName, data)
	if skillName == "AcidSpit" then
		AcidSpitVFX.Play(data.Origin, data.TargetPos)
	elseif skillName == "ToxicCloud" then
		ToxicCloudVFX.Play(data.Origin, data.Radius, data.Duration)
	elseif skillName == "SpawnLarva" then
		LarvaSpawnVFX.Play(data.SpawnPoints)
	elseif skillName == "Metamorphosis" then
		TransitionVFX.Play(data.BossModel)
	end
end

return Boss2VFX
