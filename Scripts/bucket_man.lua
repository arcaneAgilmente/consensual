local function get_song_bpm(song)
	return (song.GetDisplayBpms and math.round(song:GetDisplayBpms()[2])) or 0
end

local function generic_get_wrapper(func_name)
	return function(song, depth)
					 if song[func_name] then
						 return song[func_name](song):sub(1, depth)
					 elseif song.name then
						 return song.name:sub(1, depth)
					 else
						 return ""
					 end
				 end
end

local function generic_ndget_wrapper(func_name)
	return function(song, depth)
					 if song[func_name] then
						 return song[func_name](song)
					 elseif song.name then
						 return song.name
					 else
						 return ""
					 end
				 end
end

local function difficulty_wrapper(difficulty)
	return function(song, depth)
					 if song.GetStepsByStepsType then
						 local curr_style= GAMESTATE:GetCurrentStyle()
						 local filter_type= curr_style:GetStepsType()
						 local all_steps= song:GetStepsByStepsType(filter_type)
						 for i, v in ipairs(all_steps) do
							 if v:GetDifficulty() == difficulty then
								 return v:GetMeter()
							 end
						 end
						 return 0
					 else
						 return 0
					 end
				 end
end

local sort_info= {}

local function set_course_mode_sort_info()
	local main_title_info= {
		get_bucket= generic_get_wrapper("GetDisplayFullTitle"), depth= true }
	sort_info= {
		{ name= "Group", main= {
				get_bucket= generic_ndget_wrapper("GetGroupName"), depth= false,
				group_similar= true },
			fallback= main_title_info, },
		{ name= "Title", main= main_title_info, fallback= nil },
		{ name= "Length", main= {
				get_bucket= song_get_length, depth= false },
			fallback= main_title_info },
	}
end

local function set_song_mode_sort_info()
	local main_title_info= {
		get_bucket= generic_get_wrapper("GetDisplayMainTitle"), depth= true }
	sort_info= {
		{ name= "Group", main= {
				get_bucket= generic_ndget_wrapper("GetGroupName"), depth= false,
				group_similar= true },
			fallback= main_title_info, },
		{ name= "Title", main= main_title_info, fallback= nil },
		{ name= "BPM", main= {
				get_bucket= get_song_bpm, depth= false },
			fallback= main_title_info },
		{ name= "Artist", main= {
				get_bucket= generic_get_wrapper("GetDisplayArtist"), depth= true },
			fallback= main_title_info },
		{ name= "Genre", main= {
				get_bucket= generic_get_wrapper("GetGenre"), depth= true },
			fallback= main_title_info },
		{ name= "Length", main= {
				get_bucket= song_get_length, depth= false },
			fallback= main_title_info },
	}

	do
		local meter_list= {
			{ name= "Novice Meter", diff= "Difficulty_Beginner" },
			{ name= "Easy Meter", diff= "Difficulty_Easy" },
			{ name= "Medium Meter", diff= "Difficulty_Medium" },
			{ name= "Hard Meter", diff= "Difficulty_Hard" },
			{ name= "Expert Meter", diff= "Difficulty_Challenge" },
			{ name= "Edit Meter", diff= "Difficulty_Edit" },
		}
		for i, v in ipairs(meter_list) do
			sort_info[#sort_info+1]= {
				name= v.name, main= {
					get_bucket= difficulty_wrapper(v.diff), depth= false },
				fallback= main_title_info }
		end
	end
end

local bucket_man_interface= {}
local bucket_man_interface_mt= { __index= bucket_man_interface }

function bucket_man_interface:initialize()
	if GAMESTATE:IsCourseMode() then
		self.song_set= SONGMAN:GetAllCourses(false) -- fuck autogen courses
		set_course_mode()
		set_course_mode_sort_info()
	else
		self.song_set= SONGMAN:GetAllSongs()
		set_song_mode()
		set_song_mode_sort_info()
	end
end

function bucket_man_interface:style_filter_songs()
	local filtered_songs= {}
	local filter_types= cons_get_steps_types_to_show()
	if #filter_types >= 1 then
		for i, v in ipairs(self.song_set) do
			local matched= false
			if v.AllSongsAreFixed and v:AllSongsAreFixed() then
				local song_steps= song_get_all_steps(v)
				for si, sv in ipairs(song_steps) do
					local st= sv:GetStepsType()
					for fi, fv in ipairs(filter_types) do
						if st == fv then
							matched= true
							break
						end
					end
					if matched then break end
				end
			else
				matched= true
			end
			if matched then
				filtered_songs[#filtered_songs+1]= v
			end
		end
	end
	self.filtered_songs= filtered_songs
end

function bucket_man_interface:filter_and_resort_songs(filter_func)
	if not self.filtered_songs then
		Trace("bucket_man_interface:  fars operates on already style-filtered songs.")
		return
	end
	if not filter_func then
		Trace("bucket_man_interface:  Forgot to pass a filter_func to fars.")
		return
	end
	local refiltered_songs= {}
	for i, v in ipairs(self.filtered_songs) do
		if filter_func(v) then
			refiltered_songs[#refiltered_songs+1]= v
		end
	end
	self.filtered_songs= refiltered_songs
	if self.cur_sort_info then
		return self:sort_songs(self.cur_sort_info)
	end
end

function bucket_man_interface:sort_songs(sort_info)
	if not self.filtered_songs then
		Trace("bucket_man_interface:  Songs must be filtered before sorting.")
		return
	end
	self.current_sort_name= sort_info.name
	self.cur_sort_info= sort_info
	local function can_join(bucket)
		if bucket.name then
			return not songman_does_group_exist(bucket.name)
		else
			return true
		end
	end
	self.sorted_songs= bucket_sort{
		set= self.filtered_songs, main= sort_info.main,
		fallback= sort_info.fallback, can_join= can_join}
	return self.sorted_songs
end

bucket_man= setmetatable({}, bucket_man_interface_mt)

local wheel_x= 0
local wheel_y= SCREEN_TOP + 12
local items_on_wheel= 19

local sick_wheel_item_interface= {}
local sick_wheel_item_interface_mt= { __index= sick_wheel_item_interface }
function sick_wheel_item_interface:create_actors(name)
	self.name= name
	return Def.ActorFrame{
		Name= name,
		normal_text("text", "", solar_colors.uf_text(), 4, 0, 1, left),
		normal_text("number", "", solar_colors.uf_text(), -4, 0, 1, right),
	}
end

function sick_wheel_item_interface:find_actors(container)
	assert(container)
	self.container= container
	self.text= container:GetChild("text")
	self.number= container:GetChild("number")
end

do
local move_time= .1
function sick_wheel_item_interface:transform(item_index, num_items, is_focus)
	local width_limit= SCREEN_RIGHT - wheel_x - 8
	self.container:finishtweening()
	self.container:linear(move_time)
	self.container:x(0)
	self.container:y((item_index - 1) * (SCREEN_HEIGHT / num_items))
	if item_index == 1 or item_index == num_items then
		self.container:diffusealpha(0)
	else
		self.container:diffusealpha(1)
	end
	local xmin, xmax, ymin, ymax= rec_calc_actor_extent(self.text)
	local cxz= self.text:GetZoomX()
	local width= (xmax - xmin) / cxz
	width_limit_text(self.text, width_limit)
	if self.info then
		if self.info.is_current_group then
			self.text:diffuse(solar_colors.blue())
		elseif self.info.is_group then
			self.text:diffuse(solar_colors.violet())
		elseif self.info.is_random then
			self.text:diffuse(solar_colors.red())
			self.text:settext(self.info.disp_name)
		else
			self.text:diffuse(solar_colors.uf_text())
		end
	end
end
end

function sick_wheel_item_interface:set(info)
	self.info= info
	if not info then return end
	if info.disp_name then
		self.text:settext(info.disp_name)
	elseif info.name then
		self.text:settext(info.name)
	else
		self.text:settext(song_get_main_title(info))
	end
	if info.num_inside then
		self.number:settext(info.num_inside)
	else
		self.number:settext("")
	end
end

local function make_random_decision(random_el)
	local candidates= random_el.candidate_set
	local choice= 1
	if #candidates > 1 then
		choice= MersenneTwister.Random(1, #candidates)
	end
	-- This is a check to make sure the thing being picked is a song or course.
	if candidates[choice].GetDisplayFullTitle then
		random_el.chosen= candidates[choice]
	else
		random_el.chosen= nil
	end
end

local music_whale_interface= {}
music_whale_interface_mt= { __index= music_whale_interface }
function music_whale_interface:create_actors(x)
	wheel_x= x
	self.sick_wheel= setmetatable({}, sick_wheel_mt)
	self.frame_helper= setmetatable({}, frame_helper_mt)
	self.name= "MusicWheel"
	self.current_sort_name= "Group"
	if music_whale_state then
		self.current_sort_name= music_whale_state.cur_sort_info.name
	end
	local args= {
		Name= self.name,
		self.frame_helper:create_actors("cursor", 1, 0, 0, solar_colors.violet(),
																		solar_colors.bg(), wheel_x, wheel_y),
		self.sick_wheel:create_actors(
			items_on_wheel, sick_wheel_item_interface_mt, wheel_x, wheel_y),
	}
	self.focus_pos= self.sick_wheel.focus_pos
	return Def.ActorFrame(args)
end

function music_whale_interface:find_actors(container)
	self.sick_wheel:find_actors(container:GetChild(self.sick_wheel.name))
	self.frame_helper:find_actors(container:GetChild(self.frame_helper.name))
	self.song_set= bucket_man.filtered_songs
	self.cursor_song= gamestate_get_curr_song()
	if music_whale_state then
		if song_short_enough(music_whale_state.cursor_song) then
			self.cursor_song= music_whale_state.cursor_song
		else
			for i, v in ipairs(music_whale_state.alt_cursor_songs) do
				if song_short_enough(v) then
					self.cursor_song= v
					break
				end
			end
		end
		self:sort_songs(music_whale_state.cur_sort_info)
	else
		self:sort_songs(sort_info[1])
	end
end

function music_whale_interface:sort_songs(si)
	self.current_sort_name= si.name
	function sort_work()
		self.cur_sort_info= si
		self.sorted_songs= bucket_man:sort_songs(si)
		self.disp_stack= {}
		self.display_bucket= nil
		if self.cursor_song then
			local function final_compare(a, b)
				return a == b
			end
			local search_args= {
				set= self.sorted_songs, main= si.main, fallback= si.fallback,
				final_compare= final_compare, match_element= self.cursor_song }
			local search_path= { bucket_search(search_args) }
			if music_whale_state and music_whale_state.on_random then
				--Trace("music_whale_state.on_random, truncating path. " .. music_whale_state.depth_to_random)
				while #search_path > music_whale_state.depth_to_random+1 do
					--Trace("Removing " .. search_path[#search_path])
					search_path[#search_path]= nil
				end
			end
			if search_path[1] ~= -1 then
				self:follow_search_path(search_path, 1, self.sorted_songs)
				if music_whale_state and music_whale_state.on_random then
					--Trace("followed path done.")
					--print_table(self.display_bucket)
					self:nav_to_named_element(music_whale_state.on_random)
					music_whale_state.on_random= nil
				end
			else
				self:set_display_bucket({b= self.sorted_songs, p= 1})
			end
		else
			self:set_display_bucket({b= self.sorted_songs, p= 1})
		end
	end
	if si == self.cur_sort_info then
		local parent_group= self.disp_stack[#self.disp_stack]
		if parent_group then
			self:pop_from_disp_stack()
		else
			sort_work()
		end
	else
		sort_work()
	end
	play_sample_music()
end

function music_whale_interface:add_player_randoms(disp_bucket, player_number)
	if GetPreviousPlayerSteps then
		local prev_steps= GetPreviousPlayerSteps(player_number)
		local sn= ToEnumShortString(player_number)
		if prev_steps then
			local prev_meter= prev_steps:GetMeter()
			local sbd= ConvertScoreToFootRateChange(
				prev_meter, GetPreviousPlayerScore(player_number))
			local sbd_str= " "
			if sbd >= 0 then
				sbd_str= sbd_str .. "+" .. sbd
			else
				sbd_str= sbd_str .. sbd
			end
			local prev_easier= {}
			local prev_same= {}
			local prev_harder= {}
			local prev_sbd= {}
			local function candy_filter(song)
				local steps_list= get_filtered_sorted_steps_list(song)
				for i, v in ipairs(steps_list) do
					local meter= v:GetMeter()
					if meter == prev_meter - 1 then
						prev_easier[#prev_easier+1]= song
					end
					if meter == prev_meter then
						prev_same[#prev_same+1]= song
					end
					if meter == prev_meter + 1 then
						prev_harder[#prev_harder+1]= song
					end
					if meter == prev_meter + sbd then
						prev_sbd[#prev_sbd+1]= song
					end
				end
			end
			bucket_traverse{ set= self.curr_bucket, per_element= candy_filter}
			if #prev_easier > 0 then
				disp_bucket[#disp_bucket+1]= {
					name= sn .. "Random Easier", is_random= true,
					disp_name= sn .. get_string_wrapper("MusicWheel", "Random Easier"),
					candidate_set= prev_easier
				}
			end
			if #prev_same > 0 then
				disp_bucket[#disp_bucket+1]= {
					name= sn .. "Random Same", is_random= true,
					disp_name= sn .. get_string_wrapper("MusicWheel", "Random Same"),
					candidate_set= prev_same
				}
			end
			if #prev_harder > 0 then
				disp_bucket[#disp_bucket+1]= {
					name= sn .. "Random Harder", is_random= true,
					disp_name= sn .. get_string_wrapper("MusicWheel", "Random Harder"),
					candidate_set= prev_harder
				}
			end
			if #prev_sbd > 0 then
				disp_bucket[#disp_bucket+1]= {
					name= sn .. "Random SB", is_random= true,
					disp_name= sn .. get_string_wrapper("MusicWheel", "Random") .. sbd_str,
					candidate_set= prev_sbd
				}
			end
		end
	end
end

function music_whale_interface:add_randoms(bucket)
	local candidates= {}
	local function add_to_candidates(el)
		candidates[#candidates+1]= el
	end
	bucket_traverse{ set= bucket, per_element= add_to_candidates}
	bucket[#bucket+1]= {
		name= "Random", disp_name= get_string_wrapper("MusicWheel", "Random"),
		is_random= true, candidate_set= candidates }
	if not GAMESTATE:IsCourseMode() then
		self:add_player_randoms(bucket, PLAYER_1)
		self:add_player_randoms(bucket, PLAYER_2)
	end
end

function music_whale_interface:add_special_items_to_bucket(bucket)
	if self.current_sort_name ~= "Sort Menu" then
		-- The last element in the bucket is the special element for the current
		-- group.  It can't be added here because the name of the current display
		-- bucket isn't known when popping, and adding the special items happens
		-- during popping too.
		local last_el= bucket[#bucket]
		if last_el.is_current_group then
			bucket[#bucket]= nil
		else
			-- For the case where we are at the top level.
			last_el= nil
		end
		self:add_randoms(bucket)
		bucket[#bucket+1]= last_el
		--Trace("Added special items.")
	end
end

function music_whale_interface:remove_special_items_from_bucket(bucket)
	local i= 1
	while i <= #bucket and bucket[i] do
		local v= bucket[i]
		if v.is_random then
			table.remove(bucket, i)
		else
			i= i + 1
		end
	end
end

function music_whale_interface:set_display_bucket(bucket_info)
	local bucket= bucket_info.b
	local pos= bucket_info.p
	self.curr_bucket= bucket
	local disp_bucket= {}
	local contents= bucket.contents or bucket
	local function elname(el)
		return el.disp_name or el.name or song_get_main_title(el) or ""
	end
	local function compare(a, b)
		return elname(a) < elname(b)
	end
	for i, v in ipairs(contents) do
		if v.contents then
			disp_bucket[#disp_bucket+1]= {
				name= v.name, disp_name= v.disp_name, is_group= true,
				num_inside= #v.contents, contents= v.contents }
		elseif v.sort then
			disp_bucket[#disp_bucket+1]= { name= v.name, sort= v.sort }
		else
			disp_bucket[#disp_bucket+1]= v
		end
	end
	if bucket.name then
		disp_bucket[#disp_bucket+1]= {
			name= bucket.name, disp_name= bucket.disp_name, is_group= true,
			is_current_group= true, num_inside= #bucket.contents }
	end
	self:add_special_items_to_bucket(disp_bucket)
	self.display_bucket= disp_bucket
	self.sick_wheel:set_info_set(self.display_bucket, pos)
	self:set_stuff_from_curr_element()
	--Trace("SDB:")
	--print_table(self.display_bucket)
end

function music_whale_interface:follow_search_path(path, path_index, set)
	local sindex= path[path_index]
	--Trace("follow_search_path: " .. path_index .. " out of " .. #path)
	if sindex then
		self:set_display_bucket{b= set, p= sindex}
		local sbuck= set[sindex] or (set.contents and set.contents[sindex])
		if sbuck and path[path_index+1] then
			if sbuck.contents then
				self:push_onto_disp_stack()
				self:follow_search_path(path, path_index + 1, sbuck)
			end
		end
	end
end

function music_whale_interface:nav_to_named_element(name)
	--Trace("music_whale_interface.nav_to_named_element")
	--print_table(self.display_bucket)
	for i, v in ipairs(self.display_bucket) do
		if v.name and v.name == name then
			--Trace("Accepted " .. v.name .. " == " .. name)
			self.sick_wheel:scroll_to_pos(i)
			self:set_stuff_from_curr_element()
			return
		else
			--Trace("Rejected " .. tostring(v.name) .. " == " .. name)
		end
	end
	for i, v in ipairs(self.display_bucket) do
		if v.name and v.name:find("Random") then
			--Trace("Accepted " .. v.name)
			self.sick_wheel:scroll_to_pos(i)
			self:set_stuff_from_curr_element()
			return
		end
	end
end

function music_whale_interface:push_onto_disp_stack()
	self:remove_special_items_from_bucket(self.display_bucket)
	self.disp_stack[#self.disp_stack+1]= {
		b= self.display_bucket, c= self.curr_bucket,
		p= self.sick_wheel.info_pos }
end

function music_whale_interface:pop_from_disp_stack()
	if #self.disp_stack > 0 then
		local prev_bucket= self.disp_stack[#self.disp_stack]
		self.disp_stack[#self.disp_stack]= nil
		self.display_bucket= prev_bucket.b
		self.curr_bucket= prev_bucket.c
		self:add_special_items_to_bucket(self.display_bucket)
		self.sick_wheel:set_info_set(self.display_bucket, prev_bucket.p+self.focus_pos)
		self:set_stuff_from_curr_element()
	end
end

function music_whale_interface:scroll_left()
	self.sick_wheel:scroll_by_amount(-1)
	self:set_stuff_from_curr_element()
end

function music_whale_interface:scroll_right()
	self.sick_wheel:scroll_by_amount(1)
	self:set_stuff_from_curr_element()
end

function music_whale_interface:scroll_amount(a)
	self.sick_wheel:scroll_by_amount(a)
	self:set_stuff_from_curr_element()
end

function music_whale_interface:set_stuff_from_curr_element()
	local curr_element= self.sick_wheel:get_info_at_focus_pos()
	if curr_element.is_random then
		make_random_decision(curr_element)
		if curr_element.chosen then
			gamestate_set_curr_song(curr_element.chosen)
		else
			gamestate_set_curr_song(nil)
		end
	elseif curr_element.name then
		gamestate_set_curr_song(nil)
		MESSAGEMAN:Broadcast("current_group_changed", { curr_element.name })
	else
		gamestate_set_curr_song(curr_element)
	end
	local curr_actor= self.sick_wheel:get_actor_item_at_focus_pos()
	local xmn, xmx, ymn, ymx= rec_calc_actor_extent(curr_actor.container)
	local ox= wheel_x
	local oy= (self.focus_pos - 1) * (SCREEN_HEIGHT / items_on_wheel) + 12
	self.frame_helper:move(ox + (xmn + xmx) / 2, oy + (ymn + ymx) / 2)
	self.frame_helper:resize(xmx - xmn + 6, ymx - ymn + 6)
end

function music_whale_interface:interact_with_element()
	local curr_element= self.sick_wheel:get_info_at_focus_pos()
	if curr_element.is_group then
		if curr_element.is_current_group then
			self:pop_from_disp_stack()
		else
			self:push_onto_disp_stack()
			self:set_display_bucket({b= curr_element, p= 0})
			play_sample_music()
		end
	elseif curr_element.sort then
		self:sort_songs(curr_element.sort)
	elseif gamestate_get_curr_song() then
		local cur_song= gamestate_get_curr_song()
		local alt_cursor_songs= {}
		if not curr_element.is_random then
			local function gather_adjacent_songs(s)
				alt_cursor_songs[#alt_cursor_songs+1]= s
			end
			bucket_traverse{set= self.curr_bucket, per_element= gather_adjacent_songs}
		end
		music_whale_state= {
			cur_sort_info= self.cur_sort_info,
			cursor_song= cur_song,
			alt_cursor_songs= alt_cursor_songs
		}
		if curr_element.is_random then
			music_whale_state.on_random= curr_element.name
			music_whale_state.depth_to_random= #self.disp_stack
			--Trace("music_whale_state.depth_to_random: " .. music_whale_state.depth_to_random)
		end
		SCREENMAN:GetTopScreen():queuecommand("play_song")
	end
end

function music_whale_interface:show_sort_list()
	if self.current_sort_name ~= "Sort Menu" then
		self.current_sort_name= "Sort Menu"
		self.cursor_song= gamestate_get_curr_song()
		self:push_onto_disp_stack()
		local sort_list= {}
		for i, s in ipairs(sort_info) do
			sort_list[#sort_list+1]= { name= s.name, sort= s }
		end
		self:set_display_bucket({ b= sort_list, p= 1 })
	end
end
