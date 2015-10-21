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
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			text= self:DiffuseAndStroke(fetch_color("text"), fetch_color("stroke"))
		end
	},
	Def.ActorFrame{
			circle_amv("circlekyz1", _screen.cx, _screen.cy, 40, 6, fetch_color("accent.red")),
			circle_amv("circle2", _screen.cx, _screen.cy-20, 40, 8, fetch_color("accent.orange")),
			circle_amv("circle3", _screen.cx, _screen.cy-40, 40, 10, fetch_color("accent.yellow")),
			circle_amv("circle4", _screen.cx, _screen.cy-60, 40, 12, fetch_color("accent.green")),
			circle_amv("circle5", _screen.cx, _screen.cy-80, 40, 14, fetch_color("accent.cyan")),
			InitCommand= function(self)
				self:GetChild("circlekyz1"):diffusealpha(1)
				self:GetChild("circle2"):diffusealpha(.9)
				self:GetChild("circle3"):diffusealpha(.8)
				self:GetChild("circle4"):diffusealpha(.7)
				self:GetChild("circle5"):diffusealpha(.6)
			end
	},
	Def.BitmapText{
		Font= "Common Normal", Text= "ATTR_TEST", InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy)
				:diffuseupperleft{.5, .5, .5, 1}
				:diffuseupperright{.75, .25, .75, 1}
				:diffuselowerleft{.75, .75, .25, 1}
				:diffuselowerright{.25, .75, .75, 1}
				:AddAttribute(2, {Length= 4, Diffuses= {{.75, 0, 0, 1}, {0, .75, 0, 1}, {0, 0, .75, 1}, {.75, .75, .75, 1}}})
				:set_mult_attrs_with_diffuse(true)
		end
	},
	Def.Sprite{
		Texture= THEME:GetPathG("", "sleep_soon.png"),
		InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy)
				:visible(false)
				:texcoordvelocity(1/4, 1/64)
		end
	},
}

return Def.ActorFrame(args)
