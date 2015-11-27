local text= false
local input_list= {}

local mapping_menu_row= {
	__index= {
		create_actors= function(self)
			end
}}

local movie= false

local function input(event)
	if event.type == "InputEventType_Release" then return end
	--input_list[#input_list+1]= event.DeviceInput
	if event.type == "InputEventType_FirstPress" then
		if event.DeviceInput.button == "DeviceButton_a" then
			movie:SetSecondsIntoAnimation(10)
		elseif event.DeviceInput.button == "DeviceButton_s" then
			movie:SetSecondsIntoAnimation(20)
		elseif event.DeviceInput.button == "DeviceButton_s" then
			movie:SetSecondsIntoAnimation(30)
		elseif event.DeviceInput.button == "DeviceButton_d" then
			movie:SetSecondsIntoAnimation(40)
		elseif event.DeviceInput.button == "DeviceButton_f" then
			movie:SetSecondsIntoAnimation(50)
		elseif event.DeviceInput.button == "DeviceButton_g" then
			movie:decode_second(10)
		end
	end
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
				self:visible(false)
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
				:AddAttribute(2, {Length= 4, Diffuses= {{.75, 0, 0, 1}, {0, .75, 0, 1}, {0, 0, .75, 1}, {.75, .75, .75, 1}}, Glow= {.9, 0, 0, .5}})
--				:set_mult_attrs_with_diffuse(true)
				:glow{.5, .5, .5, .5}
				:textglowmode("TextGlowMode_Both")
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
	Def.Sprite{
		Texture= THEME:GetPathG("", "grades/default_grades"),
		Mask= THEME:GetPathG("", "grades/grade_mask"),
		InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy)
				:animate(false):setstate(0):SetTextureFiltering(false):zoom(4/2.5)
--				:set_mask_color{.75, .125, .675, .25}
		end
	},
	Def.Sprite{
		Texture= THEME:GetPathG("", "tash"),
		InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy)
			movie= self
		end
	},
	--LoadActor(THEME:GetPathO("", "DDRKonamixBGAnimation110A/default")),
}

--[[
local spacing= 160
local scaled_args= {}
local display_height= DISPLAY:GetDisplayHeight()
local display_scale= _screen.h / display_height
local x_count= math.ceil(DISPLAY:GetDisplayWidth() / spacing)
local y_count= math.ceil(DISPLAY:GetDisplayHeight() / spacing)
for x= 1, x_count do
	for y= 1, y_count do
		scaled_args[#scaled_args+1]= LoadActor(THEME:GetPathO("", "DDRKonamixBGAnimation110A/2"))..{
			InitCommand= function(self)
				local curr_x= (x-.5) * spacing * display_scale
				local curr_y= (y-.5) * spacing * display_scale
				self:xy(curr_x, curr_y):zoom(display_scale)
			end
		}
	end
end
--args[#args+1]= Def.ActorFrame(scaled_args)

local posed_args= {}
for x= 1, 4 do
	for y= 1, 3 do
		posed_args[#posed_args+1]= LoadActor(THEME:GetPathO("", "DDRKonamixBGAnimation110A/2"))..{
			InitCommand= function(self)
				local curr_x= ((x-.5) * spacing)
				local curr_y= ((y-.5) * spacing)
				local extra_pixels= (1 / display_scale) - 1
				self:xy(curr_x, curr_y):zoom((spacing+extra_pixels)/spacing)
			end
		}
	end
end
args[#args+1]= Def.ActorFrame(posed_args)
]]

return Def.ActorFrame(args)
