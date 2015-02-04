local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.DeviceInput.button == "DeviceButton_w" then
	elseif event.DeviceInput.button == "DeviceButton_w" then
	end
end

local white= {1, 1, 1, 1}

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
}

return Def.ActorFrame(args)
