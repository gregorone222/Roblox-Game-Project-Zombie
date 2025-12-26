-- RemoteEventSetup.server.luau
-- Path: ServerScriptService/Script/RemoteEventSetup.server.luau
-- Runs in ALL places to ensure all events/functions exist for unified script sync

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("RemoteEventSetup: Initializing all events for all places...")

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
	-- Weapon System (ACT 1)
	"ShootEvent", "ReloadEvent", "TracerEvent", "TracerBroadcast",
	"MuzzleFlashEvent", "MuzzleFlashBroadcast", "AmmoUpdateEvent",
	"BulletholeEvent", "PlayLocalGunshotSoundEvent", "PlayGunshotSoundEvent",
	"ExplosionEvent",
	
	-- Combat/Damage (ACT 1)
	"DamageDisplayEvent", "KnockEvent", "ReviveEvent", "GameOverEvent",
	"ShieldUpdateEvent", "DebuffStatusEvent", "PingKnockedPlayerEvent",
	
	-- Wave/Game State (ACT 1)
	"WaveUpdateEvent", "WaveCountdownEvent", "MissionCompleteEvent",
	"SpecialWaveEvent", "BossSpawnEvent",
	
	-- Movement (ACT 1)
	"UpdateWalkSpeedModifierEvent", "SprintEvent", "JumpEvent",
	"StaminaUpdate", "LookEvent",
	
	-- Shops (ACT 1)
	"UpgradeUIOpen", "ConfirmUpgrade", "PerkShopEvent", "PerkBuyEvent",
	"ElementShopEvent", "ElementBuyEvent", "RandomWeaponEvent", "BuyRandomWeaponEvent",
	
	-- Points/Currency (Shared & ACT 1)
	"PointsUpdate", "CoinsUpdate", "SetPlayerStats",
	
	-- Perks/Elements (ACT 1)
	"PerkActivatedEvent", "PerkDeactivatedEvent",
	"ElementActivatedEvent", "ElementDeactivatedEvent",
	
	-- Boss VFX (ACT 1)
	"PlayBossSkillEvent", "Boss2GravityLocalPull", "ChromaticRequiemUIEvent",
	"BossHealthUpdateEvent", "BossTimerEvent",
	
	-- Lobby Events
	"GachaEvent", "GachaRollEvent", "GachaResultEvent",
	"StartGameEvent", "JoinRoomEvent", "LeaveRoomEvent", "RoomUpdateEvent",
	"VoteDifficultyEvent", "DialogueEvent", "LeaderboardUpdateEvent",
	"DailyRewardEvent", "SkinEquipEvent", "SkinUpdateEvent",
	
	-- Shop (Lobby)
	"APShopEvent", "APShopBuyEvent", "MPShopEvent", "MPShopBuyEvent",
	"BoosterBuyEvent",
	
	-- Profile/Stats (Shared)
	"ProfileDataEvent", "AchievementEvent", "AchievementUnlockEvent",
	"MissionEvent", "MissionProgressEvent",
	"SkillEvent", "SkillUnlockEvent", "InventoryEvent",
	
	-- Settings (Shared)
	"SettingsUpdateEvent", "AdminEvent",
}

-- === ALL REMOTE FUNCTIONS (Client -> Server with return) ===
local allRemoteFunctions = {
	-- Data
	"GetPlayerData", "GetPlayerStats", "GetLeaderboardData",
	"GetProfileData", "GetInventoryData",
	
	-- Shop
	"GetAPShopItems", "GetMPShopItems", "GetBoosterInventory", "GetGachaInventory",
	"PurchaseSkin", "PurchaseSkinWithAP", "PurchaseGenericItem", "PurchaseGenericItemWithAP",
	"GetGachaConfig", "GetGachaStatus",
	
	-- Game State
	"GetWaveInfo", "GetRoomInfo",
	
	-- Settings
	"GetSettings", "SaveSettings",
	
	-- Perks/Elements (ACT 1)
	"PurchasePerk", "PurchaseElement",
	
	-- Weapons (ACT 1)
	"PurchaseRandomWeapon", "GetRandomWeaponCost",
	"UpgradeWeaponRF", "GetWeaponLevelRF",
	
	-- Missions
	"GetMissionData", "ClaimMissionReward", "RerollMission",
	
	-- Daily Rewards
	"GetDailyRewardInfo", "ClaimDailyReward",
}

-- === ALL BINDABLE EVENTS (Server <-> Server internal) ===
local allBindableEvents = {
	-- Zombie/Combat (ACT 1)
	"ZombieDied", "ReportDamageEvent", "ObjectDamaged",
	
	-- Admin Commands
	"AdminSetWave", "AdminSkipWave", "AdminKillAll",
	
	-- UI Internal
	"StartAutoFireEvent", "StopAutoFireEvent",
	"ToggleAimEvent", "AimStatusChangedEvent",
	"RequestReloadEvent", "RefreshMobileButtons",
	
	-- Lobby
	"ToggleSkillUIEvent", "ToggleProfileUIEvent", "ToggleAchievementUIEvent",
	"OpenLobbyEvent",
}

-- === ALL BINDABLE FUNCTIONS (Server <-> Server with return) ===
local allBindableFunctions = {
	"GetCurrentWave",
	"GetPlayerLoadout",
	"GetZombieCount",
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
	"RemoteEventSetup: Created %d RemoteEvents, %d RemoteFunctions, %d BindableEvents, %d BindableFunctions",
	createdEvents, createdFunctions, createdBindables, createdBindableFuncs
))
print(string.format(
	"RemoteEventSetup: Total: %d RE, %d RF, %d BE, %d BF",
	#RemoteEvents:GetChildren(), #RemoteFunctions:GetChildren(),
	#BindableEvents:GetChildren(), #BindableFunctions:GetChildren()
))

