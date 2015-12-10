local text= false
local input_list= {}

local mapping_menu_row= {
	__index= {
		create_actors= function(self)
			end
}}

local test_texts= {}
local test_quads= {}
local luma_texts= {}
local angle_texts= {}
local corner_lumas= {1, 1, 1, 1}
local good_luma= {10, .5, .5, 5}
local corner_angles= {0, 0, 0, 0}

local function color_text(text, color)
	text:diffuseupperleft(adjust_luma(color, corner_lumas[1]))
		:diffuseupperright(adjust_luma(color, corner_lumas[2]))
		:diffuselowerleft(adjust_luma(color, corner_lumas[3]))
		:diffuselowerright(adjust_luma(color, corner_lumas[4]))
end

local function rot_color_text(text, color)
	for i, corner in ipairs{"diffuseupperleft", "diffuseupperright", "diffuselowerleft", "diffuselowerright"} do
		local new_color= color
		new_color= rotate_color(new_color, corner_angles[i])
		new_color= adjust_luma(new_color, corner_lumas[i])
		text[corner](text, new_color)
	end
end

local test_colors= {
	fetch_color("text"),
	fetch_color("text_other"),
	fetch_color("rev_text"),
	fetch_color("rev_text_other"),
	fetch_color("accent.yellow"),
	fetch_color("accent.orange"),
	fetch_color("accent.red"),
	fetch_color("accent.magenta"),
	fetch_color("accent.violet"),
	fetch_color("accent.blue"),
	fetch_color("accent.cyan"),
	fetch_color("accent.green"),
}

local function update_text()
	for i, text in ipairs(test_texts) do
		rot_color_text(text, test_colors[i])
	end
	for i, quad in ipairs(test_quads) do
		rot_color_text(quad, test_colors[i])
	end
	for i, luma in ipairs(luma_texts) do
		luma:settextf("%.2f", corner_lumas[i])
	end
	for i, angle in ipairs(angle_texts) do
		angle:settextf("%.2f", corner_angles[i])
	end
end

local function adjust_corner_angle(corner, amount)
	corner_angles[corner]= corner_angles[corner] + amount
	update_text()
end

local function adjust_corner_luma(corner, amount)
	corner_lumas[corner]= corner_lumas[corner] + amount
	update_text()
end

local function reset_corner(corner)
	corner_lumas[corner]= 1
	corner_angles[corner]= 0
	update_text()
end

local function input(event)
	if event.type == "InputEventType_Release" then return end
	--input_list[#input_list+1]= event.DeviceInput
	if event.DeviceInput.button == "DeviceButton_3" then
		reset_corner(1)
	elseif event.DeviceInput.button == "DeviceButton_e" then
		reset_corner(2)
	elseif event.DeviceInput.button == "DeviceButton_d" then
		reset_corner(3)
	elseif event.DeviceInput.button == "DeviceButton_c" then
		reset_corner(4)
	elseif event.DeviceInput.button == "DeviceButton_1" then
		adjust_corner_angle(1, -1)
	elseif event.DeviceInput.button == "DeviceButton_q" then
		adjust_corner_angle(2, -1)
	elseif event.DeviceInput.button == "DeviceButton_a" then
		adjust_corner_angle(3, -1)
	elseif event.DeviceInput.button == "DeviceButton_z" then
		adjust_corner_angle(4, -1)
	elseif event.DeviceInput.button == "DeviceButton_5" then
		adjust_corner_angle(1, 1)
	elseif event.DeviceInput.button == "DeviceButton_t" then
		adjust_corner_angle(2, 1)
	elseif event.DeviceInput.button == "DeviceButton_g" then
		adjust_corner_angle(3, 1)
	elseif event.DeviceInput.button == "DeviceButton_b" then
		adjust_corner_angle(4, 1)
	elseif event.DeviceInput.button == "DeviceButton_2" then
		adjust_corner_luma(1, -.1)
	elseif event.DeviceInput.button == "DeviceButton_w" then
		adjust_corner_luma(2, -.1)
	elseif event.DeviceInput.button == "DeviceButton_s" then
		adjust_corner_luma(3, -.1)
	elseif event.DeviceInput.button == "DeviceButton_x" then
		adjust_corner_luma(4, -.1)
	elseif event.DeviceInput.button == "DeviceButton_4" then
		adjust_corner_luma(1, .1)
	elseif event.DeviceInput.button == "DeviceButton_r" then
		adjust_corner_luma(2, .1)
	elseif event.DeviceInput.button == "DeviceButton_f" then
		adjust_corner_luma(3, .1)
	elseif event.DeviceInput.button == "DeviceButton_v" then
		adjust_corner_luma(4, .1)
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
		update_text()
--		self:SetDrawFunction(draw)
	end,
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			text= self:DiffuseAndStroke(fetch_color("text"), fetch_color("stroke"))
		end
	},
}
args[#args+1]= Def.Quad{
	InitCommand= function(self)
		self:xy(_screen.cx, _screen.cy):setsize(_screen.w, _screen.h):diffuse{0, 0, 0, 1}
	end
}
for test_col= 1, #test_colors do
args[#args+1]= Def.BitmapText{
	Font= "Common Normal",
	Text= "QWERTYUIOPASDFGHJKLZXCVBNM",
	InitCommand= function(self)
		test_texts[test_col]= self
		self:xy(_screen.cx, 24*test_col)
		color_text(self, test_colors[test_col])
	end
}
	args[#args+1]= Def.Quad{
		InitCommand= function(self)
			test_quads[test_col]= self
			self:xy(_screen.cx*.4, 24*test_col):setsize(20, 20)
		end
	}
end

local luma_text_pos= {
	{8, 8, left, top}, {_screen.w-8, 8, right, top},
	{8, _screen.h-8, left, bottom}, {_screen.w-8, _screen.h-8, right, bottom}
}
local angle_text_pos= {
	{32, 32, left, top}, {_screen.w-32, 32, right, top},
	{32, _screen.h-32, left, bottom}, {_screen.w-32, _screen.h-32, right, bottom}
}
for l= 1, #luma_text_pos do
	args[#args+1]= Def.BitmapText{
		Font= "Common Normal",
		InitCommand= function(self)
			luma_texts[l]= self:diffuse(fetch_color("text"))
			local pos= luma_text_pos[l]
			self:xy(pos[1], pos[2]):horizalign(pos[3]):vertalign(pos[4])
		end
	}
	args[#args+1]= Def.BitmapText{
		Font= "Common Normal",
		InitCommand= function(self)
			angle_texts[l]= self:diffuse(fetch_color("text"))
			local pos= angle_text_pos[l]
			self:xy(pos[1], pos[2]):horizalign(pos[3]):vertalign(pos[4])
		end
	}
end

return Def.ActorFrame(args)
