-- ZombieAnimationHandler.lua (Script)
-- Path: ServerScriptService/ZombieAnimationHandler.lua
-- Description: Automatically detects zombies and plays attack animations based on "Attacking" attribute.

local Services = {
	Players = game:GetService("Players"),
	Workspace = game:GetService("Workspace")
}

-- KONFIGURASI ANIMASI
-- Ganti ID di bawah ini dengan ID Animasi kamu!
local ANIMATIONS = {
	ATTACK = "rbxassetid://0000000000", -- [GANTI INI] ID Animasi Attack Zombie
}

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

	-- Preload Animation
	local attackAnim = Instance.new("Animation")
	attackAnim.AnimationId = ANIMATIONS.ATTACK
	
	local attackTrack = nil
	pcall(function()
		attackTrack = animator:LoadAnimation(attackAnim)
		attackTrack.Priority = Enum.AnimationPriority.Action
	end)

	-- Listener untuk Attribute "Attacking" yang di-set oleh ZombieModule
	zombie:GetAttributeChangedSignal("Attacking"):Connect(function()
		local isAttacking = zombie:GetAttribute("Attacking")
		if isAttacking then
			if attackTrack then
				attackTrack:Play(0.1) -- Fade in 0.1s
				-- Opsional: Sesuaikan speed jika perlu
				-- attackTrack:AdjustSpeed(1.5) 
			end
		else
			-- Opsional: Stop animasi jika attribute 'false' sebelum animasi selesai
			-- Biasanya attack animation one-shot, jadi tidak perlu di-stop paksa kecuali looping
			-- if attackTrack and attackTrack.IsPlaying then attackTrack:Stop(0.1) end
		end
	end)
	
	-- Cleanup saat zombie mati/destroyed handeld oleh GC Roblox otomatis untuk tracks,
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
