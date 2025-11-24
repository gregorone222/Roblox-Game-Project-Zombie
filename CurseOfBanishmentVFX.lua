-- CurseOfBanishmentVFX.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CurseOfBanishmentVFX.lua
-- Script Place: ACT 1: Village

local CurseOfBanishmentVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

function CurseOfBanishmentVFX.apply(targetCharacter, config)
	local vfxContainer = Instance.new("Model", targetCharacter)
	vfxContainer.Name = "CurseOfBanishmentVFX"

	local head = targetCharacter:FindFirstChild("Head")
	if not head then
		Debris:AddItem(vfxContainer, 0.1)
		return
	end

	-- 1. Tanda di Atas Kepala
	local mark = Instance.new("Part", vfxContainer)
	mark.Shape = Enum.PartType.Ball
	mark.Material = Enum.Material.Neon
	mark.Color = Color3.fromRGB(120, 0, 180)
	mark.Size = Vector3.new(2, 2, 2)
	mark.Anchored = false
	mark.CanCollide = false
	mark.CFrame = head.CFrame * CFrame.new(0, 4, 0)

	local weld = Instance.new("WeldConstraint", mark)
	weld.Part0 = mark
	weld.Part1 = head

	-- 2. Aura Berbahaya
	local aura = Instance.new("Part", vfxContainer)
	aura.Shape = Enum.PartType.Ball
	aura.Material = Enum.Material.ForceField
	aura.Color = Color3.fromRGB(80, 20, 120)
	aura.Size = Vector3.new(0.1, 0.1, 0.1)
	aura.Anchored = false
	aura.CanCollide = false
	aura.CFrame = targetCharacter.PrimaryPart.CFrame

	local auraWeld = Instance.new("WeldConstraint", aura)
	auraWeld.Part0 = aura
	auraWeld.Part1 = targetCharacter.PrimaryPart

	-- Animasi Aura
	local finalSize = config.Radius * 2
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(aura, tweenInfo, {Size = Vector3.new(finalSize, finalSize, finalSize), Transparency = 0.75}):Play()

	-- 3. Pembersihan
	Debris:AddItem(vfxContainer, config.Duration)
end

return CurseOfBanishmentVFX