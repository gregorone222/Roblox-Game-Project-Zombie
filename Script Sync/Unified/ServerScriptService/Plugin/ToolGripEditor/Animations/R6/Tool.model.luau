-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

-- Roblox Default R6 Tool Hold Animation
return {
	ClassName = "Animation",
	Properties = {
		AnimationId = "rbxassetid://180436141",
	}
}
