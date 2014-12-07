local default_config= {
	default_credit_time= 60 * 6, -- The default starting amount of play time for one credit.
	min_remaining_time= 0, -- The minimum remaining time for the set to continue.
	song_length_grace= 120, -- This grace amount is added to time remaining when filtering which songs are on the song wheel.  Only applies when not in event mode.
	min_score_for_reward= .75, -- The minimum score to be rewarded with some more time.  At this score, the player will get the min reward.  At a score of 1 (100%), the player will get the max reward.  The reward changes linearly in between.
	-- Two modes for the time rewarding system:
	-- Reward by percent, rewards the player with an amount of time based on the length of the song time.  Song length is multiplied by the reward value and the result is added to the time remaining.
	reward_time_by_pct= true,
	min_reward_pct= 0,
	max_reward_pct= .25,
	-- Reward by time, rewards the player with a fixed amount of time, ignoring song length.  The reward value is added to the remaining time.
	min_reward_time= 0,
	max_reward_time= 30,

	-- Whether to show automatic help on screens.
	select_music_help_time= 10,
	evaluation_help_time= 60,
	service_help_time= 10,
	color_help_time= 5,
	ssm_advanced_help= true,

	gameplay_reset_limit= 5,
	have_select_button= true,

	transition_split_min= 1,
	transition_split_max= 64,
	transition_meta_var_max= 64,

	menus_have_ud= true,

	seconds_per_clock_change= 3600,

	config_menu_key= "DeviceButton_z",
	color_config_key= "DeviceButton_b",
	censor_privilege_key= "DeviceButton_c",

	initial_menu_ops= {
		single_choice= true,
		versus_choice= true,
		playmode_choice= true,
		profile_choice= true,
		stepmania_ops= true,
		consensual_ops= true,
		color_config= true,
		edit_choice= true,
		exit_choice= true,
	},
}

sorted_initial_menu_ops= {
	"single_choice",
	"versus_choice",
	"playmode_choice",
	"profile_choice",
	"stepmania_ops",
	"consensual_ops",
	"color_config",
	"edit_choice", -- coming soon
	"exit_choice",
}

misc_config= create_setting("misc config", "misc_config.lua", default_config, -1)
misc_config:load()

function ud_menus()
	return misc_config:get_data().menus_have_ud
end

-- Planned but unimplemented:  (doable on request)
--	menu_grace_time= 0, -- The amount of time the player can spend on a menu screen before time starts being deducted from their play time.
--	menu_time_multiplier= 0, -- Time spent on a menu screen is multiplied by this amount before being deducted from the play time.  0 means menu time is free, .5 means that 2 seconds on a menu takes 1 second off of play time.
