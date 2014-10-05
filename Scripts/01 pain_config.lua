max_pain_rows= 14

local default_config= {
	{{
			{is_wide= true, score= {machine= true, slot= 1}},
			{is_wide= true, score= {slot= 1}},
			{bpm= true},
			{meter= true},
			{radar_category= "RadarCategory_TapsAndHolds"},
			{radar_category= "RadarCategory_Holds"},
			{radar_category= "RadarCategory_Jumps"},
			{radar_category= "RadarCategory_Mines"},
	 },{
			{},
			{},
			{favor= "machine"},
			{favor= "player"},
			{tag= {machine= true, slot= 1}},
			{tag= {machine= true, slot= 2}},
			{tag= {slot= 1}},
			{tag= {slot= 2}},
	}},
	{{
			{bpm= true},
			{meter= true},
			{radar_category= "RadarCategory_TapsAndHolds"},
			{radar_category= "RadarCategory_Holds"},
			{radar_category= "RadarCategory_Jumps"},
			{radar_category= "RadarCategory_Mines"},
			{is_wide= true, score= {machine= true, slot= 1}},
			{is_wide= true, score= {slot= 1}},
	 },{
			{favor= "machine"},
			{favor= "player"},
			{tag= {machine= true, slot= 1}},
			{tag= {machine= true, slot= 2}},
			{tag= {slot= 1}},
			{tag= {slot= 2}},
	}},
	{{
			{bpm= true},
			{meter= true},
			{radar_category= "RadarCategory_TapsAndHolds"},
			{radar_category= "RadarCategory_Holds"},
			{radar_category= "RadarCategory_Jumps"},
			{radar_category= "RadarCategory_Mines"},
			{radar_category= "RadarCategory_Hands"},
			{radar_category= "RadarCategory_Rolls"},
			{},
			{is_wide= true, score= {machine= true, slot= 1}},
			{is_wide= true, score= {machine= true, slot= 2}},
			{is_wide= true, score= {slot= 1}},
			{is_wide= true, score= {slot= 2}},
	 },{
			{author= true},
			{favor= "machine"},
			{favor= "player"},
			{tag= {machine= true, slot= 1}},
			{tag= {machine= true, slot= 2}},
			{tag= {machine= true, slot= 3}},
			{tag= {slot= 1}},
			{tag= {slot= 2}},
			{tag= {slot= 3}},
	}},
	{{
			{radar_category= "RadarCategory_TapsAndHolds"},
			{radar_category= "RadarCategory_Holds"},
			{radar_category= "RadarCategory_Jumps"},
			{radar_category= "RadarCategory_Mines"},
			{radar_category= "RadarCategory_Hands"},
			{radar_category= "RadarCategory_Rolls"},
			{score= {machine= true, slot= 1}},
			{score= {machine= true, slot= 2}},
			{score= {machine= true, slot= 3}},
			{score= {machine= true, slot= 4}},
			{score= {slot= 1}},
			{score= {slot= 2}},
			{score= {slot= 3}},
			{score= {slot= 4}},
	 },{
			{author= true},
			{bpm= true},
			{meter= true},
			{favor= "machine"},
			{favor= "player"},
			{tag= {machine= true, slot= 1}},
			{tag= {machine= true, slot= 2}},
			{tag= {machine= true, slot= 3}},
			{tag= {machine= true, slot= 4}},
			{tag= {slot= 1}},
			{tag= {slot= 2}},
			{tag= {slot= 3}},
			{tag= {slot= 4}},
	}}
}

machine_pain_setting= create_setting("machine pain config", "pain_config.lua", default_config, 2)
machine_pain_setting:load()
profile_pain_setting= create_setting("player pain config", "pain_config.lua", machine_pain_setting:get_data()[1], 1)


function get_default_pain_config(level)
	local machine_data= machine_pain_setting:get_data()
	if machine_data[level] then
		return DeepCopy(machine_data[level])
	else
		return DeepCopy(machine_data[1])
	end
end

function set_player_pain_to_level(pn, level)
	local config= get_default_pain_config(level)
	local slot= pn_to_profile_slot(pn)
	profile_pain_setting:set_data(slot, config)
	profile_pain_setting:set_dirty(slot)
	return config
end
