local recent_limit= 64
local random_recent= {}
local played_recent= {}
local favorite_folder= {}

function reset_recents()
	random_recent= {}
	played_recent= {}
	favorite_folder= {}
end

local function add_song_to_recent_internal(song, recent)
	local song_name= song_get_dir(song)
	local shifted= recent[1]
	recent[1]= {el= song}
	if not shifted then return end
	if song_get_dir(shifted.el) == song_name then return end
	for i= 2, #recent+1 do
		if recent[i] and song_get_dir(recent[i].el) == song_name then
			recent[i]= shifted
			return
		else
			shifted, recent[i]= recent[i], shifted
		end
	end
	if recent[recent_limit+1] then recent[recent_limit+1]= nil end
end

local function make_bucket_from_recent(recent, name)
	local i= 1
	while i <= #recent do
		if check_censor_list(recent[i]) then
			table.remove(recent, i)
		else
			i= i + 1
		end
	end
	local bucket= {
		is_special= true, is_recent= name,
		bucket_info= {
			name= {
				value= name, disp_name= get_string_wrapper("MusicWheel", name),
				source= {
					name, "make from recent",
					get_names= generic_get_wrapper("GetDisplayMainTitle")}},
			contents= recent}}
	return bucket
end

random_recent_bucket= make_bucket_from_recent(random_recent, "Recent from Random")
played_recent_bucket= make_bucket_from_recent(played_recent, "Recently played")
favor_folder_bucket= make_bucket_from_recent(favorite_folder, "Favorites")

local function add_song_to_recent(song, recent, bucket)
	add_song_to_recent_internal(song, recent)
	finalize_bucket(bucket.bucket_info, 0, true)
end

function add_song_to_recent_random(song)
	add_song_to_recent(song, random_recent, random_recent_bucket)
end
function add_song_to_recent_played(song)
	add_song_to_recent(song, played_recent, played_recent_bucket)
end

local function songs_equal(a, b)
	return a:GetSongDir() == b:GetSongDir()
end

local function find_song_in_favor_folder(song)
	local lower= 1
	local upper= #favorite_folder
	if upper == 0 then
		return 1, false
	end
	local song_title= song:GetDisplayMainTitle()
	if upper == lower then
		if songs_equal(song, favorite_folder[lower].el) then
			return lower, true
		end
		if song_title < favorite_folder[lower].el:GetDisplayMainTitle() then
			return lower, false
		else
			return lower+1, false
		end
	end
	if song_title < favorite_folder[lower].el:GetDisplayMainTitle() then
		return lower, false
	end
	if song_title > favorite_folder[upper].el:GetDisplayMainTitle() then
		return upper+1, false
	end
	while upper - lower > 1 do
		local mid= math.floor((lower + upper) / 2)
		if songs_equal(song, favorite_folder[mid].el) then
			return mid, true
		end
		if song_title > favorite_folder[mid].el:GetDisplayMainTitle() then
			lower= mid
		else
			upper= mid
		end
	end
	if songs_equal(song, favorite_folder[lower].el) then
		return lower, true
	end
	if songs_equal(song, favorite_folder[upper].el) then
		return upper, true
	end
	if song_title < favorite_folder[lower].el:GetDisplayMainTitle() then
		return lower, false
	end
	if song_title > favorite_folder[upper].el:GetDisplayMainTitle() then
		return upper+1, false
	end
	return upper, false
end

function add_song_to_favor_folder_internal(song)
	local index, already_added= find_song_in_favor_folder(song)
	if already_added then return end
	table.insert(favorite_folder, index, {el= song})
end

function remove_song_from_favor_folder_internal(song)
	local index, already_added= find_song_in_favor_folder(song)
	if not already_added then return end
	table.remove(favorite_folder, index)
end

function collect_favored_songs(song)
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if get_favor(pn_to_profile_slot(pn), song) > 0 then
			add_song_to_favor_folder_internal(song, favorite_folder)
		end
	end
	return true
end

function finalize_favor_folder()
	finalize_bucket(favor_folder_bucket.bucket_info, 0, true)
end

function add_song_to_favor_folder(song)
	add_song_to_favor_folder_internal(song)
	finalize_favor_folder()
end

function remove_song_from_favor_folder(song)
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if get_favor(pn_to_profile_slot(pn), song) > 0 then
			return
		end
	end
	remove_song_from_favor_folder_internal(song)
	finalize_favor_folder()
end
