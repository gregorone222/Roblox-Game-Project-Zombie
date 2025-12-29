-- WeaponModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/WeaponModule.lua
-- Script Place: Lobby, ACT 1: Village

local WeaponModule = {}

WeaponModule.Weapons = {
	["M1911"] = {
		DisplayName = "M1911",
		Category = "Pistol",
		Damage = 28,
		HeadshotMultiplier = 2,
		MaxAmmo = 7,
		ReserveAmmo = 35,
		ReloadTime = 2,
		FireRate = 0.35,
		ADSFoV = 55,
		ADS_WalkSpeed = 8,
		Spread = 0.06,
		ADS_Spread = 0.015,
		Recoil = 0.6,
		Use_Skin = "Default Skin",
		TransitionTime = 0.15,
		ADS_BlendTimeVM = 0.2,
		-- ViewmodelPosition and ViewmodelRotation are now PER-ANIMATION (see Animations below)
		Sounds = {
			Fire = "Weapons.Pistol.Fire",
			Reload = "Weapons.Pistol.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://88770091398413",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://110673281003404",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://96179279485775",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 150,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 6,
			AmmoPerLevel = 3,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://95980085824892",
				TextureId = "rbxassetid://129377282984588",
				ADS_Position = Vector3.new(0.15, -0.37, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.15, -0.37, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["AK-47"] = {
		DisplayName = "AK-47",
		Category = "Assault Rifle",
		Damage = 35,
		HeadshotMultiplier = 2,
		MaxAmmo = 30,
		ReserveAmmo = 150,
		ReloadTime = 2.5,
		FireRate = 0.1,
		ADSFoV = 60,
		ADS_WalkSpeed = 10,
		Spread = 0.1,
		ADS_Spread = 0.02,
		Recoil = 2,
		Use_Skin = "Default Skin",
		TransitionTime = 0.2,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -0.8, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Rifle.Fire",
			Reload = "Weapons.Rifle.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://100826748354431",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://72920768054653",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://108327320146582",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 150,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 6,
			AmmoPerLevel = 5,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://127356815511032",
				TextureId = "rbxassetid://103157484998651",
				ADS_Position = Vector3.new(0.52, -0.36, -1.1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.52, -0.36, -1.1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.5,
		VisualRecoilRecovery = 15
	},
	["P90"] = {
		DisplayName = "P90",
		Category = "SMG",
		Damage = 22,
		HeadshotMultiplier = 2,
		MaxAmmo = 50,
		ReserveAmmo = 250,
		ReloadTime = 4,
		FireRate = 0.08,
		ADSFoV = 55,
		ADS_WalkSpeed = 9,
		Spread = 0.12,
		ADS_Spread = 0.03,
		Recoil = 1.5,
		Use_Skin = "Default Skin",
		TransitionTime = 0.18,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.3, -0.6, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.SMG.Fire",
			Reload = "Weapons.SMG.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://97043795469878",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://72508031899093",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://133396772482448",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 150,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 6,
			AmmoPerLevel = 8,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://90872134528837",
				TextureId = "rbxassetid://114550055405090",
				ADS_Position = Vector3.new(0.3, -0.46, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.3, -0.46, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["M590A1"] = {
		DisplayName = "M590A1",
		Category = "Shotgun",
		Damage = 10,
		HeadshotMultiplier = 1.5,
		MaxAmmo = 8,
		ReserveAmmo = 40,
		ReloadTime = 2.5,
		FireRate = 0.9,
		ADSFoV = 40,
		ADS_WalkSpeed = 6,
		Spread = 0.35,
		ADS_Spread = 0.15,
		Recoil = 4,
		Pellets = 9,
		Use_Skin = "Default Skin",
		TransitionTime = 0.25,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.6, -0.8, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Shotgun.Fire",
			Reload = "Weapons.Shotgun.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://87200989978857",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://82244417276650",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://109872961182726",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 150,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 6,
			AmmoPerLevel = 2,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://100700942206647",
				TextureId = "rbxassetid://123834941901194",
				ADS_Position = Vector3.new(0.5, -0.31, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.5, -0.25, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["L115A1"] = {
		DisplayName = "L115A1",
		Category = "Sniper",
		Damage = 95,
		HeadshotMultiplier = 3,
		MaxAmmo = 5,
		ReserveAmmo = 25,
		ReloadTime = 5,
		FireRate = 1.5,
		ADSFoV = 18,
		ADS_WalkSpeed = 4,
		Spread = 0.005,
		ADS_Spread = 0.001,
		Recoil = 6,
		Use_Skin = "Default Skin",
		TransitionTime = 0.3,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.6, -0.3, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Sniper.Fire",
			Reload = "Weapons.Sniper.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://121902228649616",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://135548977187126",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://80982085891352",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 150,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 6,
			AmmoPerLevel = 1,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://139461791487283",
				TextureId = "rbxassetid://126830477553977",
				ADS_Position = Vector3.new(0.15, 10, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.15, 10, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = false,
		ShowCrosshairADS = true,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["Desert-Eagle"] = {
		DisplayName = "Desert-Eagle",
		Category = "Pistol",
		Damage = 45,
		HeadshotMultiplier = 2.5,
		MaxAmmo = 7,
		ReserveAmmo = 28,
		ReloadTime = 2.2,
		FireRate = 0.4,
		ADSFoV = 50,
		ADS_WalkSpeed = 8,
		Spread = 0.05,
		ADS_Spread = 0.012,
		Recoil = 1.2,
		Use_Skin = "Default Skin",
		TransitionTime = 0.15,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.2, -0.4, -2.3),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Pistol.Fire",
			Reload = "Weapons.Pistol.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://132391095441661",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://96400779263437",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://124831631791034",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 200,
			CostMultiplier = 1.6,
			CostExpo = 1.3,
			DamagePerLevel = 8,
			AmmoPerLevel = 3,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://82415287072746",
				TextureId = "rbxassetid://84573716248615",
				ADS_Position = Vector3.new(0.15, -0.33, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.15, -0.35, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["Glock-19"] = {
		DisplayName = "Glock-19",
		Category = "Pistol",
		Damage = 25,
		HeadshotMultiplier = 2,
		MaxAmmo = 15,
		ReserveAmmo = 60,
		ReloadTime = 1.8,
		FireRate = 0.2,
		ADSFoV = 55,
		ADS_WalkSpeed = 9,
		Spread = 0.04,
		ADS_Spread = 0.01,
		Recoil = 0.4,
		Use_Skin = "Default Skin",
		TransitionTime = 0.12,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.4, -0.5, -2.3),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Pistol.Fire",
			Reload = "Weapons.Pistol.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://83859349242317",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://131461562310948",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://103789439088861",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 120,
			CostMultiplier = 1.4,
			CostExpo = 1.2,
			DamagePerLevel = 4,
			AmmoPerLevel = 3,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://70919476762405",
				TextureId = "rbxassetid://92972606271000",
				ADS_Position = Vector3.new(0.15, -0.39, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.15, -0.37, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["MP5"] = {
		DisplayName = "MP5",
		Category = "SMG",
		Damage = 20,
		HeadshotMultiplier = 2,
		MaxAmmo = 30,
		ReserveAmmo = 120,
		ReloadTime = 2.3,
		FireRate = 0.07,
		ADSFoV = 55,
		ADS_WalkSpeed = 10,
		Spread = 0.08,
		ADS_Spread = 0.02,
		Recoil = 1.2,
		Use_Skin = "Default Skin",
		TransitionTime = 0.18,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.6, -0.7, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.SMG.Fire",
			Reload = "Weapons.SMG.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://99254398017062",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://125098463297491",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://116818708658201",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 180,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 5,
			AmmoPerLevel = 8,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://123060009038847",
				TextureId = "rbxassetid://130904027801129",
				ADS_Position = Vector3.new(0.3, -0.49, -1.3),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.3, -0.52, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["Kriss-Vector"] = {
		DisplayName = "KRISS Vector",
		Category = "SMG",
		Damage = 24,
		HeadshotMultiplier = 2,
		MaxAmmo = 25,
		ReserveAmmo = 125,
		ReloadTime = 2.0,
		FireRate = 0.045,
		ADSFoV = 55,
		ADS_WalkSpeed = 10,
		Spread = 0.07,
		ADS_Spread = 0.018,
		Recoil = 0.8,
		Use_Skin = "Default Skin",
		TransitionTime = 0.14,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -0.6, -2.4),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.SMG.Fire",
			Reload = "Weapons.SMG.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://86311697352161",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://100200035224935",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://77507852957617",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 180,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 5,
			AmmoPerLevel = 6,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://119889303585458",
				TextureId = "rbxassetid://80067937011617",
				ADS_Position = Vector3.new(0.3, -0.46, -0.8),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.3, -0.46, -0.8),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["SCAR"] = {
		DisplayName = "SCAR",
		Category = "Assault Rifle",
		Damage = 38,
		HeadshotMultiplier = 2,
		MaxAmmo = 30,
		ReserveAmmo = 150,
		ReloadTime = 2.6,
		FireRate = 0.09,
		ADSFoV = 58,
		ADS_WalkSpeed = 9,
		Spread = 0.09,
		ADS_Spread = 0.018,
		Recoil = 1.8,
		Use_Skin = "Default Skin",
		TransitionTime = 0.2,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -1, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Rifle.Fire",
			Reload = "Weapons.Rifle.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://126126312842045",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://117091450039805",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://92487321840470",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 220,
			CostMultiplier = 1.6,
			CostExpo = 1.3,
			DamagePerLevel = 7,
			AmmoPerLevel = 5,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://116998703791477",
				TextureId = "rbxassetid://128991985008020",
				ADS_Position = Vector3.new(0.5, -0.64, -1.6),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.5, -0.75, -1.4),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["M4A1"] = {
		DisplayName = "M4A1",
		Category = "Assault Rifle",
		Damage = 32,
		HeadshotMultiplier = 2,
		MaxAmmo = 30,
		ReserveAmmo = 150,
		ReloadTime = 2.4,
		FireRate = 0.08,
		ADSFoV = 60,
		ADS_WalkSpeed = 10,
		Spread = 0.1,
		ADS_Spread = 0.02,
		Recoil = 1.5,
		Use_Skin = "Default Skin",
		TransitionTime = 0.18,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -0.7, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Rifle.Fire",
			Reload = "Weapons.Rifle.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://87771978994359",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://73724217767508",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://113162933415719",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 200,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 6,
			AmmoPerLevel = 5,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://132164890297150",
				TextureId = "rbxassetid://77998402405594",
				ADS_Position = Vector3.new(0.5, -0.5, -1.1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.5, -0.5, -1.1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["Benelli-M4"] = {
		DisplayName = "Benelli M4",
		Category = "Shotgun",
		Damage = 11,
		HeadshotMultiplier = 1.5,
		MaxAmmo = 7,
		ReserveAmmo = 35,
		ReloadTime = 2.2,
		FireRate = 0.4,
		ADSFoV = 42,
		ADS_WalkSpeed = 6,
		Spread = 0.32,
		ADS_Spread = 0.16,
		Recoil = 3.5,
		Pellets = 8,
		Use_Skin = "Default Skin",
		TransitionTime = 0.24,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.6, -0.8, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Shotgun.Fire",
			Reload = "Weapons.Shotgun.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://128166010748207",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://77677218044009",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://97662484045737",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 240,
			CostMultiplier = 1.6,
			CostExpo = 1.3,
			DamagePerLevel = 5,
			AmmoPerLevel = 2,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://137873691911712",
				TextureId = "rbxassetid://90422663068381",
				ADS_Position = Vector3.new(0.5, -0.46, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.5, -0.46, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["Remington-870"] = {
		DisplayName = "Remington 870",
		Category = "Shotgun",
		Damage = 13,
		HeadshotMultiplier = 1.5,
		MaxAmmo = 6,
		ReserveAmmo = 30,
		ReloadTime = 2.8,
		FireRate = 0.9,
		ADSFoV = 40,
		ADS_WalkSpeed = 5,
		Spread = 0.28,
		ADS_Spread = 0.14,
		Recoil = 4.0,
		Pellets = 9,
		Use_Skin = "Default Skin",
		TransitionTime = 0.28,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.6, -0.8, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Shotgun.Fire",
			Reload = "Weapons.Shotgun.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://119675476115615",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://72738152181538",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://125449482472477",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 200,
			CostMultiplier = 1.5,
			CostExpo = 1.3,
			DamagePerLevel = 6,
			AmmoPerLevel = 2,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://98862499502114",
				TextureId = "rbxassetid://97193789477962",
				ADS_Position = Vector3.new(0.5, -0.53, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.5, -0.53, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["DSR"] = {
		DisplayName = "DSR",
		Category = "Sniper",
		Damage = 110,
		HeadshotMultiplier = 3.2,
		MaxAmmo = 5,
		ReserveAmmo = 25,
		ReloadTime = 4.5,
		FireRate = 1.8,
		ADSFoV = 16,
		ADS_WalkSpeed = 3,
		Spread = 0.004,
		ADS_Spread = 0.0008,
		Recoil = 7,
		Use_Skin = "Default Skin",
		TransitionTime = 0.35,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.6, -0.3, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Sniper.Fire",
			Reload = "Weapons.Sniper.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://73084256588653",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://74716272041408",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://131460503822549",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 300,
			CostMultiplier = 1.8,
			CostExpo = 1.4,
			DamagePerLevel = 12,
			AmmoPerLevel = 1,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://76358445219389",
				TextureId = "rbxassetid://111222674661091",
				ADS_Position = Vector3.new(0.15, 10, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.15, 10, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = false,
		ShowCrosshairADS = true,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["Barrett-M82"] = {
		DisplayName = "Barrett-M82",
		Category = "Sniper",
		Damage = 150,
		HeadshotMultiplier = 3.5,
		MaxAmmo = 5,
		ReserveAmmo = 20,
		ReloadTime = 5.5,
		FireRate = 2.2,
		ADSFoV = 14,
		ADS_WalkSpeed = 2,
		Spread = 0.003,
		ADS_Spread = 0.0006,
		Recoil = 9,
		Use_Skin = "Default Skin",
		TransitionTime = 0.4,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.6, -0.3, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.Sniper.Fire",
			Reload = "Weapons.Sniper.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://71565555918300",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://90253703014927",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://107171463147424",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 350,
			CostMultiplier = 2.0,
			CostExpo = 1.5,
			DamagePerLevel = 15,
			AmmoPerLevel = 1,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://85540311840421",
				TextureId = "rbxassetid://126478701712866",
				ADS_Position = Vector3.new(0.15, 10, -1),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.15, 10, -1),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = false,
		ShowCrosshairADS = true,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["RPD"] = {
		DisplayName = "RPD",
		Category = "LMG",
		Damage = 30,
		HeadshotMultiplier = 2,
		MaxAmmo = 100,
		ReserveAmmo = 200,
		ReloadTime = 4.5,
		FireRate = 0.08,
		ADSFoV = 65,
		ADS_WalkSpeed = 8,
		Spread = 0.15,
		ADS_Spread = 0.04,
		Recoil = 2.5,
		Use_Skin = "Default Skin",
		TransitionTime = 0.25,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -0.6, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.LMG.Fire",
			Reload = "Weapons.LMG.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://121758187645048",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://123186347874158",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://83607468509793",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 280,
			CostMultiplier = 1.7,
			CostExpo = 1.4,
			DamagePerLevel = 6,
			AmmoPerLevel = 12,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://95390867886619",
				TextureId = "rbxassetid://73436350200814",
				ADS_Position = Vector3.new(0.5, -0.6, -0.5),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.5, -0.6, -0.5),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["MG-42"] = {
		DisplayName = "MG42",
		Category = "LMG",
		Damage = 32,
		HeadshotMultiplier = 2,
		MaxAmmo = 75,
		ReserveAmmo = 225,
		ReloadTime = 4.5,
		FireRate = 0.05,
		ADSFoV = 60,
		ADS_WalkSpeed = 6,
		Spread = 0.16,
		ADS_Spread = 0.04,
		Recoil = 2.5,
		Use_Skin = "Default Skin",
		TransitionTime = 0.28,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -0.6, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.LMG.Fire",
			Reload = "Weapons.LMG.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://81024085813610",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://107977795656514",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://120564764455850",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 320,
			CostMultiplier = 1.8,
			CostExpo = 1.4,
			DamagePerLevel = 6,
			AmmoPerLevel = 15,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://107100824065577",
				TextureId = "rbxassetid://96787606054376",
				ADS_Position = Vector3.new(0.5, -0.3, -1.3),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.5, -0.3, -1.3),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["M249"] = {
		DisplayName = "M249",
		Category = "LMG",
		Damage = 28,
		HeadshotMultiplier = 2,
		MaxAmmo = 200,
		ReserveAmmo = 4000000,
		ReloadTime = 6.0,
		FireRate = 0.06,
		ADSFoV = 68,
		ADS_WalkSpeed = 6,
		Spread = 0.18,
		ADS_Spread = 0.05,
		Recoil = 2.0,
		Use_Skin = "Default Skin",
		TransitionTime = 0.28,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -0.6, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		Sounds = {
			Fire = "Weapons.LMG.Fire",
			Reload = "Weapons.LMG.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			-- Per-animation viewmodel positions (R15 animations)
			Idle = {
				Id = "rbxassetid://121454959363022",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			},
			Run = {
				Id = "rbxassetid://99603718756982",
				Position = Vector3.new(0.100, -1.650, -0.750),
				Rotation = Vector3.new(6, 0, -7)
			},
			ADS = {
				Id = "rbxassetid://101603965159074",
				Position = Vector3.new(-0.365, -1.698, 0.329),
				Rotation = Vector3.new(0, -8, 0)
			}
		},
		UpgradeConfig = {
			BaseCost = 320,
			CostMultiplier = 1.9,
			CostExpo = 1.5,
			DamagePerLevel = 5,
			AmmoPerLevel = 12,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://123624823851856",
				TextureId = "rbxassetid://115924970803500",
				ADS_Position = Vector3.new(0.51, -0.52, -0.5),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.51, -0.52, -0.5),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},
	["Minigun"] = {
		DisplayName = "Minigun",
		Category = "LMG",
		Damage = 28,
		HeadshotMultiplier = 2,
		MaxAmmo = 999999999,
		ReserveAmmo = 0,
		ReloadTime = 6.0,
		FireRate = 0.02,
		ADSFoV = 68,
		ADS_WalkSpeed = 6,
		Spread = 0.18,
		ADS_Spread = 0.05,
		Recoil = 1.0,
		Use_Skin = "Default Skin",
		TransitionTime = 0.28,
		ADS_BlendTimeVM = 0.2,
		ViewmodelPosition = Vector3.new(1.5, -1, -2.5),
		ViewmodelRotation = Vector3.new(0, 0, 0),
		CanSprint = false, -- Minigun terlalu berat untuk lari
		CanADS = false, -- Minigun tidak punya ironsight
		Sounds = {
			Fire = "Weapons.LMG.Fire",
			Reload = "Weapons.LMG.Reload",
			Empty = "Weapons.Empty"
		},
		Animations = {
			Idle = {
				Id = "rbxassetid://117086210494708",
				Position = Vector3.new(0.117, -1.563, -0.250),
				Rotation = Vector3.new(5, 353, 0)
			}
			-- No Run or ADS animation
		},
		UpgradeConfig = {
			BaseCost = 999999999,
			CostMultiplier = 1.9,
			CostExpo = 1.5,
			DamagePerLevel = 5,
			AmmoPerLevel = 0,
			MaxLevel = 10
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://75877903567420",
				TextureId = "rbxassetid://112390601306926",
				ADS_Position = Vector3.new(0.51, -0.52, -0.5),
				ADS_Rotation = Vector3.new(0, 0, 0),
				ADS_Position_Mobile = Vector3.new(0.51, -0.52, -0.5),
				ADS_Rotation_Mobile = Vector3.new(0, 0, 0),
			},
			-- TODO: Add more skins here
		},
		ShowCrosshair = true,
		ShowCrosshairADS = false,
		SwayIntensity = 0.5,
		SwaySmoothing = 10,
		BobIntensity = 0.5,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.1,
		BreathSpeed = 2,
		VisualRecoilIntensity = -0.5,
		VisualRecoilKick = -0.7,
		VisualRecoilRecovery = 15
	},

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- MELEE WEAPONS (Tool Slot 1 - Cannot be replaced in-game)
	-- ═══════════════════════════════════════════════════════════════════════════════

	["Crowbar"] = {
		DisplayName = "Crowbar",
		Category = "Melee",
		IsMelee = true,
		Damage = 45,
		HeadshotMultiplier = 1.5,
		AttackSpeed = 0.8,
		Range = 5,
		StaminaCost = 5,
		Use_Skin = "Default Skin",
		Sounds = {
			Swing = "Weapons.Melee.Swing",
			Hit = "Weapons.Melee.Hit"
		},
		Animations = {
			Hold = {
				Id = "rbxassetid://138935160413870",
				Position = Vector3.new(0.2, -1.5, -0.3),
				Rotation = Vector3.new(0, 0, 0)
			},
			Attack = {
				Id = "rbxassetid://102809461040910",
				Position = Vector3.new(0.2, -1.5, -0.3),
				Rotation = Vector3.new(0, 0, 0)
			}
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://97573329768699",
				TextureId = "rbxassetid://90733729787742"
			}
		},
		ShowCrosshair = false,
		SwayIntensity = 0.3,
		SwaySmoothing = 12,
		BobIntensity = 0.4,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.05,
		BreathSpeed = 2
	},

	["Bat"] = {
		DisplayName = "Baseball Bat",
		Category = "Melee",
		IsMelee = true,
		Damage = 35,
		HeadshotMultiplier = 1.5,
		AttackSpeed = 0.5,
		Range = 4.5,
		StaminaCost = 4,
		Use_Skin = "Default Skin",
		Sounds = {
			Swing = "Weapons.Melee.Swing",
			Hit = "Weapons.Melee.Hit"
		},
		Animations = {
			Hold = {
				Id = "rbxassetid://112614643724193",
				Position = Vector3.new(0.2, -1.5, -0.3),
				Rotation = Vector3.new(0, 0, 0)
			},
			Attack = {
				Id = "rbxassetid://90802294449535",
				Position = Vector3.new(0.2, -1.5, -0.3),
				Rotation = Vector3.new(0, 0, 0)
			}
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://140341708045272",
				TextureId = "rbxassetid://115104815118400"
			}
		},
		ShowCrosshair = false,
		SwayIntensity = 0.3,
		SwaySmoothing = 12,
		BobIntensity = 0.4,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.05,
		BreathSpeed = 2
	},

	["Machete"] = {
		DisplayName = "Machete",
		Category = "Melee",
		IsMelee = true,
		Damage = 55,
		HeadshotMultiplier = 1.5,
		AttackSpeed = 1.0,
		Range = 5.5,
		StaminaCost = 6,
		Use_Skin = "Default Skin",
		Sounds = {
			Swing = "Weapons.Melee.Swing",
			Hit = "Weapons.Melee.Hit"
		},
		Animations = {
			Hold = {
				Id = "rbxassetid://82232796218764",
				Position = Vector3.new(0.2, -1.5, -0.3),
				Rotation = Vector3.new(0, 0, 0)
			},
			Attack = {
				Id = "rbxassetid://90990293014339",
				Position = Vector3.new(0.2, -1.5, -0.3),
				Rotation = Vector3.new(0, 0, 0)
			}
		},
		Skins = {
			["Default Skin"] = {
				MeshId = "rbxassetid://116058160565130",
				TextureId = "rbxassetid://110495399083937"
			}
		},
		ShowCrosshair = false,
		SwayIntensity = 0.3,
		SwaySmoothing = 12,
		BobIntensity = 0.4,
		BobSmoothing = 10,
		BobFrequency = 10,
		BreathIntensity = 0.05,
		BreathSpeed = 2
	}
}

return WeaponModule