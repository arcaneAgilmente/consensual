local dev_butt= "DeviceButton"
local mod_adjust_keys= {
	DeviceButton_a= {pn= PLAYER_1, mod= "SuddenOffset", amount= -.01},
	DeviceButton_s= {pn= PLAYER_1, mod= "SuddenOffset", amount= .01},
	DeviceButton_z= {pn= PLAYER_1, mod= "HiddenOffset", amount= -.01},
	DeviceButton_x= {pn= PLAYER_1, mod= "HiddenOffset", amount= .01},
	DeviceButton_d= {pn= PLAYER_1, mod= "Sudden", amount= -.1},
	DeviceButton_f= {pn= PLAYER_1, mod= "Sudden", amount= .1},
	DeviceButton_c= {pn= PLAYER_1, mod= "Hidden", amount= -.1},
	DeviceButton_v= {pn= PLAYER_1, mod= "Hidden", amount= .1},
	DeviceButton_j= {pn= PLAYER_2, mod= "SuddenOffset", amount= -.01},
	DeviceButton_k= {pn= PLAYER_2, mod= "SuddenOffset", amount= .01},
	DeviceButton_m= {pn= PLAYER_2, mod= "HiddenOffset", amount= -.01},
	DeviceButton_comma= {pn= PLAYER_2, mod= "HiddenOffset", amount= .01},
	DeviceButton_l= {pn= PLAYER_2, mod= "Sudden", amount= -.1},
	["DeviceButton_;"]= {pn= PLAYER_2, mod= "Sudden", amount= .1},
	DeviceButton_period= {pn= PLAYER_2, mod= "Hidden", amount= -.1},
	["DeviceButton_/"]= {pn= PLAYER_2, mod= "Hidden", amount= .1},
}

mod_adjust_config= create_setting("mod adjust keys", "mod_adjust_keys.lua", mod_adjust_keys, 0)
mod_adjust_config:load()

local function entry_not_sane(entry_name, entry)
	if entry_name:sub(1, #dev_butt) ~= dev_butt then return true end
	if entry.pn ~= PLAYER_1 and entry.pn ~= PLAYER_2 then return true end
	if not PlayerOptions[entry.mod] then return true end
	if type(entry.amount) ~= "number" then return true end
	return false
end

function sanity_check_mods_adjust_keys()
	local loaded_config= mod_adjust_config:get_data()
	for name, entry in pairs(loaded_config) do
		if entry_not_sane(name, entry) then
			loaded_config[name]= nil
		end
	end
	mod_adjust_config:set_dirty()
	mod_adjust_config:save()
end

function reload_mods_adjust_keys()
	mod_adjust_config:load()
	sanity_check_mods_adjust_keys()
end

sanity_check_mods_adjust_keys()
