local censor_config= create_setting("censor list", "censor_list.lua", {})
censor_config:load()
local censored_songs= censor_config:get_data()

function save_censored_list()
	censor_config:save()
end

function add_to_censor_list(song)
	if not song then return end
	censor_config:set_dirty()
	censored_songs[song_get_dir(song)]= true
end

function check_censor_list(song)
	if not song then return end
	local ret= censored_songs[song_get_dir(song)]
	return censored_songs[song_get_dir(song)]
end
