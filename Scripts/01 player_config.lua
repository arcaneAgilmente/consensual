-- TODO:  Make it possible to configure the number of levels and not have
-- 200+ lines of default config in here.
local default_flag_set= {
	{
		eval= {
			banner= true,
			best_scores= false,
			chart_info= true,
			color_combo= false,
			color_life_by_value= true,
			color_life_by_combo= false,
			combo_graph= true,
			dance_points= true,
			judge_list= false,
			life_graph= true,
			lock_per_arrow= true,
			offset= false,
			pct_column= false,
			pct_score= true,
			profile_data= true,
			reward= true,
			score_early_late= false,
			session_column= false,
			song_column= true,
			style_pad= true,
			sum_column= false,
		},
		gameplay= {
			allow_toasty= true,
			bpm_meter= true,
			chart_info= true,
			score_splash= true,
			dance_points= false,
			judge= false,
			offset= false,
			pct_score= true,
			score_meter= true,
			sigil= false,
		},
		interface= {
			easier_random= false,
			harder_random= false,
			same_random= false,
			score_random= false,
			straight_floats= false,
			verbose_bpm= false,
		}
	},
	{
		eval= {
			banner= true,
			best_scores= true,
			chart_info= true,
			color_combo= false,
			color_life_by_value= true,
			color_life_by_combo= false,
			combo_graph= true,
			score_splash= true,
			dance_points= true,
			judge_list= false,
			lock_per_arrow= true,
			life_graph= true,
			offset= false,
			pct_column= true,
			pct_score= true,
			profile_data= true,
			reward= true,
			score_early_late= false,
			session_column= false,
			song_column= true,
			style_pad= true,
			sum_column= false,
		},
		gameplay= {
			allow_toasty= true,
			bpm_meter= true,
			chart_info= true,
			score_splash= true,
			dance_points= true,
			pct_score= false,
			judge= false,
			offset= false,
			score_meter= true,
			sigil= false,
		},
		interface= {
			easier_random= false,
			harder_random= false,
			same_random= true,
			score_random= false,
			straight_floats= false,
			verbose_bpm= false,
		}
	},
	{
		eval= {
			banner= true,
			best_scores= true,
			chart_info= true,
			color_combo= true,
			color_life_by_value= false,
			color_life_by_combo= true,
			combo_graph= true,
			score_splash= true,
			dance_points= true,
			judge_list= false,
			life_graph= true,
			lock_per_arrow= true,
			offset= false,
			pct_column= true,
			pct_score= true,
			profile_data= true,
			reward= true,
			score_early_late= false,
			session_column= false,
			song_column= true,
			style_pad= true,
			sum_column= true,
		},
		gameplay= {
			allow_toasty= true,
			bpm_meter= true,
			chart_info= true,
			dance_points= true,
			pct_score= true,
			judge= true,
			offset= false,
			score_meter= true,
			sigil= false,
		},
		interface= {
			straight_floats= false,
			easier_random= true,
			harder_random= true,
			same_random= true,
			score_random= false,
			verbose_bpm= false,
		}
	},
	{
		eval= {
			banner= true,
			best_scores= true,
			chart_info= true,
			color_combo= true,
			color_life_by_value= true,
			color_life_by_combo= true,
			combo_graph= true,
			score_splash= true,
			dance_points= true,
			judge_list= true,
			life_graph= true,
			lock_per_arrow= false,
			offset= true,
			pct_column= true,
			pct_score= true,
			profile_data= true,
			reward= true,
			score_early_late= true,
			session_column= true,
			song_column= true,
			style_pad= true,
			sum_column= true,
		},
		gameplay= {
			allow_toasty= true,
			bpm_meter= true,
			chart_info= true,
			dance_points= true,
			pct_score= true,
			judge= true,
			offset= true,
			score_meter= true,
			sigil= true,
		},
		interface= {
			easier_random= true,
			harder_random= true,
			same_random= true,
			score_random= true,
			straight_floats= true,
			verbose_bpm= false,
		}
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
	 "dance_points",
	 "pct_score",
	 "score_splash",
	 "judge",
	 "offset",
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
	if machine_data[level] then
		return DeepCopy(machine_data[level])
	else
		return DeepCopy(machine_data[1])
	end
end

profile_flag_setting= create_setting("player flag config", "flag_config.lua", get_default_flag_config(1), -1)

function set_player_flag_to_level(pn, level)
	local config= get_default_flag_config(level)
	local slot= pn_to_profile_slot(pn)
	profile_flag_setting:set_data(slot, config)
	profile_flag_setting:set_dirty(slot)
	return config
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
	combo_splash_threshold= "TapNoteScore_W3",
	combo_graph_threshold= "TapNoteScore_W3",
	preferred_style= "single",
}

player_config= create_setting("player_config", "player_config.lua", default_config, -1)

function get_preferred_style(pn)
	return player_config:get_data(pn_to_profile_slot(pn)).preferred_style
end

function set_preferred_style(pn, value)
	player_config:set_dirty(pn_to_profile_slot(pn))
	player_config:get_data(pn_to_profile_slot(pn)).preferred_style= value
end
