return {
	ClassName = "TextButton",

	Properties = {
		Name = "RigSwitcher",
		Text = "Rig: R15",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.new(0, 100, 0, 20),

		BackgroundColor3 = Color3.fromRGB(80, 80, 80),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.SourceSans,
		TextSize = 14,

		ZIndex = 11,
	},

	Children = {
		{
			ClassName = "UICorner",
			Properties = {
				CornerRadius = UDim.new(0, 4),
			}
		}
	}
}