local text= false
local input_list= {}

local mapping_menu_row= {
	__index= {
		create_actors= function(self)
			end
}}

local function input(event)
	if event.type == "InputEventType_Release" then return end
	input_list[#input_list+1]= event.DeviceInput
end

local function draw()
	local start_y= -24
	local spacing= 48
	for i, event in ipairs(input_list) do
		text:settext(event.device .. "\n" .. event.button .. ", L:" ..
									 event.level .. ", Z:" .. event.z .. ", " ..
									 tostring(event.down) ..
									 ", J:" .. tostring(event.is_joystick) .. ", M:" ..
									 tostring(event.is_mouse))
			:xy(_screen.cx, start_y + (i * spacing)):Draw()
	end
	input_list= {}
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
--		self:SetDrawFunction(draw)
	end,
	--[[
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			text= self:DiffuseAndStroke(fetch_color("text"), fetch_color("stroke"))
		end
	},
	]]
	Def.Sprite{
		Texture= THEME:GetPathG("", "sleep_soon.png"),
		InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy)
				:texcoordvelocity(1/4, 1/64)
		end
	},
}

return Def.ActorFrame(args)
