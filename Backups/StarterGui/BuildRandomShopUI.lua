local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Configuration: NEW Cropped Asset IDs
local ASSETS = {
    HeaderBoard = "rbxassetid://99083183697675",
    MetalPanel = "rbxassetid://71404761243590",
    StatsBoard = "rbxassetid://108160025652813",
    WeaponCard = "rbxassetid://103571545472235",
    ButtonRed = "rbxassetid://139304478474664",
    ButtonGreen = "rbxassetid://118117411185993",
}

local FONTS = {
    Title = Enum.Font.LuckiestGuy,
    Body = Enum.Font.FredokaOne
}

local function CreateGenericObj(className, properties)
    local obj = Instance.new(className)
    for k, v in pairs(properties) do
        obj[k] = v
    end
    return obj
end

local function BuildUI()
    print("🛠️ Building RandomWeaponShopUI (Precise Coordinates)...")

    local guiName = "RandomWeaponShopUI"
    if PlayerGui:FindFirstChild(guiName) then
        PlayerGui[guiName]:Destroy()
    end

    local screenGui = CreateGenericObj("ScreenGui", {
        Name = guiName,
        Parent = PlayerGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })

    -- Overlay
    local overlay = CreateGenericObj("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Parent = screenGui
    })

    -- Main Container
    local mainContainer = CreateGenericObj("Frame", {
        Name = "MainContainer",
        Size = UDim2.new(0.9, 0, 0.9, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, -- Fully Transparent
        Parent = overlay
    })
    
    CreateGenericObj("UIAspectRatioConstraint", {
        AspectRatio = 1.6, -- Menjaga proporsi layar 16:9
        Parent = mainContainer
    })

    --------------------------------------------------------------------------------
    -- A. HEADER (Top)
    --------------------------------------------------------------------------------
    local headerSize = UDim2.new(0.5, 0, 0.25, 0)
    local header = CreateGenericObj("ImageLabel", {
        Name = "HeaderBoard",
        Image = ASSETS.HeaderBoard,
        BackgroundTransparency = 1,
        Size = headerSize,
        Position = UDim2.new(0.5, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        ScaleType = Enum.ScaleType.Stretch,
        Parent = mainContainer
    })

    CreateGenericObj("TextLabel", {
        Name = "TitleText",
        Text = "TACTICAL DECISION",
        Font = FONTS.Title,
        TextSize = 38,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        -- [USER PRECISE]
        Size = UDim2.new(0.8, 0, 0.488, 0),
        Position = UDim2.new(0.5, 0, 0.756, 0), 
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextScaled = true,
        Parent = header
    })
    CreateGenericObj("UIStroke", {Thickness = 3, Color = Color3.fromRGB(60, 40, 20), Parent = header.TitleText})

    --------------------------------------------------------------------------------
    -- B. CONTENT (Middle)
    --------------------------------------------------------------------------------
    local contentFrame = CreateGenericObj("Frame", {
        Name = "ContentFrame",
        Size = UDim2.new(1, 0, 0.55, 0),
        Position = UDim2.new(0, 0, 0.26, 0),
        BackgroundTransparency = 1,
        Parent = mainContainer
    })

    -- 1. LEFT PANEL (New Acq)
    local leftPanel = CreateGenericObj("ImageLabel", {
        Name = "LeftPanel",
        Image = ASSETS.MetalPanel,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.32, 0, 1, 0),
        Position = UDim2.new(0.02, 0, 0, 0),
        ScaleType = Enum.ScaleType.Stretch,
        Parent = contentFrame
    })

    CreateGenericObj("TextLabel", {
        Name = "LabelNew",
        Text = "NEW ACQUISITION",
        Font = FONTS.Title,
        TextColor3 = Color3.fromRGB(120, 240, 120), 
        Size = UDim2.new(0.8, 0, 0.1, 0),
        -- [USER PRECISE]
        Position = UDim2.new(0.5, 0, 0.062, 0), 
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        TextScaled = true,
        Parent = leftPanel
    })
    CreateGenericObj("UIStroke", {Thickness = 2.5, Color = Color3.fromRGB(0, 50, 0), Parent = leftPanel.LabelNew})

    CreateGenericObj("ViewportFrame", {
        Name = "WeaponPreview",
        -- [USER PRECISE]
        Size = UDim2.new(0.749, 0, 0.604, 0),
        Position = UDim2.new(0.501, 0, 0.507, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = leftPanel
    })

    -- 2. CENTER PANEL (Stats)
    local centerPanel = CreateGenericObj("ImageLabel", {
        Name = "CenterPanel",
        Image = ASSETS.StatsBoard,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.32, 0, 0.95, 0),
        Position = UDim2.new(0.35, 0, 0.02, 0),
        ScaleType = Enum.ScaleType.Stretch,
        Parent = contentFrame
    })

    CreateGenericObj("TextLabel", {
        Name = "LabelStats",
        Text = "STATS COMPARISON",
        Font = FONTS.Title,
        TextColor3 = Color3.fromRGB(240, 220, 180),
        Size = UDim2.new(0.8, 0, 0.12, 0),
        Position = UDim2.new(0.5, 0, 0.15, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        TextScaled = true,
        Parent = centerPanel
    })
    
    local statsContainer = CreateGenericObj("Frame", {
        Name = "StatsList",
        Size = UDim2.new(0.75, 0, 0.55, 0),
        Position = UDim2.new(0.5, 0, 0.6, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = centerPanel
    })
    CreateGenericObj("UIListLayout", {Padding = UDim.new(0.05, 0), Parent = statsContainer})
    
    local function CreateStatRow(name, val, color)
        local row = CreateGenericObj("Frame", {Size = UDim2.new(1,0,0.25,0), BackgroundTransparency=1, Parent=statsContainer})
        CreateGenericObj("TextLabel", {Text=name, Font=FONTS.Body, TextColor3=Color3.new(1,1,1), Size=UDim2.new(0.5,0,0.8,0), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, TextScaled=true, Parent=row})
        CreateGenericObj("TextLabel", {Text=val, Font=FONTS.Title, TextColor3=color, Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Right, TextScaled=true, Parent=row})
    end
    CreateStatRow("DAMAGE", "35", Color3.new(0.4,1,0.4))
    CreateStatRow("AMMO", "30/90", Color3.new(1,1,1))
    CreateStatRow("RPM", "600", Color3.new(1,0.4,0.4))

    -- 3. RIGHT PANEL (List - NO SCROLL)
    local rightPanel = CreateGenericObj("Frame", {
        Name = "RightPanel",
        BackgroundTransparency = 1,
        Size = UDim2.new(0.28, 0, 1, 0),
        Position = UDim2.new(0.7, 0, 0, 0),
        Parent = contentFrame
    })
    
    local listContainer = CreateGenericObj("Frame", {
        Name = "WeaponList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = rightPanel
    })
    -- [USER PRECISE] VerticalFlex = Fill
    CreateGenericObj("UIListLayout", {
        Padding = UDim.new(0.05, 0), 
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
        Parent = listContainer
    })
    
    -- Hanya 2 ITEM
    for i=1, 2 do
        local card = CreateGenericObj("ImageLabel", {
            Name = "InfoCard",
            Image = ASSETS.WeaponCard,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0.35, 0), 
            ScaleType = Enum.ScaleType.Stretch,
            LayoutOrder = i,
            Parent = listContainer
        })
        
        CreateGenericObj("TextLabel", {
            Text = "ITEM " .. i,
            Font = FONTS.Title,
            TextColor3 = Color3.fromRGB(60,40,20),
            Size = UDim2.new(0.8, 0, 0.4, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = card
        })
    end

    --------------------------------------------------------------------------------
    -- C. FOOTER
    --------------------------------------------------------------------------------
    local buttonsFrame = CreateGenericObj("Frame", {
        Name = "Buttons",
        Size = UDim2.new(0.6, 0, 0.15, 0),
        Position = UDim2.new(0.5, 0, 0.85, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Parent = mainContainer
    })
    
    -- Discard
    local btnDiscard = CreateGenericObj("ImageButton", {
        Image = ASSETS.ButtonRed,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.48, 0, 1.1, 0), 
        Position = UDim2.new(0, 0, -0.05, 0),
        ScaleType = Enum.ScaleType.Stretch,
        Parent = buttonsFrame
    })
    CreateGenericObj("TextLabel", {Text="DISCARD", Font=FONTS.Title, TextColor3=Color3.new(1,1,1), Size=UDim2.new(0.8,0,0.5,0), Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, TextScaled=true, Parent=btnDiscard})
    CreateGenericObj("UIStroke", {Thickness = 2, Parent = btnDiscard:FindFirstChild("TextLabel")})

    -- Swap
    local btnSwap = CreateGenericObj("ImageButton", {
        Image = ASSETS.ButtonGreen,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.48, 0, 1.1, 0), 
        Position = UDim2.new(0.52, 0, -0.05, 0),
        ScaleType = Enum.ScaleType.Stretch,
        Parent = buttonsFrame
    })
    CreateGenericObj("TextLabel", {Text="SWAP WEAPON", Font=FONTS.Title, TextColor3=Color3.new(1,1,1), Size=UDim2.new(0.8,0,0.5,0), Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, TextScaled=true, Parent=btnSwap})
     CreateGenericObj("UIStroke", {Thickness = 2, Parent = btnSwap:FindFirstChild("TextLabel")})
end

BuildUI()
