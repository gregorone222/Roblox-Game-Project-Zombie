-- DailyRewardUI.lua (LocalScript)
-- Path: DailyRewardUI.lua (Root)
-- Script Place: Lobby
-- Theme: Zombie Apocalypse "Doomsday Calendar" (Scratched Wall/Chalk)
-- Redesigned by Lead Game Developer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		WallBase = Color3.fromRGB(45, 52, 54),      -- Dark Concrete
		WallShadow = Color3.fromRGB(30, 30, 35),    -- Deep Shadow
		ChalkWhite = Color3.fromRGB(223, 230, 233), -- Chalk
		BloodRed = Color3.fromRGB(179, 57, 57),     -- Dried Blood
		Scratch = Color3.fromRGB(100, 100, 110),    -- Metal Scratch
		SafeGreen = Color3.fromRGB(85, 239, 196),   -- Safe Zone Marker
		RustyMetal = Color3.fromRGB(99, 110, 114),  -- Metal Box
	},
	Fonts = {
		Handwritten = Enum.Font.PermanentMarker, -- Marker/Chalk style
		Scratched = Enum.Font.Creepster,         -- Horror/Scratched
		Simple = Enum.Font.PatrickHand,          -- Handwritten Note
	}
}

-- ================== HELPER FUNCTIONS ==================

local function create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	return inst
end

local function addCorner(parent, radius)
	return create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius)})
end

local function addStroke(parent, color, thickness)
	return create("UIStroke", {
		Parent = parent, Color = color or THEME.Colors.ChalkWhite, Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.3
	})
end

-- Adds procedural scratches
local function addScratches(parent, count)
	for i = 1, count or 5 do
		local scratch = create("Frame", {
			Name = "Scratch", Parent = parent, Size = UDim2.new(0, math.random(10, 30), 0, 2),
			Position = UDim2.new(math.random(), 0, math.random(), 0),
			BackgroundColor3 = THEME.Colors.Scratch, BackgroundTransparency = 0.4,
			Rotation = math.random(0, 360), ZIndex = parent.ZIndex
		})
		addCorner(scratch, 1)
	end
end

-- Adds a "Chalk Circle" effect
local function addChalkCircle(parent)
	local circle = create("Frame", {
		Name = "ChalkCircle", Parent = parent, Size = UDim2.new(0.9, 0, 0.9, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
		BackgroundTransparency = 1, ZIndex = parent.ZIndex + 1
	})
	local s = create("UIStroke", {
		Parent = circle, Color = THEME.Colors.SafeGreen, Thickness = 3, Transparency = 0.2
	})
	addCorner(circle, 100)
	return circle
end

-- Adds a "Blood Cross" (X)
local function addBloodCross(parent)
	local container = create("Frame", {
		Name = "BloodCross", Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = parent.ZIndex + 2
	})

	local line1 = create("Frame", {
		Parent = container, Size = UDim2.new(0.8, 0, 0.1, 0), Position = UDim2.new(0.1, 0, 0.45, 0),
		BackgroundColor3 = THEME.Colors.BloodRed, Rotation = 45, BackgroundTransparency = 0.2
	})
	local line2 = create("Frame", {
		Parent = container, Size = UDim2.new(0.8, 0, 0.1, 0), Position = UDim2.new(0.1, 0, 0.45, 0),
		BackgroundColor3 = THEME.Colors.BloodRed, Rotation = -45, BackgroundTransparency = 0.2
	})

	-- Rough edges
	addCorner(line1, 4)
	addCorner(line2, 4)
	return container
end

-- ================== MAIN UI LOGIC ==================

local gui
local mainContainer
local openButton
local isOpening = false

-- State
local rewardConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("DailyRewardConfig"))
local getRewardInfo
local claimRewardEvent 

local function resolveRemotes()
	-- Try RemoteFunctions folder first
	local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions", 1)
	if rfFolder then
		getRewardInfo = rfFolder:FindFirstChild("GetDailyRewardInfo")
		claimRewardEvent = rfFolder:FindFirstChild("ClaimDailyReward")
	end

	-- Fallback to RemoteEvents folder (checking each individually if not found)
	local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 1)
	if reFolder then
		if not getRewardInfo then
			getRewardInfo = reFolder:FindFirstChild("GetDailyRewardInfo")
		end
		if not claimRewardEvent then
			claimRewardEvent = reFolder:FindFirstChild("ClaimDailyReward")
		end
	end
end
resolveRemotes()

-- ------------------------------------------------------
-- UI CONSTRUCTION
-- ------------------------------------------------------

local function createDailyRewardUI()
	if gui then gui:Destroy() end

	gui = create("ScreenGui", {
		Name = "DailyRewardUI", Parent = playerGui, ResetOnSpawn = false, Enabled = false, IgnoreGuiInset = true
	})

	local backdrop = create("Frame", {
		Name = "Backdrop", Parent = gui, Size = UDim2.new(1,0,1,0), 
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.2
	})

	-- === THE WALL SURFACE ===
	mainContainer = create("CanvasGroup", {
		Name = "WallFrame", Parent = gui, 
		Size = UDim2.new(0, 900, 0, 600), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.Colors.WallBase, GroupTransparency = 1
	})
	addCorner(mainContainer, 8)
	-- Wall Texture (Noise)
	create("ImageLabel", {
		Parent = mainContainer, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217", ImageTransparency = 0.9, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0, 200, 0, 200)
	})
	addScratches(mainContainer, 20)

	-- Title Scrawled on Wall
	create("TextLabel", {
		Parent = mainContainer, Size = UDim2.new(1, 0, 0.15, 0), Position = UDim2.new(0, 0, 0.05, 0),
		Text = "DAYS SURVIVED", Font = THEME.Fonts.Handwritten, TextSize = 48, TextColor3 = THEME.Colors.ChalkWhite,
		BackgroundTransparency = 1, TextStrokeTransparency = 0.8
	})

	-- Close Button (Scribbled X)
	local closeBtn = create("TextButton", {
		Name = "CloseButton", Parent = mainContainer, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.92, 0, 0.05, 0),
		Text = "X", Font = THEME.Fonts.Handwritten, TextSize = 40, TextColor3 = THEME.Colors.BloodRed,
		BackgroundTransparency = 1
	})
	closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

	-- === LEFT: CALENDAR GRID (Chalk drawn) ===
	local gridFrame = create("Frame", {
		Name = "CalendarGrid", Parent = mainContainer, Size = UDim2.new(0.6, 0, 0.7, 0), Position = UDim2.new(0.05, 0, 0.25, 0),
		BackgroundTransparency = 1
	})

	-- Grid Lines (Drawn with Frame borders)
	local gridLayout = create("UIGridLayout", {
		Parent = gridFrame, CellSize = UDim2.new(0.18, 0, 0.18, 0), CellPadding = UDim2.new(0.02, 0, 0.02, 0)
	})

	-- === RIGHT: THE STASH (Reward Info) ===
	local stashFrame = create("Frame", {
		Name = "StashFrame", Parent = mainContainer, Size = UDim2.new(0.3, 0, 0.6, 0), Position = UDim2.new(0.68, 0, 0.25, 0),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40), Rotation = 2
	})
	addCorner(stashFrame, 4)
	-- Taped to wall
	create("Frame", {
		Parent = stashFrame, Size = UDim2.new(0.4, 0, 0.1, 0), Position = UDim2.new(0.3, 0, -0.05, 0),
		BackgroundColor3 = Color3.fromRGB(200, 190, 150), Rotation = -2
	})

	-- Reward Icon Area
	local iconArea = create("Frame", {
		Parent = stashFrame, Size = UDim2.new(0.8, 0, 0.5, 0), Position = UDim2.new(0.1, 0, 0.1, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	})
	create("ImageLabel", {
		Name = "RewardIcon", Parent = iconArea, Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.1, 0, 0.1, 0),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit
	})

	-- Text
	create("TextLabel", {
		Name = "RewardTitle", Parent = stashFrame, Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.65, 0),
		Text = "AMMO BOX", Font = THEME.Fonts.Simple, TextSize = 24, TextColor3 = THEME.Colors.ChalkWhite,
		BackgroundTransparency = 1
	})

	-- CLAIM BUTTON (Scratch it off)
	local claimBtn = create("TextButton", {
		Name = "ClaimBtn", Parent = stashFrame, Size = UDim2.new(0.8, 0, 0.15, 0), Position = UDim2.new(0.1, 0, 0.8, 0),
		BackgroundColor3 = THEME.Colors.BloodRed, Text = "TAKE IT", Font = THEME.Fonts.Scratched, TextSize = 24,
		TextColor3 = Color3.new(0,0,0)
	})
	addCorner(claimBtn, 8)

end

-- ------------------------------------------------------
-- LOGIC
-- ------------------------------------------------------

local function populateCalendar(currentDay, canClaim)
	local gridFrame = mainContainer:FindFirstChild("CalendarGrid")

	-- Clear
	for _, c in ipairs(gridFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	for day = 1, #rewardConfig.Rewards do
		local cell = create("Frame", {
			Parent = gridFrame, BackgroundTransparency = 1
		})
		-- Drawn box
		local border = create("Frame", {
			Parent = cell, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1
		})
		addStroke(border, THEME.Colors.ChalkWhite, 2)
		addCorner(border, 4)

		-- Day Num
		create("TextLabel", {
			Parent = cell, Size = UDim2.new(1,0,1,0), Text = tostring(day), 
			Font = THEME.Fonts.Handwritten, TextSize = 24, TextColor3 = THEME.Colors.ChalkWhite, BackgroundTransparency = 1
		})

		if day < currentDay then
			-- Survived/Claimed (Crossed out)
			addBloodCross(cell)
			cell.BackgroundTransparency = 0.8
			cell.BackgroundColor3 = Color3.new(0,0,0)
		elseif day == currentDay then
			-- Today
			addChalkCircle(cell)
		else
			-- Future
			border.UIStroke.Transparency = 0.7
		end
	end
end

local function updateStash(day, canClaim)
	local panel = mainContainer:FindFirstChild("StashFrame")
	if not panel then return end

	local reward = rewardConfig.Rewards[day]
	if not reward then return end

	local title = panel:FindFirstChild("RewardTitle")
	local icon = panel:FindFirstChild("RewardIcon", true)
	local btn = panel:FindFirstChild("ClaimBtn")

	-- Update Info
	local typeText = reward.Type
	if reward.Type == "Coins" then typeText = string.format("%d COINS", reward.Value) end

	title.Text = typeText

	local iconId = "rbxassetid://497939460" -- Crate
	if reward.Type == "Coins" then iconId = "rbxassetid://281938327" end
	if icon then 
		icon.Image = iconId 
		icon.ImageColor3 = (canClaim and Color3.new(1,1,1) or Color3.fromRGB(150,150,150))
	end

	-- Button State
	if btn then
		if btn:GetAttribute("Conn") then
			local new = btn:Clone()
			new.Parent = panel
			btn:Destroy()
			btn = new
		end
		btn:SetAttribute("Conn", true)

		if canClaim then
			btn.Text = "TAKE IT"
			btn.BackgroundColor3 = THEME.Colors.BloodRed
			btn.Visible = true
			btn.MouseButton1Click:Connect(function() attemptScratch(day) end)
		else
			btn.Text = "TAKEN"
			btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
			btn.Visible = true -- Keep visible to show status
		end
	end
end

function attemptScratch(day)
	if not claimRewardEvent then return end

	local panel = mainContainer:FindFirstChild("StashFrame")
	local btn = panel:FindFirstChild("ClaimBtn")

	-- Animate "Taking"
	btn.Text = "TAKING..."

	local success, result = pcall(function() return claimRewardEvent:InvokeServer() end)

	if success and result and result.Success then
		btn.Text = "GOT IT"
		btn.BackgroundColor3 = THEME.Colors.SafeGreen

		-- Find the grid cell and cross it out
		local grid = mainContainer:FindFirstChild("CalendarGrid")
		-- We need to find the specific cell that corresponds to the day claimed (result.NextDay - 1)
		local targetDay = result.NextDay - 1
		for _, c in ipairs(grid:GetChildren()) do
			if c:IsA("Frame") and c:FindFirstChild("TextLabel") and c.TextLabel.Text == tostring(targetDay) then
				-- Animate Blood Cross appearing
				local cross = addBloodCross(c)
				cross.Size = UDim2.new(0,0,0,0)
				cross.Position = UDim2.new(0.5,0,0.5,0)
				TweenService:Create(cross, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0)}):Play()
				break
			end
		end

		task.wait(1)

		populateCalendar(result.NextDay, false)
		updateStash(result.NextDay - 1, false) 
	else
		btn.Text = "FAILED"
		task.wait(1)
		btn.Text = "TAKE IT"
	end
end

local function loadData()
	if isOpening then return end
	isOpening = true

	resolveRemotes()
	if not getRewardInfo then isOpening = false return end

	local success, result = pcall(function() return getRewardInfo:InvokeServer() end)

	if success and result then
		createDailyRewardUI()
		gui.Enabled = true

		populateCalendar(result.CurrentDay, result.CanClaim)
		updateStash(result.CurrentDay, result.CanClaim)

		-- Fade In
		mainContainer.GroupTransparency = 1
		TweenService:Create(mainContainer, TweenInfo.new(1.0), {GroupTransparency = 0}):Play()
	end
	isOpening = false
end

-- ================== HUD BUTTON ==================
local function createHUD()
	if playerGui:FindFirstChild("DailyRewardHUD") then playerGui.DailyRewardHUD:Destroy() end

	local hud = create("ScreenGui", {Name = "DailyRewardHUD", Parent = playerGui, ResetOnSpawn = false})

	openButton = create("TextButton", {
		Parent = hud, Size = UDim2.new(0, 70, 0, 70), Position = UDim2.new(0, 20, 0.5, 0),
		BackgroundColor3 = THEME.Colors.WallBase, Text = "", BorderSizePixel = 0
	})
	addCorner(openButton, 12)
	addStroke(openButton, THEME.Colors.ChalkWhite, 3)

	create("TextLabel", {
		Parent = openButton, Size = UDim2.new(1,0,0.6,0), Position = UDim2.new(0,0,0.2,0),
		Text = "DAYS", Font = THEME.Fonts.Handwritten, TextSize = 24, TextColor3 = THEME.Colors.ChalkWhite, BackgroundTransparency = 1
	})

	openButton.MouseButton1Click:Connect(loadData)
end

createHUD()
print("DailyRewardUI (Calendar Theme) Loaded")
