dofile(THEME:GetPathO("", "art_helpers.lua"))

local valtex_buttons= {
	CenterImageAddWidth= {"d", "a"},
	CenterImageAddHeight= {"w", "s"},
	CenterImageTranslateX= {"l", "j"},
	CenterImageTranslateY= {"k", "i"},
}
local valtex= {}
local function change_center_val(valname, amount)
	local new_val= PREFSMAN:GetPreference(valname) + amount
	PREFSMAN:SetPreference(valname, new_val)
	valtex[valname]:settext(new_val)
	update_centering()
end

local valtex_frames= {}
local widest_name= 0
local function valtexact(name, x, y, c)
	return Def.ActorFrame{
		InitCommand= function(self)
			valtex_frames[name]= self
			local name_w= self:GetChild("Name"):GetWidth()
			if name_w > widest_name then widest_name= name_w end
			self:y(y)
			for frame_name, frame in pairs(valtex_frames) do
				frame:playcommand("recenter")
			end
		end,
		recenterCommand= function(self)
			self:x(x + (widest_name / 2))
		end,
		Def.BitmapText{
			Font= "Common Normal", Name= "Value", InitCommand= function(self)
				valtex[name]= self:x(4):settext(PREFSMAN:GetPreference(name))
					:horizalign(left)
			end,
		},
		Def.BitmapText{
			Font= "Common Normal", Name= "Name", InitCommand= function(self)
				self:x(-4):settext(
					name .. "(" .. valtex_buttons[name][1] .. " or " ..
						valtex_buttons[name][2] .. "): ")
					:horizalign(right):diffuse(c)
			end,
		},
	}
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
	for valname, button_set in pairs(valtex_buttons) do
		if button == button_set[1] then
			change_center_val(valname, 1)
		elseif button == button_set[2] then
			change_center_val(valname, -1)
		end
	end
end

local function quaid(x, y, w, h, c, ha, va)
	return Def.Quad{
		InitCommand= function(self)
			self:xy(x, y):setsize(w, h):diffuse(c):horizalign(ha):vertalign(va)
		end
	}
end

local red= color("#ff0000")
local blue= color("#0000ff")

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	quaid(0, 0, _screen.w, 1, red, left, top),
	quaid(0, _screen.h, _screen.w, 1, red, left, bottom),
	quaid(0, 0, 1, _screen.h, blue, left, top),
	quaid(_screen.w, 0, 1, _screen.h, blue, right, top),
	valtexact("CenterImageAddHeight", _screen.cx, _screen.cy-36, red),
	valtexact("CenterImageAddWidth", _screen.cx, _screen.cy-12, blue),
	valtexact("CenterImageTranslateX", _screen.cx, _screen.cy+12, blue),
	valtexact("CenterImageTranslateY", _screen.cx, _screen.cy+36, red),
}

return Def.ActorFrame(args)
