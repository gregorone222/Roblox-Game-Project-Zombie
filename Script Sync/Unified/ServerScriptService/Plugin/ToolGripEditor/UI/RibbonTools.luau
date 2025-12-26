-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

return {
	ClassName = "Frame",

	Properties = {
		Active = false,
		AnchorPoint = Vector2.new(0, 1),
		AutoLocalize = true,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.new(0.105882362, 0.164705887, 0.207843155),
		BorderMode = 0, -- token
		BorderSizePixel = 1,
		ClipsDescendants = false,
		Draggable = false,
		LayoutOrder = 0,
		Name = "RibbonTools",
		NextSelectionDown = nil,
		NextSelectionLeft = nil,
		NextSelectionRight = nil,
		NextSelectionUp = nil,
		Position = UDim2.new(0, 20, 1, -20),
		RootLocalizationTable = nil,
		Rotation = 0,
		Selectable = false,
		SelectionImageObject = nil,
		Size = UDim2.new(0, 70, 0, 70),
		SizeConstraint = 0, -- token
		Style = 0, -- token
		Visible = false,
		ZIndex = 10,
	},

	Children = {
		{
			Name = "List",
			ClassName = "UIListLayout",
			Properties = {
				-- AttributesSerialize omitted (empty)
				FillDirection = 0, -- token
				HorizontalAlignment = 1, -- token
				Name = "List",
				Padding = UDim.new(0, 10),
				SortOrder = 2, -- token
				VerticalAlignment = 1, -- token
			},
			Children = {},
		},

		{
			Name = "Move",
			ClassName = "TextButton",
			Properties = {
				Active = true,
				AnchorPoint = Vector2.new(0, 0),
				-- AttributesSerialize omitted
				AutoButtonColor = true,
				AutoLocalize = true,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.new(0.105882362, 0.164705887, 0.207843155),
				BorderMode = 0, -- token
				BorderSizePixel = 1,
				ClipsDescendants = false,
				Draggable = false,
				Font = 3, -- token
				LayoutOrder = 0,
				LineHeight = 1,
				Modal = false,
				Name = "Move",
				NextSelectionDown = nil,
				NextSelectionLeft = nil,
				NextSelectionRight = nil,
				NextSelectionUp = nil,
				Position = UDim2.new(0, 0, 0, 0),
				RootLocalizationTable = nil,
				Rotation = 0,
				Selectable = true,
				Selected = false,
				SelectionImageObject = nil,
				Size = UDim2.new(1, 0, 1, 0),
				SizeConstraint = 0, -- token
				Style = 4, -- token
				Text = "",
				TextColor3 = Color3.new(0, 0, 0),
				TextScaled = false,
				TextSize = 14,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextStrokeTransparency = 1,
				TextTransparency = 0,
				TextTruncate = 0, -- token
				TextWrapped = false,
				TextXAlignment = 2, -- token
				TextYAlignment = 1, -- token
				Visible = true,
				ZIndex = 1,
			},
			Children = {
				{
					Name = "Icon",
					ClassName = "ImageLabel",
					Properties = {
						Active = false,
						AnchorPoint = Vector2.new(0.5, 0.5),
						AutoLocalize = true,
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.new(0.105882362, 0.164705887, 0.207843155),
						BorderMode = 0, -- token
						BorderSizePixel = 1,
						Image = "rbxassetid://4462132199",
						ImageColor3 = Color3.new(1, 1, 1),
						ImageRectOffset = Vector2.new(0, 0),
						ImageRectSize = Vector2.new(0, 0),
						ImageTransparency = 0,
						LayoutOrder = 0,
						Name = "Icon",
						NextSelectionDown = nil,
						NextSelectionLeft = nil,
						NextSelectionRight = nil,
						NextSelectionUp = nil,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						RootLocalizationTable = nil,
						Rotation = 0,
						ScaleType = 0, -- token
						Selectable = false,
						SelectionImageObject = nil,
						Size = UDim2.new(1, 0, 1, 0),
						SizeConstraint = 0, -- token
						SliceCenter = {
							min = Vector2.new(0, 0),
							max = Vector2.new(0, 0),
						},
						SliceScale = 1,
						TileSize = UDim2.new(1, 0, 1, 0),
						Visible = true,
						ZIndex = 1,
					},
					Children = {},
				},
			},
		},

		{
			Name = "Rotate",
			ClassName = "TextButton",
			Properties = {
				Active = true,
				AnchorPoint = Vector2.new(0, 0),
				-- AttributesSerialize omitted
				AutoButtonColor = true,
				AutoLocalize = true,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0,
				BorderColor3 = Color3.new(0.105882362, 0.164705887, 0.207843155),
				BorderMode = 0, -- token
				BorderSizePixel = 1,
				ClipsDescendants = false,
				Draggable = false,
				Font = 12, -- token
				LayoutOrder = 0,
				LineHeight = 1,
				Modal = false,
				Name = "Rotate",
				NextSelectionDown = nil,
				NextSelectionLeft = nil,
				NextSelectionRight = nil,
				NextSelectionUp = nil,
				Position = UDim2.new(0, 0, 0, 0),
				RootLocalizationTable = nil,
				Rotation = 0,
				Selectable = true,
				Selected = false,
				SelectionImageObject = nil,
				Size = UDim2.new(1, 0, 1, 0),
				SizeConstraint = 0, -- token
				Style = 3, -- token
				Text = "",
				TextColor3 = Color3.new(0, 0, 0),
				TextScaled = false,
				TextSize = 14,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextStrokeTransparency = 1,
				TextTransparency = 0,
				TextTruncate = 0, -- token
				TextWrapped = false,
				TextXAlignment = 2, -- token
				TextYAlignment = 1, -- token
				Visible = true,
				ZIndex = 1,
			},
			Children = {
				{
					Name = "Icon",
					ClassName = "ImageLabel",
					Properties = {
						Active = false,
						AnchorPoint = Vector2.new(0.5, 0.5),
						AutoLocalize = true,
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.new(0.105882362, 0.164705887, 0.207843155),
						BorderMode = 0, -- token
						BorderSizePixel = 1,
						Image = "rbxassetid://4462132461",
						ImageColor3 = Color3.new(1, 1, 1),
						ImageRectOffset = Vector2.new(0, 0),
						ImageRectSize = Vector2.new(0, 0),
						ImageTransparency = 0,
						LayoutOrder = 0,
						Name = "Icon",
						NextSelectionDown = nil,
						NextSelectionLeft = nil,
						NextSelectionRight = nil,
						NextSelectionUp = nil,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						RootLocalizationTable = nil,
						Rotation = 0,
						ScaleType = 0, -- token
						Selectable = false,
						SelectionImageObject = nil,
						Size = UDim2.new(1, 0, 1, 0),
						SizeConstraint = 0, -- token
						SliceCenter = {
							min = Vector2.new(0, 0),
							max = Vector2.new(0, 0),
						},
						SliceScale = 1,
						TileSize = UDim2.new(1, 0, 1, 0),
						Visible = true,
						ZIndex = 1,
					},
					Children = {},
				},
			},
		},
	},
}