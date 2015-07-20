local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
	for i= 1, #channel_keys do
		if button == channel_keys[i][1] then
			channel_mod(channel_keys[i][2], channel_keys[i][3])
		end
	end
end

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
		self:SetUpdateFunction(update_nps)
	end,
}

return Def.ActorFrame(args)
