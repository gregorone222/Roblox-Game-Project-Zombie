-- SettingsManager.lua (Script)
-- Path: ServerScriptService/Script/SettingsManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local UpdateSettingsEvent = ReplicatedStorage.RemoteEvents:WaitForChild("UpdateSettingsEvent")
local LoadSettingsEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LoadSettingsEvent")

-- Fungsi validasi mendalam untuk UDim2 yang disimpan sebagai tabel
-- Fungsi validasi mendalam untuk UDim2 yang disimpan sebagai tabel atau UserData
local function validateUDim2(udimData)
	-- Jika dikirim sebagai UserData (UDim2 asli)
	if typeof(udimData) == "UDim2" then
		return true
	end
	-- Jika dikirim sebagai tabel (format DataStore)
	if type(udimData) == "table" then
		if type(udimData.X) ~= "table" or type(udimData.Y) ~= "table" then return false end
		if type(udimData.X.Scale) ~= "number" or type(udimData.X.Offset) ~= "number" then return false end
		if type(udimData.Y.Scale) ~= "number" or type(udimData.Y.Offset) ~= "number" then return false end
		return true
	end
	return false
end

-- Fungsi untuk memvalidasi data pengaturan yang diterima dari klien
local function validateSettings(settings)
	if type(settings) ~= "table" then return nil end
	if type(settings.sound) ~= "table" then return nil, "Invalid sound table" end
	local sound = settings.sound
	if type(sound.enabled) ~= "boolean" then return nil, "Invalid sound.enabled" end
	if type(sound.sfxVolume) ~= "number" or not (sound.sfxVolume >= 0 and sound.sfxVolume <= 1) then return nil, "Invalid sfxVolume" end
	if settings.controls then
		if type(settings.controls) ~= "table" then return nil, "Invalid controls table" end
		local controls = settings.controls
		if controls.fireControlType and not (controls.fireControlType == "FireButton" or controls.fireControlType == "DoubleTap") then
			return nil, "Invalid fireControlType"
		end
	end
	if type(settings.hud) ~= "table" then return nil, "Invalid hud table" end
	for _, data in pairs(settings.hud) do
		if type(data) ~= "table" or not validateUDim2(data.pos) or not validateUDim2(data.size) then
			return nil, "Invalid hud UDim2 data"
		end
	end

	-- Validasi gameplay (opsional, tapi jika ada, harus benar)
	if settings.gameplay then
		if type(settings.gameplay) ~= "table" then return nil, "Invalid gameplay table" end
		if settings.gameplay.shadows ~= nil and type(settings.gameplay.shadows) ~= "boolean" then return nil, "Invalid gameplay.shadows" end
		if settings.gameplay.tracers ~= nil and type(settings.gameplay.tracers) ~= "boolean" then return nil, "Invalid gameplay.tracers" end
	end

	return settings
end

-- Fungsi untuk mengubah tabel kembali menjadi UDim2
local function deserializeUDim2(tbl)
	if typeof(tbl) == "UDim2" then return tbl end
	return UDim2.new(tbl.X.Scale, tbl.X.Offset, tbl.Y.Scale, tbl.Y.Offset)
end

-- Fungsi untuk mengubah UDim2 menjadi format tabel yang aman untuk DataStore
local function serializeUDim2(udim)
	if typeof(udim) == "UDim2" then
		return {
			X = { Scale = udim.X.Scale, Offset = udim.X.Offset },
			Y = { Scale = udim.Y.Scale, Offset = udim.Y.Offset }
		}
	elseif type(udim) == "table" then
		-- Sudah dalam bentuk tabel, kembalikan saja
		return udim
	end
	return nil
end

-- Saat klien mengirim pembaruan pengaturan
UpdateSettingsEvent.OnServerEvent:Connect(function(player, clientSettings)
	local validatedSettings, reason = validateSettings(clientSettings)
	if not validatedSettings then
		warn("Pembaruan pengaturan ditolak untuk " .. player.Name .. ": " .. (reason or "Unknown"))
		return
	end

	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then
		warn("Tidak dapat menyimpan pengaturan karena data pemain belum dimuat untuk " .. player.Name)
		return
	end

	-- Pastikan tabel pengaturan ada
	if not playerData.data.settings then
		local defaultData = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.settings = {}
		for k, v in pairs(defaultData.settings) do playerData.data.settings[k] = v end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	playerData.data.settings.sound = validatedSettings.sound

	-- Konversi UDim2 ke tabel sebelum disimpan
	local hudToSave = {}
	for k, v in pairs(validatedSettings.hud) do
		hudToSave[k] = {
			pos = serializeUDim2(v.pos),
			size = serializeUDim2(v.size)
		}
	end
	playerData.data.settings.hud = hudToSave

	playerData.data.settings.controls = validatedSettings.controls or { fireControlType = "FireButton" }

	-- Pastikan gameplay settings di-merge dengan benar, bukan ditimpa sepenuhnya jika ada field baru
	local defaultGameplay = { shadows = true, tracers = true }
	if not playerData.data.settings.gameplay then
		playerData.data.settings.gameplay = defaultGameplay
	end

	if validatedSettings.gameplay then
		for k, v in pairs(validatedSettings.gameplay) do
			playerData.data.settings.gameplay[k] = v
		end
	end

	DataStoreManager:UpdatePlayerData(player, playerData.data)
	print("Pengaturan berhasil disimpan untuk " .. player.Name)
end)

-- Fungsi untuk mengirim pengaturan ke pemain
local function onPlayerAdded(player)
	task.spawn(function()
		local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
		local settingsToSend

		if playerData and playerData.data and playerData.data.settings then
			local settings = playerData.data.settings
			settingsToSend = {
				sound = settings.sound,
				controls = settings.controls or { fireControlType = "FireButton" },
				gameplay = settings.gameplay or { shadows = true, tracers = true },
				hud = {}
			}
			if settings.hud then
				for name, data in pairs(settings.hud) do
					settingsToSend.hud[name] = {
						pos = deserializeUDim2(data.pos),
						size = deserializeUDim2(data.size)
					}
				end
			end
			print("Pengaturan yang ada telah dikirim ke " .. player.Name)
		else
			-- Gunakan default dari DataStoreManager jika tidak ada
			local defaultData = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
			settingsToSend = defaultData.settings
			print("Tidak ada data pengaturan custom untuk " .. player.Name .. ". Mengirim default.")
		end
		LoadSettingsEvent:FireClient(player, settingsToSend)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
