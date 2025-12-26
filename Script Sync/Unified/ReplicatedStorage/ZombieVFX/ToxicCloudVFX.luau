-- ToxicCloudVFX.lua (ModuleScript)
-- Expanding green smoke

local VFX = {}
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

function VFX.Play(origin, radius, duration)
	local part = Instance.new("Part")
	part.Name = "ToxicCloud"
	part.Shape = Enum.PartType.Cylinder
	part.Orientation = Vector3.new(0, 0, 90)
	part.Size = Vector3.new(1, 1, 1) -- Start small
	part.Position = origin
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.8
	part.Color = Color3.fromRGB(50, 200, 50)
	part.Material = Enum.Material.Neon
	part.Parent = workspace
	Debris:AddItem(part, duration)

	-- Emitters
	local att = Instance.new("Attachment", part)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxassetid://243953493" -- Smoke
	pe.Color = ColorSequence.new(Color3.fromRGB(50, 150, 50))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 10)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(2, 4)
	pe.Rate = 20
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = att

	-- Expand
	TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(1, radius*2, radius*2)
	}):Play()

	-- Fade out at end
	task.delay(duration - 1, function()
		if part.Parent then
			TweenService:Create(part, TweenInfo.new(1), {Transparency = 1}):Play()
			pe.Enabled = false
		end
	end)
end

return VFX
