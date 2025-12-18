-- BossVFXHandler.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/BossVFXHandler.lua
-- Listens for PlayBossSkillEvent and triggers Client VFX

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlayBossSkillEvent = RemoteEvents:WaitForChild("PlayBossSkillEvent")

-- Modules
local Boss2VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss2VFXModule"))

PlayBossSkillEvent.OnClientEvent:Connect(function(skillName, data)
	-- Router for Boss Skills
	-- Ideally, skillName would be "BossName_SkillName" or data includes boss ID
	-- For this patch, we assume skills are unique enough or mapped manually

	if skillName == "AcidSpit" or skillName == "SpawnLarva" or skillName == "ToxicCloud" or skillName == "Metamorphosis" then
		Boss2VFXModule.PlaySkill(skillName, data)
	end
end)
