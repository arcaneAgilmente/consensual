local song_favorites= {}
local favs_changed= {}

local fav_fname= "/consensual_settings/favorites.lua"

function load_favorites(prof_slot)
	local favorites_file_name= PROFILEMAN:GetProfileDir(prof_slot) .. fav_fname
	if FILEMAN:DoesFileExist(favorites_file_name) then
		song_favorites[prof_slot]= dofile(favorites_file_name)
	else
		song_favorites[prof_slot]= {}
	end
	favs_changed[prof_slot]= false
end

function clear_empty_favor(prof_slot)
	local prof_favor= song_favorites[prof_slot]
	for song_dir, favor in pairs(prof_favor) do
		if favor == 0 then
			prof_favor[song_dir]= nil
		end
	end
end

function save_favorites(prof_slot)
	clear_empty_favor(prof_slot)
	local prof_dir= PROFILEMAN:GetProfileDir(prof_slot)
	if not prof_dir or prof_dir == "" then return end
	local fav_fname= prof_dir .. fav_fname
	local favstr= "return " .. lua_table_to_string(song_favorites[prof_slot]) .. "\n"
	write_str_to_file(favstr, fav_fname, "favorites")
end

function save_all_favorites()
	for slot, favs in pairs(song_favorites) do
		if favs_changed[slot] then
			save_favorites(slot)
		end
	end
end

function change_favor(prof_slot, song, amount)
	if not song then return end
	local prof_favor= song_favorites[prof_slot]
	if prof_favor then
		local song_dir= song_get_dir(song)
		local curr_favor= prof_favor[song_dir] or 0
		prof_favor[song_dir]= curr_favor + amount
		favs_changed[prof_slot]= true
	end
end

function get_favor(prof_slot, song)
	if not song then return 0 end
	local prof_favor= song_favorites[prof_slot]
	if prof_favor then
		return prof_favor[song_get_dir(song)] or 0
	end
	return 0
end
