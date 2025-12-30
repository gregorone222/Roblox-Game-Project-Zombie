-- ZombieConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/ZombieConfig.lua
-- Script Place: ACT 1: Village

local ZombieConfig = {}

ZombieConfig.BaseZombie = {
	MaxHealth = 100,
	WalkSpeed = 10,
	AttackDamage = 10,
	AttackCooldown = 1.5,
	IsZombie = true,
	AttackRange = 4  -- Ditambahkan
}

-- Per-type overrides
ZombieConfig.Types = {
	Runner = {
		MaxHealth = 60,
		WalkSpeed = 18,
		AttackDamage = 6,
		AttackCooldown = 1.0,
		Chance = 0.30,
		AttackRange = 4, -- Ditambahkan
		MinWave = 3 -- Ditambahkan: mulai muncul di wave 3
	},
	Shooter = {
		MaxHealth = 120,
		WalkSpeed = 8,
		AttackDamage = 8,
		AttackCooldown = 1.5,
		ProjectileSpeed = 80,
		Acid = {
			PoolDuration = 8,
			DoT_Duration = 5,
			DoT_Tick = 1,
			DoT_DamagePerTick = 5
		},
		Chance = 0.25,
		AttackRange = 4, -- Ditambahkan
		MinWave = 6 -- Ditambahkan: mulai muncul di wave 6
	},
	Tank = {
		MaxHealth = 10000,
		WalkSpeed = 6,
		AttackDamage = 15,
		AttackCooldown = 2.5,
		Chance = 0.90,
		AttackRange = 5, -- Ditambahkan
		MinWave = 1, -- Ditambahkan: mulai muncul di wave 9
		WalkAnimation = "rbxassetid://119252114768657",
		AttackAnimations = {
			"rbxassetid://90804907609507",
			"rbxassetid://90804907609507",
			"rbxassetid://97183708364401",
		},
	},
	Boss = {
		Name = "Plague Titan",
		MaxHealth = 750,
		WalkSpeed = 8,
		AttackDamage = 50, -- Serangan melee standar jika pemain terlalu dekat
		AttackRange = 8,
		SpecialTimeout = 300, -- Timer pemusnahan tetap ada

		-- FASE 1 & 2
		Radiation = {
			Phase1Radius = 15,
			Phase2Radius = 25, -- Aura mengembang di Fase 2
			VerticalHalfHeight = 200,
			DamagePerSecondPct = 0.01,
			Tick = 0.5
		},

		-- FASE 1
		CorrosiveSlam = {
			Cooldown = 15, -- Cooldown sedikit dinaikkan untuk serangan yang lebih kuat
			Damage = 35, -- Damage sedikit dinaikkan
			Radius = 40,
			TelegraphDuration = 2.0, -- Waktu telegraph lebih lama untuk persiapan
			-- Parameter untuk Konsep "Nexus Peledak"
			NexusPointCount = 8, -- Jumlah titik ledakan sekunder
			NexusRadius = 30, -- Jarak titik sekunder dari pusat
			NexusPulseSpeed = 0.7, -- Kecepatan denyut nexus
			WebTravelTime = 1.2, -- Waktu yang dibutuhkan jaring energi untuk menyebar
			SecondaryExplosionDelay = 0.25, -- Jeda antara ledakan utama dan sekunder
			ScorchMarkDuration = 5.0, -- Durasi bekas hangus di tanah
		},
		ToxicLob = {
			Cooldown = 8,
			PuddleDuration = 15,
			PuddleDamagePerTick = 5,
			PuddleTickInterval = 0.5,
			PuddleRadius = 12,
			TelegraphDuration = 1,
		},

		-- TRANSISI
		PhaseTransition = {
			TriggerHPPercent = 0.5,
			RoarDuration = 4,
		},

		-- FASE 2
		VolatileMinions = {
			Cooldown = 25,
			SpawnCount = {2, 3}, -- min, max
			MinionType = "Runner", -- Akan menggunakan stats Runner tapi mungkin dengan HP lebih rendah
			ExplosionRadius = 15,
			ExplosionDamage = 25,
		},
		FissionBarrage = {
			Cooldown = 30, -- Cooldown sedikit lebih cepat
			ProjectileCount = 3, -- Lebih sedikit proyektil tetapi lebih berbahaya
			IntervalBetweenShots = 0.5,
			TelegraphDuration = 0.5,
			ChainDamage = 40, -- Damage langsung yang tinggi
			ChainRadius = 25, -- Radius pencarian awal dari titik tumbukan
			MaxChainTargets = 2, -- Jumlah maksimum target (1 awal + 1 pantulan)
			SecondaryChainRadius = 15, -- Radius pantulan dari target pertama
		},

		ChanceWaveMin = 10,
		ChanceWaveMax = 15,
		ChanceToSpawn = 1
	},
	Boss2 = {
		Name = "The Hive Mother",
		MaxHealth = 100000,
		WalkSpeed = 6, -- Slower due to size
		AttackDamage = 40,
		AttackRange = 30,
		SpecialTimeout = 300,

		-- FASE 1
		AcidSpit = {
			Cooldown = 10,
			Damage = 25,
			Speed = 60,
			AoE_Radius = 12,
			DoT_Duration = 5,
			DoT_Damage = 5
		},
		SpawnLarva = {
			Cooldown = 20,
			Count = {3, 5},
			MinionType = "Runner", -- Fast "Larva" variant
			HealthMultiplier = 0.5 -- Weaker than normal runners
		},

		-- TRANSISI
		Metamorphosis = {
			TriggerHPPercent = 0.5,
			Duration = 5, -- Scream / Burst Animation
			HealAmount = 5000, -- Small regeneration
		},

		-- FASE 2
		ToxicCloud = {
			Cooldown = 25,
			Duration = 15,
			Radius = 40, -- Massive area denial
			DamagePerSecond = 15
		},
		BroodFrenzy = {
			Cooldown = 35,
			Duration = 10,
			SpeedBoost = 1.5, -- Minions get faster
			SpawnRateMultiplier = 2
		},

		ChanceWaveMin = 30,
		ChanceWaveMax = 35,
		ChanceToSpawn = 1,
	},
	Boss3 = {
		Name = "The Blighted Alchemist",
		MaxHealth = 1250,
		WalkSpeed = 8,
		AttackDamage = 55,
		AttackRange = 25,
		SpecialTimeout = 300,

		GuaranteedSpawn = {
			GameMode = "Story",
			Wave = 50,
		},

		-- Formulas
		Movements = {
			-- Formula 1: Volatile Formula
			VolatileFormula = {
				SyringeVolley = {
					Cooldown = 8,
					ProjectileSpeed = 60,
					ProjectileCount = 15,
					Interval = 0.2,
					Damage = 10,
				},
				UnstableVials = {
					Cooldown = 12,
					PillarCount = 5,
					Radius = 8,
					Damage = 20,
					TelegraphDuration = 1.5,
				},
			},
			-- Formula 2: Debilitating Formula
			DebilitatingFormula = {
				CausticCatalyst = {
					Cooldown = 10,
					BlastRadius = 15,
					BlastDamage = 10,
					PuddleDuration = 10,
					PuddleDamagePerTick = 5,
					PuddleTickInterval = 0.5,
					TelegraphDuration = 1.5,
				},
				SymbioticLink = {
					Cooldown = 18,
					Duration = 12,
					MaxDistance = 40,
					DamagePerSecond = 10,
				},
			},
			-- Formula 3: Terminal Formula
			TerminalFormula = {
				MutatedSpecimens = {
					Cooldown = 25,
					EchoHealth = 5000,
					MaxEchoes = 3, -- 1 spesimen per 2 pemain, maks 3
				},
				PlagueBomb = {
					Cooldown = 40,
					ChargeDuration = 5,
					Damage = 10,
				},
			},
		},
	},
}

return ZombieConfig
