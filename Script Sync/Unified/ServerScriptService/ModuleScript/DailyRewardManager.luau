-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return {} end

-- DailyRewardManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/DailyRewardManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DailyRewardConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("DailyRewardConfig"))
local CoinsModule = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local BoosterModule = require(ServerScriptService.ModuleScript:WaitForChild("BoosterModule"))
local SkinManager = require(ServerScriptService.ModuleScript:WaitForChild("SkinManager"))
local StatsModule = require(ServerScriptService.ModuleScript:WaitForChild("StatsModule"))

local DailyRewardManager = {}
local ONE_DAY = 86400

function DailyRewardManager:GetPlayerState(player)
	-- Validasi aman
	if not StatsModule then return nil end
	local playerData = StatsModule.GetData(player)
	if not playerData then return nil end

	local lastClaim = playerData.DailyRewardLastClaim or 0
	local currentDay = playerData.DailyRewardCurrentDay or 1

	-- Reset jika > 3 hari tidak login
	if lastClaim > 0 and (os.time() - lastClaim) > (3 * ONE_DAY) then
		currentDay = 1
		playerData.DailyRewardCurrentDay = 1
		playerData.DailyRewardLastClaim = 0
		lastClaim = 0
		StatsModule.SaveData(player, playerData)
	end

	-- Cek apakah hari ini sudah klaim (berdasarkan hari kalender UTC/lokal sederhana)
	local canClaim = false
	local lastClaimDay = math.floor(lastClaim / ONE_DAY)
	local currentOsDay = math.floor(os.time() / ONE_DAY)

	if lastClaim == 0 or currentOsDay > lastClaimDay then
		canClaim = true
	end

	return { CurrentDay = currentDay, CanClaim = canClaim }
end

function DailyRewardManager:ClaimReward(player)
	local state = self:GetPlayerState(player)
	if not state or not state.CanClaim then return { Success = false, Reason = "Not eligible" } end

	local reward = DailyRewardConfig.Rewards[state.CurrentDay]
	if not reward then return { Success = false, Reason = "Config Error" } end

	-- Berikan Hadiah
	if reward.Type == "Mystery" then
		local pool = DailyRewardConfig.MysteryRewards
		reward = pool[math.random(1, #pool)]
	end

	if reward.Type == "Coins" then CoinsModule.AddCoins(player, reward.Value)
	elseif reward.Type == "Booster" then BoosterModule.AddBooster(player, reward.Value, 1)
	elseif reward.Type == "Skin" then SkinManager.GiveRandomSkin(player) end

	-- Simpan Data
	local playerData = StatsModule.GetData(player)
	local nextDay = state.CurrentDay + 1
	if nextDay > #DailyRewardConfig.Rewards then nextDay = 1 end

	playerData.DailyRewardLastClaim = os.time()
	playerData.DailyRewardCurrentDay = nextDay
	StatsModule.SaveData(player, playerData)

	return { Success = true, ClaimedReward = reward, NextDay = nextDay }
end

return DailyRewardManager