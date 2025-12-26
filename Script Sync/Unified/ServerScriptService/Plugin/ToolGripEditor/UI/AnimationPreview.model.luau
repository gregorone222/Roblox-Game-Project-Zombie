-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

return {
	ClassName = "Frame",
	Properties = {
		Name = "AnimationPreview",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundTransparency = 1,
		Visible = false, -- Initially hidden
		ZIndex = 2,
	},
	Children = {
		{
			ClassName = "UIListLayout",
			Properties = {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 5),
			},
		},
		{
			ClassName = "TextBox",
			Properties = {
				Name = "AnimIdInput",
				LayoutOrder = 1,
				Text = "",
				PlaceholderText = "rbxassetid://...",
				Size = UDim2.new(0.7, -10, 1, 0),
				Font = Enum.Font.SourceSans,
				TextSize = 18,
				ClearTextOnFocus = false,
			},
		},
		{
			ClassName = "TextButton",
			Properties = {
				Name = "PlayButton",
				LayoutOrder = 2,
				Text = "Play",
				Size = UDim2.new(0.15, 0, 1, 0),
				Font = Enum.Font.SourceSansSemibold,
				TextSize = 18,
				Style = Enum.ButtonStyle.RobloxRoundDefaultButton,
			},
		},
		{
			ClassName = "TextButton",
			Properties = {
				Name = "StopButton",
				LayoutOrder = 3,
				Text = "Stop",
				Size = UDim2.new(0.15, 0, 1, 0),
				Font = Enum.Font.SourceSansSemibold,
				TextSize = 18,
				Style = Enum.ButtonStyle.RobloxRoundButton,
			},
		},
	}
}