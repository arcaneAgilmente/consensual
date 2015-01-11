local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.DeviceInput.button == "DeviceButton_w" then
	elseif event.DeviceInput.button == "DeviceButton_s" then
	elseif event.DeviceInput.button == "DeviceButton_d" then
	elseif event.DeviceInput.button == "DeviceButton_a" then
	elseif event.DeviceInput.button == "DeviceButton_q" then
	elseif event.DeviceInput.button == "DeviceButton_e" then
	elseif event.DeviceInput.button == "DeviceButton_x" then
	elseif event.DeviceInput.button == "DeviceButton_z" then
	elseif event.DeviceInput.button == "DeviceButton_c" then
	elseif event.DeviceInput.button == "DeviceButton_v" then
	end
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
}

return Def.ActorFrame(args)
