-- Use the unchangeable colors so this screen is usable even with a config
-- that makes text unreadable.

local colors= unchangeable_color

dofile(THEME:GetPathO("", "art_helpers.lua"))
dofile(THEME:GetPathO("", "options_menu.lua"))
set_option_set_metatables()

local cursor_button_list= {
	{"top", "MenuLeft"}, {"bottom", "MenuRight"},
	{"left", "MenuLeft"}, {"right", "MenuRight"},
}
reverse_button_list(cursor_button_list)

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
		cursor:set_sides_vis({"top", "bottom"}, true)
		cursor:set_sides_vis({"left", "right"}, false)
	elseif cursor_pos == "second" then
		cursor.align= 0
		cursor_fit= item_fit(second_menu:get_cursor_element())
		cursor:set_sides_vis({"top", "bottom"}, true)
		cursor:set_sides_vis({"left", "right"}, false)
	elseif cursor_pos == "color" then
		cursor.align= 0
		cursor_fit= manip:get_cursor_fit()
		if manip.locked_in_editing then
			cursor:set_sides_vis({"top", "bottom"}, true)
			cursor:set_sides_vis({"left", "right"}, false)
		else
			cursor:set_sides_vis({"top", "bottom"}, false)
			cursor:set_sides_vis({"left", "right"}, true)
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
	manip:create_actors("manip", SCREEN_RIGHT-76, 100, colors),
	main_display:create_actors(
		"main_disp", _screen.w * .25 + 8, 16, 18, _screen.w * .5-16, 24, 1,
		false, true, true),
	second_display:create_actors(
		"second_disp", _screen.w * .75, 56, 19, _screen.w * .25, 24, 1,
		true, true),
	cursor:create_actors(
		"cursor", _screen.cx, _screen.cy, 1, fetch_color("player.both"),
		fetch_color("player.hilight"), cursor_button_list),
	helper:create_actors("helper", misc_config:get_data().color_help_time, "ColorConfig", "main_help"),
}
