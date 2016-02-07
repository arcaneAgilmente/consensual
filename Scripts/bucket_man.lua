local machine_profile= false
local difficulty_list= {
	{ name= "Novice", diff= "Difficulty_Beginner" },
	{ name= "Easy", diff= "Difficulty_Easy" },
	{ name= "Medium", diff= "Difficulty_Medium" },
	{ name= "Hard", diff= "Difficulty_Hard" },
	{ name= "Expert", diff= "Difficulty_Challenge" },
	{ name= "Edit", diff= "Difficulty_Edit" },
}

local function get_song_bpm(song)
	return {(song.GetDisplayBpms and math.round(song:GetDisplayBpms()[2])) or 0}
end

function generic_get_wrapper(func_name)
	return function(song)
					 if song[func_name] then
						 return {song[func_name](song)}
					 elseif song.name then
						 return {song.name}
					 else
						 return {""}
					 end
				 end
end

local function title_length(song)
	if not song then return {0} end
	return {#song:GetDisplayMainTitle()}
end

local function length(song)
	if not song then return {0} end
	return {math.round(song_get_length(song))}
end

local function first_second(song)
	if not song then return {0} end
	return {song:GetFirstSecond()}
end

local function difficulty_wrapper(difficulty)
	return function(song)
					 if song.GetStepsByStepsType then
						 local curr_style= GAMESTATE:GetCurrentStyle()
						 local filter_type= curr_style:GetStepsType()
						 local all_steps= song:GetStepsByStepsType(filter_type)
						 for i, v in ipairs(all_steps) do
							 if v:GetDifficulty() == difficulty then
								 return {v:GetMeter()}
							 end
						 end
						 return {0}
					 else
						 return {0}
					 end
				 end
end

local function step_artist(song)
	if song.GetStepsByStepsType then
		local curr_style= GAMESTATE:GetCurrentStyle()
		local filter_type= curr_style:GetStepsType()
		local all_steps= song:GetStepsByStepsType(filter_type)
		local artists= {}
		for i, v in ipairs(all_steps) do
			local author= steps_get_author(v, song)
			if not string_in_table(author, artists) then
				artists[#artists+1]= author
			end
		end
		if #artists > 0 then
			return artists
		end
		return {""}
	else
		return {""}
	end
end

local nps_player= false
function set_nps_player(pn)
	nps_player= pn or GAMESTATE:GetEnabledPlayers()[1]
end

local function get_steps_for_current_style(song, pn)
	local curr_style= GAMESTATE:GetCurrentStyle(nps_player)
	local filter_type= curr_style:GetStepsType()
	return song:GetStepsByStepsType(filter_type)
end

local function note_count(song)
	if song.GetStepsByStepsType then
		local all_steps= get_steps_for_current_style(song, nps_player)
		local ret= {}
		local radar
		for i, v in ipairs(all_steps) do
			radar= v:GetRadarValues(nps_player)
			ret[#ret+1]= radar:GetValue("RadarCategory_Notes")
		end
		if #ret > 0 then
			return ret
		end
		return {0}
	else
		return {0}
	end
end

function calc_nps(pn, song_len, steps)
	local radar= steps:GetRadarValues(pn)
	local notes= radar:GetValue("RadarCategory_Notes")
	if notes <= 0 or song_len <= 0 then return 0 end
	return notes / song_len
end

local function nps(song)
	if song.GetStepsByStepsType then
		local all_steps= get_steps_for_current_style(song, nps_player)
		local ret= {}
		local len= song_get_length(song)
		for i, v in ipairs(all_steps) do
			ret[#ret+1]= math.round(calc_nps(nps_player, len, v) * 100) / 100
		end
		if #ret > 0 then
			return ret
		end
		return {0}
	else
		return {0}
	end
end

local function radar_cat_wrapper(radar_name)
	return function(song)
		if song.GetStepsByStepsType then
			local all_steps= get_steps_for_current_style(song, nps_player)
			local ret= {}
			local radar
			local len= song_get_length(song)
			for i, steps in ipairs(all_steps) do
				radar= steps:GetRadarValues(nps_player)
				ret[#ret+1]= math.round(radar:GetValue(radar_name) * 100) * .01
			end
			if #ret > 0 then
				return ret
			end
			return {0}
		else
			return {0}
		end
	end
end

local timing_segments= {
	{"Stops", "GetStops"},
	{"Delays", "GetDelays"},
	{"BPM Changes", "GetBPMs"},
	{"Warps", "GetWarps"},
	{"Tickcounts", "GetTickcounts"},
	{"Speed Changes", "GetSpeeds"},
	{"Scroll Changes", "GetScrolls"},
	{"Combo Multipliers", "GetCombos"},
}

local function timing_data_wrapper(func_name)
	return function(song)
		if song.GetStepsByStepsType then
			local all_steps= get_steps_for_current_style(song, nps_player)
			local high_count= 0
			for i, steps in ipairs(all_steps) do
				local timing_data= steps:GetTimingData()
				local count= #timing_data[func_name](timing_data, true)
				if count > high_count then
					high_count= count
				end
			end
			return {high_count}
		else
			return {0}
		end
	end
end

local function timing_segment_count(song)
	if song.GetStepsByStepsType then
		local all_steps= get_steps_for_current_style(song, nps_player)
		local high_count= 0
		for i, steps in ipairs(all_steps) do
			local timing_data= steps:GetTimingData()
			local count= 0
			for i, seg_info in ipairs(timing_segments) do
				count= count + #timing_data[seg_info[2]](timing_data, true)
			end
			if count > high_count then
				high_count= count
			end
		end
		return {high_count}
	else
		return {0}
	end
end

local function by_words(song)
	return split_string_to_words(song:GetDisplayMainTitle())
end

local function by_words_in_group(song)
	return split_string_to_words(song:GetGroupName())
end

local function any_meter(song)
	if song.GetStepsByStepsType then
		local all_steps= get_steps_for_current_style(song, nps_player)
		local meters= {}
		for i, v in ipairs(all_steps) do
			meters[#meters+1]= v:GetMeter()
		end
		if #meters > 0 then
			return meters
		end
		return {0}
	else
		return {0}
	end
end

local function favor_wrapper(prof_slot)
	return function(song)
		return {get_favor(prof_slot, song)}
	end
end

local function tag_wrapper(prof_slot)
	return function(song)
		local tags= get_tags_for_song(prof_slot, song)
		if #tags > 0 then return tags end
		return {"Untagged"}
	end
end

local function highest_score(score_list)
	if #score_list:GetHighScores() > 0 then
		return {math.round(score_list:GetHighScores()[1]:GetPercentDP() * 100000) * .001}
	else
		return {0}
	end
end

local function newest_score(score_list)
	if #score_list:GetHighScores() > 0 then
		-- Date is clipped to YYYY-MM-DD
		return {score_list:GetHighScores()[1]:GetDate():sub(1, 10)}
	else
		return {"No Scores"}
	end
end

local function open_score(score_list)
	if #score_list:GetHighScores() > 0 then
		return {math.max(0, 10 - #score_list:GetHighScores())}
	else
		return {10}
	end
end

local function num_scores(score_list)
	return {#score_list:GetHighScores()}
end

local active_rival= "Taisetsu"
local function set_rival(name)
	active_rival= name
end
local rival_functions= {
	{ name= "Rank", func=
		function(score_list)
			if score_list.GetRankOfName then
				return {score_list:GetRankOfName(active_rival)}
			else
				return {0}
			end
		end,
		name_func=
			function(name, diff_name)
				return name .. " " .. diff_name .. " Rank"
			end,
	},
	{ name= "Highest", func=
		function(score_list)
			if score_list.GetHighestScoreOfName then
				local highest= score_list:GetHighestScoreOfName(active_rival)
				if highest then
					return {math.round(highest:GetPercentDP() * 100000) * .001}
				end
				return {0}
			else
				return {0}
			end
		end,
		name_func=
			function(name, diff_name)
				return "Highest " .. name .. " " .. diff_name .. " Score"
			end,
	},
	{ name= "Newest", func=
		function(score_list)
			if score_list.GetHighestScoreOfName then
				local highest= score_list:GetHighestScoreOfName(active_rival)
				if highest then
					-- Date is clipped to YYYY-MM-DD
					return {highest:GetDate():sub(1, 10)}
				end
				return {"No Scores"}
			else
				return {"No Scores"}
			end
		end,
		name_func=
			function(name, diff_name)
				return "Newest " .. name .. " " .. diff_name .. " Score"
			end,
	},
}

local fake_high_score_list= {GetHighScores= function() return {} end}

local function score_wrapper(score_func, difficulty)
	local default_return= score_func(fake_high_score_list)
	return function(song)
					 if not machine_profile then return default_return end
					 if song.GetStepsByStepsType then
						 local curr_style= GAMESTATE:GetCurrentStyle()
						 local filter_type= curr_style:GetStepsType()
						 local all_steps= song:GetStepsByStepsType(filter_type)
						 local matched_steps= false
						 for i, v in ipairs(all_steps) do
							 if v:GetDifficulty() == difficulty then
								 matched_steps= v
								 break
							 end
						 end
						 if matched_steps then
							 local score_list= machine_profile:GetHighScoreListIfExists(
								 song, matched_steps)
							 if score_list then
								 return score_func(score_list)
							 else
								 return default_return
							 end
						 else
							 return default_return
						 end
					 else
						 return default_return
					 end
				 end
end

local function cant_join_if_contain_buckets(left, right)
	return not left.contents[1].contents and not right.contents[1].contents
end

local function default_cant_join_wrapper(score_func, default_el)
	local default_return= score_func(default_el)
	return function(left, right)
		return left.name.value ~= default_return[1] and
			right.name.value ~= default_return[1]
	end
end

local title_sort= {
	name= "Title", get_names= generic_get_wrapper("GetDisplayMainTitle"),
	uses_depth= true, can_join= noop_true, insensitive_names= true}
local group_sort= {
	name= "Group", get_names= generic_get_wrapper("GetGroupName"),
		can_join= noop_false, group_similar= true}
local nps_sort= {
	name= "NPS", get_names= nps, returns_multiple= true,
	can_join= cant_join_if_contain_buckets,
	pre_sort_func= set_nps_player}
local any_meter_sort= {
	name= "Any Meter", get_names= any_meter, returns_multiple= true, can_join= cant_join_if_contain_buckets}

function get_group_sort_info() return group_sort end
function get_nps_sort_info() return nps_sort end
function get_any_meter_sort_info() return any_meter_sort end

local shared_sort_factors= {
	group_sort,
	title_sort,
	-- Fun fact:  Implemented 2 days before Anime Banzai 2014, just to show off.
--	{ name= "Title Length", get_names= title_length, can_join= noop_false},
	{ name= "Word In Title", get_names= by_words, uses_depth= true,
		can_join= noop_true, insensitive_names= true, returns_multiple= true},
	{ name= "Word In Group", get_names= by_words_in_group, uses_depth= true,
		can_join= noop_false, insensitive_names= true, returns_multiple= true},
	{ name= "Favor+Group", multi_level_sort= true, get_names= noop_blank,
		{name= "Favor", get_names= favor_wrapper("ProfileSlot_Machine"), can_join= noop_false},
		group_sort,
	},
	{ name= "Tag+Group", multi_level_sort= true, get_names= noop_blank,
		{name= "Tag", get_names= tag_wrapper("ProfileSlot_Machine"), can_join= noop_false,
		 returns_multiple= true},
		group_sort,
	},
}

local function make_bucket_from_factors(name, factors)
	return {
		name= {value= name, source= {name= "make from " .. name}},
		contents= factors}
end

local timing_sort_factors= {
	{ name= "Timing Segment Total", get_names= timing_segment_count,
		pre_sort_func= set_nps_player},
}
for i, seg_info in ipairs(timing_segments) do
	timing_sort_factors[#timing_sort_factors+1]= {
		name= seg_info[1], get_names= timing_data_wrapper(seg_info[2]),
		pre_sort_func= set_nps_player}
end

local radar_sort_factors= {}
for i, radar in ipairs(RadarCategory) do
	radar_sort_factors[#radar_sort_factors+1]= {
		name= ToEnumShortString(radar), get_names= radar_cat_wrapper(radar),
		pre_sort_func= set_nps_player, returns_multiple= true}
end
radar_sort_factors[#radar_sort_factors+1]= nps_sort

local song_sort_factors= {
	{ name= "BPM", get_names= get_song_bpm},
	{ name= "Artist", get_names= generic_get_wrapper("GetDisplayArtist"),
		uses_depth= true, insensitive_names= true},
	{ name= "Genre", get_names= generic_get_wrapper("GetGenre"),
		uses_depth= true, insensitive_names= true},
	{ name= "Length", get_names= length},
	{ name= "First Second", get_names= first_second},
	{ name= "Step Artist", insensitive_names= true, get_names= step_artist,
		returns_multiple= true},
	make_bucket_from_factors("Timing Data", timing_sort_factors),
	make_bucket_from_factors("Radar Value", radar_sort_factors),
}

local course_sort_factors= {
}

local favor_sort_factors= {}
local tag_sort_factors= {}
local function make_favor_tag_sorts()
	-- Clear the tables so we don't accumulate sort_factors every time.
	favor_sort_factors= {}
	tag_sort_factors= {}
	local slots= {"ProfileSlot_Machine"}
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		slots[#slots+1]= pn_to_profile_slot(pn)
	end
	for i, slot in ipairs(slots) do
		favor_sort_factors[#favor_sort_factors+1]= {
			name= slot:sub(13) .. " Favor", get_names= favor_wrapper(slot),
			can_join= noop_false}
		tag_sort_factors[#tag_sort_factors+1]= {
			name= slot:sub(13) .. " Tag", get_names= tag_wrapper(slot),
			can_join= noop_false, returns_multiple= true}
	end
end


local meter_sort_factors= {any_meter_sort}
for d, diff in pairs(difficulty_list) do
	meter_sort_factors[#meter_sort_factors+1]= {
		name= diff.name .. " Meter", get_names= difficulty_wrapper(diff.diff)}
end

local score_factor_source= {name= "score_factor_bucket"}
local function score_sub_bucket_maker(score_func, prename, postname)
	local contents= {}
	local name= prename or postname or "Report this bug"
	prename= (prename and prename .. " ") or ""
	postname= (postname and " " .. postname) or ""
	for d, diff in ipairs(difficulty_list) do
		contents[#contents+1]= {
				name= prename .. diff.name .. postname,
				get_names= score_wrapper(score_func, diff.diff), dont_clip= true,
				group_similar= true,
				can_join= default_cant_join_wrapper(score_func, fake_high_score_list)}
	end
	return {
		name= {value= name, source= score_factor_source},
		contents= contents}
end
local score_factor_bucket= {
	name= {value= "Score", source= score_factor_source},
	contents= {
		 score_sub_bucket_maker(highest_score, "Highest", "Score"),
		 score_sub_bucket_maker(newest_score, "Newest", "Score"),
		 score_sub_bucket_maker(open_score, "Open", "Scores"),
		 score_sub_bucket_maker(num_scores, "Total", "Scores"),
}}

local function make_rival_bucket()
	local source= {name= "make_rival_bucket"}
	if not machine_profile then
		return {name= {value= "No Machine Profile"}, contents= {}}
	end
	local all_names= machine_profile:GetAllUsedHighScoreNames()
	if #all_names < 1 then return nil end
	local name_sort_factor= {
		name= "Rival Name", get_names= function(n) return {n} end,
		uses_depth= true, can_join= noop_false}
	local sorted_names= {}
	local worker= coroutine.create(
		function()
			sorted_names= bucket_sort(all_names, {name_sort_factor})
	end)
	while coroutine.status(worker) ~= "dead" do
		coroutine.resume(worker)
	end
	local function convert_name_to_bucket(item)
		local name= item.el
		local contents= {}
		for r, rival_element in ipairs(rival_functions) do
			local sub_contents= {}
			for d, diff in ipairs(difficulty_list) do
				local elname= rival_element.name_func(name, diff.name)
				sub_contents[#sub_contents+1]= {
					name= elname, pre_sort_func= set_rival, pre_sort_arg= name,
					get_names= score_wrapper(rival_element.func, diff.diff),
					can_join= default_cant_join_wrapper(
						rival_element.func, fake_high_score_list),
					group_similar= true, dont_clip= true, from_rival= true}
			end
			contents[#contents+1]= {
				name= {value= rival_element.name, source= source},
				contents= sub_contents}
		end
		return {name= {value= name, source= source}, contents= contents}
	end
--	Trace("Made rival bucket:")
--	rec_print_table(sorted_names)
	bucket_traverse(sorted_names, nil, convert_name_to_bucket)
--	Trace("Converted names to buckets:")
--	rec_print_table(sorted_names)
	return {name= {value= "Highscore Name", source= source}, contents= sorted_names}
end

local rival_bucket= {}

local function gen_test_sorts(contents)
	local factor_list= {}
	local function add_to_factor_list(item)
		if not item.from_rival then
			factor_list[#factor_list+1]= item.el or item
		end
	end
	bucket_traverse(contents, nil, add_to_factor_list)
	Warn("Generating test data with " .. #factor_list .. " factors.")
	if #factor_list == 0 then
		Warn("Bad factor_list, contents:")
		rec_print_table(contents)
	end
	generate_song_sort_test_data(factor_list)
end

function gen_name_only_test_data()
	generate_song_sort_test_data({group_sort, title_sort})
end

local function add_factor_sets_to_sort_list(contents, sets)
	for i, set in ipairs(sets) do
		for f, sf in ipairs(set) do
			contents[#contents+1]= sf
		end
	end
end

local function add_common_buckets_to_sort_list(contents)
	contents[#contents+1]= make_bucket_from_factors("Difficulty",meter_sort_factors)
	contents[#contents+1]= make_bucket_from_factors("Favor",favor_sort_factors)
	contents[#contents+1]= make_bucket_from_factors("Tag",tag_sort_factors)
	contents[#contents+1]= score_factor_bucket
	contents[#contents+1]= rival_bucket
end

local function get_course_mode_sort_info()
	local contents= {}
	add_factor_sets_to_sort_list(
		contents, {shared_sort_factors, course_sort_factors})
	add_common_buckets_to_sort_list(contents)
	return contents
end

local function get_song_mode_sort_info()
	local contents= {}
	add_factor_sets_to_sort_list(
		contents, {shared_sort_factors, song_sort_factors})
	add_common_buckets_to_sort_list(contents)
	return contents
end

local function get_sort_info()
	make_favor_tag_sorts()
	if GAMESTATE:IsCourseMode() then
		return get_course_mode_sort_info()
	else
		return get_song_mode_sort_info()
	end
end

local songs_of_each_style= false
local courses_of_each_style= false
local function add_to_of_style(of_set, style_name)
	of_set[style_name]= (of_set[style_name] or 0) + 1
end
function init_songs_of_each_style()
	-- Walking all steps for all songs is time consuming, so only do it once.
	-- Problem is the data is invalid if songs are reloaded.
	if songs_of_each_style then return end
	songs_of_each_style= {}
	courses_of_each_style= {}
	local function make_of(set, set_of)
		for i, item in ipairs(set) do
			if not item.AllSongsAreFixed or item:AllSongsAreFixed() then
				local step_set= sourse_get_all_steps(item)
				for si, steps in ipairs(step_set) do
					local stype= steps:GetStepsType()
					local added= false
					for sts, style_set in ipairs(visible_styles) do
						for sti, style in ipairs(style_set) do
							if stype == style.stepstype then
								add_to_of_style(set_of, style.style)
								added= true
								break
							end
						end
						if added then break end
					end
				end
			end
		end
	end
	make_of(SONGMAN:GetAllSongs(), songs_of_each_style)
	make_of(SONGMAN:GetAllCourses(false), courses_of_each_style)
end

function enough_sourses_of_visible_styles()
	local total= 0
	local function calc_total(of_set)
		for i, style in ipairs(combined_visible_styles()) do
			total= total + (of_set[style.style] or 0)
		end
	end
	if GAMESTATE:IsCourseMode() then
		calc_total(courses_of_each_style)
	else
		calc_total(songs_of_each_style)
	end
	return total > 0
end

local bucket_man_interface= {}
local bucket_man_interface_mt= { __index= bucket_man_interface }
local prev_was_course= false
local favorites_folder= {}

local function find_named_factor(name_list, list)
	for i, item in ipairs(list) do
		if type(item.name) == "string"
		and string_in_table(item.name, name_list) then return i end
		if item.contents then
			local sub_ret= find_named_factor(name_list, item.contents)
			if sub_ret then return sub_ret end
		end
	end
end

local function add_sort_names_to_list(list, contents)
	for i, item in ipairs(contents) do
		if type(item.name) == "string" then
			list[#list+1]= item.name
		elseif item.contents then
			add_sort_names_to_list(list, item.contents)
		end
	end
end

function bucket_man_interface:initialize()
	init_songs_of_each_style()
	machine_profile= PROFILEMAN:GetMachineProfile()
	if GAMESTATE:IsCourseMode() then
		if not prev_was_course then
			reset_recents()
		end
		prev_was_course= true
		self.song_set= SONGMAN:GetAllCourses(false) -- fuck autogen courses
		set_course_mode()
	else
		if prev_was_course then
			reset_recents()
		end
		prev_was_course= false
		self.song_set= SONGMAN:GetAllSongs()
		set_song_mode()
	end
	rival_bucket= make_rival_bucket()
	self.pre_filter_functions= {}
	self.filter_functions= {song_short_and_uncensored, collect_favored_songs}
	self.post_filter_functions= {finalize_favor_folder}
	self:style_filter_songs()
	local sort_info= get_sort_info()
	local default_sort= {misc_config:get_data().default_wheel_sort}
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local psort= cons_players[pn].preferred_sort
		if psort ~= "" then default_sort[#default_sort+1]= psort end
	end
	local sort_index= find_named_factor(default_sort, sort_info) or 1
	self.cur_sort_info= sort_info[sort_index]
end

function bucket_man_interface:add_filter_function(func)
	self.filter_functions[#self.filter_functions+1]= func
end

function bucket_man_interface:remove_filter_function(func)
	for i, f in ipairs(self.filter_functions) do
		if f == func then table.remove(self.filter_functions, i) return end
	end
end

function bucket_man_interface:clear_filter_functions()
	self.filter_functions= {song_short_and_uncensored, collect_favored_songs}
end

function bucket_man_interface:style_filter_songs()
	local filtered_songs= {}
	local filter_types= cons_get_steps_types_to_show()
	for i, v in ipairs(self.song_set) do
		local matched= false
		if not v.AllSongsAreFixed or v:AllSongsAreFixed() then
			local song_steps= song_get_all_steps(v)
			for si, sv in ipairs(song_steps) do
				if filter_types[sv:GetStepsType()] then
					matched= true
					break
				end
			end
		else
			matched= true
		end
		if matched then
			filtered_songs[#filtered_songs+1]= v
		end
	end
	self.style_filtered_songs= filtered_songs
end

function bucket_man_interface:filter_songs()
	if not self.style_filtered_songs then
		lua.ReportScriptError("bucket_man_interface:  filter_songs operates on already style-filtered songs.")
		return
	end
	local refiltered_songs= {}
	local num_songs= #self.style_filtered_songs
	local num_filters= #self.filter_functions
	for f= 1, #self.pre_filter_functions do
		self.pre_filter_functions[f]()
	end
	for i= 1, num_songs do
		local song= self.style_filtered_songs[i]
		local show= true
		for f= 1, num_filters do
			if not self.filter_functions[f](song) then
				show= false
				break
			end
		end
		if show then
			refiltered_songs[#refiltered_songs+1]= song
		end
		if i % 1000 == 0 then maybe_yield("Filtering", fracstr(i, num_songs)) end
	end
	self.filtered_songs= refiltered_songs
	for f= 1, #self.post_filter_functions do
		self.post_filter_functions[f]()
	end
end

function bucket_man_interface:get_sort_info()
	return get_sort_info()
end

function bucket_man_interface:get_sort_names_for_menu()
	local ret= {}
	add_sort_names_to_list(ret, get_sort_info())
	return ret
end

if bucket_man then
	setmetatable(bucket_man, bucket_man_interface_mt)
else
	bucket_man= setmetatable({}, bucket_man_interface_mt)
end

local function filter_work()
	bucket_man:filter_songs()
end

function finalize_bucket(bucket, depth_above, no_yield)
	local song_count= 0
	local depth_below= 0
	local mins= {meter= 10000, nps= 10000}
	local maxs= {meter= 0, nps= 0}
	local difficulties= {}
	local meters= {}
	local step_artists= {}
	local step_artist_count= 0
	local max_step_artists= 5
	local handle_item= noop_nil
	if #bucket.contents > 0 and bucket.contents[1].contents then
		handle_item= function(item)
			finalize_bucket(item, depth_above + 1, no_yield)
			song_count= song_count + item.song_count
			depth_below= math.max(item.depth_below, depth_below)
			update_min_table(mins, item.mins, math.min)
			update_min_table(maxs, item.maxs, math.max)
			update_totals_table(difficulties, item.difficulties)
			update_totals_table(meters, item.meters)
			if step_artist_count < max_step_artists then
				for artist, exists in pairs(item.step_artists) do
					if not step_artists[artist] then
						step_artists[artist]= true
						step_artist_count= step_artist_count + 1
						if step_artist_count > max_step_artists then
							break
						end
					end
				end
			end
		end
	else
		handle_item= function(item)
			song_count= song_count + 1
			local len= song_get_length(item.el)
			local steps_list= get_filtered_steps_list(item.el)
			for i, steps in ipairs(steps_list) do
				local met= steps:GetMeter()
				local nps= calc_nps(PLAYER_1, len, steps)
				local diff= steps:GetDifficulty()
				mins.meter= math.min(mins.meter, met)
				mins.nps= math.min(mins.nps, nps)
				maxs.meter= math.max(maxs.meter, met)
				maxs.nps= math.max(maxs.nps, nps)
				if step_artist_count < max_step_artists then
					step_artists[steps_get_author(steps, item.el)]= true
					step_artist_count= step_artist_count + 1
				end
				difficulties[diff]= 1 + (difficulties[diff] or 0)
				meters[met]= 1 + (meters[met] or 0)
			end
		end
	end
	for i, item in ipairs(bucket.contents) do
		handle_item(item)
	end
	bucket.song_count= song_count
	bucket.depth_below= depth_below + 1
	bucket.depth_above= depth_above
	bucket.mins= mins
	bucket.maxs= maxs
	bucket.difficulties= difficulties
	bucket.meters= meters
	bucket.step_artists= step_artists
	bucket.step_artist_count= step_artist_count
	if not no_yield then
		maybe_yield("Finalizing", fracstr(depth_above, bucket.depth_below))
	end
end

local function sort_work()
--	Trace("Sorting by: " .. bucket_man.cur_sort_info.name)
	update_rating_cap()
	local filter_start= GetTimeSinceStart()
	bucket_man.filtered_songs= {}
	while not bucket_man.filtered_songs[2] do
		bucket_man:filter_songs()
		-- TODO:  The case where the player filters out all songs should be
		-- handled better.
		if not bucket_man.filtered_songs[2] then
			if #bucket_man.filter_functions > 1 then
				bucket_man.filter_functions[#bucket_man.filter_functions]= nil
			elseif get_rating_cap() > 0 then
				disable_rating_cap()
			else
				break
			end
		end
	end
	local filter_end= GetTimeSinceStart()
	local sfcount= #bucket_man.style_filtered_songs
	maybe_yield("filtered", sfcount .. "/" .. sfcount)
--	lua.ReportScriptError("Filtering took " .. filter_end - filter_start)
	local csi= bucket_man.cur_sort_info
	if csi.pre_sort_func then
		csi.pre_sort_func(csi.pre_sort_arg)
	end
	local sort_factors= {csi}
	if csi.multi_level_sort then
		for i, factor in ipairs(csi) do
			sort_factors[i]= factor
		end
	end
	sort_factors[#sort_factors+1]= title_sort
	bucket_man.current_sort_name= csi.name
	local sort_start= GetTimeSinceStart()
	bucket_man.sorted_songs= bucket_sort(
		bucket_man.filtered_songs, sort_factors)
	local sort_end= GetTimeSinceStart()
--	lua.ReportScriptError(csi.name .. ": Converting + sorting took " .. sort_end - sort_start)
	local finalize_start= GetTimeSinceStart()
	local fake_bucket= {contents= bucket_man.sorted_songs}
	finalize_bucket(fake_bucket, 0)
	local finalize_end= GetTimeSinceStart()
--	lua.ReportScriptError(csi.name .. ": Finalizing took " .. finalize_end - finalize_start)
end

local song_sort_worker= false

function make_song_sort_worker()
	song_sort_worker= coroutine.create(sort_work)
	return song_sort_worker
end

function make_song_filter_worker()
	song_sort_worker= coroutine.create(filter_work)
	return song_sort_worker
end

function finish_song_sort_worker()
	if song_sort_worker then
		while coroutine.status(song_sort_worker) ~= "dead" do
			coroutine.resume(song_sort_worker)
		end
		song_sort_worker= false
	end
end
