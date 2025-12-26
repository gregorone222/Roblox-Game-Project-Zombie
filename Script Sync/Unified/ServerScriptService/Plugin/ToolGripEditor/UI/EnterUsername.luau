-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

return {
	ClassName = "TextLabel",

	Properties = {
		Active = false,
		AnchorPoint = Vector2.new(0, 0),
		-- AttributesSerialize omitted (empty)
		AutoLocalize = true,
		AutomaticSize = 0, -- token
		BackgroundColor3 = Color3.new(0.180392161, 0.180392161, 0.180392161),
		BackgroundTransparency = 0,
		BorderColor3 = Color3.new(0.105882362, 0.164705887, 0.207843155),
		BorderMode = 0, -- token
		BorderSizePixel = 1,
		ClipsDescendants = false,
		Draggable = false,
		Font = 16, -- token (keadaan awal: disimpan sebagai angka)
		LayoutOrder = 0,
		LineHeight = 1,
		Name = "EnterUsername",
		NextSelectionDown = nil,
		NextSelectionLeft = nil,
		NextSelectionRight = nil,
		NextSelectionUp = nil,
		Position = UDim2.new(0, 0, 0, 0),
		RichText = false,
		RootLocalizationTable = nil,
		Rotation = 0,
		Selectable = false,
		SelectionImageObject = nil,
		Size = UDim2.new(1, 0, 1, 0),
		SizeConstraint = 0, -- token
		SourceAssetId = -1, -- int64
		-- Tags omitted (empty)
		Text = "Enter a Username:\n\n",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = false,
		TextSize = 36,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 1,
		TextTransparency = 0,
		TextTruncate = 0, -- token
		TextWrapped = false,
		TextXAlignment = 2, -- token
		TextYAlignment = 1, -- token
		Visible = false,
		ZIndex = 100,
	},

	Children = {
		{
			Name = "Input",
			ClassName = "TextBox",
			Properties = {
				Active = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- AttributesSerialize omitted (empty)
				AutoLocalize = true,
				AutomaticSize = 0,
				BackgroundColor3 = Color3.new(0.145098045, 0.145098045, 0.145098045),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.new(0.101960793, 0.101960793, 0.101960793),
				BorderMode = 0, -- token
				BorderSizePixel = 1,
				ClearTextOnFocus = true,
				ClipsDescendants = false,
				Draggable = false,
				Font = 16, -- token
				LayoutOrder = 0,
				LineHeight = 1,
				MultiLine = false,
				Name = "Input",
				NextSelectionDown = nil,
				NextSelectionLeft = nil,
				NextSelectionRight = nil,
				NextSelectionUp = nil,
				PlaceholderColor3 = Color3.new(0.699999988, 0.699999988, 0.699999988),
				PlaceholderText = "",
				Position = UDim2.new(0.5, 0, 0.550000012, 0),
				RichText = false,
				RootLocalizationTable = nil,
				Rotation = 0,
				Selectable = true,
				SelectionImageObject = nil,
				ShowNativeInput = true,
				Size = UDim2.new(0.699999988, 0, 0.200000003, 0),
				SizeConstraint = 0, -- token
				SourceAssetId = -1, -- int64
				-- Tags omitted (empty)
				Text = "",
				TextColor3 = Color3.new(0.800000072, 0.800000072, 0.800000072),
				TextEditable = true,
				TextScaled = true,
				TextSize = 8,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextStrokeTransparency = 1,
				TextTransparency = 0,
				TextTruncate = 0, -- token
				TextWrapped = true,
				TextXAlignment = 2, -- token
				TextYAlignment = 1, -- token
				Visible = true,
				ZIndex = 1000,
			},

			Children = {
				{
					Name = "AspectRatio",
					ClassName = "UIAspectRatioConstraint",
					Properties = {
						AspectRatio = 7,
						AspectType = 0, -- token
						-- AttributesSerialize omitted (empty)
						DominantAxis = 0, -- token
						Name = "AspectRatio",
						SourceAssetId = -1, -- int64
						-- Tags omitted (empty)
					},
					Children = {},
				},
			},
		},
	},
}