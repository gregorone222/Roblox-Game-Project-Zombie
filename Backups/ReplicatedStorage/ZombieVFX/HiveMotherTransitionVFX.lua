-- HiveMotherTransitionVFX.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/HiveMotherTransitionVFX.lua
-- Script Place: ACT 1: Village
-- Phase change scream

local VFX = {}
local TweenService = game:GetService("TweenService")

function VFX.Play(bossModel)
	if not bossModel or not bossModel.PrimaryPart then return end

	local root = bossModel.PrimaryPart

	-- Shockwave
	local wave = Instance.new("Part")
	wave.Shape = Enum.PartType.Ball
	wave.Size = Vector3.new(5,5,5)
	wave.Color = Color3.fromRGB(150, 255, 100)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 0.5
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = root.CFrame
	wave.Parent = workspace

	local t1 = TweenService:Create(wave, TweenInfo.new(1), {Size = Vector3.new(50,50,50), Transparency = 1})
	t1:Play()
	t1.Completed:Connect(function() wave:Destroy() end)

	-- Color Pulse on Boss
	for _, part in ipairs(bossModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local originalColor = part.Color
			local t2 = TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 4, true), {Color = Color3.fromRGB(100, 255, 100)})
			t2:Play()
			t2.Completed:Connect(function() part.Color = originalColor end)
		end
	end
end

return VFX
