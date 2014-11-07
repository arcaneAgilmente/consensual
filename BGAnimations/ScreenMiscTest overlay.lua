local h= 24
local w= 96
local t= 2
local cursolor= fetch_color("player.p2")
local curalor= fetch_color("player.hilight")

--local cursor= setmetatable({}, cursor_mt)
local roller= false
local crop_text= false
local quad= false
local roll_number= 100

local function color_corners(self)
	self:linear(5)
	self:diffuseupperleft(fetch_color("accent.red"))
	self:diffuseupperright(fetch_color("accent.cyan"))
	self:diffuselowerleft(fetch_color("accent.violet"))
	self:diffuselowerright(fetch_color("accent.yellow"))
end

local function alt_color_corners(self)
	self:linear(5)
	self:diffuseupperleft(fetch_color("accent.cyan"))
	self:diffuseupperright(fetch_color("accent.red"))
	self:diffuselowerleft(fetch_color("accent.yellow"))
	self:diffuselowerright(fetch_color("accent.violet"))
end

local function stroke_text(self)
	self:linear(5)
	self:strokecolor(fetch_color("stroke"))
end

local function stroke_alt(self)
	self:linear(5)
	self:strokecolor(fetch_color("text"))
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
--[[	if event.DeviceInput.button == "DeviceButton_w" then
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
]]
	if not roller then return false end
	if event.DeviceInput.button == "DeviceButton_w" then
		roll_number= roll_number + 100
	elseif event.DeviceInput.button == "DeviceButton_a" then
		roll_number= roll_number - 1000
	elseif event.DeviceInput.button == "DeviceButton_s" then
		roll_number= roll_number - 100
	elseif event.DeviceInput.button == "DeviceButton_d" then
		roll_number= roll_number + 1000
	elseif event.DeviceInput.button == "DeviceButton_q" then
		trans_new_screen("ScreenInitialMenu")
	elseif event.DeviceInput.button == "DeviceButton_i" then
		roller:playcommand("Up")
	elseif event.DeviceInput.button == "DeviceButton_k" then
		roller:playcommand("Down")
	elseif event.DeviceInput.button == "DeviceButton_z" then
		alt_color_corners(roller)
	elseif event.DeviceInput.button == "DeviceButton_x" then
		color_corners(roller)
	elseif event.DeviceInput.button == "DeviceButton_c" then
		alt_color_corners(crop_text)
	elseif event.DeviceInput.button == "DeviceButton_v" then
		color_corners(crop_text)
	elseif event.DeviceInput.button == "DeviceButton_b" then
		alt_color_corners(quad)
	elseif event.DeviceInput.button == "DeviceButton_n" then
		color_corners(quad)
	elseif event.DeviceInput.button == "DeviceButton_t" then
		stroke_text(crop_text)
	elseif event.DeviceInput.button == "DeviceButton_y" then
		stroke_alt(crop_text)
	elseif event.DeviceInput.button == "DeviceButton_g" then
		stroke_text(roller)
	elseif event.DeviceInput.button == "DeviceButton_h" then
		stroke_alt(roller)
	end
	roller:targetnumber(roll_number)
end

local args= {
	OnCommand= function(self)
--		cursor:refit(nil, nil, 96, 24)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
--	cursor:create_actors("cursor", _screen.cx, _screen.cy, 2, cursolor, curalor,
--	false, true),
	-- metrics:
	-- [RollingTest]
	-- TextFormat="%09.0f"
	-- ApproachSeconds=2
	-- Commify=true
	-- LeadingZeroMultiplyColor=color("#dc322f")
	Def.RollingNumbers{
		Name= "roller", Font= "Common Normal", InitCommand= function(self)
			roller= self
			self:xy(_screen.cx, _screen.cy)
			self:Load("RollingTest")
			self:targetnumber(roll_number)
			color_corners(self)
--			self:cropleft(.5)
--			self:cropright(.125)
		end,
		DownCommand= function(self)
			self:linear(5)
			self:addy(40)
		end,
		UpCommand= function(self)
			self:linear(5)
			self:addy(-40)
		end,
	},
	Def.BitmapText{
		Name= "croptext", Font= "Common Normal", InitCommand= function(self)
			crop_text= self
			self:xy(_screen.cx, _screen.cy + 32)
			self:settext("000,000,000")
			color_corners(self)
--			self:cropleft(.25)
--			self:cropright(.25)
		end
	},
	Def.Quad{
		Name= "quad", InitCommand= function(self)
			quad= self
			self:xy(_screen.cx, _screen.cy - 120)
			self:setsize(80, 80)
			color_corners(self)
--			self:cropleft(.25)
--			self:cropright(.25)
		end
	},
}

return Def.ActorFrame(args)
