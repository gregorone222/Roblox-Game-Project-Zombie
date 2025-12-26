-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- GachaManager.lua (Script)
-- Path: ServerScriptService/Script/GachaManager.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Memuat modul yang diperlukan
local GachaModule = require(ServerScriptService.ModuleScript:WaitForChild("GachaModule"))
local GachaConfig = require(ServerScriptService.ModuleScript:WaitForChild("GachaConfig"))

-- Mencari RemoteFunction untuk mengambil konfigurasi
local getConfigFuncName = "GetGachaConfig"
local GetGachaConfig = ReplicatedStorage:WaitForChild("RemoteFunctions"):FindFirstChild(getConfigFuncName)
if not GetGachaConfig then
	GetGachaConfig = Instance.new("RemoteFunction", ReplicatedStorage:WaitForChild("RemoteFunctions"))
	GetGachaConfig.Name = getConfigFuncName
end

-- Atur callback untuk RemoteFunction
GetGachaConfig.OnServerInvoke = function(player)
	-- Hanya kirim data yang aman untuk dilihat klien
	return GachaConfig.RARITY_CHANCES
end

-- Mencari RemoteEvent untuk komunikasi gacha
local gachaEventName = "GachaRollEvent"
local GachaRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild(gachaEventName)
if not GachaRollEvent then
	GachaRollEvent = Instance.new("RemoteEvent", ReplicatedStorage:WaitForChild("RemoteEvents"))
	GachaRollEvent.Name = gachaEventName
end

-- Fungsi ini akan dieksekusi ketika client mengirim permintaan roll dari UI
-- [MODIFIED] Fungsi ini sekarang menerima 'weaponName' dari klien
local function onGachaRollRequested(player, weaponName)
	-- Panggil fungsi Roll dari GachaModule secara aman menggunakan pcall, teruskan weaponName
	local success, resultOrError = pcall(GachaModule.Roll, player, weaponName)

	if success then
		GachaRollEvent:FireClient(player, resultOrError)
	else
		warn("GachaManager Error: Terjadi error saat menjalankan GachaModule.Roll - " .. tostring(resultOrError))
		local errorResult = {
			Success = false,
			Message = "Terjadi kesalahan internal pada server. Silakan coba lagi nanti."
		}
		GachaRollEvent:FireClient(player, errorResult)
	end
end

GachaRollEvent.OnServerEvent:Connect(onGachaRollRequested)

-- Endpoint untuk Multi-Roll
local gachaMultiRollEventName = "GachaMultiRollEvent"
local GachaMultiRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild(gachaMultiRollEventName)
if not GachaMultiRollEvent then
	GachaMultiRollEvent = Instance.new("RemoteEvent", ReplicatedStorage:WaitForChild("RemoteEvents"))
	GachaMultiRollEvent.Name = gachaMultiRollEventName
end

-- [MODIFIED] Fungsi ini sekarang menerima 'weaponName' dari klien
local function onGachaMultiRollRequested(player, weaponName)
	-- Panggil fungsi RollMultiple dari GachaModule, teruskan weaponName
	local success, resultOrError = pcall(GachaModule.RollMultiple, player, weaponName)
	if success then
		GachaMultiRollEvent:FireClient(player, resultOrError)
	else
		warn("GachaManager Error: Terjadi error saat menjalankan GachaModule.RollMultiple - " .. tostring(resultOrError))
		local errorResult = {
			Success = false,
			Message = "Terjadi kesalahan internal pada server. Silakan coba lagi nanti."
		}
		GachaMultiRollEvent:FireClient(player, errorResult)
	end
end

GachaMultiRollEvent.OnServerEvent:Connect(onGachaMultiRollRequested)

-- Endpoint untuk Free Daily Roll
local gachaFreeRollEventName = "GachaFreeRollEvent"
local GachaFreeRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild(gachaFreeRollEventName)
if not GachaFreeRollEvent then
	GachaFreeRollEvent = Instance.new("RemoteEvent", ReplicatedStorage:WaitForChild("RemoteEvents"))
	GachaFreeRollEvent.Name = gachaFreeRollEventName
end

-- [MODIFIED] Fungsi ini sekarang menerima 'weaponName' dari klien
local function onGachaFreeRollRequested(player, weaponName)
	-- Panggil fungsi RollFreeDaily dari GachaModule, teruskan weaponName
	local success, resultOrError = pcall(GachaModule.RollFreeDaily, player, weaponName)
	if success then
		-- Hasil dari RollFreeDaily memiliki format yang sama dengan Roll tunggal
		GachaRollEvent:FireClient(player, resultOrError)
	else
		warn("GachaManager Error: Terjadi error saat menjalankan GachaModule.RollFreeDaily - " .. tostring(resultOrError))
		local errorResult = {
			Success = false,
			Message = "Terjadi kesalahan internal pada server saat mencoba roll gratis."
		}
		GachaRollEvent:FireClient(player, errorResult)
	end
end

GachaFreeRollEvent.OnServerEvent:Connect(onGachaFreeRollRequested)

-- RemoteFunction untuk mendapatkan status gacha pemain
local getGachaStatusFuncName = "GetGachaStatus"
local GetGachaStatus = ReplicatedStorage:WaitForChild("RemoteFunctions"):FindFirstChild(getGachaStatusFuncName)
if not GetGachaStatus then
	GetGachaStatus = Instance.new("RemoteFunction", ReplicatedStorage:WaitForChild("RemoteFunctions"))
	GetGachaStatus.Name = getGachaStatusFuncName
end

GetGachaStatus.OnServerInvoke = function(player)
	local playerData = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule")).GetData(player)
	if playerData then
		return {
			Coins = playerData.Coins,
			PityCount = playerData.PityCount,
			LastFreeGachaClaimUTC = playerData.LastFreeGachaClaimUTC,
			PityThreshold = GachaConfig.PITY_THRESHOLD
		}
	end
	return nil
end

-- Hapus koneksi ke ProximityPrompt dari sisi server
-- Kode di bawah ini tidak lagi diperlukan dan telah dihapus.
-- local gachaShopPart = Workspace:WaitForChild("GachaShopSkin")
-- ... proximityPrompt.Triggered:Connect(...)

