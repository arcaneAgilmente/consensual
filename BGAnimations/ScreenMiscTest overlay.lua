dofile(THEME:GetPathO("", "strokes.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
end

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	animated_text("Consensual", _screen.cx, _screen.cy, 4, 4, 10)
}

return Def.ActorFrame(args)
