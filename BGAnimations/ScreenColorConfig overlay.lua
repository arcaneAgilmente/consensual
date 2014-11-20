-- Use the unchangeable colors so this screen is usable even with a config
-- that makes text unreadable.

local colors= unchangeable_color
local chactor_width= 16

local color_manipulator_mt= {
	__index= {
		create_actors= function(self, name, x, y)
			self.name= name
			self.chactors= {}
			self.chex= {}
			local args= {
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.mode= subself:GetChild("mode")
					self.done_actor= subself:GetChild("done")
					self.editing_name= subself:GetChild("editing")
					for i= 1, 8 do
						self.chactors[i]= subself:GetChild("ch"..i)
					end
				end,
				Def.Quad{
					Name= "example", InitCommand= function(subself)
						self.example= subself
						subself:setsize(chactor_width*8, 80)
						subself:vertalign(bottom)
						subself:xy(8, -16)
					end
				},
				normal_text("done", get_string_wrapper("ColorConfig", "done"),
										colors.text, colors.bg, -112, 0, 1),
				normal_text("mode", "#", colors.text, colors.bg, -64, 0),
				normal_text("editing", "", colors.text, colors.bg, -128, -84),
			}
			for i= 1, 4 do
				args[#args+1]= Def.Quad{
					Name= "chex"..i, InitCommand= function(subself)
						self.chex[i]= subself
						subself:setsize(chactor_width*2, 256)
						subself:xy(-64 + (chactor_width*2 * i) - chactor_width/2, 16)
						subself:vertalign(top)
					end
				}
			end
			for i= 1, 8 do
				args[#args+1]= normal_text(
					"ch"..i, "", colors.text, colors.bg, -64 + (chactor_width*i), 0)
			end
			return Def.ActorFrame(args)
		end,
		initialize= function(self, edit_name, example_color)
			self.done= false
			self.edit_channel= "done"
			self.locked_in_editing= false
			self.editing_name:settext(edit_name)
			width_limit_text(self.editing_name, 128)
			self.example:diffuse(example_color)
			self.example_color= DeepCopy(example_color)
			self.internal_values= {}
			for i= 1, 4 do
				self.internal_values[i]= math.round(example_color[i] * 255)
			end
			for i= 1, 4 do
				self:set_channel_text(i, self.internal_values[i])
				self:set_channel_example(i)
			end
		end,
		set_channel_text= function(self, chid, chval)
			local text= ("%02X"):format(chval)
			self.chactors[(chid-1)*2+1]:settext(text:sub(1, 1))
			self.chactors[(chid-1)*2+2]:settext(text:sub(2, 2))
		end,
		set_channel_example= function(self, chid)
			local top_color= DeepCopy(self.example_color)
			local bottom_color= DeepCopy(self.example_color)
			top_color[chid]= 1
			bottom_color[chid]= 0
			self.chex[chid]:diffusetopedge(top_color)
			self.chex[chid]:diffusebottomedge(bottom_color)
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end,
		adjust_channel= function(self, chid, amount)
			if not chid then return end
			local new_val= self.internal_values[chid] + amount
			if new_val < 0 then new_val= 0 end
			if new_val > 255 then new_val= 255 end
			self.internal_values[chid]= new_val
			self.example_color[chid]= self.internal_values[chid] / 255
			self.example:diffuse(self.example_color)
			self:set_channel_text(chid, self.internal_values[chid])
			for i= 1, 4 do
				self:set_channel_example(i)
			end
		end,
		interpret_code= function(self, code)
			if self.locked_in_editing then
				if code == "MenuLeft" then
					code= "MenuDown"
				elseif code == "MenuRight" then
					code= "MenuUp"
				end
			end
			if code == "Start" then
				if self.edit_channel == "done" then
					self.done= true
				elseif tonumber(self.edit_channel) then
					self.locked_in_editing= not self.locked_in_editing
				end
			elseif code == "MenuLeft" then
				if self.edit_channel == "done" then
					self.edit_channel= #self.chactors
				elseif tonumber(self.edit_channel) then
					if self.edit_channel == 1 then
						self.edit_channel= "done"
					else
						self.edit_channel= self.edit_channel - 1
					end
				end
			elseif code == "MenuRight" then
				if self.edit_channel == "done" then
					self.edit_channel= 1
				elseif tonumber(self.edit_channel) then
					if self.edit_channel == #self.chactors then
						self.edit_channel= "done"
					else
						self.edit_channel= self.edit_channel + 1
					end
				end
			elseif code == "MenuUp" then
				if tonumber(self.edit_channel) then
					local chid= math.ceil(self.edit_channel / 2)
					if self.edit_channel % 2 == 1 then
						self:adjust_channel(chid, 16)
					else
						self:adjust_channel(chid, 1)
					end
				end
			elseif code == "MenuDown" then
				if tonumber(self.edit_channel) then
					local chid= math.ceil(self.edit_channel / 2)
					if self.edit_channel % 2 == 1 then
						self:adjust_channel(chid, -16)
					else
						self:adjust_channel(chid, -1)
					end
				end
			end
		end,
		get_cursor_fit= function(self)
			local cx= self.container:GetX()
			local cy= self.container:GetY()
			local chact
			if self.edit_channel == "done" then
				chact= self.done_actor
			elseif tonumber(self.edit_channel) then
				chact= self.chactors[self.edit_channel]
			end
			local fit= {cx + chact:GetX(), cy + chact:GetY(), chact:GetWidth(), 24}
			return fit
		end
}}

dofile(THEME:GetPathO("", "options_menu.lua"))
set_option_set_metatables()

local manip= setmetatable({}, color_manipulator_mt)
local cursor= setmetatable({}, cursor_mt)
local main_menu= setmetatable({}, options_sets.menu)
local second_menu= setmetatable({}, options_sets.menu)
local main_display= setmetatable({}, option_display_mt)
local second_display= setmetatable({}, option_display_mt)

local color_data= color_config:get_data()
local current_level= {}
local current_data= color_data
local cursor_pos= "main"
local second_menu_data= {{name= "do_nothing"}}
local picked_on_main= 1

local function current_picked_to_name(picked_on)
	if #current_level == 0 then
		return picked_on[1]
	else
		return table.concat(current_level, ".") .. "." .. picked_on[1]
	end
end

local function color_entry_to_menu_entry(color_entry)
	local value= ""
	if type(color_entry[2]) == "string" then
		value= color_entry[2]
	else
		if is_color(color_entry[2]) then
			value= "#" .. ColorToHex(color_entry[2])
		else
			value= "{group}"
		end
	end
	if color_entry[3] then
		value= value .. " A:" .. color_entry[3]
	end
	return {name= color_entry[1], value= value, color_ref= color_entry}
end

local function update_main_menu(reinit)
	current_data= color_data
	for i= 1, #current_level do
		local name= current_level[i]
		for ci= 1, #current_data do
			if name == current_data[ci][1] then
				current_data= current_data[ci][2]
				break
			end
		end
	end
	local data= {name= table.concat(current_level, ".")}
	for i= 1, #current_data do
		data[i]= color_entry_to_menu_entry(current_data[i])
	end
	data[#data+1]= {name= "add_color"}
	data[#data+1]= {name= "add_group"}
	data[#data+1]= {name= "default_group"}
	if reinit then
		if #current_level > 0 then
			main_menu:initialize(nil, data)
		else
			main_menu:initialize(nil, data, false, "save_config")
		end
	else
		main_menu:update_info(data)
	end
	main_menu:set_status()
end

local function update_cursor()
	local cursor_fit= {}
	local function item_fit(item)
		local fit= item:get_cursor_fit()
		local xp, yp= rec_calc_actor_pos(item.container)
		return {xp + fit[1], yp + fit[2], fit[3], fit[4]}
	end
	if cursor_pos == "main" then
		cursor.align= .5
		cursor_fit= item_fit(main_menu:get_cursor_element())
	elseif cursor_pos == "second" then
		cursor.align= 0
		cursor_fit= item_fit(second_menu:get_cursor_element())
	elseif cursor_pos == "color" then
		cursor.align= 0
		cursor_fit= manip:get_cursor_fit()
		if manip.locked_in_editing then
			cursor.parts[2]:visible(false)
		else
			cursor.parts[2]:visible(true)
		end
	end
	cursor:refit(unpack(cursor_fit))
end

local fully_qualified_text= get_string_wrapper(
	"ColorConfig", "fully_qualified")
local mismatched_group_text= get_string_wrapper(
	"ColorConfig", "mismatched_group")
local reference_entry_settings= {
	Question= fully_qualified_text,
	InitialAnswer= "",
	MaxInputLength= 512,
	Validate= function(answer, err)
		local refresult= is_color_string(answer)
		if not refresult then
			return false, fully_qualified_text
		end
		local old= current_data[picked_on_main][2]
		local sim, err= groups_are_similar(old, answer)
		local oldstr= old
		if type(old) == "table" then
			if is_color(old) then
				oldstr= ColorToHex(old)
			else
				oldstr= "{group}"
			end
		end
		if not sim then
			return false, oldstr .. "->" .. answer .. ": " .. err
		end
		return true, ""
	end,
	OnOK= function(answer)
		if is_color_string(answer) then
			local dest= current_data[picked_on_main]
			dest[2]= is_color_not_ref(answer) or answer
		end
		update_main_menu(false)
		update_cursor()
	end,
}

local add_color_settings= {
	Question= get_string_wrapper("ColorConfig", "add_color_prompt"),
	InitialAnswer= "",
	MaxInputLength= 512,
	Validate= function(answer, err)
		for i= 1, #current_data do
			if answer == current_data[i][1] then
				return false, get_string_wrapper("ColorConfig", "already_exists")
			end
		end
		return true, ""
	end,
	OnOK= function(answer)
		current_data[#current_data+1]= {answer, color("#000000")}
		update_main_menu(false)
		update_cursor()
	end
}

local add_group_settings= {
	Question= get_string_wrapper("ColorConfig", "add_group_prompt"),
	InitialAnswer= "",
	MaxInputLength= 512,
	Validate= add_color_settings.Validate,
	OnOK= function(answer)
		current_data[#current_data+1]= {answer, {}}
		update_main_menu(false)
		update_cursor()
	end
}

local set_alpha_settings= {
	Question= get_string_wrapper("ColorConfig", "enter_alpha"),
	InitialAnswer= "1",
	MaxInputLength= 512,
	Validate= function(answer, err)
		local tona= tonumber(answer)
		if not tona or tona < 0 or tona > 1 then
			return false, get_string_wrapper("ColorConfig", "alpha_rejected")
		end
		return true, ""
	end,
	OnOK= function(answer)
		if tonumber(answer) == 1 then
			current_data[picked_on_main][3]= nil
		else
			current_data[picked_on_main][3]= tonumber(answer)
		end
		update_main_menu(false)
		update_cursor()
	end
}

dofile(THEME:GetPathO("", "auto_hider.lua"))
local helper= setmetatable({}, updatable_help_mt)
local function update_help()
	local prim_help= ""
	local second_help= ""
	if cursor_pos == "main" then
		if main_menu.cursor_pos == 1 and #current_level == 0 then
			prim_help= "save_config_help"
		else
			prim_help= main_menu:get_item_name() .. "_help"
		end
		second_help= current_picked_to_name({prim_help})
	elseif cursor_pos == "second" then
		prim_help= second_menu:get_item_name() .. "_help"
		second_help= "blank_help"
	else
		prim_help= "blank_help"
		second_help= "blank_help"
	end
	helper:update_text(prim_help, second_help)
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.GameButton == "" then return false end
	if cursor_pos == "main" then
		local handled, extra= main_menu:interpret_code(event.GameButton)
		if handled and extra then
			local ref= extra.color_ref
			if ref then
				picked_on_main= main_menu.cursor_pos - 1
				second_menu_data= {
					{name= "do_nothing"},
					{name= "set_reference"},
					{name= "set_direct"},
					{name= "set_alpha"},
				}
				local defname= current_picked_to_name(ref)
				if color_can_be_removed(defname) then
					second_menu_data[#second_menu_data+1]= {name= "remove"}
				end
				if fetch_default_color_setting(defname) then
					second_menu_data[#second_menu_data+1]= {name= "set_to_default"}
				end
				second_menu:initialize(nil, second_menu_data, true)
				cursor_pos= "second"
			elseif extra.name == "add_color" then
				SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
				SCREENMAN:GetTopScreen():Load(add_color_settings)
			elseif extra.name == "add_group" then
				SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
				SCREENMAN:GetTopScreen():Load(add_group_settings)
			elseif extra.name == "default_group" then
				local name= table.concat(current_level, ".")
				local def_value= fetch_default_color_setting(name)
				if def_value then
					DeepCopy(def_value, current_data)
					update_main_menu(false)
				end
			end
		elseif event.GameButton == "Start" then
			if #current_level > 0 then
				current_level[#current_level]= nil
				update_main_menu(true)
			else
				if sanity_check_color_config() then
					color_config:set_dirty()
					color_config:save()
					resolve_color_references()
					update_common_bg_colors()
					update_confetti_color()
					trans_new_screen("ScreenInitialMenu")
				else
					lua.ReportScriptError("Config sanity check failed.")
				end
			end
		end
	elseif cursor_pos == "second" then
		local handled, extra= second_menu:interpret_code(event.GameButton)
		if handled and extra then
			local main_pick= current_data[picked_on_main]
			if extra.name == "do_nothing" then
				cursor_pos= "main"
				second_display:hide()
			elseif extra.name == "set_reference" then
				reference_entry_settings.Question=
					"Enter a reference to set '" .. main_pick[1] .. "' to."
				if type(main_pick[2]) == "string" then
					reference_entry_settings.InitialAnswer= main_pick[2]
				elseif is_color(main_pick[2]) then
					reference_entry_settings.InitialAnswer=
						"#" .. ColorToHex(main_pick[2])
				end
				SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
				SCREENMAN:GetTopScreen():Load(reference_entry_settings)
				second_display:hide()
				cursor_pos= "main"
			elseif extra.name == "set_direct" then
				if is_color(main_pick[2]) then
					manip:initialize(main_pick[1], main_pick[2])
					manip:unhide()
					second_display:hide()
					cursor_pos= "color"
				elseif type(main_pick[2]) == "string" then
					local refresult= lookup_color_reference(main_pick[2])
					if is_color(refresult) then
						manip:initialize(main_pick[1], refresult)
						manip:unhide()
						second_display:hide()
						cursor_pos= "color"
					else
						main_pick[2]= DeepCopy(refresult)
						current_level[#current_level+1]= main_pick[1]
						second_display:hide()
						update_main_menu(true)
						cursor_pos= "main"
					end
				else
					current_level[#current_level+1]= main_pick[1]
					second_display:hide()
					update_main_menu(true)
					cursor_pos= "main"
				end
			elseif extra.name == "set_to_default" then
				local name= current_picked_to_name(current_data[picked_on_main])
				local def_value= fetch_default_color_setting(name)
				if def_value then
					if type(def_value) == "table" then
						current_data[picked_on_main][2]= DeepCopy(def_value)
					else
						current_data[picked_on_main][2]= def_value
					end
					second_display:hide()
					update_main_menu(false)
					cursor_pos= "main"
				else
					lua.ReportScriptError("Default value for '"..name.."' not found.")
				end
			elseif extra.name == "set_alpha" then
				local alf= current_data[picked_on_main][3] or 1
				set_alpha_settings.InitialAnswer= tostring(alf)
				SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
				SCREENMAN:GetTopScreen():Load(set_alpha_settings)
				second_display:hide()
				cursor_pos= "main"
			elseif extra.name == "remove" then
				table.remove(current_data, picked_on_main)
				second_display:hide()
				update_main_menu(false)
				cursor_pos= "main"
			end
		end
	elseif cursor_pos == "color" then
		manip:interpret_code(event.GameButton)
		if manip.done then
			local main_pick= current_data[picked_on_main]
			local function set_new_color_if_different(old_color)
				local new_color_is_different= false
				for i= 1, 4 do
					local old_channel= math.round(old_color[i] * 255)
					if old_channel ~= manip.internal_values[i] then
						new_color_is_different= true
					end
				end
				if new_color_is_different then
					main_pick[2]= {}
					for i= 1, 4 do
						main_pick[2][i]= manip.example_color[i]
					end
					update_main_menu(false)
				end
			end
			if type(main_pick[2]) == "string" then
				local refresult= lookup_color_reference(main_pick[2])
				if is_color(refresult) then
					set_new_color_if_different(refresult)
				else
					-- Cannot use the color manipulator if the reference is to a group.
				end
			elseif is_color(main_pick[2]) then
				set_new_color_if_different(main_pick[2])
			else
				-- Cannot use color manipulator if a group was picked.
			end
			manip:hide()
			cursor_pos= "main"
		end
	end
	update_cursor()
	update_help()
end

return Def.ActorFrame{
	OnCommand= function(self)
		cursor:refit(nil, nil, 12, 24)
		manip:hide()
		main_display:set_text_colors(colors.text, colors.bg)
		main_display:set_translation_section("ColorConfig")
		second_display:set_text_colors(colors.text, colors.bg)
		second_display:set_translation_section("ColorConfig")
		update_main_menu(true)
		main_menu:set_display(main_display)
		second_menu:initialize(nil, second_menu_data, true)
		second_menu:set_display(second_display)
		second_display:hide()
		update_cursor()
		update_help()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.Quad{
		InitCommand= function(self)
			self:FullScreen()
			self:diffuse(colors.bg)
		end
	},
	manip:create_actors("manip", SCREEN_RIGHT-76, 100),
	main_display:create_actors(
		"main_disp", _screen.w * .25 + 8, 16, 18, _screen.w * .5-16, 24, 1,
		false, true, true),
	second_display:create_actors(
		"second_disp", _screen.w * .75, 56, 19, _screen.w * .25, 24, 1,
		true, true),
	cursor:create_actors(
		"cursor", _screen.cx, _screen.cy, 1, fetch_color("player.both"),
		fetch_color("player.hilight"), true, true),
	helper:create_actors("helper", misc_config:get_data().color_help_time, "ColorConfig", "main_help"),
}
