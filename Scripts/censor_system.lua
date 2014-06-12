local censored_songs= {}
local censor_list_changed= false
local censor_file_name= "Save/consensual_settings/censor_list.lua"

function load_censored_list()
	censor_list_changed= false
	if FILEMAN:DoesFileExist(censor_file_name) then
		censored_songs= dofile(censor_file_name)
	end
end

function save_censored_list()
	if not censor_list_changed then return end
	local censor_str= "return " .. lua_table_to_string(censored_songs) .. "\n"
	write_str_to_file(censor_str, censor_file_name, "censors")
end

function add_to_censor_list(song)
	if not song then return end
	censor_list_changed= true
	censored_songs[song_get_dir(song)]= true
end

function check_censor_list(song)
	if not song then return end
	return censored_songs[song_get_dir(song)]
end
