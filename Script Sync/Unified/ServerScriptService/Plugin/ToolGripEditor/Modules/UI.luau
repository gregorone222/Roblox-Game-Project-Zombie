--!nonstrict
local UI = {}

function UI.create(obj)
	local inst = Instance.new(obj.ClassName)

	if obj.Properties then
		for prop, value in pairs(obj.Properties) do
			pcall(function()
				if prop == "SliceCenter" and typeof(value) == "table" then
					inst[prop] = Rect.new(value.min, value.max)
				else
					inst[prop] = value
				end
			end)
		end
	end

	if obj.Children then
		for _, childObj in ipairs(obj.Children) do
			local childInst = UI.create(childObj)
			childInst.Parent = inst
		end
	end

	return inst
end

return UI