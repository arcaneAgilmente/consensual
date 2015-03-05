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
	transition_type= "random",

	menus_have_ud= true,
	show_startup_time= true,

	seconds_per_clock_change= 3600,

	config_menu_key= "DeviceButton_z",
	color_config_key= "DeviceButton_b",
	censor_privilege_key= "DeviceButton_c",

	screen_demo_idle_time= 60,
	screen_demo_show_time= 120,

	line_height= 24,

	max_star_points= -1,

	initial_menu_ops= {
		single_choice= true,
		versus_choice= true,
		playmode_choice= true,
		profile_choice= true,
		stepmania_ops= true,
		consensual_ops= true,
		color_config= true,
		edit_choice= true,
		offset_choice= true,
		exit_choice= true,
	},
}

transition_type_enum= {"skew", "scramble", "random"}

sorted_initial_menu_ops= {
	"single_choice",
	"versus_choice",
	"playmode_choice",
	"profile_choice",
	"stepmania_ops",
	"consensual_ops",
	"color_config",
	"edit_choice",
	"offset_choice",
	"exit_choice",
}

misc_config= create_setting("misc config", "misc_config.lua", default_config, -1)
misc_config:load()

function get_line_height()
	return misc_config:get_data().line_height
end

function ud_menus()
	return misc_config:get_data().menus_have_ud
end

function screen_demonstration_show_time()
	return misc_config:get_data().screen_demo_show_time
end

-- Gametype compatibility:  Any new game mode will need to have its menu
-- reverse mapping added to this.
local reverse_menu_button_mapping= {
	dance= {
		MenuLeft= "Left", MenuRight= "Right", MenuUp= "Up", MenuDown= "Down"
	},
	pump= {
		MenuLeft= "DownLeft", MenuRight= "DownRight", MenuUp= "UpLeft", MenuDown= "UpRight"
	},
	kb7= {
		MenuLeft= "Key2", MenuRight= "Key3", MenuUp= "Key5", MenuDown= "Key6"
	},
	ez2= {
		MenuLeft= "HandUpLeft", MenuRight= "HandUpRight", MenuUp= "FootUpLeft", MenuDown= "FootUpRight"
	},
	para= {
		MenuLeft= "Left", MenuRight= "Right", MenuUp= "UpRight", MenuDown= "UpLeft"
	},
	ds3ddx= {
		MenuLeft= "HandLeft", MenuRight= "HandRight", MenuUp= "HandUp", MenuDown= "HandDown"
	},
	beat= {
		MenuLeft= "Key1", MenuRight= "Key3", MenuUp= "Scratch up", MenuDown= "Scratch down"
	},
	maniax= {
		MenuLeft= "HandUpLeft", MenuRight= "HandUpRight", MenuUp= "HandLrRight", MenuDown= "HandLrLeft"
	},
	techno= {
		MenuLeft= "Left", MenuRight= "Right", MenuUp= "Up", MenuDown= "Down"
	},
	popn= {
		MenuLeft= "Left Blue", MenuRight= "Right Blue", MenuUp= "Left Yellow", MenuDown= "Right Yellow"
	},
	lights= {
		MenuLeft= "MarqueeUpLeft", MenuRight= "MarqueeUpRight", MenuUp= "MarqueeLrLeft", MenuDown= "MarqueeLrRight"
	},
	kickbox= {
		MenuLeft= "UpLeftFist", MenuRight= "UpRightFist", MenuUp= "DownLeftFist", MenuDown= "DownRightFist"
	},
}

local game_name= GAMESTATE:GetCurrentGame():GetName()
local rev_map= reverse_menu_button_mapping[game_name]

function reverse_menu_button(button)
	if not rev_map then
		return button
	end
	return rev_map[button] or button
end

function reverse_button_list(list)
	if not PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
		for i, button in ipairs(list) do
			button[2]= reverse_menu_button(button[2])
		end
	end
end

function button_list_for_menu_cursor()
	local button_list= {}
	if ud_menus() then
		button_list= {{"top", "MenuUp"}, {"bottom", "MenuDown"}}
	else
		button_list= {{"top", "MenuLeft"}, {"bottom", "MenuRight"}}
	end
	reverse_button_list(button_list)
	return button_list
end

-- Planned but unimplemented:  (doable on request)
--	menu_grace_time= 0, -- The amount of time the player can spend on a menu screen before time starts being deducted from their play time.
--	menu_time_multiplier= 0, -- Time spent on a menu screen is multiplied by this amount before being deducted from the play time.  0 means menu time is free, .5 means that 2 seconds on a menu takes 1 second off of play time.
