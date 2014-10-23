local h= 24
local w= 96
local t= 2
local cursolor= fetch_color("player.p2")
local curalor= fetch_color("player.hilight")

local cursor= setmetatable({}, cursor_mt)

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.DeviceInput.button == "DeviceButton_w" then
		cursor:refit(cursor.x, cursor.y - 10)
	elseif event.DeviceInput.button == "DeviceButton_a" then
		cursor:refit(cursor.x - 10, cursor.y)
	elseif event.DeviceInput.button == "DeviceButton_s" then
		cursor:refit(cursor.x, cursor.y + 10)
	elseif event.DeviceInput.button == "DeviceButton_d" then
		cursor:refit(cursor.x + 10, cursor.y)
	elseif event.DeviceInput.button == "DeviceButton_i" then
		cursor:refit(nil, nil, cursor.w, cursor.h - 4)
	elseif event.DeviceInput.button == "DeviceButton_j" then
		cursor:refit(nil, nil, cursor.w - 4, cursor.h)
	elseif event.DeviceInput.button == "DeviceButton_k" then
		cursor:refit(nil, nil, cursor.w, cursor.h + 4)
	elseif event.DeviceInput.button == "DeviceButton_l" then
		cursor:refit(nil, nil, cursor.w + 4, cursor.h)
	elseif event.DeviceInput.button == "DeviceButton_c" then
		cursor:left_half()
	elseif event.DeviceInput.button == "DeviceButton_n" then
		cursor:right_half()
	elseif event.DeviceInput.button == "DeviceButton_v" then
		cursor:un_half()
	end
end

local args= {
	OnCommand= function(self)
		cursor:refit(nil, nil, 96, 24)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	cursor:create_actors("cursor", _screen.cx, _screen.cy, 2, cursolor, curalor,
	false, true),
}

return Def.ActorFrame(args)
