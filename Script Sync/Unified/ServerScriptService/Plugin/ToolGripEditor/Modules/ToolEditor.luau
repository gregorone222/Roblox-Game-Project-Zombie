local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local Players = game:GetService("Players")

local Modules = script.Parent
local UI = require(Modules.UI)
local Project = Modules.Parent

local ToolEditor = {}
ToolEditor.__index = ToolEditor

function ToolEditor:_createNewDummy(rigType)
	if self.Dummy then
		self.Dummy:Destroy()
	end

	local hDesc
	if rigType == "R15" and self.ActiveHumanoidDescription then
		hDesc = self.ActiveHumanoidDescription
	else -- For R6, or initial R15 creation, use a plain description
		hDesc = Instance.new("HumanoidDescription")
		local gray = BrickColor.new(-1).Color
		for _,limb in pairs(Enum.BodyPart:GetEnumItems()) do
			hDesc[limb.Name .. "Color"] = gray
		end
	end

	local success, dummy = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(hDesc, rigType)
	end)

	if not success or not dummy then
		warn("Tool Grip Editor: Failed to create humanoid model")
		return
	end

	local humanoid = dummy:WaitForChild("Humanoid")

	-- Avoid unintended script injection.
	if dummy:FindFirstChild("Animate") then
		dummy.Animate:Destroy()
	end

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	local worldModel = self.WorldModel
	if not worldModel then
		worldModel = Instance.new("WorldModel")
		self.WorldModel = worldModel
	end
	dummy.Parent = worldModel

	local rootPart = humanoid.RootPart
	rootPart.Anchored = true

	self.Dummy = dummy
	self.Humanoid = humanoid
	self.RootPart = rootPart
	self.Animator = animator

	self:StartAnimations()
end

function ToolEditor.new()
	local editor = 
		{
			RigType = "R15",
			ActiveHumanoidDescription = nil,
			ZoomMultiplier = 1,


		}

	setmetatable(editor, ToolEditor)
	editor:_createNewDummy("R15")
	return editor
end

function ToolEditor:SetParent(parent)
	local worldModel = self.WorldModel
	worldModel.Parent = parent
end

function ToolEditor:FindObject(className, name)
	local dummy = self.Dummy
	local child = dummy:FindFirstChild(name, true)

	if child and child:IsA(className) then
		return child
	end
end

function ToolEditor:FindLimb(limbName)
	return self:FindObject("BasePart", limbName)
end

function ToolEditor:FindJoint(jointName)
	return self:FindObject("JointInstance", jointName)
end

function ToolEditor:FindAttachment(attName)
	return self:FindObject("Attachment", attName)
end

function ToolEditor:GetCameraZoom()
	local handle = self.Handle
	local baseZoom

	if handle then
		local size = handle.Size
		baseZoom = math.max(4, size.Magnitude * 1.5)
	else
		local cf, size = self.Dummy:GetBoundingBox()
		baseZoom = size.Magnitude
	end

	return baseZoom * self.ZoomMultiplier
end

function ToolEditor:AdjustZoom(scrollDelta)
	local currentMultiplier = self.ZoomMultiplier
	local newMultiplier = currentMultiplier - (scrollDelta * 0.1)
	self.ZoomMultiplier = math.clamp(newMultiplier, 0.5, 2)
end

function ToolEditor:StepAnimator(delta)
	local animator = self.Animator
	animator:StepAnimations(delta)
end

function ToolEditor:ApplyDescription(hDesc)
	self.ActiveHumanoidDescription = hDesc
	-- Only R15 rigs can have descriptions applied in this way.
	if self.RigType == "R15" then
		local humanoid = self.Humanoid
		humanoid:ApplyDescription(hDesc)
	end
end

function ToolEditor:SwitchRigType()
	local currentTool = self.Tool
	self:ClearTool()

	local newRigType = (self.RigType == "R15") and "R6" or "R15"
	self.RigType = newRigType

	self:_createNewDummy(newRigType)

	if currentTool then
		self:BindTool(currentTool)
	end

	return newRigType
end

function ToolEditor:StartAnimations()
	local anims = Project:WaitForChild("Animations")[self.RigType]
	local animator = self.Animator

	for _,track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	self.CustomAnimationTrack = nil

	for _,animDef in pairs(anims:GetChildren()) do
		local anim = UI.create(require(animDef))
		local track = animator:LoadAnimation(anim)
		track:Play()
	end
end

function ToolEditor:PlayAnimation(animationId)
	self:StopCustomAnimation()

	local animator = self.Animator

	-- Stop all default animations first
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	local success, animation = pcall(function()
		local anim = Instance.new("Animation")
		anim.AnimationId = animationId
		return anim
	end)

	if not success then
		return false, "Invalid AnimationId format"
	end

	local loaded, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	animation:Destroy()

	if not loaded then
		return false, "Failed to load animation. Check permissions and ID."
	end

	self.CustomAnimationTrack = track
	track.Looped = true
	track:Play()

	return true
end

function ToolEditor:StopCustomAnimation()
	if self.CustomAnimationTrack then
		self.CustomAnimationTrack:Stop()
		self.CustomAnimationTrack:Destroy()
		self.CustomAnimationTrack = nil
	end

	-- Restart the default animations
	self:StartAnimations()
end

function ToolEditor:Connect(name, event)
	return event:Connect(function (...)
		self[name](self, ...)
	end)
end

function ToolEditor:BindProperty(object, property, funcName)
	local event = object:GetPropertyChangedSignal(property)
	return self:Connect(funcName, event)
end

function ToolEditor:RefreshGrip()
	local rightGrip = self.RightGrip
	local handle = self.Handle
	local tool = self.Tool

	if rightGrip and handle then
		local grip = tool.Grip
		rightGrip.C1 = grip
	end
end

function ToolEditor:ReflectGrip()
	local tool = self.Tool
	local gripEditor = self.GripEditor

	if tool and gripEditor then
		local newCFrame = gripEditor.CFrame
		tool.Grip = newCFrame


	end
end




function ToolEditor:ClearTool()

	if self.GripRefresh then
		self.GripRefresh:Disconnect()
		self.GripRefresh = nil
	end

	if self.GripReflect then
		self.GripReflect:Disconnect()
		self.GripReflect = nil
	end

	if self.Handle then
		self.Handle:Destroy()
		self.Handle = nil
	end

	if self.GripEditor then
		self.GripEditor:Destroy()
		self.GripEditor = nil
	end

	self:StopCustomAnimation()

	if self.RightGrip then
		self.RightGrip.Part1 = nil
	end

	self.Tool = nil
	self.ZoomMultiplier = 1
end

function ToolEditor:CreateGhostArm()
	local dummy = self.Dummy:Clone()
	local humanoid = dummy.Humanoid

	for _,child in pairs(dummy:GetChildren()) do
		if child:IsA("BasePart") then
			local limb = humanoid:GetLimb(child)

			if limb.Name == "RightArm" then
				child:ClearAllChildren()
				child.Anchored = true
				child.Locked = true

				if child.Name == "RightHand" then
					dummy.PrimaryPart = child
				end
			else
				child:Destroy()
			end
		elseif child:IsA("Accoutrement") then
			child:Destroy()
		end
	end

	dummy.Archivable = false
	dummy.Name = "PreviewArm"

	return dummy
end

function ToolEditor:BindTool(tool)
	if tool == nil then
		self:ClearTool()
		return false
	end

	if self.Tool == tool then
		return true
	elseif self.Tool ~= nil then
		self:ClearTool()
	end

	local dummy = self.Dummy
	local handle = tool:FindFirstChild("Handle")

	if not (handle and handle:IsA("BasePart")) then
		return
	end

	local part0Name = (self.RigType == "R15") and "RightHand" or "Right Arm"
	local rightHand = self:FindLimb(part0Name)
	local rightGrip = self.RightGrip

	if not (rightGrip and rightGrip:IsDescendantOf(dummy)) then
		local gripAtt = self:FindAttachment("RightGripAttachment")

		rightGrip = Instance.new("Motor6D")
		rightGrip.C0 = gripAtt.CFrame
		rightGrip.Name = "RightGrip"
		rightGrip.Part0 = rightHand
		rightGrip.Parent = rightHand

		self.RightGrip = rightGrip
	end

	local newHandle = handle:Clone()
	newHandle.Parent = self.Dummy

	for _,joint in pairs(newHandle:GetJoints()) do
		joint:Destroy()
	end

	for _,child in pairs(newHandle:GetChildren()) do
		if child:IsA("Sound") then
			child.PlayOnRemove = false
		end
	end

	newHandle.Locked = true
	newHandle.Anchored = false
	rightGrip.Part1 = newHandle

	local gripEditor = Instance.new("Attachment")
	gripEditor.Archivable = false
	gripEditor.CFrame = tool.Grip
	gripEditor.Name = "Grip"

	for _,part in pairs(tool:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		if part == handle then
			continue
		end

		if not part:IsDescendantOf(tool) then
			continue
		end

		local copy = part:Clone()
		copy.Anchored = false
		copy.Locked = true
		copy.Parent = newHandle

		for _,joint in pairs(copy:GetJoints()) do
			joint:Destroy()
		end

		local weld = Instance.new("Weld")
		weld.C0 = handle.CFrame:ToObjectSpace(part.CFrame)
		weld.Part0 = newHandle
		weld.Part1 = copy
		weld.Parent = copy
	end

	self.GripRefresh = self:BindProperty(tool, "Grip", "RefreshGrip")
	self.GripReflect = self:BindProperty(gripEditor, "CFrame", "ReflectGrip")

	self.GripEditor = gripEditor
	self.DirectHandle = handle

	self.Handle = newHandle
	self.Tool = tool

	self:RefreshGrip()

	return (self.Handle ~= nil)
end

function ToolEditor:EditGrip(plugin)
	local tool = self.Tool
	local handle = self.Handle

	local gripEditor = self.GripEditor
	local directHandle = self.DirectHandle

	if tool and handle and gripEditor then
		local editor = Instance.new("Model")
		editor.Name = "Tool Grip Editor"
		editor.Archivable = false
		editor.Parent = workspace

		local proxyHandle = handle:Clone()
		proxyHandle.Locked = true
		proxyHandle.Anchored = true
		proxyHandle.Parent = editor

		for _,desc in pairs(proxyHandle:GetDescendants()) do
			if desc:IsA("BasePart") then
				if tool:IsDescendantOf(workspace) then
					desc:Destroy()
				else 
					desc.Locked = true
					desc.Anchored = true
					desc.Parent = editor
				end
			end
		end

		gripEditor.Parent = proxyHandle
		editor.PrimaryPart = proxyHandle
		editor:PivotTo(directHandle.CFrame)

		local camera = workspace.CurrentCamera
		self.InUse = true

		if camera then
			local cf = camera.CFrame
			local focus = gripEditor.WorldPosition

			local lookVector = cf.LookVector
			local extents = handle.Size.Magnitude

			camera.CFrame = CFrame.new(focus - (lookVector * extents * 1.5), focus)
			camera.Focus = CFrame.new(focus)
		end

		if tool:IsDescendantOf(workspace) then
			proxyHandle.Transparency = 1

			for _,child in pairs(proxyHandle:GetChildren()) do
				if child ~= gripEditor then
					if child:IsA("Sound") then
						child.PlayOnRemove = false
					end

					child:Destroy()
				end
			end
		end

		local ghostArm = self:CreateGhostArm()
		ghostArm.Parent = editor

		self.GhostArm = ghostArm
		Selection:Set{gripEditor}

		if plugin:GetSelectedRibbonTool() ~= Enum.RibbonTool.Move then
			plugin:SelectRibbonTool("Move", UDim2.new())
		end

		ChangeHistoryService:SetWaypoint("Begin Grip Edit")
		Selection.SelectionChanged:Wait()

		gripEditor.Parent = nil
		ghostArm.Parent = nil

		self.GhostArm = nil
		self.InUse = false

		ChangeHistoryService:SetWaypoint("End Grip Edit")
		editor:Destroy()
	end
end

-----------------------------------------------------------
-- TODO: If this module is ever constructed multiple times
--       then return the ToolEditor table itself. At the
--       present moment, it acts more like a singleton.
-----------------------------------------------------------

return ToolEditor.new()