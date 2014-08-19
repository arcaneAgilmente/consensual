local default_flag_set= {
	{
		eval= {
			banner= true,
			best_scores= false,
			chart_info= true,
			combo_graph= true,
			dance_points= true,
			judge_list= false,
			life_graph= true,
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
			dance_points= false,
			judge= false,
			offset= false,
			pct_score= true,
			score_meter= true,
			sigil= false,
		},
		interface= {
			straight_floats= false,
		}
	},
	{
		eval= {
			banner= true,
			best_scores= true,
			chart_info= true,
			combo_graph= true,
			dance_points= true,
			judge_list= false,
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
			dance_points= true,
			pct_score= false,
			judge= false,
			offset= false,
			score_meter= true,
			sigil= false,
		},
		interface= {
			straight_floats= false,
		}
	},
	{
		eval= {
			banner= true,
			best_scores= true,
			chart_info= true,
			combo_graph= true,
			dance_points= true,
			judge_list= false,
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
		}
	},
	{
		eval= {
			banner= true,
			best_scores= true,
			chart_info= true,
			combo_graph= true,
			dance_points= true,
			judge_list= true,
			life_graph= true,
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
			straight_floats= true,
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
	 "pct_column",
	 "session_column",
	 "song_column",
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
	 "judge",
	 "offset",
	 "score_meter",
	 "sigil",
	},
	{type= "interface",
	 "straight_floats",
	}
}
sorted_eval_flag_names= sorted_flag_names[1]
sorted_gameplay_flag_names= sorted_flag_names[2]
sorted_interface_flag_names= sorted_flag_names[3]

machine_flag_setting= create_setting("machine flag config", "flag_config.lua", default_flag_set, -1)
profile_flag_setting= create_setting("player flag config", "flag_config.lua", default_flag_set[1], -1)

machine_flag_setting:load()

function get_default_flag_config(level)
	local machine_data= machine_flag_setting:get_data()
	if machine_data[level] then
		return DeepCopy(machine_data[level])
	else
		return DeepCopy(machine_data[1])
	end
end

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
}

player_config= create_setting("player_config", "player_config.lua", default_config, -1)
