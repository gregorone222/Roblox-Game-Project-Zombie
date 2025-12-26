-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

return {
	ClassName = "TextButton",

	Properties = {
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	},
}