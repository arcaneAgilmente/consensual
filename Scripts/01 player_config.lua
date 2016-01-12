local default_flag_set= {
	eval= {
		banner= {true},
		best_scores= {false, true},
		chart_info= {true},
		color_combo= {false, false, true},
		color_grade= {true},
		color_life_by_value= {true},
		color_life_by_combo= {false, false, true},
		combo_graph= {true},
		dance_points= {true},
		grade= {true},
		judge_list= {true},
		life_graph= {true},
		lock_per_arrow= {true, true, true, false},
		lowest_life= {false, false, false, true},
		offset= {false, false, false, true},
		pct_column= {false, true},
		pct_score= {true},
		profile_data= {true},
		reward= {true},
		score_early_late= {false, false, false, true},
		session_column= {false, false, false, true},
		song_column= {true},
		style_pad= {true},
		sum_column= {false, false, false, true},
	},
	gameplay= {
		allow_toasty= {true},
		bpm= {true},
		chart_info= {true},
		combo_confetti= {true},
		dance_points= {false, true},
		error_bar= {false, false, false, true},
		judge_list= {false, false, true},
		judge_flashes= {false, false, false, false},
		pct_score= {true},
		score_confetti= {true},
		score_meter= {true},
		score_splash= {true},
		sigil= {false, false, false, true},
		still_judge= {false, false, false, true},
		subtractive_score= {false, false, false, true},
		surround_life= {false, false, false, true},
	},
	interface= {
		easier_random= {false, false, true},
		harder_random= {false, false, true},
		same_random= {false, true},
		score_random= {false, false, false, true},
		unplayed_random= {false, false, true},
		low_score_random= {false, false, false, true},
		music_wheel_grades= {true},
		straight_floats= {false, false, false, true},
		verbose_bpm= {false, false, false, true},
	}
}

sorted_flag_names= {
	{type= "eval",
	 "chart_info",
	 "grade",
	 "pct_score",
	 "dance_points",
	 "offset",
	 "score_early_late",
	 "lock_per_arrow",
	 "color_combo",
	 "color_grade",
	 "color_life_by_value",
	 "color_life_by_combo",
	 "pct_column",
	 "song_column",
	 "session_column",
	 "sum_column",
	 "best_scores",
	 "profile_data",
	 "combo_graph",
	 "life_graph",
	 "lowest_life",
	 "style_pad",
	 "banner",
	 "judge_list",
	 "reward",
	},
	{type= "gameplay",
	 "allow_toasty",
	 "bpm",
	 "chart_info",
	 "combo_confetti",
	 "dance_points",
	 "pct_score",
	 "score_splash",
	 "judge_list",
	 "judge_flashes",
	 "error_bar",
	 "score_confetti",
	 "score_meter",
	 "sigil",
	 "still_judge",
	 "subtractive_score",
	 "surround_life",
	},
	{type= "interface",
	 "easier_random",
	 "harder_random",
	 "same_random",
	 "score_random",
--	 "unplayed_random",
--	 "low_score_random",
	 "music_wheel_grades",
	 "straight_floats",
	 "verbose_bpm",
	}
}
sorted_eval_flag_names= sorted_flag_names[1]
sorted_gameplay_flag_names= sorted_flag_names[2]
sorted_interface_flag_names= sorted_flag_names[3]

machine_flag_setting= create_setting("machine flag config", "flag_config.lua", default_flag_set, -1)
machine_flag_setting:load()

function get_default_flag_config(level)
	local machine_data= machine_flag_setting:get_data()
	local ret= {}
	for group_name, group_values in pairs(machine_data) do
		ret[group_name]= {}
		for flag_name, flag_levels in pairs(group_values) do
			ret[group_name][flag_name]= flag_levels[math.min(level, #flag_levels)]
		end
	end
	return ret
end

profile_flag_setting= create_setting("player flag config", "flag_config.lua", get_default_flag_config(1), -1)

function set_player_flag_to_level(pn, level)
	local machine_flags= machine_flag_setting:get_data()
	local slot= pn_to_profile_slot(pn)
	local player_flags= profile_flag_setting:get_data(slot)
	for set_name, set in pairs(machine_flags) do
		for name, levels in pairs(set) do
			player_flags[set_name][name]= levels[math.min(level, #levels)]
		end
	end
	profile_flag_setting:set_dirty(slot)
	return player_flags
end

local dspeed_default_min= 0
local dspeed_default_max= 2
do
	local receptor_min= THEME:GetMetric("Player", "ReceptorArrowsYStandard")
	local receptor_max= THEME:GetMetric("Player", "ReceptorArrowsYReverse")
	local arrow_height= THEME:GetMetric("ArrowEffects", "ArrowSpacing")
	local field_height= receptor_max - receptor_min
	local center_effect_size= field_height / 2
	dspeed_default_min= (SCREEN_CENTER_Y + receptor_min) / -center_effect_size
	dspeed_default_max= (SCREEN_CENTER_Y + receptor_max) / center_effect_size
end

mine_effects= {
	stealth= {
		apply=
			function(pn)
				cons_players[pn].song_options:Stealth(.75, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Stealth(0, .75)
			end,
		time= .0625
	},
	boomerang= {
		apply=
			function(pn)
				cons_players[pn].song_options:Boomerang(1, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Boomerang(0, 1)
			end,
		time= .0625
	},
	brake= {
		apply=
			function(pn)
				cons_players[pn].song_options:Brake(1, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Brake(0, 1)
			end,
		time= .0625
	},
	tiny= {
		apply=
			function(pn)
				cons_players[pn].song_options:Tiny(1, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Tiny(0, 1)
			end,
		time= .0625
	},
	none= {
		apply= noop_nil,
		unapply= noop_nil,
		time= .0625
	},
}

sorted_mine_effect_names= {
	"stealth",
	"boomerang",
	"brake",
	"tiny",
	"none",
}

local v1config= {
	speed_info= {mode= "m", speed= 250},
	sigil_data= {detail= 16, size= 150},
	dspeed= {min= dspeed_default_min, max= dspeed_default_max, alternate= false},
	mine_effect= sorted_mine_effect_names[1],
	options_level= 1,
	rating_cap= -1,
	toasty_level= 1,
	combo_splash_threshold= "TapNoteScore_W3",
	combo_graph_threshold= "TapNoteScore_W3",
	low_score_random_threshold= .9,
	preferred_style= "single",
	experience_level= 1, -- To ease triggering confetti on gaining a level.
	judgment_hoffset= 0,
	judgment_offset= -30,
	combo_hoffset= 0,
	combo_offset= 60,
	ALL_SETTINGS_MIGRATED_TO_V2= false,
}

local default_config= {
	speed_info= {mode= "m", speed= 250},
	persistent_mods= {},
	cons_persistent_mods= {},
	persistent_song_mods= {},
	sigil_data= {detail= 16},
	dspeed= {min= dspeed_default_min, max= dspeed_default_max, alternate= false},
	mine_effect= sorted_mine_effect_names[1],
	-- TODO:  Make a system similar to the flags levels for options_level,
	-- rating_cap, combo_splash_threshold, and combo_graph_threshold.
	options_level= 4,
	rating_cap= -1,
	toasty_level= 1,
	error_history_size= 32,
	error_history_threshold= "TapNoteScore_Miss",
	combo_splash_threshold= "TapNoteScore_W3",
	combo_graph_threshold= "TapNoteScore_W3",
	low_score_random_threshold= .9,
	preferred_steps_type= "",
	preferred_sort= "",
	music_info_expansion_mode= "",
	select_music= {
		hide_empty_pane= false,
		show_inactive_pane= false,
		show_pane_during_song_select= true,
		wheel_layout= "middle",
	},
	experience_level= 1, -- To ease triggering confetti on gaining a level.
	life_blank_percent= .25,
	life_use_width= 1,
	life_stages= 1,
	notefield_config= {
		fov= 45,
		reverse= 1,
		rot_x= 0,
		rot_y= 0,
		rot_z= 0,
		use_separate_zooms= false,
		vanish_x= 0,
		vanish_y= 0,
		yoffset= -88,
		zoom= 1,
		zoom_x= 1,
		zoom_y= 1,
		zoom_z= 1,
	},
	pause_hold_time= 0,
	gameplay_element_colors= {
		filter= fetch_color("accent.violet", 0),
		life_full_outer= fetch_color("accent.blue"),
		life_full_inner= fetch_color("accent.cyan", 0),
		life_empty_outer= fetch_color("accent.red"),
		life_empty_inner= fetch_color("accent.magenta", 0),
	},
	gameplay_element_positions= {
		bpm_xoffset= 0,
		bpm_yoffset= 211,
		bpm_scale= 1,
		chart_info_xoffset= 0,
		chart_info_yoffset= -204,
		chart_info_scale= 1,
		combo_xoffset= 0,
		combo_yoffset= 60,
		combo_scale= 1,
		error_bar_xoffset= 0,
		error_bar_yoffset= 30,
		error_bar_scale= 1,
		judgment_xoffset= 0,
		judgment_yoffset= -30,
		judgment_scale= 1,
		judge_list_xoffset= 0,
		judge_list_yoffset= 55,
		judge_list_scale= .75,
		notefield_xoffset= 0,
		notefield_yoffset= 0,
		score_xoffset= 0,
		score_yoffset= -228,
		score_scale= 1,
		sigil_xoffset= 0,
		sigil_yoffset= -60,
		sigil_scale= 1,
	},
}

v1_player_config= create_setting("player_config", "player_config.lua", v1config, -1)
player_config= create_setting("player_config", "player_config_v2.lua", default_config, -1, {"persistent_mods", "cons_persistent_mods", "persistent_song_mods"})

function update_old_player_config(prof_slot, config)
	-- Reverse changed engine-side from [0, 1] range to [1, -1] range.
	if config.notefield_config.reverse == 0 then
		config.notefield_config.reverse= 1
	end
	local fname= v1_player_config:get_filename(prof_slot)
	if not fname then return end
	if FILEMAN:DoesFileExist(fname) then
		local old_config= v1_player_config:load(prof_slot)
		if old_config.ALL_SETTINGS_MIGRATED_TO_V2 then return end
		old_config.ALL_SETTINGS_MIGRATED_TO_V2= true
		v1_player_config:set_dirty(prof_slot)
		v1_player_config:save(prof_slot)
		local to_deep_copy= {"speed_info", "sigil_data", "dspeed"}
		local to_straight_copy= {
			"mine_effect", "options_level", "rating_cap", "toasty_level",
			"combo_splash_threshold", "combo_graph_threshold", "preferred_style",
			"experience_level"}
		for i, tdc in ipairs(to_deep_copy) do
			config[tdc]= DeepCopy(old_config[tdc])
		end
		for i, tsc in ipairs(to_straight_copy) do
			config[tsc]= old_config[tsc]
		end
		config.gameplay_element_positions.judgment_xoffset=
			old_config.judgment_hoffset
		config.gameplay_element_positions.judgment_yoffset=
			old_config.judgment_offset
		config.gameplay_element_positions.combo_xoffset= old_config.combo_hoffset
		config.gameplay_element_positions.combo_yoffset= old_config.combo_offset
		SCREENMAN:SystemMessage("Loaded old player config from '" .. fname .. "'.  That config file can be safely deleted.")
		return true
	end
end
