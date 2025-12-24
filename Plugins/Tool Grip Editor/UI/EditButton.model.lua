return {
	ClassName = "TextButton",

	Properties = {
		Text = "Edit Tool Grip",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.new(1, -50, 0, 40),

		Font = Enum.Font.SourceSansSemibold,
		Style = Enum.ButtonStyle.RobloxRoundDefaultButton,

		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),

		Visible = false,
		ZIndex = 10,
	},

	Children = {
		{
			Name = "SizeCap",
			ClassName = "UISizeConstraint",

			Properties = {
				MaxSize = Vector2.new(300, 40)
			}
		},
	}
}