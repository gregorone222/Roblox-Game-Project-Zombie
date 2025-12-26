-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

-- Roblox Default R6 Idle Animation
return {
	ClassName = "Animation",
	Properties = {
		AnimationId = "rbxassetid://180435571",
	}
}
