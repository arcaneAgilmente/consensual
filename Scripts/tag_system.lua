local song_to_tags= {}
local tag_to_songs= {}
local tags_changed= {}
usable_tags= {}

local song_tags_fname= "/song_tags.lua"
local usable_tags_fname= "/usable_tags.lua"

function load_usable_tags(prof_slot)
	if not prof_slot then return end
	local tags_file_name= PROFILEMAN:GetProfileDir(prof_slot) ..
		usable_tags_fname
	if FILEMAN:DoesFileExist(tags_file_name) then
		usable_tags[prof_slot]= dofile(tags_file_name)
	else
		usable_tags[prof_slot]= {}
	end
end

function load_tags(prof_slot)
	if not prof_slot then return end
	local tags_file_name= PROFILEMAN:GetProfileDir(prof_slot) ..song_tags_fname
	if FILEMAN:DoesFileExist(tags_file_name) then
		song_to_tags[prof_slot]= dofile(tags_file_name)
		local tts= {}
		for song_name, song_tags in pairs(song_to_tags[prof_slot]) do
			for tag_name, tag_value in pairs(song_tags) do
				if not tts[tag_name] then tts[tag_name]= {} end
				tts[tag_name][song_name]= tag_value
			end
		end
		tag_to_songs[prof_slot]= tts
	else
		song_to_tags[prof_slot]= {}
		tag_to_songs[prof_slot]= {}
	end
	load_usable_tags(prof_slot)
	tags_changed[prof_slot]= false
end

function clear_empty_tags(prof_slot)
	if not prof_slot then return end
	local prof_stt= song_to_tags[prof_slot]
	for song_name, song_tags in pairs(prof_stt) do
		for tag_name, tag_value in pairs(song_tags) do
			if tag_value == 0 then
				song_tags[tag_name]= nil
			end
		end
	end
end

function save_usable_tags(prof_slot)
	if not prof_slot then return end
	local prof_dir= PROFILEMAN:GetProfileDir(prof_slot)
	if not prof_dir or prof_dir == "" then return end
	local tags_file_name= prof_dir .. usable_tags_fname
	local tagstr= "return " ..
		lua_table_to_string(usable_tags[prof_slot]) .. "\n"
	write_str_to_file(tagstr, tags_file_name, "usable tags")
end

function save_tags(prof_slot)
	if not prof_slot then return end
	save_usable_tags(prof_slot)
	clear_empty_tags(prof_slot)
	local prof_dir= PROFILEMAN:GetProfileDir(prof_slot)
	if not prof_dir or prof_dir == "" then return end
	local tag_fname= prof_dir .. song_tags_fname
	local tagstr= "return "..lua_table_to_string(song_to_tags[prof_slot]).."\n"
	write_str_to_file(tagstr, tag_fname, "tags")
end

function save_all_tags()
	for slot, tags in pairs(song_to_tags) do
		if tags_changed[slot] then
			save_tags(slot)
		end
	end
end

function change_tag_value(prof_slot, song, tag, amount)
	if not song or not tag then return end
	local prof_stt= song_to_tags[prof_slot]
	local prof_tts= tag_to_songs[prof_slot]
	if prof_stt and prof_tts then
		local song_dir= song_get_dir(song)
		if not prof_tts[tag] then prof_tts[tag]= {} end
		local curr_value= prof_stt[song_dir][tag] or 0
		local new_value= curr_value + amount
		prof_stt[song_dir][tag]= new_value
		prof_tts[tag][song_dir]= new_value
		tags_changed[prof_slot]= true
	end
end

function set_tag_value(prof_slot, song, tag, new_value)
	if not song or not tag then return end
	local prof_stt= song_to_tags[prof_slot]
	local prof_tts= tag_to_songs[prof_slot]
	if prof_stt and prof_tts then
		local song_dir= song_get_dir(song)
		if not prof_stt[song_dir] then prof_stt[song_dir] = {} end
		if not prof_tts[tag] then prof_tts[tag]= {} end
		prof_stt[song_dir][tag]= new_value
		prof_tts[tag][song_dir]= new_value
		tags_changed[prof_slot]= true
	end
end

function toggle_tag_value(prof_slot, song, tag)
	local prof_stt= song_to_tags[prof_slot]
	local prof_tts= tag_to_songs[prof_slot]
	if not song or not tag then return end
	if prof_stt and prof_tts then
		local song_dir= song_get_dir(song)
		if not prof_stt[song_dir] then prof_stt[song_dir] = {} end
		if not prof_tts[tag] then prof_tts[tag]= {} end
		local new_value= toggle_int_as_bool(prof_stt[song_dir][tag])
		prof_stt[song_dir][tag]= new_value
		prof_tts[tag][song_dir]= new_value
		tags_changed[prof_slot]= true
		return new_value
	end
	return 0
end

function get_tag_value(prof_slot, song, tag)
	if not song or not tag then return 0 end
	local prof_stt= song_to_tags[prof_slot]
	if prof_stt then
		local song_dir= song_get_dir(song)
		return (prof_stt[song_dir] and prof_stt[song_dir][tag]) or 0
	end
	return 0
end

function get_tags_for_song(prof_slot, song, return_values)
	if not song then return {} end
	local prof_stt= song_to_tags[prof_slot]
	local tags= {}
	if prof_stt then
		local tag_set= prof_stt[song_get_dir(song)]
		if tag_set then
			for tag_name, tag_value in pairs(tag_set) do
				if tag_value ~= 0 then
					if return_values then
						tags[#tags+1]= {name= tag_name, value= tag_value}
					else
						tags[#tags+1]= tag_name
					end
				end
			end
		end
		if return_values then
			local function cmp(l, r) return l.name < r.name end
			table.sort(tags, cmp)
		else
			table.sort(tags)
		end
	end
	return tags
end

function get_songs_with_tag(prof_slot, tag_name, return_values)
	if not tag_name then return {} end
	local prof_tts= tag_to_songs[prof_slot]
	if prof_tts then
		local songs= {}
		if not prof_tts[tag_name] then return end
		for song_dir, tag_value in pairs(prof_tts[tag_name]) do
			if tag_value ~= 0 then
				local search_name= song_dir:match("(/[^/]*/[^/]*/)$")
				local song= SONGMAN:FindSong(search_name)
				if song then
					if return_values then
						songs[#songs+1]= {
							song= song, song_dir= song_dir, value= tag_value}
					else
						songs[#songs+1]= song
					end
				end
			end
		end
		if return_values then
			local function cmp(l, r) return l.song_dir < r.song_dir end
			table.sort(songs, cmp)
		else
			local function cmp(l, r) return song_get_dir(l) < song_get_dir(r) end
			table.sort(songs, cmp)
		end
		return songs
	end
	return {}
end
