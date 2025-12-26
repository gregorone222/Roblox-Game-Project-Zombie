-- AcidSpitVFX.lua (ModuleScript)
-- Green projectile with splash

local VFX = {}
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

function VFX.Play(origin, targetPos)
	local dist = (targetPos - origin).Magnitude
	local duration = dist / 60 -- Speed

	-- Projectile
	local proj = Instance.new("Part")
	proj.Size = Vector3.new(1,1,1)
	proj.Shape = Enum.PartType.Ball
	proj.Color = Color3.fromRGB(100, 255, 50)
	proj.Material = Enum.Material.Neon
	proj.CanCollide = false
	proj.Anchored = true
	proj.CFrame = CFrame.new(origin, targetPos)
	proj.Parent = workspace

	-- Trail
	local att0 = Instance.new("Attachment", proj)
	local att1 = Instance.new("Attachment", proj); att1.Position = Vector3.new(0,0,0.5)
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(100, 255, 50))
	trail.Lifetime = 0.3
	trail.Parent = proj

	-- Motion
	local tween = TweenService:Create(proj, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = targetPos})
	tween:Play()

	tween.Completed:Connect(function()
		proj:Destroy()
		-- Splash Effect
		VFX.Splash(targetPos)
	end)
end

function VFX.Splash(pos)
	local part = Instance.new("Part")
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = pos
	part.Parent = workspace
	Debris:AddItem(part, 2)

	local att = Instance.new("Attachment", part)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(100, 255, 50))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
	pe.Texture = "rbxassetid://243953493" -- Generic blob
	pe.Speed = NumberRange.new(5, 10)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.5, 1)
	pe.Rate = 0
	pe.Parent = att

	pe:Emit(30)
end

return VFX
