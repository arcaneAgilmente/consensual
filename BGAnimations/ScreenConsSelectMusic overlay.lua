local music_wheel= setmetatable({}, music_whale_interface_mt)
local auto_scrolling= nil
local next_auto_scroll_time= 0
local time_before_auto_scroll= .15
local time_between_auto_scroll= .08
local fast_auto_scroll= nil
local fast_scroll_start_time= 0
local time_before_fast_scroll= .8
local time_between_fast_scroll= .02
local banner_x= SCREEN_LEFT + 132
local banner_y= SCREEN_TOP + 44
local banner_w= 256
local banner_h= 80
local sort_width= 120
local sort_text_x= banner_x + (banner_w / 2) + (sort_width/2)
local wheel_x= sort_text_x + (sort_width/2) + 32
local title_x= banner_x - (banner_w / 2)
local title_y= banner_y + (banner_h / 2) + 12
local title_width= (wheel_x - 40) - title_x

local pane_text_zoom= .625
local pane_text_height= 16 * (pane_text_zoom / 0.5875)
-- Height was originally 16 in default theme, zoom was originally 0.5875,
--   so that is used as the base point.
local pane_text_width= 8 * (pane_text_zoom / 0.5875)
local pane_w= pane_text_width * 30
local pane_rows= 6 -- One row is actually padding.
local pane_h= pane_text_height * pane_rows
local pane_yoff= -pane_h * .5 + pane_text_height * .5
local pane_ltx= -pane_w * .25
local pane_rtx= pane_w * .25
local pad= 4

local entering_song= false
local options_time= 1.5
local go_to_options= false

local timer_actor= false
local function get_screen_time()
	if timer_actor then
		return timer_actor:GetSecsIntoEffect()
	else
		return 0
	end
end

local player_profiles= {}
local machine_profile= PROFILEMAN:GetMachineProfile()

function update_player_profile(pn)
	player_profiles[pn]= PROFILEMAN:GetProfile(pn)
end
update_player_profile(PLAYER_1)
update_player_profile(PLAYER_2)

local steps_display_interface= {}
local steps_display_interface_mt= { __index= steps_display_interface }

local std_items_mt= {
	__index=
		{
		create_actors= function(self, name)
			self.name= name
			self.tani= setmetatable({}, text_and_number_interface_mt)
			return self.tani:create_actors(
				name, {
					tx= -4, tz= .5, tc= solar_colors.uf_text(),
					text_section= "",
					nx= 4, nz= .5, nc= solar_colors.f_text()})
		end,
		find_actors= function(self, container)
			self.tani:find_actors(container)
		end,
		transform=
			function(self, item_index, num_items, is_focus)
				local changing_edge=
					((self.prev_index == 1 and item_index == num_items) or
				 (self.prev_index == num_items and item_index == 1))
				if changing_edge then
					self.tani:hide()
				end
				self.tani:move_to(0, (item_index - 1) * 12, .1)
				self.tani:unhide()
				self.prev_index= item_index
			end,
		set=
			function(self, info)
				self.info= info
				if info then
					self.tani:set_text(steps_to_string(info))
					self.tani:set_number(info:GetMeter())
					self.tani:unhide()
				else
					self.tani:set_text("")
					self.tani:set_number("")
				end
			end
	}
}

local steps_display_elements= 5
function steps_display_interface:create_actors(name)
	self.name= name
	local args= { Name= name, InitCommand= cmd(xy, banner_x, banner_y + (banner_h / 2) + 84) }
	local cursors= {}
	for i, v in ipairs(all_player_indices) do
		local new_curs= {}
		setmetatable(new_curs, frame_helper_mt)
		args[#args+1]= new_curs:create_actors(
			v .. "curs", .75, 80, 12, solar_colors[v](), solar_colors.bg(), -20, 0)
		cursors[v]= new_curs
	end
	self.cursors= cursors
	self.sick_wheel= setmetatable({disable_wrapping= true}, sick_wheel_mt)
	args[#args+1]= self.sick_wheel:create_actors(steps_display_elements, std_items_mt, 0, 0)
	return Def.ActorFrame(args)
end

function steps_display_interface:find_actors(container)
	self.container= container
	if not self.container then
		Trace("steps_display_interface:find_actors passed nil container.")
		return nil
	end
	for k, v in pairs(self.cursors) do
		v:find_actors(container:GetChild(v.name))
		if not GAMESTATE:IsPlayerEnabled(k) then
			v:hide()
		end
	end
	self.sick_wheel:find_actors(container:GetChild(self.sick_wheel.name))
	return true
end

function steps_display_interface:update_steps_set()
	local candidates= get_filtered_sorted_steps_list()
	if candidates and #candidates > 0 then
		self.sick_wheel:set_info_set(candidates, 1)
		self.container:diffusealpha(1)
	else
		self.sick_wheel:set_info_set(candidates, 1)
		self.container:diffusealpha(0)
	end
end

function steps_display_interface:update_cursors()
	local candidates= self.sick_wheel.info_set
	if candidates and #candidates > 0 then
		local player_steps= {}
		local enabled_players= GAMESTATE:GetEnabledPlayers()
		for i, v in ipairs(enabled_players) do
			player_steps[v]= gamestate_get_curr_steps(v)
		end
		local cursor_poses= {}
		for i, s in ipairs(candidates) do
			for pi, pv in ipairs(enabled_players) do
				if s == player_steps[pv] then
					cursor_poses[pv]= i-1
				end
			end
		end
		local tot= 0
		local cnt= 0
		for k, p in pairs(cursor_poses) do
			tot= tot + p
			cnt= cnt + 1
		end
		local average= tot / cnt
		self.sick_wheel:scroll_to_pos(average+1)
		for k, cursor in pairs(self.cursors) do
			if cursor_poses[k] then
				local real_pos= cursor_poses[k] - self.sick_wheel.info_pos
				local item= self.sick_wheel:find_item_by_info(player_steps[k])[1]
				if item then
					local tot, tw, nw= item.tani:get_widths()
					local cx= nw - (tot / 2)
					local cy= item.tani.y
					cursor:set_width(tot + 2)
					cursor:move(cx, cy)
					cursor:unhide()
				else
					cursor:hide()
				end
			else
				cursor:hide()
			end
		end
		if cursor_poses[PLAYER_1] == cursor_poses[PLAYER_2] then
			self.cursors[PLAYER_1].inner:cropright(.5)
			self.cursors[PLAYER_1].outer:cropright(.5)
			self.cursors[PLAYER_2].inner:cropleft(.5)
			self.cursors[PLAYER_2].outer:cropleft(.5)
		else
			self.cursors[PLAYER_1].inner:cropright(0)
			self.cursors[PLAYER_1].outer:cropright(0)
			self.cursors[PLAYER_2].inner:cropleft(0)
			self.cursors[PLAYER_2].outer:cropleft(0)
		end
	end
end

local pain_display_interface= {}
local pain_display_interface_mt= { __index= pain_display_interface }

local radar_categories= {
	"RadarCategory_TapsAndHolds", "RadarCategory_Jumps", "RadarCategory_Holds",
	"RadarCategory_Mines", "RadarCategory_Hands", "RadarCategory_Rolls",
	"RadarCategory_Lifts", "RadarCategory_Fakes"
}
local pane_element_switches= {
	{Taps= false, Jumps= false, Holds= false, Mines= false, Rating= true,
	 Hands= false, Rolls= false, Lifts= false, Fakes= false},
	{Taps= true, Jumps= true, Holds= true, Mines= false, Rating= true,
	 Hands= false, Rolls= false, Lifts= false, Fakes= false},
	{Taps= true, Jumps= true, Holds= true, Mines= true, Rating= true,
	 Hands= true, Rolls= true, Lifts= false, Fakes= false},
	{Taps= true, Jumps= true, Holds= true, Mines= true, Rating= true,
	 Hands= true, Rolls= true, Lifts= true, Fakes= true},
}

local radar_poses= {
	RadarCategory_TapsAndHolds= { short_name= "Taps", x= pane_ltx,
																y= pane_yoff + pane_text_height * 2 },
	RadarCategory_Jumps= { short_name= "Jumps", x= pane_ltx,
												 y= pane_yoff + pane_text_height * 3 },
	RadarCategory_Holds= { short_name= "Holds", x= pane_ltx,
												 y= pane_yoff + pane_text_height * 4 },
	RadarCategory_Mines= { short_name= "Mines", x= pane_ltx,
												 y= pane_yoff + pane_text_height * 5 },
	RadarCategory_Hands= { short_name= "Hands", x= pane_rtx,
												 y= pane_yoff + pane_text_height * 2},
	RadarCategory_Rolls= { short_name= "Rolls", x= pane_rtx,
												 y= pane_yoff + pane_text_height * 3 },
	RadarCategory_Lifts= { short_name= "Lifts", x= pane_rtx,
												 y= pane_yoff + pane_text_height * 4 },
	RadarCategory_Fakes= { short_name= "Fakes", x= pane_rtx,
												 y= pane_yoff + pane_text_height * 5 }
}

function pain_display_interface:create_actors(player_number, x, y)
	self.name= player_number .. "pain"
	self.player_number= player_number
	local args= { Name= self.name, InitCommand= cmd(xy, x, y) }
	args[#args+1]= create_frame_quads(
		"frame", 2, pane_w, pane_h, solar_colors[player_number](),
		solar_colors.bg(), 0, 0)
	self.radars= {}
	local column_pad= 4
	local tani_args= {
			tz= pane_text_zoom, nz= pane_text_zoom, text_section= "PaneDisplay",
			tx= column_pad - pane_w * .25, nx= pane_w * .25 - column_pad,
			ta= left, na= right, tf= "Common SemiBold", nf= "Common SemiBold"
		}
	for i, v in ipairs(radar_categories) do
		tani_args.sx= radar_poses[v].x  tani_args.sy= radar_poses[v].y
		tani_args.tt= radar_poses[v].short_name
		local rad= setmetatable({}, text_and_number_interface_mt)
		rad.short_name= radar_poses[v].short_name
		rad.upper= false
		self.radars[i]= rad
		args[#args+1]= rad:create_actors(v, tani_args)
	end
	tani_args.tt= nil
	self.machine_score= setmetatable({}, text_and_number_interface_mt)
	tani_args.sx= pane_rtx  tani_args.sy= pane_yoff
	args[#args+1]= self.machine_score:create_actors("MScore", tani_args)
	self.player_score= setmetatable({}, text_and_number_interface_mt)
	tani_args.sx= pane_ltx  tani_args.sy= pane_yoff
	args[#args+1]= self.player_score:create_actors("PScore", tani_args)
	self.rating= setmetatable({}, text_and_number_interface_mt)
	tani_args.sx= pane_rtx  tani_args.sy= pane_yoff + pane_text_height
	args[#args+1]= self.rating:create_actors("Rating", tani_args)
	self.bpm_disp= setmetatable({}, text_and_number_interface_mt)
	tani_args.sx= pane_ltx  tani_args.sy= pane_yoff + pane_text_height
	tani_args.tt= "BPM"
	args[#args+1]= self.bpm_disp:create_actors("BPM", tani_args)
	return Def.ActorFrame(args)
end

function pain_display_interface:find_actors(container)
	self.container= container
	if not self.container then
		Trace("pain_display_interface:find_actors passed nil container.")
		return nil
	end
	if not GAMESTATE:IsPlayerEnabled(self.player_number) then
		container:visible(false)
	end
	for i, v in ipairs(self.radars) do
		v:find_actors(container:GetChild(v.name))
	end
	self.machine_score:find_actors(container:GetChild(self.machine_score.name))
	self.player_score:find_actors(container:GetChild(self.player_score.name))
	self.rating:find_actors(container:GetChild(self.rating.name))
	self.bpm_disp:find_actors(container:GetChild(self.bpm_disp.name))
	return true
end

function pain_display_interface:update()
	if self.container then
		if GAMESTATE:IsPlayerEnabled(self.player_number) then
			self.container:visible(true)
			local strail= gamestate_get_curr_steps(self.player_number)
			local song= gamestate_get_curr_song()
			-- For hiding.
			if song and strail then
				local radar_values= strail:GetRadarValues(self.player_number)
				if radar_values then
					local vis_table= pane_element_switches[cons_players[self.player_number].options_level]
					for i, v in ipairs(self.radars) do
						local value= radar_values:GetValue(radar_categories[i])
						v:set_number(value)
						if vis_table and vis_table[v.short_name] then
							v:unhide()
						else
							v:hide()
						end
					end
				end
				function set_score_tani_from_profile(pro, tani)
					tani:hide()
					if pro then
						local hs_list= pro:GetHighScoreList(song, strail)
						if hs_list then
							local highest_score= hs_list:GetHighScores()[1]
							if highest_score then
								tani:set_text(highest_score:GetName())
								width_clip_text(tani.text, pane_w * .25)
								local score= highest_score:GetPercentDP()
								tani:set_number(("%.2f%%"):format(score * 100))
								tani.number:diffuse(color_for_score(score))
								if score > .9999 then
									if global_distortion_mode then
										tani.number:undistort()
									else
										tani.number:distort(.5)
									end
								elseif not global_distortion_mode then
									tani.number:undistort()
								end
								tani:unhide()
							end
						end
					end
				end
				set_score_tani_from_profile(
					player_profiles[self.player_number], self.player_score)
				set_score_tani_from_profile(machine_profile, self.machine_score)
				self.rating:set_text(steps_to_string(strail))
				self.rating:set_number(strail:GetMeter())
				local bpm_text= steps_get_bpms_as_text(strail)
				self.bpm_disp:set_number(bpm_text)
				self.rating:unhide()
				self.bpm_disp:unhide()
			else
				for i, v in ipairs(self.radars) do
					v:hide()
				end
				self.machine_score:hide()
				self.player_score:hide()
				self.rating:hide()
				self.bpm_disp:hide()
			end
			self.container:diffusealpha(1)
		else
			self.container:diffusealpha(0)
		end
	end
end

local steps_display= setmetatable({}, steps_display_interface_mt)
local pain_displays= {
	[PLAYER_1]= setmetatable({}, pain_display_interface_mt),
	[PLAYER_2]= setmetatable({}, pain_display_interface_mt),
}

local function start_auto_scrolling(dir)
	local time_before_scroll= GetTimeSinceStart()
	music_wheel:scroll_amount(dir)
	local time_after_scroll= GetTimeSinceStart()
	auto_scrolling= dir
	local curr_time= get_screen_time() + (time_after_scroll - time_before_scroll)
	next_auto_scroll_time= curr_time + time_before_auto_scroll
	fast_scroll_start_time= curr_time + time_before_fast_scroll
end

local function note_data_mod_test(note_data)
	local tapnote_found= false
	local tap_row= 1
	while not tapnote_found do
		local tapnote= note_data:GetTapNote(1, tap_row)
		if tapnote then
			Trace("Tapnote found on row " .. tap_row .. " of type " .. tapnote:GetType())
			tapnote_found= true
		end
		tap_row= tap_row + 1
		if tap_row > 3000 then
			Trace("Tapnote not found in the first 3000 rows.")
			tapnote_found= true
		end
	end
	local function print_rows(tapnote, row, track)
		Trace(tapnote:GetType() .. " r: " .. row .. " t: " .. tostring(track))
	end
	local lefts= 0
	local rights= 0
	local function arrow_count(tapnote, row, track)
		if track == 0 then
			lefts= lefts+1
		end
		if track == 3 then
			rights= rights+1
		end
	end
	local function print_and_count(tapnote, row, track)
		print_rows(tapnote, row, track)
		arrow_count(tapnote, row, track)
	end
	note_data:ForEachTapNoteAllTracks(0, -1, arrow_count)
	Trace(lefts .. " lefts, " .. rights .. " rights.");
	local first_left_beat= note_data:GetNextTapNoteRowForTrack(0, 0)
	Trace("first_left_beat is " .. tostring(first_left_beat))
	local row_empty= note_data:IsRowEmpty(first_left_beat)
	local range_empty= note_data:IsRangeEmpty(0, first_left_beat-1, first_left_beat+1)
	local num_taps_on_row= note_data:GetNumTapsOnRow(first_left_beat)
	local tracks_with_tap= note_data:GetTracksWithTapAtRow(first_left_beat)
	Trace("flb: " .. first_left_beat .. " re: " .. tostring(row_empty) .. " rae: " .. tostring(range_empty) .. " ntor: " .. num_taps_on_row .. " twt: " .. table.concat(tracks_with_tap, ", "))
end

local function steps_decompress_test(steps)
	if not steps then return end
	local start_time= GetTimeSinceStart()
	local note_data= steps:GetNoteData()
	local end_time= GetTimeSinceStart()
	--NoteDataUtil.ExamineNoteDataMeta(note_data)
	local note_meta= getmetatable(note_data)
	Trace("NoteData metatable:")
	rec_print_table(note_meta)
	local alloced_nd= NoteDataUtil.NewNoteData()
	Trace("alloced_nd: " .. tostring(alloced_nd))
	local alloced_meta= getmetatable(alloced_nd)
	Trace("Alloced metatable:")
	rec_print_table(alloced_meta)
	local alloced_meta_meta= getmetatable(alloced_meta)
	Trace("Alloced metametatable:")
	rec_print_table(alloced_meta_meta)
	Trace("alloced_nd.GetTapNote: " .. tostring(alloced_nd.GetTapNote))
	-- note_data_mod_test(note_data)
	steps:ReleaseNoteData()
	local post_release_time= GetTimeSinceStart()
	Trace("SDT:  " .. (end_time - start_time) .. " to decompress.  " .. (post_release_time - end_time) .. " to release.")
end

local function stop_auto_scrolling()
	--steps_decompress_test(GAMESTATE:GetCurrentSteps(PLAYER_2))
	play_sample_music()
	auto_scrolling= nil
	fast_auto_scroll= nil
end

local function Update(self)
	if entering_song then
		if get_screen_time() > entering_song then
			SCREENMAN:GetTopScreen():queuecommand("real_play_song")
		end
	else
		if auto_scrolling then
			if get_screen_time() > next_auto_scroll_time then
				local time_before_scroll= GetTimeSinceStart()
				music_wheel:scroll_amount(auto_scrolling)
				local time_after_scroll= GetTimeSinceStart()
				local curr_time= get_screen_time()
				curr_time= curr_time + (time_after_scroll - time_before_scroll)
				if fast_auto_scroll then
					next_auto_scroll_time= curr_time + time_between_fast_scroll
				else
					next_auto_scroll_time= curr_time + time_between_auto_scroll
					if curr_time > fast_scroll_start_time then
						fast_auto_scroll= true
					end
				end
			end
		end
	end
end

local codes= {
	{ name= "sort_mode", ignore_release= true,
		"up", "down", "up", "down" },
	{ name= "sort_mode", ignore_release= false,
		"menu_left", "menu_right" },
	{ name= "sort_mode", ignore_release= false,
		ignore_press_list= {"menu_left", "menu_right", "start"},
		ignore_release_list= {"menu_left_release", "menu_right_release"},
		"select", "start" },
	{ name= "diff_up", ignore_release= true,
		"up", "up" },
	{ name= "diff_down", ignore_release= true,
		"down", "down" },
	{ name= "diff_up", ignore_release= false, repeat_first_on_end= true,
		ignore_press_list= {"menu_right", "start"},
		ignore_release_list= {
			"menu_left_release", "menu_right_release", "start_release"},
		"select", "menu_left"},
	{ name= "diff_down", ignore_release= false, repeat_first_on_end= true,
		ignore_press_list= {"menu_left", "start"},
		ignore_release_list= {
			"menu_left_release", "menu_right_release", "start_release"},
		"select", "menu_right"},
	--{ name= "noob_mode", ignore_release= true,
	--"left", "left", "left", "right", "right", "right", "up", "up",
	--"up", "down", "down", "down" },
	{ name= "simple_options_mode", ignore_release= true,
	"left", "down", "right", "left", "down", "right" },
	{ name= "all_options_mode", ignore_release= true,
	"right", "down", "left", "right", "down", "left" },
	{ name= "excessive_options_mode", ignore_release= true,
		"left", "up", "right", "up", "left", "down", "right", "down", "left" },
	{ name= "kyzentun_mode", ignore_release= true,
		"right", "up", "left", "right", "up", "left" },
	{ name= "unjoin", ignore_release= true,
		"down", "left", "up", "down", "left", "up", "down", "left", "up" },
}
for i, v in ipairs(codes) do
	v.curr_pos= { [PLAYER_1]= 1, [PLAYER_2]= 1}
end

local function key_on_list(key, list)
	if list then
		for i, entry in ipairs(list) do
			if entry == key then
				return true
			end
		end
	end
	return false
end

local function update_code_status(press, player)
	local triggered= {}
	for i, v in ipairs(codes) do
		if press == v[v.curr_pos[player]] then
			v.curr_pos[player]= v.curr_pos[player] + 1
			if v.curr_pos[player] > #v then
				triggered[#triggered+1]= v.name
				v.curr_pos[player]= 1
				if v.repeat_first_on_end then
					v.curr_pos[player]= 2
				end
			end
		else
			if press:find("release") then
				local on_ignore= key_on_list(press, v.ignore_release_list)
				if not v.ignore_release and not on_ignore then
					v.curr_pos[player]= 1
				end
			else
				local on_ignore= key_on_list(press, v.ignore_press_list)
				if not on_ignore then
					v.curr_pos[player]= 1
				end
			end
		end
	end
	return triggered
end

local function adjust_difficulty(player, dir, sound)
	local steps= gamestate_get_curr_steps(player)
	if steps then
		local steps_list= get_filtered_sorted_steps_list()
		for i, v in ipairs(steps_list) do
			if v == steps then
				local picked_steps= steps_list[i+dir]
				if picked_steps then
					cons_set_current_steps(player, picked_steps)
					SOUND:PlayOnce("Themes/_fallback/Sounds/_switch " .. sound)
				else
					SOUND:PlayOnce("Themes/_fallback/Sounds/Common invalid.ogg")
				end
				break
			end
		end
	end
end

local options_message_frame_helper= setmetatable({}, frame_helper_mt)

local input_functions= {
	scroll_left= function() start_auto_scrolling(-1) end,
	scroll_right= function() start_auto_scrolling(1) end,
	stop_scroll= function() stop_auto_scrolling() end,
	interact= function()
							music_wheel:interact_with_element()
							local sort_name= music_wheel.current_sort_name
							local stext= SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("sort_text")
							if stext then
								stext:settext(sort_name)
								width_limit_text(stext, sort_width)
							end
						end,
	back= function()
					stop_music()
					SOUND:PlayOnce("Themes/_fallback/Sounds/Common cancel.ogg")
					SCREENMAN:SetNewScreen("ScreenInitialMenu")
				end
}

local input_maps= {
	[input_mode_pad]= {
		left= input_functions.scroll_left,
		right= input_functions.scroll_right,
		left_release= input_functions.stop_scroll,
		right_release= input_functions.stop_scroll,
		start= input_functions.interact,
		back= input_functions.back
	},
	[input_mode_cabinet]= {
		menu_left= input_functions.scroll_left,
		menu_right= input_functions.scroll_right,
		menu_left_release= input_functions.stop_scroll,
		menu_right_release= input_functions.stop_scroll,
		start= input_functions.interact,
		back= input_functions.back
	},
}

local curr_input_map= input_maps[get_input_mode()]

local function spew_song_specials(song)
	local special_names= {
		"Warps", "Fakes", "Scrolls", "Speeds", "TimeSignatures", "Combos",
		"Tickcounts", "Stops", "Delays", "BPMs", "BPMsAndTimes"
	}
	Trace("Spewing specials for " .. song:GetDisplayFullTitle())
	local timing_data= song:GetTimingData()
	for i, name in ipairs(special_names) do
		local func_name= "Get"..name
		Trace(name .. " : (" .. func_name .. ")")
		local specs= timing_data[func_name](timing_data)
		rec_print_table(specs, "  ")
	end
	Trace("Done.")
	Trace("Does GetBPMs actually return strings?")
	local bpms= timing_data:GetBPMs()
	for i, bpm in ipairs(bpms) do
		print(type(bpm))
	end
	Trace("Done.")
end

return Def.ActorFrame {
	InitCommand= function(self)
								 self:SetUpdateFunction(Update)
								 for k, v in pairs(pain_displays) do
									 v:find_actors(self:GetChild(v.name))
								 end
								 steps_display:find_actors(self:GetChild(steps_display.name))
								 music_wheel:find_actors(self:GetChild(music_wheel.name))
							 end,
	OnCommand= function(self)
							 local top_screen= SCREENMAN:GetTopScreen()
							 if top_screen.SetAllowLateJoin then
								 top_screen:SetAllowLateJoin(true)
							 end
						 end,
	play_songCommand= function(self)
											SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
											local om= self:GetChild("options message")
											om:accelerate(0.25)
											om:diffusealpha(1)
											entering_song= get_screen_time() + options_time
										end,
	real_play_songCommand= function(self)
													 if go_to_options then
														 SCREENMAN:SetNewScreen("ScreenSickPlayerOptions")
													 else
														 SCREENMAN:SetNewScreen("ScreenStageInformation")
													 end
												 end,
	Def.ActorFrame{
		Name= "If these commands were in the parent actor frame, they would not activate.",
		CurrentSongChangedMessageCommand=cmd(playcommand,"SCSet"),
		CurrentCourseChangedMessageCommand=cmd(playcommand,"SCSet"),
		PlayerJoinedMessageCommand=cmd(playcommand,"Set"),
		PlayerUnJoinedMessageCommand=cmd(playcommand,"Set"),
		CurrentStepsP1ChangedMessageCommand=cmd(playcommand,"Set"),
		CurrentStepsP2ChangedMessageCommand=cmd(playcommand,"Set"),
		CurrentTrailP1ChangedMessageCommand=cmd(playcommand,"Set"),
		CurrentTrailP2ChangedMessageCommand=cmd(playcommand,"Set"),
		SCSetCommand= function(self)
										steps_display:update_steps_set()
										self:playcommand("Set")
									end,
		SetCommand= function(self)
									pain_displays[PLAYER_1]:update()
									pain_displays[PLAYER_2]:update()
									steps_display:update_cursors()
								end,
	},
	pain_displays[PLAYER_1]:create_actors(
		PLAYER_1, SCREEN_LEFT+(pane_w/2)+pad,
		SCREEN_BOTTOM-pane_h-(pane_h/2)-(pad*2)),
	pain_displays[PLAYER_2]:create_actors(
		PLAYER_2, SCREEN_LEFT+(pane_w/2)+pad, SCREEN_BOTTOM-(pane_h/2)-pad),
	steps_display:create_actors("StepsDisplay"),
	Def.Sprite {
		Name="CDTitle",
		InitCommand=cmd(x,SCREEN_CENTER_X-43;y,SCREEN_TOP+210),
		OnCommand=cmd(draworder,106;shadowlength,1;zoom,0.75;diffusealpha,1;zoom,0;bounceend,0.35;zoom,0.75;),
		CurrentSongChangedMessageCommand=
			function(self)
				-- Courses can't have CDTitles, so gamestate_get_curr_song isn't used.
				local song= GAMESTATE:GetCurrentSong()
				if song and song:HasCDTitle()then
					self:Load(song:GetCDTitlePath())
					self:visible(true)
					-- Jousway suggests fucking people with fucking huge cdtitles.
					local height= self:GetHeight()
					local width= self:GetWidth()
					local max_size= 70
					self:zoom(max_size / math.max(max_size, math.max(height, width)))
				else
					self:visible(false)
				end
			end
	},
	Def.Sprite {
		Name="Banner",
		InitCommand=cmd(xy, banner_x, banner_y),
		OnCommand=cmd(scaletoclipped, banner_w, banner_h),
		CurrentCourseChangedMessageCommand= cmd(playcommand, "Set"),
		CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
		SetCommand=
			function(self)
				local song= gamestate_get_curr_song()
				if song and song:HasBanner()then
					self:Load(song:GetBannerPath())
					self:visible(true)
				else
					self:visible(false)
				end
			end,
		current_group_changedMessageCommand=
			function(self, param)
				local name= param[1]
				if songman_does_group_exist(name) then
					local path= songman_get_group_banner_path(name)
					if path and path ~= "" then
						self:Load(path)
						self:visible(true)
					else
						self:visible(false)
					end
				else
					self:visible(false)
				end
			end
	},
	normal_text("SongName", "", solar_colors.f_text(),
							title_x, title_y, 1, left,
							{ CurrentCourseChangedMessageCommand= cmd(playcommand, "Set"),
								CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
								SetCommand=
									function(self)
										local song= gamestate_get_curr_song()
										if song then
											--spew_song_specials(song)
											self:settext(song_get_main_title(song))
											width_limit_text(self, title_width)
											self:visible(true)
										else
											self:visible(false)
										end
									end,
								current_group_changedMessageCommand=
									function(self, param)
										local name= param[1]
										if name then
											self:settext(name)
											width_limit_text(self, title_width)
											self:visible(true)
										else
											self:visible(false)
										end
									end }),
	normal_text("length", "", solar_colors.f_text(), SCREEN_LEFT + 16,
							banner_y + (banner_h / 2) + 36, 1, left, {
								CurrentCourseChangedMessageCommand= cmd(playcommand, "Set"),
								CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
								SetCommand=
									function(self)
										local song= gamestate_get_curr_song()
										if song then
											local seconds= song_get_length(song)
											local minutes= math.floor(math.round(seconds) / 60)
											seconds= math.round(seconds) % 60
											if seconds < 10 then seconds= "0" .. seconds end
											self:settext(minutes .. ":" .. seconds .. " long")
											self:visible(true)
										else
											self:visible(false)
										end
									end
							}),
	normal_text("remaining", "", solar_colors.uf_text(), SCREEN_LEFT + 16,
							banner_y + (banner_h / 2) + 60, 1, left, {
								OnCommand=
									function(self)
										local seconds= get_time_remaining()
										local minutes= math.floor(math.round(seconds) / 60)
										seconds= math.round(seconds) % 60
										if seconds < 10 then seconds= "0" .. seconds end
										self:settext(minutes .. ":" .. seconds .. " remaining")
									end
							}),
	music_wheel:create_actors(wheel_x),
	Def.Actor{
		Name= "code_interpreter",
		InitCommand= function(self)
									 self:effectperiod(2^16)
									 timer_actor= self
								 end,
		CurrentCourseChangedMessageCommand= cmd(playcommand, "sc_changed"),
		CurrentSongChangedMessageCommand= cmd(playcommand, "sc_changed"),
		sc_changedCommand=
			function(self)
				local enabled_players= GAMESTATE:GetEnabledPlayers()
				for i, v in ipairs(enabled_players) do
					local preferred_diff= GAMESTATE:GetPreferredDifficulty(v)
					local curr_steps_type= GAMESTATE:GetCurrentStyle():GetStepsType()
					local candidates= get_filtered_sorted_steps_list()
					if candidates and #candidates > 0 then
						local steps_set= false
						local default_steps= nil
						for i, c in ipairs(candidates) do
							if c:GetDifficulty() == preferred_diff
							and c:GetStepsType() == curr_steps_type then
								cons_set_current_steps(v, c)
								steps_set= true
							elseif not default_steps then
								default_steps= c
							end
						end
						if not steps_set and default_steps then
							cons_set_current_steps(v, default_steps)
						end
					end
				end
			end,
		CodeMessageCommand=
			function(self, param)
				local pn = param.PlayerNumber
				if GAMESTATE:IsSideJoined(pn) then
					if get_screen_time() > 0.25 then
						local name = param.Name
						if entering_song then
							if name == "start" then
								SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
								entering_song= 0
								go_to_options= true
							end
						else
							local triggered= update_code_status(name, pn)
							for i, v in ipairs(triggered) do
								local ctext= SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("code_text")
								if ctext then
									if convert_code_name_to_display_text[v] then
										ctext:settext(convert_code_name_to_display_text[v])
										ctext:DiffuseAndStroke(solar_colors.bg(0),solar_colors.f_text())
										ctext:finishtweening()
										local w= ctext:GetWidth()
										local h= ctext:GetHeight()
										local z= ctext:GetZoom()
										ctext:x(SCREEN_LEFT+(w*z/2)+2)
										ctext:y(SCREEN_TOP+(h*z/2)+4)
										ctext:ease(.5,-100)
										ctext:diffusealpha(1)
										ctext:sleep(2)
										ctext:ease(.5,100)
										ctext:diffusealpha(0)
									end
								end
								if v == "sort_mode" then
									music_wheel:show_sort_list()
								elseif v == "diff_up" then
									adjust_difficulty(pn, -1, "up.ogg")
								elseif v == "diff_down" then
									adjust_difficulty(pn, 1, "down.ogg")
								elseif v == "unjoin" then
									SOUND:PlayOnce("Themes/_fallback/Sounds/Common Cancel.ogg")
									if false then -- crashes
										Trace("Master player: " .. GAMESTATE:GetMasterPlayerNumber())
										Trace("Unjoining player: " .. pn)
										GAMESTATE:UnjoinPlayer(other_player[pn])
										Trace("NPE: " .. GAMESTATE:GetNumPlayersEnabled())
										lua.Flush()
										GAMESTATE:ApplyGameCommand("style,single", pn)
										Trace("Master player after unjoin: " .. GAMESTATE:GetMasterPlayerNumber())
										steps_display:update_steps_set()
										pain_displays[pn]:update()
									end
								end
								if cons_players[pn] and cons_players[pn][v] then
									cons_players[pn][v](cons_players[pn])
								end
							end
							if #triggered == 0 then
								if curr_input_map[name] then
									curr_input_map[name]()
								end
							end
						end
					end
				else
					if param.Name == "start" then
						local curr_style_type= GAMESTATE:GetCurrentStyle():GetStyleType()
						if curr_style_type == "StyleType_OnePlayerOneSide" then
							if cons_join_player(pn) then
								SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
								cons_players[pn]:clear_init(pn)
								local cpm= GAMESTATE:GetPlayMode()
								GAMESTATE:ApplyGameCommand(
									"playmode," .. playmode_to_command[cpm], pn)
								GAMESTATE:ApplyGameCommand("style,versus")
								steps_display:update_steps_set()
								-- Loading the profile for the joining player is not
								-- possible without exposing several PROFILEMAN and GAMESTATE
								-- functions.
								local pref_diff= (GAMESTATE:GetPreferredDifficulty(pn) or
																"Difficulty_Beginner")
								local steps_list= get_filtered_sorted_steps_list()
								local set_steps= false
								for i, v in ipairs(steps_list) do
									if v:GetDifficulty() == pref_diff then
										set_steps= true
										cons_set_current_steps(pn, v)
									end
								end
								if not set_steps and steps_list[1] then
									cons_set_current_steps(pn, steps_list[1])
								end
							end
						end
					end
				end
			end
	},
	normal_text("code_text", "", solar_colors.f_text(0), 0, 0, .75),
	normal_text("sort", "Sort", solar_colors.uf_text(), sort_text_x, SCREEN_TOP + 36),
	normal_text("sort_text", music_wheel.current_sort_name,
							solar_colors.f_text(), sort_text_x, SCREEN_TOP + 12),
	credit_reporter(SCREEN_LEFT+120, SCREEN_BOTTOM - 24 - (pane_h * 2), true),
	Def.ActorFrame{
		Name= "options message",
		InitCommand= function(self)
									 self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
									 self:diffusealpha(0)
									 options_message_frame_helper:find_actors(
										 self:GetChild(options_message_frame_helper.name))
								 end,
		OnCommand= function(self)
								 local xmn, xmx, ymn, ymx= rec_calc_actor_extent(self)
								 options_message_frame_helper:move((xmx+xmn)/2, (ymx+ymn)/2)
								 options_message_frame_helper:resize(xmx-xmn+20, ymx-ymn+20)
							 end,
		options_message_frame_helper:create_actors(
			"omf", 2, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0),
		normal_text("omm", "Press start for options.", solar_colors.green(), 0, 0, 2),
	},
}
