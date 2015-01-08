local strip_verts= 132
local spline_verts= 16
local vert_text= false
local spl_text= false
local amv= false

dofile(THEME:GetPathO("", "art_helpers.lua"))

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.DeviceInput.button == "DeviceButton_w" then
	elseif event.DeviceInput.button == "DeviceButton_s" then
	elseif event.DeviceInput.button == "DeviceButton_d" then
	elseif event.DeviceInput.button == "DeviceButton_a" then
	elseif event.DeviceInput.button == "DeviceButton_x" then
	elseif event.DeviceInput.button == "DeviceButton_z" then
	elseif event.DeviceInput.button == "DeviceButton_c" then
	elseif event.DeviceInput.button == "DeviceButton_l" then
	elseif event.DeviceInput.button == "DeviceButton_o" then
	end
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			vert_text= self
			self:xy(_screen.cx, 20):diffuse(fetch_color("text"))
		end
	},
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			spl_text= self
			self:xy(_screen.cx, 44):diffuse(fetch_color("text"))
		end
	},
	Def.ActorMultiVertex{
		InitCommand= function(self)
			amv= self
			self:xy(_screen.cx, _screen.cy)
				:SetDrawState{Mode="DrawMode_LineStrip"}
				:SetNumVertices(strip_verts)
			for i= 1, strip_verts do
				self:SetVertex(i, {wrapping_number_to_color(i)})
			end
		end
	},
}

return Def.ActorFrame(args)
