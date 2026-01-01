-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return {} end

-- ValorModule.luau (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ValorModule.luau
-- Script Place: ACT 1: Village

local ValorSystem = {}

local playerPoints = {}

-- Tambahkan ini di atas
local ServerScriptService = game:GetService("ServerScriptService")
local LevelManager = require(ServerScriptService.ModuleScript:WaitForChild("LevelModule"))

function ValorSystem.SetupPlayer(player)
	-- simpan poin internal
	playerPoints[player] = 100000

	if player and player:IsA("Player") then
		local leaderstats = player:FindFirstChild("leaderstats")

		-- Jika folder leaderstats belum ada, buat.
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player
		end

		-- Fungsi helper untuk membuat atau me-reset stat
		local function createOrResetStat(name, value)
			local stat = leaderstats:FindFirstChild(name)
			if not stat then
				stat = Instance.new("IntValue")
				stat.Name = name
				stat.Parent = leaderstats
			end
			stat.Value = value
		end

		-- Buat atau reset semua stats yang diperlukan
		createOrResetStat("Valor", 0)
		createOrResetStat("TotalDamage", 0)
		createOrResetStat("Kills", 0)
		createOrResetStat("Knock", 0)
	end
end

function ValorSystem.RemovePlayer(player)
	playerPoints[player] = nil
	-- bersihkan leaderstats bila ada
	if player and player:FindFirstChild("leaderstats") then
		player.leaderstats:Destroy()
	end
end

function ValorSystem.AddPoints(player, amount)
	-- Auto-initialize if player not set up yet (fallback safety)
	if not playerPoints[player] then
		-- Initialize in background to not block hit detection
		playerPoints[player] = 0 -- Set immediately to prevent re-entry
		task.spawn(function()
			print("[ValorModule] Auto-initializing player:", player.Name)
			ValorSystem.SetupPlayer(player)
		end)
	end
	
	-- Still nil after setup attempt? Something is wrong
	if not playerPoints[player] then 
		warn("[ValorModule] Failed to initialize player: " .. tostring(player.Name))
		return false 
	end

	-- Jika ini adalah pengurangan (pembelian), periksa apakah poin cukup
	if amount < 0 then
		if playerPoints[player] < math.abs(amount) then
			return false -- Poin tidak cukup
		end
	end

	playerPoints[player] += amount

	-- update leaderstats Valor bila ada
	if player and player:FindFirstChild("leaderstats") then
		local valorVal = player.leaderstats:FindFirstChild("Valor")
		if valorVal then
			valorVal.Value = playerPoints[player] or 0
		end
	end

	-- update ke client (UI)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ValorUpdate = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("ValorUpdate")
	if ValorUpdate then
		ValorUpdate:FireClient(player, playerPoints[player])
	end

	return true
end

function ValorSystem.GetPoints(player)
	return playerPoints[player] or 0
end

-- increment kills leaderstat (dipanggil dari ZombieModule saat ada killer)
function ValorSystem.AddKill(player)
	if not player or not player:IsA("Player") then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Kills")
		if v then v.Value = v.Value + 1 end
	end
end

-- increment knock leaderstat (dipanggil saat player knock)
function ValorSystem.AddKnock(player)
	if not player or not player:IsA("Player") then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Knock")
		if v then v.Value = v.Value + 1 end
	end
end

function ValorSystem.AddDamage(player, damageAmount)
	if not player or not player:IsA("Player") then return end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("TotalDamage")
		if v then
			v.Value = v.Value + damageAmount
		end
	end

end

return ValorSystem
