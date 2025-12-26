-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return {} end

-- GameStatus.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GameStatus.lua
-- Script Place: ACT 1: Village

local GameStatus = {}

local currentStatus = {
	Difficulty = "Easy" -- Nilai default
}

-- Fungsi untuk mengatur status permainan
function GameStatus:SetDifficulty(difficulty)
	if difficulty then
		print("[GameStatus] Tingkat kesulitan diatur ke: " .. difficulty)
		currentStatus.Difficulty = difficulty
	else
		warn("[GameStatus] Usaha untuk mengatur tingkat kesulitan dengan nilai nil.")
	end
end

-- Fungsi untuk mendapatkan status permainan saat ini
function GameStatus:GetDifficulty()
	return currentStatus.Difficulty
end

return GameStatus