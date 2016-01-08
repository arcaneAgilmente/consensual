local pad= 4
local hpad= 2
local wheel_x= 0
local wheel_y= 0
local wheel_move_time= .1
local items_on_wheel= 24
local items_on_screen= items_on_wheel - 2
local available_height= _screen.h
local per_item= available_height / items_on_screen
local wheel_width_limit= 0
wheel_colors= {}
local item_width= 0
local item_text_width= 0
local item_height= 0
local item_text_height= 0
local item_text_zoom= 0
local item_grade_width= 0
local item_grade_offset= 0
local center_expansion= 0
local dual_mode= false

local function recalc_heights()
	item_height= per_item - pad
	item_text_height= item_height - pad
	item_text_zoom= item_text_height / 24
end
recalc_heights()

-- Some calculations to figure out the height in real pixels, to see if the
-- items are too short to be useful.  If they are, switch to dual mode.
do
	local fake_pix_to_real_ratio= DISPLAY:GetDisplayHeight() /_screen.h
	if item_text_height * fake_pix_to_real_ratio < 12 then
		dual_mode= true
		per_item= per_item * 2
	end
end
recalc_heights()

function nice_bucket_disp_name(bucket)
	if not bucket.name then return "" end
	local disp_name= bucket.name.value
	if bucket.from_split then
		disp_name= bucket_disp_name(bucket)
	end
	if smmaxx_packs[bucket.name.value] then
		return smmaxx_packs[bucket.name.value]
	end
	return disp_name
end

local function recalc_width_limit()
	if dual_mode then
		wheel_width_limit= wheel_width_limit * .5
	end
	item_width= wheel_width_limit - 4
	item_text_width= item_width - 4
	item_grade_width= item_height
	item_grade_offset= (item_width - item_grade_width) * .5
end

local wheel_item_mt= {
	__index= {
		create_actors= function(self, name)
			self.name= name
			self.prev_index= 1
			self.grades= {
				[PLAYER_1]= setmetatable({}, grade_image_mt),
				[PLAYER_2]= setmetatable({}, grade_image_mt)}
			self.grade_to_show= {}
			return Def.ActorFrame{
				Name= name,
				InitCommand= function(subself)
					self.container= subself
					self.text= subself:GetChild("text")
				end,
				Def.Quad{
					InitCommand= function(subself)
						self.bg= subself
						subself:diffuse({0, 0, 0, .125})
					end
				},
				normal_text("text", "", fetch_color("text"), fetch_color("stroke"), 0, 0, item_text_zoom, center),
				self.grades[PLAYER_1]:create_actors(),
				self.grades[PLAYER_2]:create_actors(),
			}
		end,
		grade_is_showing= function(self)
			return not (self.grades[PLAYER_1].hidden and self.grades[PLAYER_2].hidden)
		end,
		resize_text= function(self)
			local text_width= item_text_width
			if self:grade_is_showing() then
				text_width= text_width - (item_grade_width * 2)
			end
			width_limit_text(self.text, text_width, item_text_zoom)
		end,
		resize= function(self)
			self.bg:setsize(wheel_width_limit-hpad, item_height)
			self.grades[PLAYER_1]:move(-item_grade_offset, 0)
			self.grades[PLAYER_1]:set_size(item_grade_width)
			self.grades[PLAYER_2]:move(item_grade_offset, 0)
			self.grades[PLAYER_2]:set_size(item_grade_width)
			self:resize_text()
		end,
		transform= function(self, item_index, num_items, is_focus, focus_pos)
			local changing_edge= math.abs(item_index-self.prev_index)>num_items/2
			local dist_from_focus= item_index - focus_pos
			local start_y= _screen.cy
			if center_expansion > 0 then
				if dist_from_focus < 0 then
					start_y= start_y - center_expansion + (per_item * .5) - pad
				else
					start_y= start_y + pad - (per_item * .5) + center_expansion
				end
			end
			local x= 0
			local y= 0
			if dual_mode then
				local items_to_edge= 0
				if dist_from_focus < 0 then
					items_to_edge= math.floor((start_y - 32) / per_item)
					if -dist_from_focus > items_to_edge then
						dist_from_focus= dist_from_focus + items_to_edge
						x= wheel_width_limit * -.5
					else
						x= wheel_width_limit * .5
					end
				else
					items_to_edge= math.floor((_screen.h - start_y) / per_item)
					if dist_from_focus > items_to_edge then
						dist_from_focus= dist_from_focus - items_to_edge
						x= wheel_width_limit * -.5
					else
						x= wheel_width_limit * .5
					end
				end
			end
			y= start_y + (dist_from_focus * per_item)
			if changing_edge then
				self.container:diffusealpha(0)
			end
			if april_fools then
				self.container:stoptweening()
				local curr_x= self.container:GetX()
				local curr_y= self.container:GetY()
				local halfway_x= (curr_x + x) * .5
				local halfway_y= (curr_y + y) * .5
				local rot= math.random() * 180 * ((math.random(0, 1) * 2) - 1)
				self.container:linear(wheel_move_time*4)
					:xy(halfway_x, halfway_y):rotationz(rot)
					:linear(wheel_move_time*4):xy(x, y):rotationz(0)
			else
				self.container:finishtweening()
					:april_linear(wheel_move_time):xy(x, y)
			end
			if item_index == 1 or item_index == num_items or
			(is_focus and center_expansion > 0) then
				self.container:diffusealpha(0)
			else
				self.container:diffusealpha(1)
			end
			self.prev_index= item_index
		end,
		set= function(self, info)
			self.info= info
			if not info then return end
			local text_width= item_text_width
			if info.bucket_info then
				if info.is_current_group then
					rot_color_text(self.bg, wheel_colors.current_group)
				else
					rot_color_text(self.bg, wheel_colors.group)
				end
				self.text:settext(bucket_disp_name(info.bucket_info))
			elseif info.random_info then
				self.text:settext(info.disp_name)
				rot_color_text(self.bg, wheel_colors.random)
			elseif info.song_info then
				if info.is_prev then
					self.text:settext(info.disp_name)
					rot_color_text(self.bg, wheel_colors.prev_song)
				else
					self.text:settext(song_get_main_title(info.song_info))
					rot_color_text(self.bg, wheel_colors.song)
				end
				if check_censor_list(info.song_info) then
					rot_color_text(self.bg, wheel_colors.censored_song)
				end
			elseif info.sort_info then
				self.text:settext(info.sort_info.name)
				rot_color_text(self.bg, wheel_colors.sort)
			else
				Warn("Tried to display bad element in display bucket.")
				rec_print_table(info)
			end
			for i, pn in ipairs(all_player_indices) do
				self:update_grade(pn)
			end
			self:resize_text()
			self.bg:diffusealpha(.75)
		end,
		update_grade= function(self, pn)
			local set_grade= false
			self.grade_to_show[pn]= false
			if GAMESTATE:IsPlayerEnabled(pn)
			and self.info and self.info.song_info then
				local stype= get_preferred_steps_type(pn)
				local diff= GAMESTATE:GetPreferredDifficulty(pn)
				local steps= self.info.song_info:GetOneSteps(stype, diff)
				local profile= PROFILEMAN:GetProfile(pn)
				if steps and profile then
					local score_list= profile:GetHighScoreListIfExists(self.info.song_info, steps)
					if score_list then
						local top_score= score_list:GetHighScores()[1]
						if top_score then
							local grade, color= convert_score_to_grade(convert_high_score_to_judge_counts(top_score))
							self.grades[pn]:set_grade(grade, color)
							self.grade_to_show[pn]= true
							if cons_players[pn].flags.interface.music_wheel_grades then
								set_grade= true
							end
						end
					end
				end
			end
			if set_grade then
				self.grades[pn]:unhide()
			else
				self.grades[pn]:hide()
			end
		end,
		update_grade_shown= function(self, pn)
			local set_grade= false
			if GAMESTATE:IsPlayerEnabled(pn)
			and self.info and self.info.song_info
			and cons_players[pn].flags.interface.music_wheel_grades
			and self.grade_to_show[pn] then
				set_grade= true
			end
			if set_grade then
				self.grades[pn]:unhide()
			else
				self.grades[pn]:hide()
			end
			self:resize_text()
		end,
}}

local function make_random_decision(random_el)
	local candidates= random_el.candidate_set
	local choice= 1
	if #candidates > 1 then
		choice= MersenneTwister.Random(1, #candidates)
	end
	-- This is a check to make sure the thing being picked is a song or course.
	if candidates[choice].GetDisplayFullTitle then
		random_el.chosen= candidates[choice]
		add_song_to_recent_random(random_el.chosen)
	else
		random_el.chosen= nil
	end
end

local function add_player_randoms(filters, candies, pn)
	local prev_steps= GetPreviousPlayerSteps(pn)
	local sn= ToEnumShortString(pn)
	local interface_flags= cons_players[pn].flags.interface
	local function ritem_name(type_name)
		return sn .. get_string_wrapper("MusicWheel", type_name)
	end
	local use_prev= interface_flags.easier_random or interface_flags.same_random
	or interface_flags.harder_random or interface_flags.score_random
	if prev_steps and use_prev then
		local prev_meter= prev_steps:GetMeter()
		local sbd= ConvertScoreToFootRateChange(
			prev_meter, GetPreviousPlayerScore(pn))
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
		filters[#filters+1]= function(item)
			local song= item.el
			local steps_list= get_filtered_steps_list(song)
			for i, steps in ipairs(steps_list) do
				local meter= steps:GetMeter()
				if interface_flags.easier_random and meter == prev_meter - 1 then
					prev_easier[#prev_easier+1]= song
				end
				if interface_flags.same_random and meter == prev_meter then
					prev_same[#prev_same+1]= song
				end
				if interface_flags.harder_random and meter == prev_meter + 1 then
					prev_harder[#prev_harder+1]= song
				end
				if interface_flags.score_random and meter == prev_meter + sbd then
					prev_sbd[#prev_sbd+1]= song
				end
			end
		end
		candies[#candies+1]= {
			name= sn .. "Random Easier", disp_name= ritem_name("Random Easier"),
			candy= prev_easier}
		candies[#candies+1]= {
			name= sn .. "Random Same", disp_name= ritem_name("Random Same"),
			candy= prev_same}
		candies[#candies+1]= {
			name= sn .. "Random Harder", disp_name= ritem_name("Random Harder"),
			candy= prev_harder}
		candies[#candies+1]= {
			name= sn .. "Random SB", disp_name= ritem_name("Random") .. sbd_str,
			candy= prev_sbd}
	end
	local preferred_diff= GAMESTATE:GetPreferredDifficulty(pn) or
		"Difficulty_Beginner"
	local curr_steps_type= GAMESTATE:GetCurrentStyle(pn):GetStepsType()
	local profile= PROFILEMAN:GetProfile(pn)
	if profile and false and -- Finding unplayed songs takes too long.
	(interface_flags.unplayed_random or interface_flags.low_score_random) then
		local unplayed_candy= {}
		local low_score_candy= {}
		filters[#filters+1]= function(item)
			local song= item.el
			local steps_list= get_filtered_steps_list(song)
			for i, steps in ipairs(steps_list) do
				if steps:GetDifficulty() == preferred_diff
					and steps:GetStepsType() == curr_steps_type then
					local score_list= profile:GetHighScoreListIfExists(song, steps)
					if score_list then
						if #score_list:GetHighScores() > 0 then
							local score= score_list:GetHighScores()[1]:GetPercentDP()
							if score < .05 then
								unplayed_candy[#unplayed_candy+1]= song
							elseif score < cons_players[pn].low_score_random_threshold then
								low_score_candy[#low_score_candy+1]= song
							end
						else
							unplayed_candy[#unplayed_candy+1]= song
						end
					else
						unplayed_candy[#unplayed_candy+1]= song
					end
				end
			end
		end
		candies[#candies+1]= {
			name= sn .. "Random Unplayed", disp_name= ritem_name("Random Unplayed"),
			candy= unplayed_candy}
		candies[#candies+1]= {
			name= sn .. "Random Low Score", disp_name= ritem_name("Random Low Score"),
			candy= low_score_candy}
	end
end

local music_whale= {
	create_actors= function(self, x, w, move_time)
		wheel_x= x
		wheel_width_limit= w
		wheel_move_time= move_time
		recalc_width_limit()
		wheel_colors= fetch_color("music_select.music_wheel", 1)
		for i, c in pairs(wheel_colors) do
			wheel_colors[i]= adjust_luma(c, .25)
		end
		self.sick_wheel= setmetatable({}, sick_wheel_mt)
		self.name= "MusicWheel"
		self.current_sort_name= "Group"
		if music_whale_state then
			self.current_sort_name= music_whale_state.cur_sort_info.name
		end
		local args= {
			Name= self.name, InitCommand= function(subself)
				self.container= subself
				subself:xy(wheel_x, wheel_y)
			end,
			player_flags_changedMessageCommand= function(subself, param)
				if param.field ~= "interface" then return end
				if param.name ~= "music_wheel_grades" then return end
				for i, item in ipairs(self.sick_wheel.items) do
					item:update_grade_shown(param.pn)
				end
			end,
			self.sick_wheel:create_actors("wheel", items_on_wheel, wheel_item_mt, 0, 0),
		}
		self.sick_wheel.focus_pos= self.sick_wheel.focus_pos + 1
		self.focus_pos= self.sick_wheel.focus_pos
		return Def.ActorFrame(args)
	end,
	find_actors= function(self)
		self.song_set= bucket_man.filtered_songs
		self.cursor_song= gamestate_get_curr_song()
		finish_song_sort_worker()
		if music_whale_state then
			self.cursor_item= music_whale_state.cursor_item
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
		end
		self:post_sort_update()
		self.ready= true
	end,
	move_resize= function(self, newx, neww)
		wheel_width_limit= neww
		wheel_x= newx
		recalc_width_limit()
		self.container:stoptweening():april_linear(wheel_move_time):x(wheel_x)
		self.sick_wheel:scroll_by_amount(0)
		for i, item in ipairs(self.sick_wheel.items) do
			item:resize()
		end
	end,
	post_sort_update= function(self)
		self.current_sort_name= bucket_man.cur_sort_info.name
		self.cur_sort_info= bucket_man.cur_sort_info
		self.sorted_songs= bucket_man.sorted_songs
		self.disp_stack= {}
		self.in_recent= false
		self.display_bucket= nil
		if self.cursor_song or self.cursor_item and #self.sorted_songs > 0 then
			local function final_compare(a, b)
				return a == b
			end
			local function dir_compare(a, b)
				if a.el then a= a.el else return false end
				if b.el then b= b.el else return false end
				return a and b and a.GetSongDir and b.GetSongDir and
					a:GetSongDir() == b:GetSongDir()
			end
			local search_path= {}
			if self.cursor_item and self.cursor_item.name_set then
--				Trace("using cursor_item")
--				rec_print_table(self.cursor_item)
				search_path= {
					bucket_search_for_item(self.sorted_songs, self.cursor_item, dir_compare)}
				if search_path[1] == -1 then
--					Trace("Failed to find cursor item, searching for song:  " .. table.concat(search_path, ", "))
					search_path= {bucket_search(self.sorted_songs, self.cursor_song,
																			final_compare, true)}
				end
			else
--				if self.cursor_item then
--					Trace("cursor_item has some stuff:")
--					rec_print_table(self.cursor_item)
--				end
--				Trace("using cursor_song")
				search_path= {bucket_search(self.sorted_songs, self.cursor_song,
																		final_compare, true)}
			end
--			Trace("resulting path: " .. table.concat(search_path, ", "))
			if music_whale_state and music_whale_state.on_random then
				while #search_path > music_whale_state.depth_to_random+1 do
					search_path[#search_path]= nil
				end
			end
			if search_path[1] ~= -1 then
				self:follow_search_path(search_path, 1, self.sorted_songs)
				if music_whale_state and music_whale_state.on_random then
					self:nav_to_named_element(music_whale_state.on_random)
					music_whale_state.on_random= nil
				end
			else
				self:set_display_bucket(self.sorted_songs, 1)
			end
		else
			self:set_display_bucket(self.sorted_songs, 1)
		end
		play_sample_music(GAMESTATE:GetCurrentSong())
	end,
	resort_for_new_style= function(self)
		-- TODO:  This is being over used in places that don't actually change the
		-- style settings.  For efficiency, there should probably be special
		-- functions that only do the necessary work.
		self.cursor_song= gamestate_get_curr_song()
		self.cursor_item= self.sick_wheel:get_info_at_focus_pos().item
		bucket_man:style_filter_songs()
		return make_song_sort_worker(), function() self:post_sort_update() end
	end,
	add_randoms= function(self, bucket)
		local general_candy= {}
		local function general_random(el)
			if check_censor_list(el.el) then return end
			general_candy[#general_candy+1]= el.el
		end
		local filters= {general_random}
		local candies= {{name= "Random", candy= general_candy}}
		if not GAMESTATE:IsCourseMode() then
			for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
				add_player_randoms(filters, candies, pn)
			end
		end
		local function kidney(item)
			if check_censor_list(item.el) then return end
			for i= 1, #filters do
				filters[i](item)
			end
		end
		bucket_traverse(
			self.curr_bucket.contents or self.curr_bucket, nil, kidney)
		for i, candy in ipairs(candies) do
			local disp_name= candy.disp_name or
				get_string_wrapper("MusicWheel", candy.name)
			if #candy.candy > 0 then
				bucket[#bucket+1]= {
					name= candy.name, disp_name= disp_name, is_special= true,
					random_info= {candidate_set= candy.candy}}
			end
		end
	end,
	add_special_items_to_bucket= function(self, bucket)
		if self.current_sort_name ~= "Sort Menu" then
			-- The last element in the bucket is the special element for the current
			-- group.  It can't be added here because the name of the current display
			-- bucket isn't known when popping, and adding the special items happens
			-- during popping too.
			local last_el= bucket[#bucket]
			if last_el and last_el.is_current_group then
				bucket[#bucket]= nil
			else
				-- For the case where we are at the top level.
				last_el= nil
			end
			if not self.in_recent then
				if prev_picked_song and not check_censor_list(prev_picked_song) then
					bucket[#bucket+1]= {
						name= "Previous Song", is_special= true,
						disp_name= get_string_wrapper("MusicWheel", "PrevSong"),
						is_prev= true, song_info= prev_picked_song}
				end
				self.random_recent_pos= #bucket+1
				bucket[#bucket+1]= random_recent_bucket
				self.played_recent_pos= #bucket+1
				bucket[#bucket+1]= played_recent_bucket
				self.favorite_folder_pos= #bucket+1
				bucket[#bucket+1]= favor_folder_bucket
				self:add_randoms(bucket)
			end
			bucket[#bucket+1]= last_el
			--Trace("Added special items.")
		end
	end,
	remove_special_items_from_bucket= function(self, bucket)
		local i= 1
		while i <= #bucket and bucket[i] do
			local v= bucket[i]
			if v.is_special then
				table.remove(bucket, i)
			else
				i= i + 1
			end
		end
	end,
	set_display_bucket= function(self, bucket, pos)
		self.curr_bucket= bucket
		local disp_bucket= {}
		for i, v in ipairs(bucket.contents or bucket) do
			if v.contents then
				disp_bucket[#disp_bucket+1]= {bucket_info= v}
			elseif v.el then
				if v.el.GetBackgroundPath then
					disp_bucket[#disp_bucket+1]= {song_info= v.el, item= v}
				end
			elseif v.GetBackgroundPath then
				disp_bucket[#disp_bucket+1]= {song_info= v}
			elseif v.get_names then
				disp_bucket[#disp_bucket+1]= {sort_info= v}
			else
				Warn("Bad element in display bucket: " .. i)
				rec_print_table(v)
			end
		end
		if bucket.name then
			disp_bucket[#disp_bucket+1]= {bucket_info= bucket, is_current_group=true}
		end
		self:add_special_items_to_bucket(disp_bucket)
		self.display_bucket= disp_bucket
		self.sick_wheel:set_info_set(self.display_bucket, pos)
		self:set_stuff_from_curr_element()
		--Trace("SDB:")
		--print_table(self.display_bucket)
	end,
	follow_search_path= function(self, path, path_index, set)
		local sindex= path[path_index]
--		Trace("follow_search_path: " .. path_index .. " out of " .. #path)
		if sindex then
			self:set_display_bucket(set, sindex)
			local sbuck= set[sindex] or (set.contents and set.contents[sindex])
			if sbuck and path[path_index+1] then
				if sbuck.contents then
					self:push_onto_disp_stack()
					self:follow_search_path(path, path_index + 1, sbuck)
				end
			end
		end
	end,
	nav_to_named_element= function(self, name)
		--Trace("music_whale.nav_to_named_element")
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
	end,
	push_onto_disp_stack= function(self)
		self:remove_special_items_from_bucket(self.display_bucket)
		self.disp_stack[#self.disp_stack+1]= {
			b= self.display_bucket, c= self.curr_bucket,
			p= self.sick_wheel.info_pos }
	end,
	pop_from_disp_stack= function(self)
		if #self.disp_stack > 0 then
			local prev_bucket= self.disp_stack[#self.disp_stack]
			self.disp_stack[#self.disp_stack]= nil
			self.display_bucket= prev_bucket.b
			self.curr_bucket= prev_bucket.c
			self:add_special_items_to_bucket(self.display_bucket)
			self.sick_wheel:set_info_set(self.display_bucket, prev_bucket.p+self.focus_pos)
			self:set_stuff_from_curr_element()
		end
	end,
	save_disp_state= function(self)
		local state= {}
		for i, disp in ipairs(self.disp_stack) do
			state[#state+1]= {
				name= disp.b.name,
				combined_name_range= disp.b.combined_name_range,
				contents_name_range= disp.b.contents_name_range,
				from_adduns= disp.b.from_adduns,
				from_split= disp.b.from_split,
				from_similar= disp.b.from_similar,
			}
		end
		return state
	end,
	restore_disp_state= function(self, state)
		local i= 1
		local curr_set= self.sorted_songs
		while i <= #state do
			local disp= state[i]
			local sort_factor_matches= false
			for b, bucket in ipairs(curr_set) do
				
			end
		end
	end,
	scroll_left= function(self)
		self.sick_wheel:scroll_by_amount(-1)
		self:set_stuff_from_curr_element()
	end,
	scroll_right= function(self)
		self.sick_wheel:scroll_by_amount(1)
		self:set_stuff_from_curr_element()
	end,
	scroll_amount= function(self, a)
		self.sick_wheel:scroll_by_amount(a)
		self:set_stuff_from_curr_element()
	end,
	set_center_expansion= function(self, exp)
		center_expansion= exp
		self.sick_wheel:scroll_by_amount(0)
	end,
	update_recent_items= function(self)
		if self.random_recent_pos then
			local items= self.sick_wheel:get_items_by_info_index(self.random_recent_pos)
			for i, item in ipairs(items) do
				item:set(item.info)
			end
		elseif false then -- TODO:  This doesn't work smoothly.
			local new_pos= self.sick_wheel:maybe_wrap_index(
				self.sick_wheel.info_pos, 0, self.display_bucket)
			table.insert(self.display_bucket, make_bucket_from_recent(random_recent, "Recent from Random"))
			self.random_recent_pos= #self.display_bucket
			self.sick_wheel:set_info_set(self.display_bucket, new_pos + self.focus_pos)
		end
	end,
	set_stuff_from_curr_element= function(self)
		local curr_element= self.sick_wheel:get_info_at_focus_pos()
		if not curr_element then return end
		if curr_element.random_info then
			make_random_decision(curr_element.random_info)
			self:update_recent_items()
			if curr_element.random_info.chosen then
				gamestate_set_curr_song(curr_element.random_info.chosen)
			else
				gamestate_set_curr_song(nil)
			end
		elseif curr_element.bucket_info then
			gamestate_set_curr_song(nil)
		elseif curr_element.song_info then
			gamestate_set_curr_song(curr_element.song_info)
		else
			gamestate_set_curr_song(nil)
		end
	end,
	interact_with_element= function(self, pn)
		local curr_element= self.sick_wheel:get_info_at_focus_pos()
		if curr_element.bucket_info then
			if curr_element.is_current_group then
				self.in_recent= false
				self:pop_from_disp_stack()
			else
				self:push_onto_disp_stack()
				if curr_element.is_recent then
					self.in_recent= true
				else
					self.in_recent= false
				end
				self:set_display_bucket(curr_element.bucket_info, 0)
				play_sample_music()
			end
			local group_name= nice_bucket_disp_name(self.curr_bucket)
			MESSAGEMAN:Broadcast("current_group_changed", {group_name})
		elseif curr_element.sort_info then
			-- TODO:  Avoid the work of sorting if the current sort type is chosen.
			-- Problem:  Picking the current type when on a Random or Previous Song
			-- choice is a useful way of seeing what group that item came from.
			bucket_man.cur_sort_info= curr_element.sort_info
			if curr_element.sort_info.pre_sort_func == set_nps_player then
				curr_element.sort_info.pre_sort_arg= pn
			end
			return make_song_sort_worker(), function() self:post_sort_update() end
		elseif (curr_element.song_info or curr_element.random_info) and
		gamestate_get_curr_song() then
			local cur_song= gamestate_get_curr_song()
			add_song_to_recent_played(cur_song)
			local alt_cursor_songs= {}
			if not curr_element.random_info then
				local function gather_adjacent_songs(s)
					alt_cursor_songs[#alt_cursor_songs+1]= s.el
				end
				bucket_traverse(self.curr_bucket, nil, gather_adjacent_songs)
			end
			-- TODO:  Save off the names and sort factors of the buckets in the
			-- display stack and use that to find the way back to the same spot after
			-- gameplay.
			music_whale_state= {
				cur_sort_info= self.cur_sort_info,
				cursor_song= cur_song,
				cursor_item= curr_element.item,
				alt_cursor_songs= alt_cursor_songs,
			}
--			Trace("saved cursor_item:")
--			rec_print_table(music_whale_state.cursor_item)
			if curr_element.random_info or curr_element.is_prev then
				music_whale_state.on_random= curr_element.name
				music_whale_state.depth_to_random= #self.disp_stack
				--Trace("music_whale_state.depth_to_random: " .. music_whale_state.depth_to_random)
			end
			SCREENMAN:GetTopScreen():queuecommand("play_song")
		else
			Warn("Interacted with bad element in display bucket:")
			rec_print_table(curr_element)
		end
	end,
	close_group= function(self)
		self.in_recent= false
		self:pop_from_disp_stack()
		local group_name= nice_bucket_disp_name(self.curr_bucket)
		MESSAGEMAN:Broadcast("current_group_changed", {group_name})
	end,
	show_sort_list= function(self)
		if self.current_sort_name ~= "Sort Menu" then
			self.current_sort_name= "Sort Menu"
			self.cursor_song= gamestate_get_curr_song()
			self.cursor_item= nil
			self.in_recent= false
			self:push_onto_disp_stack()
			self:set_display_bucket(bucket_man:get_sort_info(), 1)
		end
	end,
	get_item_height= function(self)
		return item_height
	end,
}
music_whale_mt= { __index= music_whale }
