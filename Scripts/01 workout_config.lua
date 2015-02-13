workout_goal_types= {
	"calories", "step_count", "time",
}

workout_step_or_calorie_multiplier= 100
workout_counted_steps= {
	"TapNoteScore_W1", "TapNoteScore_W2", "TapNoteScore_W3", "TapNoteScore_W4"}

local default_config= {
	goal_type= workout_goal_types[1],
	goal_target= 6,
	use_nps_to_rate= false,
	start_meter= 8,
	easier_threshold= .8,
	harder_threshold= .95,
	allow_pause_midsong= false,
	use_workout_tag= false,
	use_favor_level= false,
}

sorted_workout_field_names= {
	"goal_type",
	"goal_target",
	"use_nps_to_rate",
	"start_meter",
	"easier_threshold",
	"harder_threshold",
	"allow_pause_midsong",
	"use_workout_tag",
	"use_favor_level",
}

workout_config= create_setting("workout config", "workout_config.lua", default_config, -1)
