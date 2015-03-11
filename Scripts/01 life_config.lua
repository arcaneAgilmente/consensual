local named_configs= {
	mad_matt= {
		initial= 1,
		w1= .004,
		w2= .004,
		w3= .004,
		w4= .000,
		w5= -.004,
		miss= -.004,
		hit_mine= 0, -- Because fuck mines.
		held= .004,
		let_go= -.004,
		missed_hold= -.004,
		checkpoint_hit= .004,
		checkpoint_miss= -.004,
	},
	sm5= {
		initial= .5,
		w1= .008,
		w2= .008,
		w3= .004,
		w4= .000,
		w5= -.040,
		miss= -.080,
		hit_mine= 0, -- Because fuck mines.
		held= .008,
		let_go= -.080,
		missed_hold= -.080,
		checkpoint_hit= .008,
		checkpoint_miss= -.080,
	},
}

life_config_value_names= {
		"initial",
		"w1",
		"w2",
		"w3",
		"w4",
		"w5",
		"miss",
		"hit_mine",
		"held",
		"let_go",
		"missed_hold",
		"checkpoint_hit",
		"checkpoint_miss",
}

life_config_names= {
	"mad_matt", "sm5"
}

life_config= create_setting("life_config", "life_config.lua", named_configs.mad_matt, -1)
life_config:load()

function get_life_value(name)
	return life_config:get_data()[name] or 0
end

function set_life_config(name)
	if named_configs[name] then
		life_config:set_data(nil, DeepCopy(named_configs[name]))
	end
end
