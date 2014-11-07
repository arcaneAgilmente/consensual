local config_data= misc_config:get_data()
misc_config:set_dirty()

dofile(THEME:GetPathO("", "options_menu.lua"))
dofile(THEME:GetPathO("", "pain_display.lua"))
options_sets.settable_thing= {
	__index= {
		initialize= function(self, pn, extra)
			self.name= extra.name
			self.get= extra.get
			self.set= extra.set
			self.cursor_pos= 1
			self.info_set= {up_element(), {text= self.get()}}
		end,
		set_status= function(self) self.display:set_heading(self.name) end,
		update_text= function(self)
			self.info_set[2].text= self.get()
			self.display:set_element_info(2, self.info_set[2])
		end,
		interpret_start= function(self)
			if self.cursor_pos == 2 then
				self.set()
				return true
			end
			return false
		end
}}
set_option_set_metatables()
dofile(THEME:GetPathO("", "auto_hider.lua"))

local function make_extra_for_conf_val(name, min_scale, scale, max_scale)
	return {
		name= name, min_scale= min_scale, scale= scale, max_scale= max_scale,
		initial_value= function() return config_data[name] end,
		set= function(pn, value) config_data[name]= value end
	}
end

local function time_conf(name, min_scale, scale, max_scale)
	return {
		name= name, min_scale= min_scale, scale= scale, max_scale= max_scale,
		initial_value= function() return config_data[name] end,
		set= function(pn, value) config_data[name]= value end,
		val_to_text= function(pn, value) return secs_to_str(value) end,
		scale_to_text= function(pn, value) return secs_to_str(value) end,
	}
end

local function make_extra_for_bool_val(name, on, off)
	return {
		name= name,
		true_text= on,
		false_text= off,
		get= function() return config_data[name] end,
		set= function(pn, value) config_data[name]= value end
	}
end

local function sub_bool_conf(sub_name, name, on, off)
	return {
		name= name,
		true_text= on,
		false_text= off,
		get= function() return config_data[sub_name][name] end,
		set= function(pn, value) config_data[sub_name][name]= value end
	}
end

local reward_options= {
	{name= "default_credit_time", meta= options_sets.adjustable_float,
	 args= time_conf("default_credit_time", 0, 1, 2)},
	{name= "min_remaining_time", meta= options_sets.adjustable_float,
	 args= time_conf("min_remaining_time", 0, 1, 2)},
	{name= "song_length_grace", meta= options_sets.adjustable_float,
	 args= time_conf("song_length_grace", 0, 1, 2)},
	{name= "min_score_for_reward", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("min_score_for_reward", -2, -1, 0)},
	{name= "reward_time_by_pct", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("reward_time_by_pct", "Percent", "Flat")},
	{name= "min_reward_pct", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("min_reward_pct", -3, -1, 0)},
	{name= "max_reward_pct", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("max_reward_pct", -3, -1, 0)},
	{name= "min_reward_time", meta= options_sets.adjustable_float,
	 args= time_conf("min_reward_time", 0, 1, 2)},
	{name= "max_reward_time", meta= options_sets.adjustable_float,
	 args= time_conf("max_reward_time", 0, 1, 2)},
	{name= "reset_limit", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("gameplay_reset_limit", 0, 0, 1)},
}

local help_options= {
	{name= "select_music_help_time", meta= options_sets.adjustable_float,
	 args= time_conf("select_music_help_time", -3, 0, 2)},
	{name= "ssm_advanced_help", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("ssm_advanced_help", "Yes", "No")},
	{name= "evaluation_help_time", meta= options_sets.adjustable_float,
	 args= time_conf("evaluation_help_time", -3, 0, 2)},
	{name= "service_help_time", meta= options_sets.adjustable_float,
	 args= time_conf("service_help_time", -3, 0, 2)},
	{name= "color_help_time", meta= options_sets.adjustable_float,
	 args= time_conf("color_help_time", -3, 0, 2)},
}

local flag_slot_options= {}
do -- make a flags menu for each set of flags.
	local machine_flags= machine_flag_setting:get_data()
	machine_flag_setting:set_dirty()
	local function flag_controller(slot, type_name, flag_name)
		return {
			name= flag_name,
			init= function(pn)
				return machine_flags[slot][type_name][flag_name]
			end,
			set= function(pn)
				machine_flags[slot][type_name][flag_name]= true
			end,
			unset= function(pn)
				machine_flags[slot][type_name][flag_name]= false
			end
		}
	end
	for slot, set in ipairs(machine_flags) do
		local type_eles= {}
		for i, name_list in ipairs(sorted_flag_names) do
			local flag_eles= {}
			for f, name in ipairs(name_list) do
				flag_eles[#flag_eles+1]= flag_controller(slot, name_list.type, name)
			end
			type_eles[#type_eles+1]= {
				name= name_list.type, meta= options_sets.special_functions,
				args= {eles= flag_eles}}
		end
		flag_slot_options[#flag_slot_options+1]= {
			name= "Slot " .. slot, meta= options_sets.menu, args= type_eles}
	end
end

local pain_display= setmetatable({}, pain_display_mt)
local in_pain= false
local function pain_extern(params)
	in_pain= true
	pain_display:set_config(params.config)
	pain_display:enter_edit_mode()
	pain_display:unhide()
end

local pain_slot_options= {}
do -- make an option for each pain slot.
	local machine_pain= machine_pain_setting:get_data()
	machine_pain_setting:set_dirty()
	for slot, config in ipairs(machine_pain) do
		pain_slot_options[#pain_slot_options+1]= {
			name= "Slot " .. slot, meta= "external_interface",
			extern= pain_extern, args= {config= config}}
	end
end

local press_prompt= {}
local on_press_prompt= false
local function key_get(key_name)
	return function() return ToEnumShortString(config_data[key_name]) end
end

local function key_set(key_name)
	return function()
		press_prompt:visible(true)
		on_press_prompt= true
		local tops= SCREENMAN:GetTopScreen()
		local tempback= noop_false
		tempback= function(event)
			if event.type == "InputEventType_FirstPress" then
				config_data[key_name]= event.DeviceInput.button
				tops:RemoveInputCallback(tempback)
				press_prompt:visible(false)
				on_press_prompt= 2
			end
		end
		tops:AddInputCallback(tempback)
	end
end

local function key_get_set(key_name)
	return {get= key_get(key_name), set= key_set(key_name)}
end

local im_options= {
	{name= "im_have_single", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "single_choice", "On", "Off")},
	{name= "im_have_versus", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "versus_choice", "On", "Off")},
	{name= "im_have_playmode", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "playmode_choice", "On", "Off")},
	{name= "im_have_profile", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "profile_choice", "On", "Off")},
	{name= "im_have_smops", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "stepmania_ops", "On", "Off")},
	{name= "im_have_consops", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "consensual_ops", "On", "Off")},
	{name= "im_have_colconf", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "color_config", "On", "Off")},
	{name= "im_have_edit", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "edit_choice", "On", "Off")},
	{name= "im_have_exit", meta= options_sets.boolean_option,
	 args= sub_bool_conf("initial_menu_ops", "exit_choice", "On", "Off")},
}

local consensual_options= {
	{name= "set_config_key", meta= options_sets.settable_thing,
	 args= key_get_set("config_menu_key")},
	{name= "set_color_key", meta= options_sets.settable_thing,
	 args= key_get_set("color_config_key")},
	{name= "set_censor_privilege_key", meta= options_sets.settable_thing,
	 args= key_get_set("censor_privilege_key")},
	{name= "set_have_select", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("have_select_button", "Yes", "No")},
	{name= "set_ud_menus", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("menus_have_ud", "Yes", "No")},
	{name= "sex_per_clock_change", meta= options_sets.adjustable_float,
	 args= time_conf("seconds_per_clock_change", 0, 0, 3)},
	{name= "transition_split_min", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("transition_split_min", 0, 0, 1)},
	{name= "transition_split_max", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("transition_split_max", 0, 0, 1)},
	{name= "transition_meta_var_max", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("transition_meta_var_max", 0, 0, 1)},
	{name= "initial_menu_choices", meta= options_sets.menu, args= im_options},
}

local menu_items= {
	{name= "cons_config", meta= options_sets.menu, args= consensual_options},
	{name= "reward_config", meta= options_sets.menu, args= reward_options},
	{name= "help_config", meta= options_sets.menu, args= help_options},
	{name= "flags_config", meta= options_sets.menu, args= flag_slot_options},
	{name= "pain_config", meta= options_sets.menu, args= pain_slot_options},
}

local config_menu= setmetatable({}, menu_stack_mt)

local secondary_menu= {}
local on_main_menu= true
local return_on_start= false

local helper= setmetatable({}, updatable_help_mt)
local function update_help()
	local item_name= config_menu:get_cursor_item_name()
	helper:update_text(item_name)
	helper:update_hide_time(config_data.service_help_time)
end

local prompt_frame= setmetatable({}, frame_helper_mt)

local function input(event)
	if on_press_prompt then
		config_menu:top_menu():update_text()
		if on_press_prompt == 2 then
			on_press_prompt= false
		end
		return false
	end
	if event.type == "InputEventType_Release" then return false end
	if event.PlayerNumber and event.GameButton then
		local code= event.GameButton
		if in_pain then
			local handled, close= pain_display:interpret_code(code)
			if handled and close then
				pain_display:hide()
				config_menu:exit_external_mode()
				in_pain= false
			end
		else
			if not config_menu:interpret_code(code) then
				if code == "Start" and config_menu:can_exit_screen() then
					misc_config:save()
					machine_flag_setting:save()
					machine_pain_setting:save()
					trans_new_screen("ScreenInitialMenu")
				end
			end
			update_help()
		end
		return false
	end
	return false
end

return Def.ActorFrame{
	InitCommand= function(self)
		config_menu:push_options_set_stack(options_sets.menu, menu_items, "Exit Menu")
		config_menu:update_cursor_pos()
		update_help()
	end,
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	config_menu:create_actors(
		"menu", 0, 16, _screen.w, _screen.h, _screen.h / 24 - 3, nil),
	pain_display:create_actors("pain", _screen.w*.75, 80, nil, 184, .625),
	helper:create_actors("helper", config_data.service_help_time, "ConsService", ""),
	Def.ActorFrame{
		Name= "press prompt",
		InitCommand= function(self)
			press_prompt= self
			self:xy(_screen.cx, _screen.cy)
			self:visible(false)
		end,
		OnCommand= function(self)
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(self)
			prompt_frame:move((xmx+xmn)/2, (ymx+ymn)/2)
			prompt_frame:resize(xmx-xmn+20, ymx-ymn+20)
		end,
		prompt_frame:create_actors(
			"ppf", 1, 0, 0, fetch_color("prompt.frame"), fetch_color("prompt.bg"),
			0, 0),
		normal_text("ppt", "Press key.", fetch_color("prompt.text"), nil, 0, 0, 1),
	},
}
