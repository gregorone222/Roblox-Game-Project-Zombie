-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby
-- Theme: Survival Backpack (Grid Canvas, Fabric Texture, Straps)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- --- UI CREATION (Immediate) ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10 -- Ensure it's on top of other lobby UIs
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Initialize Blur Effect
local camera = workspace.CurrentCamera
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "InventoryBlur"
blurEffect.Size = 0
blurEffect.Enabled = false
blurEffect.Parent = camera

-- Module & Event References
local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))

-- Safe Remote Retrieval
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
local inventoryRemote
if RemoteFunctions then
	inventoryRemote = RemoteFunctions:WaitForChild("GetInventoryData", 5)
else
	warn("InventoryUI: RemoteFunctions folder not found!")
end

local skinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SkinManagementEvent", 5)

-- --- THEME CONFIGURATION ---
local THEME = {

-- Zipper Top
local zipper = Instance.new("Frame")
zipper.Size = UDim2.new(1, 0, 0, 10)
zipper.Position = UDim2.new(0, 0, 0.12, -5)
zipper.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
zipper.BorderSizePixel = 0
zipper.ZIndex = 105
zipper.Parent = mainPanel

-- Close Button (Zipper Pull)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 60)
closeBtn.Position = UDim2.new(0.95, 0, 0, -20)
closeBtn.BackgroundColor3 = THEME.COLORS.ACCENT_ZIP
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(0,0,0)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 110
closeBtn.Parent = zipper
addCorner(closeBtn, 15)

-- Content Container
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -100)
content.Position = UDim2.new(0, 20, 0, 80)
content.BackgroundTransparency = 1
content.ZIndex = 102
content.Parent = mainPanel

-- 1. Sidebar (Straps)
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 200, 1, 0)
sidebar.BackgroundTransparency = 1
sidebar.Parent = content

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = sidebar

local function createTab(name)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 50)
	btn.BackgroundColor3 = THEME.COLORS.STRAP
	btn.Text = name:upper()
	btn.TextColor3 = THEME.COLORS.TEXT_MAIN
	btn.Font = THEME.FONTS.HEADER
	btn.TextSize = 18
	btn.Parent = sidebar
	addCorner(btn, 8)
	addStitching(btn)
	return btn
end

local tWeapons = createTab("Weapons")
-- local tBoosters = createTab("Boosters") -- Disabled for now until logic verified

-- 2. Grid Area (Pockets)
local gridArea = Instance.new("Frame")
gridArea.Size = UDim2.new(1, -220, 1, 0)
gridArea.Position = UDim2.new(0, 220, 0, 0)
gridArea.BackgroundTransparency = 1
gridArea.Parent = content

-- Filter Pockets
local filterRow = Instance.new("ScrollingFrame")
filterRow.Size = UDim2.new(1, 0, 0, 40)
filterRow.BackgroundTransparency = 1
filterRow.ScrollBarThickness = 0
filterRow.ScrollingDirection = Enum.ScrollingDirection.X
filterRow.CanvasSize = UDim2.new(2,0,0,0) -- Expandable
filterRow.Parent = gridArea

local fl = Instance.new("UIListLayout")
fl.FillDirection = Enum.FillDirection.Horizontal
fl.Padding = UDim.new(0, 5)
fl.Parent = filterRow

-- Item Grid (Mesh Mesh Pockets)
local itemGrid = Instance.new("ScrollingFrame")
itemGrid.Size = UDim2.new(0.6, 0, 1, -50)
itemGrid.Position = UDim2.new(0, 0, 0, 50)
itemGrid.BackgroundColor3 = THEME.COLORS.POCKET_BG
itemGrid.BackgroundTransparency = 0.5
itemGrid.BorderSizePixel = 0
itemGrid.Parent = gridArea
addCorner(itemGrid, 8)

local igl = Instance.new("UIGridLayout")
igl.CellSize = UDim2.new(0, 100, 0, 100)
igl.CellPadding = UDim2.new(0, 10, 0, 10)
igl.Parent = itemGrid
local igp = Instance.new("UIPadding")
igp.PaddingTop = UDim.new(0, 10)
igp.PaddingLeft = UDim.new(0, 10)
igp.Parent = itemGrid

-- 3. Inspector Panel (Detailed Pocket)
local inspector = Instance.new("Frame")
inspector.Size = UDim2.new(0.38, 0, 1, -50)
inspector.Position = UDim2.new(0.62, 0, 0, 50)
inspector.BackgroundColor3 = THEME.COLORS.POCKET_DARK
inspector.Parent = gridArea
addCorner(inspector, 8)
addStitching(inspector)

local vp = Instance.new("ViewportFrame")
vp.Size = UDim2.new(1, 0, 0.5, 0)
vp.BackgroundTransparency = 1
vp.Parent = inspector

local info = Instance.new("Frame")
info.Size = UDim2.new(1, -20, 0.5, -20)
info.Position = UDim2.new(0, 10, 0.5, 10)
info.BackgroundTransparency = 1
info.Parent = inspector

local iName = Instance.new("TextLabel")
iName.Size = UDim2.new(1,0,0,30)
iName.BackgroundTransparency = 1
iName.Text = "SELECT ITEM"
iName.TextColor3 = THEME.COLORS.TEXT_MAIN
iName.Font = THEME.FONTS.TITLE
iName.TextSize = 24
iName.TextXAlignment = Enum.TextXAlignment.Left
iName.Parent = info

local equipBtn = Instance.new("TextButton")
equipBtn.Size = UDim2.new(1, 0, 0, 50)
equipBtn.Position = UDim2.new(0, 0, 1, 0)
equipBtn.AnchorPoint = Vector2.new(0, 1)
equipBtn.BackgroundColor3 = THEME.COLORS.ACCENT_ZIP
equipBtn.Text = "EQUIP"
equipBtn.Font = THEME.FONTS.HEADER
equipBtn.TextSize = 20
equipBtn.TextColor3 = THEME.COLORS.TEXT_DARK
equipBtn.Parent = info
addCorner(equipBtn, 8)


-- --- LOGIC ---

local CATEGORIES = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Pistol", "LMG"}

function updateDetails(id)
	if not WeaponModule or not WeaponModule.Weapons then return end
	local data = WeaponModule.Weapons[id]
	if not data then return end
	iName.Text = data.DisplayName or id

	if currentPreview then ModelPreviewModule.destroy(currentPreview) end

	-- Default skin preview
	local sData = nil
	if data.Skins then
		-- Cari skin default atau skin yang sedang dipakai (logika sederhana ambil first)
		for k, v in pairs(data.Skins) do
			if k == "Default Skin" then sData = v break end
		end
		if not sData then -- Fallback
			local k, v = next(data.Skins)
			sData = v
		end
	end

	if sData then
		currentPreview = ModelPreviewModule.create(vp, data, sData)
		ModelPreviewModule.startRotation(currentPreview, 1)
	end
end

function updateWeaponList()
	-- Clean grid
	for _, c in ipairs(itemGrid:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	if not WeaponModule or not WeaponModule.Weapons then
		warn("InventoryUI: WeaponModule not loaded correctly.")
		return
	end

	local list = {}
	for id, data in pairs(WeaponModule.Weapons) do
		local match = false
		if selectedCategory == "All" then
			match = true
		elseif data.Category then
			-- Flexible matching (e.g. Assault Rifle contains Rifle)
			if string.find(string.lower(data.Category), string.lower(selectedCategory)) then
				match = true
			end
		end

		if match then
			table.insert(list, {id=id, name=data.DisplayName or id})
		end
	end
	table.sort(list, function(a,b) return a.name < b.name end)

	for _, w in ipairs(list) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = (w.id == selectedWeapon) and THEME.COLORS.HIGHLIGHT or THEME.COLORS.POCKET_BG
		btn.Text = ""
		btn.Parent = itemGrid
		addCorner(btn, 6)
		addStitching(btn)

		local lb = Instance.new("TextLabel")
		lb.Size = UDim2.new(1,0,1,0)
		lb.BackgroundTransparency = 1
		lb.Text = string.sub(w.name, 1, 2)
		lb.TextSize = 30
		lb.Font = THEME.FONTS.HEADER
		lb.TextColor3 = (w.id == selectedWeapon) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN
		lb.Parent = btn

		-- Full name label small at bottom
		local nameLb = Instance.new("TextLabel")
		nameLb.Size = UDim2.new(1,0,0,20)
		nameLb.Position = UDim2.new(0,0,1,-20)
		nameLb.BackgroundTransparency = 1
		nameLb.Text = w.name
		nameLb.TextSize = 10
		nameLb.Font = THEME.FONTS.BODY
		nameLb.TextColor3 = (w.id == selectedWeapon) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN
		nameLb.Parent = btn

		btn.MouseButton1Click:Connect(function()
			selectedWeapon = w.id
			updateWeaponList()
			updateDetails(w.id)
		end)
	end
end

local function updateFilters()
	for _, c in ipairs(filterRow:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, cat in ipairs(CATEGORIES) do
		local b = Instance.new("TextButton")
		b.Text = cat
		b.Size = UDim2.new(0, 80, 1, 0)
		b.BackgroundColor3 = (selectedCategory == cat) and THEME.COLORS.HIGHLIGHT or THEME.COLORS.STRAP
		b.TextColor3 = (selectedCategory == cat) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN
		b.Font = THEME.FONTS.BODY
		b.Parent = filterRow
		addCorner(b, 4)
		b.MouseButton1Click:Connect(function()
			selectedCategory = cat
			updateFilters()
			if currentTab == "Weapons" then updateWeaponList() end
		end)
	end
end

-- --- MAIN EVENTS ---
openButton.MouseButton1Click:Connect(function()
	print("InventoryUI: Open Button Clicked")
	mainPanel.Visible = true
	mainPanel.Size = UDim2.new(0.5,0,0.5,0)
	mainPanel:TweenSize(UDim2.new(0.85,0,0.85,0), "Out", "Back", 0.3, true)
	openButton.Visible = false

	-- Enable Blur
	if blurEffect then
		blurEffect.Enabled = true
		TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 15}):Play()
	end

	updateFilters()
	updateWeaponList()
end)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	openButton.Visible = true

	-- Disable Blur
	if blurEffect then
		TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
		task.delay(0.3, function() blurEffect.Enabled = false end)
	end
end)

tWeapons.MouseButton1Click:Connect(function() 
	currentTab="Weapons" 
	itemGrid.Visible=true 
	inspector.Visible=true 
	updateWeaponList() 
end)

-- Initial Data Load
task.spawn(function()
	if inventoryRemote then
		local s, d = pcall(function() return inventoryRemote:InvokeServer() end)
		if s then
			inventoryData = d
		else
			warn("InventoryUI: Failed to fetch data from server.")
		end
	end
end)

return {}
