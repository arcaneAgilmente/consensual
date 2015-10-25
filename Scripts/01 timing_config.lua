local default_config= {
	itg= {
    Scale= 1,
    SecondsW1= .01075,
		SecondsW2= .0215,
		SecondsW3= .043,
		SecondsW4= .102,
		SecondsW5= .135,
		SecondsMine= .07,
		SecondsHold= .32,
		SecondsRoll= .32,
		SecondsAttack= .13,
		SecondsCheckpoint= .1664,
		Add= 0,
		Jump= .25,
		Hopo= .25,
		Strum= .1,
	},
	sm5= {
    Scale= 1,
    SecondsW1= .01125,
		SecondsW2= .0225,
		SecondsW3= .045,
		SecondsW4= .090,
		SecondsW5= .135,
		SecondsMine= .09,
		SecondsHold= .25,
		SecondsRoll= .5,
		SecondsAttack= .135,
		SecondsCheckpoint= .1664,
		Add= 0,
		Jump= .25,
		Hopo= .25,
		Strum= .1,
	},
	ddr= {
    Scale= 1,
    SecondsW1= 1/120,
		SecondsW2= 2/120,
		SecondsW3= 4/120,
		SecondsW4= 13/120,
		SecondsW5= 19/120,
		SecondsMine= 13/120,
		SecondsHold= .25,
		SecondsRoll= .5,
		SecondsAttack= .135,
		SecondsCheckpoint= .1664,
		Add= 0,
		Jump= .25,
		Hopo= .25,
		Strum= .1,
	},
}

timing_config= create_setting("timing_config", "timing_config.lua", default_config, 0)

sorted_timing_window_names= {
	"Scale", "SecondsW1", "SecondsW2", "SecondsW3", "SecondsW4", "SecondsW5",
	"SecondsMine", "SecondsHold", "SecondsRoll", "SecondsAttack",
	"SecondsCheckpoint", "Add", "Jump", "Hopo", "Strum"}

local timing_window_names= {}
for i, name in ipairs(sorted_timing_window_names) do
	timing_window_names[name]= true
end

local function sanity_check_timing_group(group)
	local dirty= false
	if type(group) ~= "table" then return false end
	for key, value in pairs(group) do
		if not timing_window_names[key] then
			dirty= true
			group[key]= nil
		end
	end
	for name in ivalues(sorted_timing_window_names) do
		if type(group[name]) ~= "number" then
			dirty= true
			group[name]= default_config.sm5[name]
		end
	end
	return true, dirty
end

local function sanity_check_timing_config(config)
	local dirty= false
	for name, group in pairs(config) do
		local name_type= type(name)
		local sane, sub_dirty= sanity_check_timing_group(group)
		if (name_type ~= "number" and name_type ~= "string")
		or not sane then
			config[name]= nil
			dirty= true
		end
		if sub_dirty then dirty= true end
	end
end

function load_timing_config()
	timing_config:load()
	local dirty= sanity_check_timing_config(timing_config:get_data())
	if dirty then timing_config:set_dirty() end
end

load_timing_config()

function apply_timing_config(name)
	local group= timing_config:get_data()[name]
	if not group then return end
	for name, window in pairs(group) do
		PREFSMAN:SetPreference("TimingWindow" .. name, window)
	end
end

function save_prefs_as_named_timing_config(name)
	local group= {}
	for win_name in ivalues(sorted_timing_window_names) do
		group[win_name]= PREFSMAN:GetPreference("TimingWindow" .. win_name)
	end
	timing_config:get_data()[name]= group
	timing_config:set_dirty()
end

function remove_named_timing_config(name)
	timing_config:get_data()[name]= nil
	timing_config:set_dirty()
end

function add_timing_config_to_menu_choices(choices)
	local config= timing_config:get_data()
	local function add_element(name, group)
		choices[#choices+1]= {name= "use_" .. name, text= get_string_wrapper("OptionNames", "use_timing_group") .. " " .. name}
	end
	foreach_ordered(config, add_element)
end

function add_timing_prefs_to_menu_choices(choices)
	for win_name in ivalues(sorted_timing_window_names) do
		choices[#choices+1]= float_pref_val("TimingWindow" .. win_name, 5, -6, -3, 0)
	end
end
