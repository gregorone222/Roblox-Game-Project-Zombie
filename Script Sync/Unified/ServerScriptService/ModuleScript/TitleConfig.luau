-- TitleConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/TitleConfig.lua
-- Script Place: Lobby & ACT 1: Village
-- Titles diperoleh dari Exchange (AP/MP) dan Gacha

local TitleConfig = {
	-- =============================================================================
	-- RARITY COLORS
	-- =============================================================================
	RarityColors = {
		Common = Color3.fromRGB(180, 180, 180),    -- Abu-abu
		Uncommon = Color3.fromRGB(0, 200, 0),      -- Hijau
		Rare = Color3.fromRGB(0, 150, 255),        -- Biru
		Epic = Color3.fromRGB(150, 0, 200),        -- Ungu
		Legendary = Color3.fromRGB(255, 200, 0)    -- Emas
	},
	
	-- =============================================================================
	-- COMMON TITLES (40% Gacha / Low Exchange Cost)
	-- =============================================================================
	Rookie = {
		DisplayName = "Rookie",
		Rarity = "Common",
		Source = "Exchange",
		Cost = { Currency = "AP", Amount = 100 },
		Description = "Just starting out."
	},
	Newbie = {
		DisplayName = "Newbie",
		Rarity = "Common",
		Source = "Exchange",
		Cost = { Currency = "MP", Amount = 50 },
		Description = "Everyone starts somewhere."
	},
	Trainee = {
		DisplayName = "Trainee",
		Rarity = "Common",
		Source = "Gacha",
		Description = "Learning the ropes."
	},
	
	-- =============================================================================
	-- UNCOMMON TITLES (30% Gacha / Medium Exchange Cost)
	-- =============================================================================
	Survivor = {
		DisplayName = "Survivor",
		Rarity = "Uncommon",
		Source = "Exchange",
		Cost = { Currency = "AP", Amount = 300 },
		Description = "You made it through."
	},
	Fighter = {
		DisplayName = "Fighter",
		Rarity = "Uncommon",
		Source = "Gacha",
		Description = "Never backs down."
	},
	Defender = {
		DisplayName = "Defender",
		Rarity = "Uncommon",
		Source = "Gacha",
		Description = "Protects the team."
	},
	
	-- =============================================================================
	-- RARE TITLES (20% Gacha / High Exchange Cost)
	-- =============================================================================
	Veteran = {
		DisplayName = "Veteran",
		Rarity = "Rare",
		Source = "Exchange",
		Cost = { Currency = "AP", Amount = 750 },
		Description = "Experienced in combat."
	},
	Sharpshooter = {
		DisplayName = "Sharpshooter",
		Rarity = "Rare",
		Source = "Gacha",
		Description = "Never misses."
	},
	Guardian = {
		DisplayName = "Guardian",
		Rarity = "Rare",
		Source = "Gacha",
		Description = "Watches over allies."
	},
	
	-- =============================================================================
	-- EPIC TITLES (8% Gacha / Very High Exchange Cost)
	-- =============================================================================
	EliteOperator = {
		DisplayName = "Elite Operator",
		Rarity = "Epic",
		Source = "Exchange",
		Cost = { Currency = "AP", Amount = 1500 },
		Description = "Top tier survivor."
	},
	Warlord = {
		DisplayName = "Warlord",
		Rarity = "Epic",
		Source = "Gacha",
		Description = "Commands respect."
	},
	Nightmare = {
		DisplayName = "Nightmare",
		Rarity = "Epic",
		Source = "Gacha",
		Description = "Fear of all zombies."
	},
	
	-- =============================================================================
	-- LEGENDARY TITLES (2% Gacha / Premium Exchange)
	-- =============================================================================
	ZombieSlayer = {
		DisplayName = "Zombie Slayer",
		Rarity = "Legendary",
		Source = "Exchange",
		Cost = { Currency = "AP", Amount = 5000 },
		Description = "The ultimate zombie hunter."
	},
	Apocalypse = {
		DisplayName = "Apocalypse",
		Rarity = "Legendary",
		Source = "Gacha",
		Description = "The end of all zombies."
	},
	Legendary = {
		DisplayName = "Legendary",
		Rarity = "Legendary",
		Source = "Gacha",
		Description = "A living legend."
	}
}

-- Helper function untuk mendapatkan warna rarity
function TitleConfig.GetRarityColor(rarity)
	return TitleConfig.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

-- Helper function untuk mendapatkan semua titles by rarity
function TitleConfig.GetTitlesByRarity(rarity)
	local titles = {}
	for titleId, titleData in pairs(TitleConfig) do
		if type(titleData) == "table" and titleData.Rarity == rarity then
			titles[titleId] = titleData
		end
	end
	return titles
end

-- Helper function untuk gacha
function TitleConfig.GetGachaTitles()
	local titles = {}
	for titleId, titleData in pairs(TitleConfig) do
		if type(titleData) == "table" and titleData.Source == "Gacha" then
			titles[titleId] = titleData
		end
	end
	return titles
end

return TitleConfig
