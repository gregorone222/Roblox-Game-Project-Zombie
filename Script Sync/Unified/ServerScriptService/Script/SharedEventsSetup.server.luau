-- SharedEventsSetup.server.luau
-- Path: ServerScriptService/Script/SharedEventsSetup.server.luau
-- Runs in ALL places to ensure all events/functions exist for unified script sync

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("SharedEventsSetup: Initializing all events for all places...")

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

-- === ALL REMOTE EVENTS (Client <-> Server) ===
local allRemoteEvents = {
	-- ========== WEAPON SYSTEM (ACT 1) ==========
	"ShootEvent", "ReloadEvent", "AmmoUpdateEvent",
	"TracerEvent", "TracerBroadcast",
	"MuzzleFlashEvent", "MuzzleFlashBroadcast",
	"BulletholeEvent", "HitmarkerEvent",
	"PlayLocalGunshotSoundEvent", "PlayGunshotSoundEvent",
	"ExplosionEvent",
	
	-- ========== COMBAT/DAMAGE (ACT 1) ==========
	"DamageDisplayEvent", "KnockEvent", "ReviveEvent", "GameOverEvent",
	"ShieldUpdateEvent", "DebuffStatusEvent", "PingKnockedPlayerEvent",
	"DamageFlashEvent",
	
	-- ========== WAVE/GAME STATE (ACT 1) ==========
	"WaveUpdateEvent", "WaveCountdownEvent", "MissionCompleteEvent",
	"SpecialWaveEvent", "SpecialWaveAlertEvent",
	"BossSpawnEvent", "BossHealthUpdateEvent", "BossTimerEvent",
	
	-- ========== MOVEMENT (ACT 1) ==========
	"UpdateWalkSpeedModifierEvent", "SprintEvent", "JumpEvent",
	"StaminaUpdate", "LookEvent",
	
	-- ========== SHOPS (ACT 1) ==========
	"UpgradeUIOpen", "ConfirmUpgrade",
	"PerkShopEvent", "PerkBuyEvent",
	"ElementShopEvent", "ElementBuyEvent",
	"RandomWeaponEvent", "BuyRandomWeaponEvent",
	"OpenReplaceUI", "ReplaceChoice",
	
	-- ========== POINTS/CURRENCY (Shared) ==========
	"PointsUpdate", "CoinsUpdate", "SetPlayerStats",
	
	-- ========== PERKS/ELEMENTS (ACT 1) ==========
	"PerkActivatedEvent", "PerkDeactivatedEvent",
	"PerkEquippedEvent", "PerkDisplayUpdate",
	"ElementActivatedEvent", "ElementDeactivatedEvent",
	"ElementEquippedEvent", "ElementDisplayUpdate",
	
	-- ========== BOSS VFX (ACT 1) ==========
	"PlayBossSkillEvent", "Boss2GravityLocalPull", "ChromaticRequiemUIEvent",
	
	-- ========== LOBBY EVENTS ==========
	"GachaEvent", "GachaRollEvent", "GachaResultEvent",
	"StartGameEvent", "JoinRoomEvent", "LeaveRoomEvent", "RoomUpdateEvent",
	"VoteDifficultyEvent", "DialogueEvent", "LeaderboardUpdateEvent",
	"DailyRewardEvent", "ClaimDailyRewardEvent",
	"SkinEquipEvent", "SkinUpdateEvent",
	
	-- ========== SHOP (LOBBY) ==========
	"APShopEvent", "APShopBuyEvent",
	"MPShopEvent", "MPShopBuyEvent",
	"BoosterBuyEvent",
	
	-- ========== PROFILE/STATS (Shared) ==========
	"ProfileDataEvent", "AchievementEvent", "AchievementUnlockEvent",
	"MissionEvent", "MissionProgressEvent",
	"SkillEvent", "SkillUnlockEvent", "InventoryEvent",
	
	-- ========== SETTINGS (Shared) ==========
	"SettingsUpdateEvent", "UpdateSettingsEvent", "LoadSettingsEvent",
	"AdminEvent",
	
	-- ========== GLOBAL MISSION ==========
	"GlobalMissionUpdate", "GlobalMissionProgress",
}

-- === ALL REMOTE FUNCTIONS (Client -> Server with return) ===
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
	
	-- ========== PERKS/ELEMENTS (ACT 1) ==========
	"PurchasePerk", "GetOwnedPerks",
	"PurchaseElement", "GetOwnedElements",
	
	-- ========== WEAPONS (ACT 1) ==========
	"PurchaseRandomWeapon", "GetRandomWeaponCost",
	"UpgradeWeaponRF", "GetWeaponLevelRF",
	
	-- ========== MISSIONS ==========
	"GetMissionData", "ClaimMissionReward", "RerollMission",
	
	-- ========== DAILY REWARDS ==========
	"GetDailyRewardInfo", "ClaimDailyReward",
	
	-- ========== BOOSTERS ==========
	"GetActiveBooster", "ActivateBooster",
	
	-- ========== SKILLS ==========
	"GetSkillData", "UnlockSkill",
	
	-- ========== ACHIEVEMENTS ==========
	"GetAchievementData", "ClaimAchievementReward",
	
	-- ========== GLOBAL MISSION ==========
	"GetGlobalMissionData", "ContributeGlobalMission",
}

-- === ALL BINDABLE EVENTS (Server <-> Server internal) ===
local allBindableEvents = {
	-- ========== ZOMBIE/COMBAT (ACT 1) ==========
	"ZombieDied", "ReportDamageEvent", "ObjectDamaged",
	
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

-- === ALL BINDABLE FUNCTIONS (Server <-> Server with return) ===
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

print(string.format(
	"SharedEventsSetup: Created %d RE, %d RF, %d BE, %d BF",
	createdEvents, createdFunctions, createdBindables, createdBindableFuncs
))
print(string.format(
	"SharedEventsSetup: Total: %d RemoteEvents, %d RemoteFunctions, %d BindableEvents, %d BindableFunctions",
	#RemoteEvents:GetChildren(), #RemoteFunctions:GetChildren(),
	#BindableEvents:GetChildren(), #BindableFunctions:GetChildren()
))
