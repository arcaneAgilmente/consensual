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

local confetti_data= confetti_config:get_data()
local function confetti_val(name, min, max, min_scale, scale, max_scale)
	return {
		name= name, min_scale= min_scale, scale= scale, max_scale= max_scale,
		validator= function(v) return v >= min and v <= max end,
		initial_value= function() return confetti_data[name] end,
		set= function(pn, v)
			confetti_data[name]= v
			confetti_config:set_dirty()
			update_confetti_count()
		end
	}
end

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
		val_to_text= function(pn, value) return secs_to_str(value, -min_scale) end,
		scale_to_text= function(pn, value) return secs_to_str(value, -min_scale) end,
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
	for gi, group_data in ipairs(sorted_flag_names) do
		local this_group= {}
		for fi, flag_name in ipairs(group_data) do
			this_group[#this_group+1]= {
				name= flag_name, meta= options_sets.extensible_boolean_menu,
				args= {values= machine_flags[group_data.type][flag_name],
							 true_text= "True", false_text= "False",
							 default_for_new= false}}
		end
		flag_slot_options[#flag_slot_options+1]= {
			name= group_data.type, meta= options_sets.menu, args= this_group}
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

local function imop(show_name, op_name)
	return {name= show_name,
					init= function() return config_data.initial_menu_ops[op_name] end,
					set= function() config_data.initial_menu_ops[op_name]= true end,
					unset= function() config_data.initial_menu_ops[op_name]= false end}
end

local im_options= {
	imop("im_have_single", "single_choice"),
	imop("im_have_versus", "versus_choice"),
	imop("im_have_playmode", "playmode_choice"),
	imop("im_have_profile", "profile_choice"),
	imop("im_have_smops", "stepmania_ops"),
	imop("im_have_consops", "consensual_ops"),
	imop("im_have_colconf", "color_config"),
	imop("im_have_edit", "edit_choice"),
	imop("im_have_exit", "exit_choice"),
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
	{name= "initial_menu_choices", meta= options_sets.special_functions,
	 args= {eles= im_options}},
}

local confetti_options= {
	{name= "confetti_amount", meta= options_sets.adjustable_float,
	 args= confetti_val("amount", 0, 2000, 0, 2, 3)},
	{name= "confetti_min_size", meta= options_sets.adjustable_float,
	 args= confetti_val("min_size", 1, 512, 0, 1, 2)},
	{name= "confetti_max_size", meta= options_sets.adjustable_float,
	 args= confetti_val("max_size", 1, 512, 0, 1, 2)},
	{name= "confetti_min_fall", meta= options_sets.adjustable_float,
	 args= confetti_val("min_fall", 0, 60, -2, 0, 1)},
	{name= "confetti_max_fall", meta= options_sets.adjustable_float,
	 args= confetti_val("max_fall", 0, 60, -2, 0, 1)},
	{name= "confetti_lumax", meta= options_sets.adjustable_float,
	 args= confetti_val("lumax", 0, 256, -1, 1, 2)},
	{name= "confetti_spin", meta= options_sets.adjustable_float,
	 args= confetti_val("spin", 0, 3600, 0, 2, 3)},
	{name= "confetti_on", meta= options_sets.special_functions,
	 args= {
		 eles= {
			 { name= "On", init= function() return get_confetti("perm") end,
				 set= function() activate_confetti("perm", true) end,
				 unset= function() activate_confetti("perm", false) end}}}},
}

local menu_items= {
	{name= "cons_config", meta= options_sets.menu, args= consensual_options},
	{name= "reward_config", meta= options_sets.menu, args= reward_options},
	{name= "help_config", meta= options_sets.menu, args= help_options},
	{name= "flags_config", meta= options_sets.menu, args= flag_slot_options},
	{name= "pain_config", meta= options_sets.menu, args= pain_slot_options},
	{name= "confetti_config", meta= options_sets.menu, args= confetti_options},
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
					confetti_config:save()
					update_confetti_count()
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
