-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

return {
	ClassName = "TextLabel",

	Properties = {
		BackgroundColor3 = Color3.new(0.125, 0.125, 0.125),
		BackgroundTransparency = 0.1,

		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(1, 0, 1, 0),

		Font = Enum.Font.SourceSansSemibold,
		Text = "Select a Tool\n",

		TextSize = 36,
	},
}