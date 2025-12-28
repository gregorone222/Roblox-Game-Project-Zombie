-- SharedEventsSetup.server.luau
-- Path: ServerScriptService/Script/SharedEventsSetup.server.luau
-- Runs in ALL places to ensure all events/functions exist for unified script sync
-- COMPLETE LIST: Generated from grep search of all WaitForChild calls

local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- === CREATE FOLDERS ===
local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local RemoteEvents = getOrCreateFolder(ReplicatedStorage, "RemoteEvents")
local RemoteFunctions = getOrCreateFolder(ReplicatedStorage, "RemoteFunctions")
local BindableEvents = getOrCreateFolder(ReplicatedStorage, "BindableEvents")
local BindableFunctions = getOrCreateFolder(ReplicatedStorage, "BindableFunctions")

-- === ALL REMOTE EVENTS (Complete List) ===
local allRemoteEvents = {
	-- ========== WEAPON SYSTEM ==========
	"ShootEvent", "ReloadEvent", "AmmoUpdateEvent",
	"TracerEvent", "TracerBroadcast",
	"MuzzleFlashEvent", "MuzzleFlashBroadcast",
	"BulletholeEvent", "HitmarkerEvent",
	"PlayLocalGunshotSoundEvent", "PlayGunshotSoundEvent",
	"ExplosionEvent",
	
	-- ========== COMBAT/DAMAGE ==========
	"DamageDisplayEvent", "KnockEvent", "ReviveEvent", "GameOverEvent", "ExitGameEvent",
	"ShieldUpdateEvent", "DebuffStatusEvent", "PingKnockedPlayerEvent", "GlobalKnockNotificationEvent",
	"DamageFlashEvent", "CancelReviveEvent", "ReviveProgressEvent",
	
	-- ========== WAVE/GAME STATE ==========
	"WaveUpdateEvent", "WaveCountdownEvent", "MissionCompleteEvent",
	"SpecialWaveEvent", "SpecialWaveAlertEvent",
	"BossSpawnEvent", "BossHealthUpdateEvent", "BossTimerEvent", "BossIncoming", "HardWipeVFXEvent",
	"PlayerCountEvent", "OpenStartUIEvent", "ReadyCountEvent",
	"StartVoteCountdownEvent", "StartVoteCanceledEvent", "CancelStartVoteEvent",
	"GameSettingsUpdateEvent", "LevelUpdateEvent", "RestartGameEvent",
	
	-- ========== MOVEMENT ==========
	"UpdateWalkSpeedModifierEvent", "SprintEvent", "JumpEvent",
	"StaminaUpdate", "LookEvent",
	
	-- ========== SHOPS ==========
	"UpgradeUIOpen", "ConfirmUpgrade",
	"PerkShopEvent", "PerkBuyEvent", "OpenPerkShop", "PerkUpdate", "RequestOpenPerkShop", "ClosePerkShop",
	"TacticalBoostShopEvent", "TacticalBoostBuyEvent", "OpenTacticalBoostShop", "TacticalBoostUpdate", "RequestOpenTacticalBoostShop", "CloseTacticalBoostShop",
	"RandomWeaponEvent", "BuyRandomWeaponEvent",
	"OpenReplaceUI", "ReplaceChoice",
	
	-- ========== POINTS/CURRENCY ==========
	"PointsUpdate", "PointsUpdateEvent", "CoinsUpdate", "CoinsUpdateEvent", "SetPlayerStats",
	"SurvivalCoinsUpdateEvent", "ValorUpdate", -- New currency events
	
	-- ========== PERKS/ELEMENTS ==========
	"PerkActivatedEvent", "PerkDeactivatedEvent", "PerkActivated", "PerkDeactivated", "ActivatePerkEvent", "PerkPurchased",
	"PerkEquippedEvent", "PerkDisplayUpdate",
	"TacticalBoostActivatedEvent", "TacticalBoostDeactivatedEvent", "TacticalBoostActivated", "TacticalBoostDeactivated", "ActivateTacticalBoostEvent", "TacticalBoostPurchased",
	"TacticalBoostEquippedEvent", "TacticalBoostDisplayUpdate", "InvincibilityEffectEvent",
	
	-- ========== BOSS VFX ==========
	"PlayBossSkillEvent", "Boss2GravityLocalPull", "ChromaticRequiemUIEvent",
	
	-- ========== LOBBY EVENTS ==========
	"GachaEvent", "GachaRollEvent", "GachaResultEvent", "GachaSkinWonEvent",
	"StartGameEvent", "JoinRoomEvent", "LeaveRoomEvent", "RoomUpdateEvent",
	"VoteDifficultyEvent", "DialogueEvent", "LeaderboardUpdateEvent",
	"DailyRewardEvent", "ClaimDailyRewardEvent",
	"SkinEquipEvent", "SkinUpdateEvent",
	
	-- ========== SHOP (LOBBY) ==========
	"APShopEvent", "APShopBuyEvent", "APUpdateEvent",
	"MPShopEvent", "MPShopBuyEvent", "MPUpdateEvent",
	"BoosterBuyEvent", "BoosterUpdateEvent", "UpdatePlayerBoosterStatusEvent", "ActivateBoosterEvent",
	"FieldKitBuyEvent", "FieldKitUpdateEvent", "UpdatePlayerFieldKitStatusEvent", "ActivateFieldKitEvent",
	
	-- ========== PROFILE/STATS ==========
	"ProfileDataEvent", "ProfileUpdateEvent",
	"AchievementEvent", "AchievementUnlockEvent", "AchievementUpdateEvent",
	"MissionEvent", "MissionProgressEvent", "MissionUpdateEvent", "MissionsReset", "MissionProgressUpdated",
	"SkillEvent", "SkillUnlockEvent", "SkillUpdateEvent",
	"InventoryEvent", "InventoryUpdateEvent",
	
	-- ========== SETTINGS ==========
	"SettingsUpdateEvent", "UpdateSettingsEvent", "LoadSettingsEvent",
	"AdminEvent",
	
	-- ========== GLOBAL MISSION ==========
	"GlobalMissionUpdate", "GlobalMissionProgress",
	
	-- ========== TITLE DISPLAY ==========
	"TitleUpdateEvent",
}

-- === ALL REMOTE FUNCTIONS (Complete List) ===
local allRemoteFunctions = {
	-- ========== DATA ==========
	"GetPlayerData", "GetPlayerStats", "GetLeaderboardData",
	"GetProfileData", "GetInventoryData",
	
	-- ========== SHOP ==========
	"GetAPShopItems", "GetMPShopItems", "GetBoosterInventory", "GetGachaInventory",
	"PurchaseSkin", "PurchaseSkinWithAP", "PurchaseGenericItem", "PurchaseGenericItemWithAP",
	"GetGachaConfig", "GetGachaStatus",
	
	-- ========== GAME STATE ==========
	"GetWaveInfo", "GetRoomInfo",
	
	-- ========== SETTINGS ==========
	"GetSettings", "SaveSettings",
	
	-- ========== PERKS/ELEMENTS ==========
	"PurchasePerk", "GetOwnedPerks",
	"PurchaseTacticalBoost", "GetOwnedTacticalBoosts",
	
	-- ========== WEAPONS ==========
	"PurchaseRandomWeapon", "GetRandomWeaponCost",
	"UpgradeWeaponRF", "GetWeaponLevelRF",
	
	-- ========== MISSIONS ==========
	"GetMissionData", "ClaimMissionReward", "RerollMission",
	
	-- ========== DAILY REWARDS ==========
	"GetDailyRewardInfo", "ClaimDailyReward",
	
	-- ========== FIELD KITS (formerly BOOSTERS) ==========
	"GetActiveBooster", "ActivateBooster",
	"GetActiveFieldKit", "ActivateFieldKit",
	
	-- ========== SKILLS ==========
	"GetSkillData", "UnlockSkill",
	
	-- ========== ACHIEVEMENTS ==========
	"GetAchievementData", "ClaimAchievementReward", "GetAchievementsFunc",
	
	-- ========== GLOBAL MISSION ==========
	"GetGlobalMissionData", "ContributeGlobalMission",
	
	-- ========== SKINS ==========
	"GetOwnedSkins", "EquipSkin",
	
	-- ========== LOBBY ==========
	"GetRoomList", "CreateRoom", "JoinRoom", "LeaveRoom",
}

-- === ALL BINDABLE EVENTS ===
local allBindableEvents = {
	-- ========== ZOMBIE/COMBAT ==========
	"ZombieDied", "ZombieDiedEvent", "ReportDamageEvent", "ObjectDamaged",
	
	-- ========== ADMIN COMMANDS ==========
	"AdminSetWave", "AdminSkipWave", "AdminKillAll",
	"AdminGivePoints", "AdminSpawnBoss",
	
	-- ========== UI INTERNAL ==========
	"StartAutoFireEvent", "StopAutoFireEvent",
	"ToggleAimEvent", "AimStatusChangedEvent",
	"RequestReloadEvent", "RefreshMobileButtons",
	
	-- ========== LOBBY UI ==========
	"ToggleSkillUIEvent", "ToggleProfileUIEvent", "ToggleAchievementUIEvent",
	"ToggleMissionUIEvent", "ToggleInventoryUIEvent",
	"OpenLobbyEvent",
}

-- === ALL BINDABLE FUNCTIONS ===
local allBindableFunctions = {
	"GetCurrentWave",
	"GetPlayerLoadout",
	"GetZombieCount",
	"GetAlivePlayers",
}

-- === CREATE ALL INSTANCES ===
local createdEvents, createdFunctions, createdBindables, createdBindableFuncs = 0, 0, 0, 0

-- RemoteEvents
for _, name in ipairs(allRemoteEvents) do
	if not RemoteEvents:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = RemoteEvents
		createdEvents += 1
	end
end

-- RemoteFunctions
for _, name in ipairs(allRemoteFunctions) do
	if not RemoteFunctions:FindFirstChild(name) then
		local func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = RemoteFunctions
		createdFunctions += 1
	end
end

-- BindableEvents
for _, name in ipairs(allBindableEvents) do
	if not BindableEvents:FindFirstChild(name) then
		local event = Instance.new("BindableEvent")
		event.Name = name
		event.Parent = BindableEvents
		createdBindables += 1
	end
end

-- BindableFunctions
for _, name in ipairs(allBindableFunctions) do
	if not BindableFunctions:FindFirstChild(name) then
		local func = Instance.new("BindableFunction")
		func.Name = name
		func.Parent = BindableFunctions
		createdBindableFuncs += 1
	end
end

-- === CREATE ADDITIONAL FOLDERS ===
local SkillRemotes = getOrCreateFolder(ReplicatedStorage, "SkillRemotes")

-- === ROOT-LEVEL EVENTS (directly in ReplicatedStorage, not in folder) ===
local rootLevelEvents = {
	"TitleChanged", "MissionPointsChanged", "MissionProgressUpdated",
	"ShowDailyRewardUI",
}
for _, name in ipairs(rootLevelEvents) do
	if not ReplicatedStorage:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
		createdEvents += 1
	end
end

-- === ROOT-LEVEL FUNCTIONS (directly in ReplicatedStorage, not in folder) ===
local rootLevelFunctions = {
	"GetTitleData", "GetInitialMissionPoints",
}
for _, name in ipairs(rootLevelFunctions) do
	if not ReplicatedStorage:FindFirstChild(name) then
		local func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = ReplicatedStorage
		createdFunctions += 1
	end
end

-- MissionPointsChanged also needs to be in RemoteEvents folder
if not RemoteEvents:FindFirstChild("MissionPointsChanged") then
	local event = Instance.new("RemoteEvent")
	event.Name = "MissionPointsChanged"
	event.Parent = RemoteEvents
end
if not RemoteEvents:FindFirstChild("MissionProgressUpdated") then
	local event = Instance.new("RemoteEvent")
	event.Name = "MissionProgressUpdated"
	event.Parent = RemoteEvents
end
if not RemoteEvents:FindFirstChild("ShowDailyRewardUI") then
	local event = Instance.new("RemoteEvent")
	event.Name = "ShowDailyRewardUI"
	event.Parent = RemoteEvents
end

print(string.format(
	"SharedEventsSetup: Created %d RE, %d RF, %d BE, %d BF",
	createdEvents, createdFunctions, createdBindables, createdBindableFuncs
))
print(string.format(
	"SharedEventsSetup: Total: %d RemoteEvents, %d RemoteFunctions, %d BindableEvents, %d BindableFunctions",
	#RemoteEvents:GetChildren(), #RemoteFunctions:GetChildren(),
	#BindableEvents:GetChildren(), #BindableFunctions:GetChildren()
))
print("SharedEventsSetup: SkillRemotes folder created: " .. tostring(SkillRemotes ~= nil))

