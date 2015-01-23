local default_flag_set= {
	eval= {
		banner= {true},
		best_scores= {false, true},
		chart_info= {true},
		color_combo= {false, false, true},
		color_life_by_value= {true},
		color_life_by_combo= {false, false, true},
		combo_graph= {true},
		dance_points= {true},
		judge_list= {true},
		life_graph= {true},
		lock_per_arrow= {true, true, true, false},
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
		bpm_meter= {true},
		chart_info= {true},
		combo_confetti= {true},
		dance_points= {false, true},
		judge= {false, false, true},
		offset= {false, false, false, true},
		pct_score= {true},
		score_confetti= {true},
		score_meter= {true},
		score_splash= {true},
		sigil= {false, false, false, true},
	},
	interface= {
		easier_random= {false, false, true},
		harder_random= {false, false, true},
		same_random= {false, true},
		score_random= {false, false, false, true},
		straight_floats= {false, false, false, true},
		verbose_bpm= {false, false, false, true},
	}
}

sorted_flag_names= {
	{type= "eval",
	 "chart_info",
	 "pct_score",
	 "dance_points",
	 "offset",
	 "score_early_late",
	 "lock_per_arrow",
	 "color_combo",
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
	 "style_pad",
	 "banner",
	 "judge_list",
	 "reward",
	},
	{type= "gameplay",
	 "allow_toasty",
	 "bpm_meter",
	 "chart_info",
	 "combo_confetti",
	 "dance_points",
	 "pct_score",
	 "score_splash",
	 "judge",
	 "offset",
	 "score_confetti",
	 "score_meter",
	 "sigil",
	},
	{type= "interface",
	 "easier_random",
	 "harder_random",
	 "same_random",
	 "score_random",
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

local default_config= {
	speed_info= {mode= "m", speed= 250},
	sigil_data= {detail= 16, size= 150},
	dspeed= {min= dspeed_default_min, max= dspeed_default_max, alternate= false},
	mine_effect= sorted_mine_effect_names[1],
	-- TODO:  Make a system similar to the flags levels for options_level,
	-- rating_cap, combo_splash_threshold, and combo_graph_threshold.
	options_level= 1,
	rating_cap= -1,
	toasty_level= 1,
	combo_splash_threshold= "TapNoteScore_W3",
	combo_graph_threshold= "TapNoteScore_W3",
	preferred_style= "single",
	experience_level= 1, -- To ease triggering confetti on gaining a level.
	judgment_offset= -30,
	combo_offset= 60,
}

player_config= create_setting("player_config", "player_config.lua", default_config, -1)

function get_preferred_style(pn)
	return player_config:get_data(pn_to_profile_slot(pn)).preferred_style
end

function set_preferred_style(pn, value)
	player_config:set_dirty(pn_to_profile_slot(pn))
	player_config:get_data(pn_to_profile_slot(pn)).preferred_style= value
end
