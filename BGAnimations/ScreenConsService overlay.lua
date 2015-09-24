local config_data= misc_config:get_data()
misc_config:set_dirty()

dofile(THEME:GetPathO("", "art_helpers.lua"))
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

local bubble_data= bubble_config:get_data()
local function bubble_val(name, min, max, min_scale, scale, max_scale)
	return {
		name= name, min_scale= min_scale, scale= scale, max_scale= max_scale,
		validator= function(v) return v >= min and v <= max end,
		initial_value= function() return bubble_data[name] end,
		set= function(pn, v)
			bubble_data[name]= v
			bubble_config:set_dirty()
			update_common_bg_colors()
		end
	}
end

local function bubble_amount(name, min, max, min_scale, scale, max_scale)
	return {
		name= name, min_scale= min_scale, scale= scale, max_scale= max_scale,
		validator= function(v) return v >= min and v <= max end,
		initial_value= function() return bubble_data[name] end,
		set= function(pn, v)
			bubble_data[name]= v
			bubble_config:set_dirty()
			update_common_bg_colors()
			reset_bubble_amount()
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

local function floating_center_pref_val(valname)
	return {
		name= valname, meta= options_sets.adjustable_float, args= {
			name= valname, min_scale= -3, scale= 0, max_scale= 3,
			initial_value= function()
				return PREFSMAN:GetPreference(valname)
			end,
			set= function(pn, value)
				PREFSMAN:SetPreference(valname, value)
				update_centering()
			end
	}}
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
local function pain_extern(menu, params)
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

local grade_data= grade_config:get_data()
local function fmt_gpct(i)
	return ("%.4f%%"):format(i)
end
local function grade_val_conf(index)
	return {
		name= fmt_gpct(grade_data[index]*100), meta= options_sets.adjustable_float,
		args= {
			name= fmt_gpct(grade_data[index]*100), min_scale= -4, scale= 1, max_scale= 1,
			initial_value= function() return grade_data[index]*100 end,
			set= function(pn, value) grade_data[index]= value/100 end,
			val_to_text= function(pn, value) return fmt_gpct(value) end,
	}}
end

local function gen_grade_image_menu()
	local eles= {}
	local function add_images_in_dir(dir)
		local image_list= FILEMAN:GetDirListing(dir)
		for i= 1, #image_list do
			local image= image_list[i]:sub(1, -5)
			local first_space= image:find(" ")
			if first_space then
				image= image:sub(1, first_space-1)
			end
			eles[i]= {
				name= image, init= function() return grade_data.file == image end,
				set= function() grade_data.file= image end,
				unset= function() end}
		end
	end
	for i, dir in ipairs(cons_theme_dir_list) do
		add_images_in_dir(dir .. "Graphics/grades/")
	end
	return {
		name= "change_image",
		meta= options_sets.mutually_exclusive_special_functions,
		args= {eles= eles}, disallow_unset= true}
end

local function gen_grade_options()
	local ret= {
		recall_init_on_pop= true,
		name= "grade_config",
		special_handler= function(menu, data)
			if data.name == "save_grade_config" then
				grade_config:save()
				return {}
			elseif data.name == "change_image" then
				grade_config:set_dirty()
				return {ret_data= {true, gen_grade_image_menu()}}
			elseif data.name == "add_grade" then
				grade_config:set_dirty()
				grade_data[#grade_data+1]= 0
				return {recall_init= true}
			elseif data.name == "remove_grade" then
				grade_config:set_dirty()
				if #grade_data > 1 then
					grade_data[#grade_data]= nil
				end
				return {recall_init= true}
			elseif data.name:sub(1, 3) == "set" then
				grade_config:set_dirty()
				set_grade_config(data.name:sub(11, -1))
				grade_data= grade_config:get_data()
				return {recall_init= true}
			else
				grade_config:set_dirty()
				return {ret_data= {true, data}}
			end
		end,
		{name= "save_grade_config"},
		{name= "change_image"},
	}
	for i, name in ipairs(grade_config_names) do
		ret[#ret+1]= {name= "set_grade_" .. name}
	end
	for i= 1, #grade_data do
		ret[#ret+1]= grade_val_conf(i)
	end
	ret[#ret+1]= {name= "add_grade"}
	ret[#ret+1]= {name= "remove_grade"}
	return ret
end

local scoring_data= scoring_config:get_data()
local function set_scoring_half(from, to)
	scoring_config:set_dirty()
	for name, value in pairs(scoring_data) do
		if name:find(to) then
			scoring_data[name]= scoring_data[from .. name:sub(#to+1, -1)]
		end
	end
end

local function scoring_options()
	local percent_score= {}
	local grade= {}
	local ret= {
		special_handler= function(menu, data)
			if data.name == "set_percent_to_grade" then
				set_scoring_half("Grade", "PercentScore")
				return {ret_data= {true}}
			elseif data.name == "set_grade_to_percent" then
				set_scoring_half("PercentScore", "Grade")
				return {ret_data= {true}}
			else
				return {ret_data= {true, data}}
			end
		end,
		{name= "percent_score", meta= options_sets.menu, args= percent_score},
		{name= "grade_weights", meta= options_sets.menu, args= grade},
		{name= "set_percent_to_grade"},
		{name= "set_grade_to_percent"},
	}
	for i, name in ipairs(THEME:GetMetricNamesInGroup("ScoreKeeperNormal")) do
		if scoring_data[name] then
			local entry= {
				name= name, meta= options_sets.adjustable_float, args= {
					name= name, min_scale= -3, scale= 0, max_scale= 3,
					initial_value= function() return scoring_data[name] end,
					set= function(pn, value) scoring_config:set_dirty()
						scoring_data[name]= value end,
			}}
			if name:find("PercentScore") then
				percent_score[#percent_score+1]= entry
			elseif name:find("Grade") then
				grade[#grade+1]= entry
			else
				ret[#ret+1]= entry
			end
		end
	end
	return ret
end

local life_data= life_config:get_data()
local function life_val_conf(name)
	return {
		name= name, meta= options_sets.adjustable_float, args= {
			name= name, min_scale= -4, scale= -3, max_scale= -1,
			initial_value= function() return life_data[name] end,
			set= function(pn, value) life_data[name]= value end,
			validator= function(value) return value >= -1 and value <= 1 end,
	}}
end

local function life_options()
	local ret= {
		special_handler= function(menu, data)
			if data.name:sub(1, 3) == "set" then
				life_config:set_dirty()
				set_life_config(data.name:sub(10, -1))
				life_data= life_config:get_data()
				return {ret_data= {true}}
			else
				return {ret_data= {true, data}}
			end
		end,
	}
	for i, name in ipairs(life_config_names) do
		ret[#ret+1]= {name= "set_life_" .. name}
	end
	for i, name in ipairs(life_config_value_names) do
		ret[#ret+1]= life_val_conf(name)
	end
	return ret
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

local function trans_type_extra()
	return {
		name= "transition_type", enum= transition_type_enum, fake_enum= true,
		get= function() return config_data.transition_type end,
		set= function(value) config_data.transition_type= value end,
		obj_get= noop_nil
	}
end

local function nopan_mode_omake()
	return {
		name= "default_expansion_mode", enum= expansion_mode_enum,
		fake_enum= true, obj_get= noop_nil,
		get= function() return config_data.default_expansion_mode end,
		set= function(value) config_data.default_expansion_mode= value end,
	}
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
	imop("im_have_offset", "offset_choice"),
	imop("im_have_exit", "exit_choice"),
}

local function sorting_options()
	local ret= {
		status= config_data.default_wheel_sort,
		special_handler= function(menu, data)
			config_data.default_wheel_sort= data.name
			menu.display:set_display(data.name)
			return {ret_data= {true}}
		end,
	}
	for i, item in ipairs(bucket_man:get_sort_names_for_menu()) do
		ret[#ret+1]= {name= item}
	end
	return ret
end

local consensual_options= {
	{name= "set_config_key", meta= options_sets.settable_thing,
	 args= key_get_set("config_menu_key")},
	{name= "set_color_key", meta= options_sets.settable_thing,
	 args= key_get_set("color_config_key")},
	{name= "set_censor_privilege_key", meta= options_sets.settable_thing,
	 args= key_get_set("censor_privilege_key")},
	{name= "set_enable_player_options", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("enable_player_options", "Yes", "No")},
	{name= "set_have_select", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("have_select_button", "Yes", "No")},
	{name= "set_cursor_button_icon_size", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("cursor_button_icon_size", -2, -1, 0)},
	{name= "set_ud_menus", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("menus_have_ud", "Yes", "No")},
	{name= "set_show_startup_time", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("show_startup_time", "Yes", "No")},
	{name= "set_save_last_played_on_eval", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("save_last_played_on_eval", "Yes", "No")},
	{name= "set_demo_idle", meta= options_sets.adjustable_float,
	 args= time_conf("screen_demo_idle_time", 0, 1, 2)},
	{name= "set_demo_show", meta= options_sets.adjustable_float,
	 args= time_conf("screen_demo_show_time", 0, 1, 2)},
	{name= "set_star_points", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("max_star_points", 0, 1, 3)},
	-- Not worth the effort right now.
--	{name= "set_line_height", meta= options_sets.adjustable_float,
--	 args= make_extra_for_conf_val("line_height", 0, 0, 1)},
	{name= "sex_per_clock_change", meta= options_sets.adjustable_float,
	 args= time_conf("seconds_per_clock_change", 0, 0, 3)},
	{name= "disable_extra_processing", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("disable_extra_processing", "Yes", "No")},
	{name= "transition_split_min", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("transition_split_min", 0, 0, 1)},
	{name= "transition_split_max", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("transition_split_max", 0, 0, 1)},
	{name= "transition_meta_var_max", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("transition_meta_var_max", 0, 0, 1)},
	{name= "transition_time", meta= options_sets.adjustable_float,
	 args= make_extra_for_conf_val("transition_time", -1, 0, 1)},
	{name= "transition_type", meta= options_sets.enum_option,
	 args= trans_type_extra()},
	{name= "initial_menu_choices", meta= options_sets.special_functions,
	 args= {eles= im_options}},
	{name= "default_wheel_sort", meta= options_sets.menu,
	 args= sorting_options()},
	{name= "default_expansion_mode", meta= options_sets.enum_option,
	 args= nopan_mode_omake()},
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

local bubble_options= {
	{name= "bubble_bg_tex_size", meta= options_sets.adjustable_float,
	 args= bubble_val("bg_tex_size", 2, 2048, 0, 2, 3)},
	{name= "bubble_bg_zoomx", meta= options_sets.adjustable_float,
	 args= bubble_val("bg_zoomx", 0, 4, -2, -1, 0)},
	{name= "bubble_bg_zoomy", meta= options_sets.adjustable_float,
	 args= bubble_val("bg_zoomy", 0, 4, -2, -1, 0)},
	{name= "bubble_bg_start_angle", meta= options_sets.adjustable_float,
	 args= bubble_val("bg_start_angle", -2, 2, -2, -1, 0)},
	{name= "bubble_square_bg", meta= options_sets.special_functions,
	 args= {
		 eles= {
			 { name= "On", init= function() return bubble_data.square_bg end,
				 set= function() bubble_data.square_bg= true
					 bubble_config:set_dirty() update_common_bg_colors() end,
				 unset= function() bubble_data.square_bg= false
					 bubble_config:set_dirty() update_common_bg_colors() end}}}},
	{name= "bubble_amount", meta= options_sets.adjustable_float,
	 args= bubble_amount("amount", 0, 128, 0, 1, 2)},
	{name= "bubble_pos_min_speed", meta= options_sets.adjustable_float,
	 args= bubble_val("pos_min_speed", 0, 512, -1, 0, 2)},
	{name= "bubble_pos_max_speed", meta= options_sets.adjustable_float,
	 args= bubble_val("pos_max_speed", 0, 512, -1, 0, 2)},
	{name= "bubble_min_size", meta= options_sets.adjustable_float,
	 args= bubble_val("min_size", 0, 512, 0, 1, 2)},
	{name= "bubble_max_size", meta= options_sets.adjustable_float,
	 args= bubble_val("max_size", 0, 512, 0, 1, 2)},
	{name= "bubble_size_min_speed", meta= options_sets.adjustable_float,
	 args= bubble_val("size_min_speed", 0, 1, -8, -2, -1)},
	{name= "bubble_size_max_speed", meta= options_sets.adjustable_float,
	 args= bubble_val("size_max_speed", 0, 1, -8, -2, -1)},
	{name= "bubble_min_color", meta= options_sets.adjustable_float,
	 args= bubble_val("min_color", 0, 1, -8, -2, -1)},
	{name= "bubble_max_color", meta= options_sets.adjustable_float,
	 args= bubble_val("max_color", 0, 1, -8, -2, -1)},
	{name= "bubble_color_min_speed", meta= options_sets.adjustable_float,
	 args= bubble_val("color_min_speed", 0, 1, -8, -2, -1)},
	{name= "bubble_color_max_speed", meta= options_sets.adjustable_float,
	 args= bubble_val("color_max_speed", 0, 1, -8, -2, -1)},
}

local special_options= {
	{name= "tag_by_genre", meta= "execute", execute= function()
		 tag_all_songs_with_genre_info("ProfileSlot_Machine")
		 save_tags("ProfileSlot_Machine")
		 SCREENMAN:SystemMessage(get_string_wrapper("ConsService", "finished_tagging"))
	end},
	{name= "set_adjust_mods_on_gameplay", meta= options_sets.boolean_option,
	 args= make_extra_for_bool_val("adjust_mods_on_gameplay", "Yes", "No")},
	{name= "reload_mods_adjust_keys", meta= "execute", execute= function()
		 reload_mods_adjust_keys()
		 SCREENMAN:SystemMessage(get_string_wrapper("ConsService", "finished_loading_mods_adjust_keys"))
	end},
	floating_center_pref_val("CenterImageAddHeight"),
	floating_center_pref_val("CenterImageAddWidth"),
	floating_center_pref_val("CenterImageTranslateX"),
	floating_center_pref_val("CenterImageTranslateY"),
}

local menu_items= {
	{name= "cons_config", meta= options_sets.menu, args= consensual_options},
	{name= "reward_config", meta= options_sets.menu, args= reward_options},
	{name= "help_config", meta= options_sets.menu, args= help_options},
	{name= "flags_config", meta= options_sets.menu, args= flag_slot_options},
	{name= "pain_config", meta= options_sets.menu, args= pain_slot_options},
	{name= "grade_config", meta= options_sets.menu, args= gen_grade_options},
	{name= "scoring_config", meta= options_sets.menu, args= scoring_options()},
	{name= "life_config", meta= options_sets.menu, args= life_options()},
	{name= "confetti_config", meta= options_sets.menu, args= confetti_options},
	{name= "bubble_config", meta= options_sets.menu, args= bubble_options},
	{name= "offset_config", meta= options_sets.menu, args= get_offset_service_menu},
	{name= "special_options", meta= options_sets.menu, args= special_options},
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
					local metrics_need_to_be_reloaded= scoring_config:check_dirty() or
						life_config:check_dirty()
					misc_config:save()
					confetti_config:save()
					bubble_config:save()
					update_confetti_count()
					machine_flag_setting:save()
					machine_pain_setting:save()
					scoring_config:save()
					life_config:save()
					if metrics_need_to_be_reloaded then
						THEME:ReloadMetrics()
					end
					trans_new_screen("ScreenInitialMenu")
				end
			end
			update_help()
		end
		return false
	end
	return false
end

local function quaid(x, y, w, h, c, ha, va)
	return Def.Quad{
		InitCommand= function(self)
			self:xy(x, y):setsize(w, h):diffuse(c):horizalign(ha):vertalign(va)
		end
	}
end
local red= fetch_color("accent.red")
local blue= fetch_color("accent.blue")
local menu_disps= 2
local display_height= DISPLAY:GetDisplayHeight()
if display_height >= 720 then
	menu_disps= 3
end
if display_height >= 1080 then
	menu_disps= 4
end
local menu_zoom= 2 / menu_disps
local menu_elh= 24 * menu_zoom

return Def.ActorFrame{
	InitCommand= function(self)
		config_menu:push_options_set_stack(options_sets.menu, menu_items, "Exit Menu")
		config_menu:update_cursor_pos()
		update_help()
	end,
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.ActorFrame{
		quaid(0, 0, _screen.w, 1, red, left, top),
		quaid(0, _screen.h, _screen.w, 1, red, left, bottom),
		quaid(0, 0, 1, _screen.h, blue, left, top),
		quaid(_screen.w, 0, 1, _screen.h, blue, right, top),
	},
	config_menu:create_actors("menu", 0, 10, _screen.w, _screen.h, nil, menu_disps, menu_elh, menu_zoom),
	pain_display:create_actors("pain", _screen.w*.75, 80, nil, 184, .625),
	helper:create_actors("helper", config_data.service_help_time, "ConsService", ""),
	Def.ActorFrame{
		Name= "press prompt",
		InitCommand= function(self)
			press_prompt= self
			self:xy(_screen.cx, _screen.cy):visible(false)
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
