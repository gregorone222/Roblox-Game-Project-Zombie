-- LarvaSpawnVFX.lua (ModuleScript)
-- Egg Burst

local VFX = {}
local Debris = game:GetService("Debris")

function VFX.Play(spawnPoints)
	for _, pos in ipairs(spawnPoints) do
		local part = Instance.new("Part")
		part.Transparency = 1
		part.CanCollide = false
		part.Anchored = true
		part.Position = pos
		part.Parent = workspace
		Debris:AddItem(part, 2)

		local att = Instance.new("Attachment", part)
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(200, 200, 100)) -- Yellow goo
		pe.Texture = "rbxassetid://243953493"
		pe.Size = NumberSequence.new(0.5, 0)
		pe.Speed = NumberRange.new(10, 20)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Lifetime = NumberRange.new(0.5, 1)
		pe.Parent = att

		pe:Emit(20)

		-- SFX could be added here
	end
end

return VFX
