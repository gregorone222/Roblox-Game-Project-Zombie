-- ZombieAnimationHandler.lua (Script)
-- Path: ServerScriptService/ZombieAnimationHandler.lua
-- Description: Automatically detects zombies and plays attack animations based on "Attacking" attribute.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = {
	Players = game:GetService("Players"),
	Workspace = game:GetService("Workspace")
}

-- Load ZombieConfig untuk mendapatkan animasi per-tipe
local ZombieConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("ZombieConfig"))

-- KONFIGURASI ANIMASI DEFAULT
-- Digunakan jika tipe zombie tidak memiliki AttackAnimations sendiri
local DEFAULT_ATTACK_ANIM = "rbxassetid://0000000000" -- [GANTI INI] ID Animasi Attack Zombie Default

local function setupZombie(zombie)
	-- Hindari setup ganda
	if zombie:GetAttribute("AnimSetupConfigured") then return end
	zombie:SetAttribute("AnimSetupConfigured", true)

	local humanoid = zombie:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	
	local animator = humanoid:WaitForChild("Animator", 5)
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Tentukan tipe zombie berdasarkan nama model
	local zombieType = zombie.Name
	local typeConfig = ZombieConfig.Types[zombieType]
	
	-- Ambil daftar animasi dari config, atau gunakan default
	local animationIds = {}
	if typeConfig and typeConfig.AttackAnimations and #typeConfig.AttackAnimations > 0 then
		animationIds = typeConfig.AttackAnimations
	else
		animationIds = { DEFAULT_ATTACK_ANIM }
	end

	-- Preload semua animasi attack
	local attackTracks = {}
	for _, animId in ipairs(animationIds) do
		local attackAnim = Instance.new("Animation")
		attackAnim.AnimationId = animId
		pcall(function()
			local track = animator:LoadAnimation(attackAnim)
			track.Priority = Enum.AnimationPriority.Action
			table.insert(attackTracks, track)
		end)
	end

	-- Listener untuk Attribute "Attacking" yang di-set oleh ZombieModule
	zombie:GetAttributeChangedSignal("Attacking"):Connect(function()
		local isAttacking = zombie:GetAttribute("Attacking")
		if isAttacking then
			if #attackTracks > 0 then
				-- Pilih animasi secara acak
				local randomTrack = attackTracks[math.random(1, #attackTracks)]
				randomTrack:Play(0.1) -- Fade in 0.1s
			end
		end
	end)
	
	-- Cleanup saat zombie mati/destroyed handled oleh GC Roblox otomatis untuk tracks,
	-- tapi connection akan putus saat instance destroyed.
end

local function onChildAdded(child)
	-- Cek apakah objek ini adalah Zombie
	-- ZombieModule menambahkan BoolValue "IsZombie"
	if child:IsA("Model") then
		-- Tunggu sebentar karena tag IsZombie mungkin ditambahkan setelah parent
		task.delay(0.5, function()
			if child.Parent and child:FindFirstChild("IsZombie") then
				setupZombie(child)
			end
		end)
	end
end

-- Monitor Zombie baru yang spawn
Services.Workspace.ChildAdded:Connect(onChildAdded)

-- Scan zombie yang sudah ada saat server start (jika ada)
for _, child in ipairs(Services.Workspace:GetChildren()) do
	onChildAdded(child)
end

print("Zombie Animation Handler Loaded. Waiting for zombies...")
