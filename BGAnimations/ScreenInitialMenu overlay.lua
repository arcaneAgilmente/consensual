-- Unjoin currently joined players because stuff like going into the options and changing the theme joins players.
local reset_start= GetTimeSinceStart()
GAMESTATE:Reset()
for i, cn in ipairs{PLAYER_1, PLAYER_2} do
	cons_players[cn]:clear_init(cn)
end
local reset_end= GetTimeSinceStart()
--Trace("Reset time: " .. reset_end - reset_start)
SOUND:StopMusic()
turn_censoring_on()
play_sample_music(true)
aprf_check()
activate_confetti("credit", false)
workout_mode= nil
in_edit_mode= false
true_gameplay= false

local line_height= get_line_height()

local profile_list= {}
for p= 0, PROFILEMAN:GetNumLocalProfiles()-1 do
	local profile= PROFILEMAN:GetLocalProfileFromIndex(p)
	local id= PROFILEMAN:GetLocalProfileIDFromIndex(p)
	profile_list[#profile_list+1]= {
		name= profile:GetDisplayName(), id= id}
end

load_favorites("ProfileSlot_Machine")
load_tags("ProfileSlot_Machine")

local num_songs= SONGMAN:GetNumSongs()
local num_groups= SONGMAN:GetNumSongGroups()
local frame_helper= setmetatable({}, frame_helper_mt)

local playmode= "PlayMode_Regular"
local function get_prof_choice(pn)
	return PREFSMAN:GetPreference("DefaultLocalProfileID" .. ToEnumShortString(pn))
end
local function set_prof_choice(pn, id)
	PREFSMAN:SetPreference("DefaultLocalProfileID" .. ToEnumShortString(pn), id)
end

dofile(THEME:GetPathO("", "options_menu.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))

local function check_play_regular()
	return playmode == "PlayMode_Regular"
end
local function set_play_regular()
	playmode= "PlayMode_Regular"
end
local function check_play_nonstop()
	return playmode == "PlayMode_Nonstop"
end
local function set_play_nonstop()
	playmode= "PlayMode_Nonstop"
end
local function check_play_workout()
	return playmode == "PlayMode_Workout"
end
local function set_play_workout()
	playmode= "PlayMode_Workout"
end

local playmode_menu_init= {
	name= "playmode_choice", eles= {
		{ name= "Regular", init= check_play_regular, set= set_play_regular,
			unset= noop_false},
		{ name= "Nonstop", init= check_play_nonstop, set= set_play_nonstop,
			unset= noop_false},
--		{ name= "Workout", init= check_play_workout, set= set_play_workout,
--			unset= noop_false},
}}
local playmode_menu= setmetatable({}, options_sets.mutually_exclusive_special_functions)
playmode_menu:initialize(nil, playmode_menu_init)

options_sets.profile_menu= {
	__index= {
		initialize= function(self, player_number)
			self.name= ToEnumShortString(player_number) .. " Profile"
			self.cursor_pos= 1
			self.player_number= player_number
			self.info_set= {up_element()}
			local has_card= false
			if PREFSMAN:GetPreference("MemoryCards") then
				local state= MEMCARDMAN:GetCardState(player_number)
				Trace("Memcard " .. player_number .. " state: " .. state)
				if state == "MemoryCardState_ready" then
					self.info_set[#self.info_set+1]= {text= "Card", underline= true}
					has_card= true
				end
			end
			if not has_card then
				for i, pro in ipairs(profile_list) do
					self.info_set[#self.info_set+1]= {text= pro.name, id= pro.id}
					if pro.id == get_prof_choice(player_number) then
						self.info_set[#self.info_set].underline= true
					end
				end
			end
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
		end,
		interpret_start= function(self)
			for i, info in ipairs(self.info_set) do
				if info.underline then
					info.underline= false
					self.display:set_element_info(i, info)
				end
			end
			local prinfo= self.info_set[self.cursor_pos]
			if prinfo.id then
				set_prof_choice(self.player_number, prinfo.id)
			end
			self.info_set[self.cursor_pos].underline= true
			self.display:set_element_info(
				self.cursor_pos, self.info_set[self.cursor_pos])
		end
}}
local profile_menus= {
	[PLAYER_1]= setmetatable({}, options_sets.profile_menu),
	[PLAYER_2]= setmetatable({}, options_sets.profile_menu)
}
profile_menus[PLAYER_1]:initialize(PLAYER_1)
profile_menus[PLAYER_2]:initialize(PLAYER_2)

set_option_set_metatables()

local main_menu= setmetatable({}, options_sets.menu)
local offset_menu_data= get_offset_menu()
local offset_menu_open= false
local offset_menus= {}

for i, pn in ipairs{PLAYER_1, PLAYER_2} do
	offset_menus[pn]= setmetatable({}, offset_menu_data.meta)
	offset_menus[pn]:initialize(pn, offset_menu_data.args)
end

local menu_options= {}
do
	local menu_config= misc_config:get_data().initial_menu_ops
	for i, op_name in ipairs(sorted_initial_menu_ops) do
		local have= false
		if menu_config[op_name] then
			have= true
		end
		if op_name == "offset_choice" then
			if not offset_menu_data.args.eles[1] then have= false end
		end
		if have then
			menu_options[#menu_options+1]= {name= op_name}
		end
	end
end
main_menu:initialize(nil, menu_options, true)
local choosing_menu= 1
local choosing_playmode= 2
local choosing_profile= 3
local choosing_offset= 4
local choosing_states= {
	[PLAYER_1]= choosing_menu, [PLAYER_2]= choosing_menu }
local cursor_poses= { [PLAYER_1]= 1, [PLAYER_2]= 1 }
local menu_name_to_number= {
	playmode_choice= choosing_playmode,
	profile_choice= choosing_profile,
	offset_choice= choosing_offset,
}
local all_menus= { main_menu, playmode_menu, profile_menus, offset_menus }
--for i, m in ipairs(all_menus) do
--	Trace("Menu " .. i .. " " .. tostring(m))
--end

local disp_width= (SCREEN_WIDTH / 4) - 8
local menu_display= setmetatable({}, option_display_mt)
local playmode_display= setmetatable({}, option_display_mt)
local profile_displays= {
	[PLAYER_1]= setmetatable({}, option_display_mt),
	[PLAYER_2]= setmetatable({}, option_display_mt)
}
local offset_displays= {
	[PLAYER_1]= setmetatable({}, option_display_mt),
	[PLAYER_2]= setmetatable({}, option_display_mt)
}
local prod_xs= {
	[PLAYER_1]= SCREEN_CENTER_X - SCREEN_WIDTH / 4,
	[PLAYER_2]= SCREEN_CENTER_X + SCREEN_WIDTH / 4,
}
local all_displays= {
	menu_display, playmode_display
}
for k, v in pairs(profile_displays) do
	all_displays[#all_displays+1]= v
end
for k, v in pairs(offset_displays) do
	all_displays[#all_displays+1]= v
end
local display_frames= {}
for i, disp in ipairs(all_displays) do
	display_frames[i]= setmetatable({}, frame_helper_mt)
end
local cursors= {
	[PLAYER_1]= setmetatable({}, cursor_mt),
	[PLAYER_2]= setmetatable({}, cursor_mt)
}

local star_xs= {[PLAYER_1]= SCREEN_WIDTH * .25, [PLAYER_2]= SCREEN_WIDTH * .75}
local star_rad= SCREEN_HEIGHT*.25
local star_rot= 45
if april_fools then star_rot= 720 end
local star_points= 511
local star_y= SCREEN_HEIGHT*.5
local stars= {setmetatable({}, star_amv_mt), setmetatable({}, star_amv_mt)}
local function rescale_stars()
	local pad= 16
	local radius= ((SCREEN_WIDTH - display_frames[1].w) / 4) - pad
	local scale_factor= DISPLAY:GetDisplayHeight() / SCREEN_HEIGHT
	local circ= radius * math.pi * 2
	star_points= math.round(circ * scale_factor * 1)
	if misc_config:get_data().max_star_points > 2 then
		star_points= math.min(star_points, misc_config:get_data().max_star_points)
	end
	local apmul= 1
	if april_fools then apmul= 4 end
	stars[1]:repoint(star_points, radius * apmul)
	stars[2]:repoint(star_points, radius * apmul)
	star_xs[PLAYER_1]= radius+pad
	star_xs[PLAYER_2]= SCREEN_WIDTH - (radius+pad)
	stars[1]:move(star_xs[PLAYER_1])
	stars[2]:move(star_xs[PLAYER_2])
end

local function create_actors()
	local args= {Name= "Displays"}
	for i, frame in ipairs(display_frames) do
		args[#args+1]= frame:create_actors(
			i .. "_frame", 1, 0, 0,
			fetch_color("initial_menu.frame"),
			Alpha(fetch_color("initial_menu.menu_bg"), .5),
			SCREEN_CENTER_X, SCREEN_CENTER_Y)
	end
	local used_by_stats= line_height * 3
	local playmode_height= 108
	local playmode_pos= used_by_stats+line_height
	local main_height= math.min(
		#menu_options * line_height,
		_screen.h - used_by_stats - playmode_height - 120)
	args[#args+1]= menu_display:create_actors(
		"Menu", SCREEN_CENTER_X, playmode_pos + playmode_height + line_height,
		main_height,
		disp_width, line_height, 1, true, true)
	args[#args+1]= playmode_display:create_actors(
		"Playmode", SCREEN_CENTER_X, playmode_pos,
		playmode_height, disp_width, line_height, 1, false, true)
	local prof_menu_height= _screen.h*.25
	for k, prod in pairs(profile_displays) do
		args[#args+1]= prod:create_actors(
			ToEnumShortString(k) .. "_profiles", prod_xs[k],
			star_y - ((prof_menu_height*.5)-(line_height*.5)),
			prof_menu_height, disp_width, line_height, 1, false, true)
	end
	for k, offd in pairs(offset_displays) do
		args[#args+1]= offd:create_actors(
			"global_offset", prod_xs[k],
			star_y - ((prof_menu_height*.5)-(line_height*.5)),
			prof_menu_height, disp_width, line_height, 1, false, true)
	end
	for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
		args[#args+1]= cursors[rpn]:create_actors(
			rpn .. "_cursor", 0, 0, 1, pn_to_color(rpn),
			fetch_color("player.hilight"), button_list_for_menu_cursor())
	end
	return Def.ActorFrame(args)
end

local function find_actors(container)
	container= container:GetChild("Displays")
	main_menu:set_display(menu_display)
	playmode_display:set_underline_color(fetch_color("player.both"))
	playmode_menu:set_display(playmode_display)
	playmode_display:hide()
	local function size_display_frame(i, frame)
		all_displays[i]:scroll(1)
		local disp_cont= all_displays[i].container
		frame:resize_to_outline(disp_cont, 8)
		all_displays[i]:set_el_geo(frame.w-16, nil, nil)
		frame:move(disp_cont:GetX(), disp_cont:GetY() + frame.h/2-18)
		frame:hide()
	end
	size_display_frame(1, display_frames[1])
	rescale_stars()
	for k, prod in pairs(profile_displays) do
		prod.container:x(star_xs[k])
		prod:set_underline_color(pn_to_color(k))
		profile_menus[k]:set_display(prod)
		prod:hide()
	end
	for k, offd in pairs(offset_displays) do
		offd.container:x(star_xs[k])
		offd:set_underline_color(pn_to_color(k))
		offset_menus[k]:set_display(offd)
		offd:hide()
	end
	for i, frame in ipairs(display_frames) do
		size_display_frame(i, frame)
	end
end

local fail_message_mt= {
	__index= {
		create_actors= function(self, name, x, y)
			self.name= name
			self.frame= setmetatable({}, frame_helper_mt)
			return Def.ActorFrame{
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.text= subself:GetChild("text")
					self.container:diffusealpha(0)
				end,
				self.frame:create_actors(
					"frame", 1, 0, 0,
					fetch_color("initial_menu.cant_play.frame"),
					fetch_color("initial_menu.cant_play.bg"), 0, 0),
				normal_text("text", "", fetch_color("initial_menu.cant_play.text"))
			}
		end,
		show_message= function(self, message)
			self.text:settext(message)
			self.frame:resize_to_outline(self.text, 12)
			self.container:stoptweening():linear(.125):diffusealpha(1)
				:sleep(2):linear(.25):diffusealpha(0)
		end
}}

local last_input_time= GetTimeSinceStart()
local idle_limit= misc_config:get_data().screen_demo_idle_time

local fail_message= setmetatable({}, fail_message_mt)

local worker= false
local function worker_update()
	if worker then
		if coroutine.status(worker) ~= "dead" then
			local working, err= coroutine.resume(worker)
			if not working then
				lua.ReportScriptError(err)
				worker= false
			end
		else
			worker= false
		end
	else
		if idle_limit > 1 and not SCREENMAN:GetTopScreen():IsTransitioning()
			and GetTimeSinceStart() - last_input_time > idle_limit
		and misc_config:get_data().screen_demo_show_time > 10 then
			set_song_mode()
			for i, cn in ipairs{PLAYER_1, PLAYER_2} do
				cons_players[cn]:clear_init(cn)
				cons_players[cn]:set_ops_from_profile()
			end
			trans_new_screen("ScreenDemonstration")
		end
	end
end

local function finalize_and_exit(pns)
	SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
	GAMESTATE:LoadProfiles()
	for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
		local prof= PROFILEMAN:GetProfile(rpn)
		if prof then
			if prof ~= PROFILEMAN:GetMachineProfile() then
				cons_players[rpn]:set_ops_from_profile(prof)
				load_favorites(pn_to_profile_slot(rpn))
				load_tags(pn_to_profile_slot(rpn))
			end
		end
	end
	set_time_remaining_to_default()
	prev_picked_song= nil
	true_gameplay= true
	if workout_mode then
		trans_new_screen("ScreenWorkoutConfig")
	else
		bucket_man:initialize()
		worker= make_song_sort_worker()
		trans_new_screen("ScreenConsSelectMusic")
	end
end

-- Players have to be joined before Screen:Finish can be called, but Screen:Finish can fail for various reasons, and joining uses up credits.
-- So this function exists to check the things that can cause Screen:Finish to fail, so a failed attempt doesn't use up credits.
local function play_will_succeed(pns)
	local credits, coins, needed= get_coin_info()
	if needed > 0 and credits < #pns then
		local coins_needed= (#pns * needed) - (coins + (needed * credits))
		local coins_text= "coins"
		if coins_needed == 1 then coins_text= "coin" end
		fail_message:show_message("Insert " .. coins_needed .. " " .. coins_text)
		return false
	end
	return true
end

local function check_both_ready(presser, choice_name)
	if choosing_states[PLAYER_1] == choosing_states[PLAYER_2] and
	cursor_poses[PLAYER_1] == cursor_poses[PLAYER_2] then
		return true
	else
		fail_message:show_message(
			"Player " .. ToEnumShortString(other_player[presser]) ..
				" must also pick " .. get_string_wrapper("OptionNames", choice_name)
				.. ".")
		return false
	end
end

local function attempt_play(pns, presser, choice_name)
	if check_both_ready(presser, choice_name) and play_will_succeed(pns) then
		local join_success= true
		for i, rpn in ipairs(pns) do
			if not cons_join_player(rpn) then
				join_failed= false
				break
			end
		end
		if join_success then
			set_current_style(first_compat_style(#pns))
			if playmode == "PlayMode_Workout" then
				workout_mode= {}
				set_play_regular()
			end
			set_current_playmode(playmode)
			finalize_and_exit(pns)
			return
		end
	end
	SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
end

local function interpret_code(pn, code)
	local current_menu= all_menus[choosing_states[pn]]
	if current_menu == profile_menus or current_menu == offset_menus then
		current_menu= current_menu[pn]
	end
	--Trace("Code " .. code .. " from " .. pn .. " to " .. tostring(current_menu))
	-- The menu system was designed and created around having one cursor, and
	-- it's really not worth it or necessary to redesign it for the one case
	-- where we have two cursors.
	current_menu.cursor_pos= cursor_poses[pn]
	local handled, extra= current_menu:interpret_code(code)
	cursor_poses[pn]= current_menu.cursor_pos
	--Trace("(" .. tostring(handled) .. ") (" .. tostring(extra) .. ")")
	if handled then
		if extra then
			extra= extra.name
			if extra == "single_choice" then
				attempt_play({pn}, pn, extra)
			elseif extra == "versus_choice" then
				attempt_play({PLAYER_1, PLAYER_2}, pn, extra)
			elseif extra == "stepmania_ops" then
				trans_new_screen("ScreenOptionsService")
			elseif extra == "consensual_ops" then
				trans_new_screen("ScreenConsService")
			elseif extra == "color_config" then
				trans_new_screen("ScreenColorConfig")
			elseif extra == "edit_choice" then
				in_edit_mode= true
				for i, cn in ipairs{PLAYER_1, PLAYER_2} do
					cons_players[cn]:clear_init(cn)
					cons_players[cn]:set_ops_from_profile()
				end
				trans_new_screen("ScreenEditMenu")
			elseif extra == "exit_choice" then
				trans_new_screen("ScreenExit")
			else
				local new_menu= menu_name_to_number[extra]
				if all_menus[new_menu] then
					if extra == "profile_choice" then
						profile_menus[pn]:initialize(pn)
						profile_menus[pn]:set_display(profile_displays[pn])
					elseif extra == "offset_choice" then
						offset_menus[pn]:initialize(pn, offset_menu_data.args)
						offset_menus[pn]:set_display(offset_displays[pn])
					end
					choosing_states[pn]= new_menu
					cursor_poses[pn]= 1
				end
			end
		end
		if code == "Start" and current_menu ~= main_menu
		and cursor_poses[pn] ~= 1 then
			current_menu.display:hide()
			cursor_poses[pn]= 1
			choosing_states[pn]= choosing_menu
		end
	else
		if code == "Start" then
			if current_menu ~= main_menu then
				current_menu.display:hide()
			end
			cursor_poses[pn]= 1
			choosing_states[pn]= choosing_menu
		end
	end
	return handled
end

local function a_player_on_personal_menu()
	for i, pn in ipairs({PLAYER_1, PLAYER_2}) do
		if choosing_states[pn] == choosing_profile
		or choosing_states[pn] == choosing_offset then
			return true
		end
	end
	return false
end

local function update_cursor_pos()
	for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
		local current_menu= all_menus[choosing_states[rpn]]
		if current_menu == profile_menus or current_menu == offset_menus then
			current_menu= current_menu[rpn]
		end
		current_menu.display:unhide()
		current_menu.cursor_pos= cursor_poses[rpn]
		local item= current_menu:get_cursor_element()
		if item then
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(item.container)
			local xp, yp= rec_calc_actor_pos(item.container)
			cursors[rpn]:unhide()
			cursors[rpn]:refit(xp, yp, xmx - xmn + 4, ymx - ymn + 4)
		else
			cursors[rpn]:hide()
		end
	end
	for i, frame in ipairs(display_frames) do
		if all_displays[i].hidden then
			frame:hide()
		else
			frame:unhide()
		end
	end
	if choosing_states[PLAYER_1] == choosing_states[PLAYER_2] and
		cursor_poses[PLAYER_1] == cursor_poses[PLAYER_2] and
		not a_player_on_personal_menu() then
		cursors[PLAYER_1]:left_half()
		cursors[PLAYER_2]:right_half()
	else
		cursors[PLAYER_1]:un_half()
		cursors[PLAYER_2]:un_half()
	end
end

local currents= {1, 2, 3}
local goals= {2, 4, 6}
local speeds= {1, 1, 1}


local function input(event)
	last_input_time= GetTimeSinceStart()
	if event.type == "InputEventType_Release" then return false end
	if event.DeviceInput.button == "DeviceButton_m" then
--		find_missing_strings_in_theme_translations("_fallback", "en.ini")
--		find_missing_strings_in_theme_translations("default", "en.ini")
--		trans_new_screen("ScreenSplineDesign")
		set_prev_song_bpm(math.random(60, 200))
		play_sample_music(true)
	elseif event.DeviceInput.button == "DeviceButton_n" then
--		trans_new_screen("ScreenMiscTest")
	end
	--[[
	if event.DeviceInput.button == "DeviceButton_n" then
		set_song_mode()
		for i, cn in ipairs{PLAYER_1, PLAYER_2} do
			cons_players[cn]:clear_init(cn)
			cons_players[cn]:set_ops_from_profile()
		end
		trans_new_screen("ScreenDemonstration")
	end
	if event.DeviceInput.button == "DeviceButton_a" then
		activate_confetti("perm", true)
	end
	if event.DeviceInput.button == "DeviceButton_s" then
		activate_confetti("perm", false)
	end
	]]
	if event.DeviceInput.button == misc_config:get_data().color_config_key then
		trans_new_screen("ScreenColorConfig")
	end
	if event.DeviceInput.button == "DeviceButton_x" and event.type == "InputEventType_FirstPress" then
		gen_name_only_test_data()
	end
	if event.DeviceInput.button == misc_config:get_data().config_menu_key then
		trans_new_screen("ScreenConsService")
	end
	if event.PlayerNumber and event.GameButton then
		interpret_code(event.PlayerNumber, event.GameButton)
		update_cursor_pos()
		return true
	end
	return false
end

local star_args= {
	Name= "Star frame",
	stars[1]:create_actors(
		"lstar", SCREEN_WIDTH * .25, star_y, star_rad, 0, star_points,
		pn_to_color(PLAYER_1), 8, star_rot),
	stars[2]:create_actors(
		"rstar", SCREEN_WIDTH * .75, star_y, star_rad, math.pi, star_points,
		pn_to_color(PLAYER_2), 8, -star_rot),
}

local hms= {}
local hset= fetch_color("hours")
local prev_timestamp= ""
local function get_hour_indices()
	local curr_second= (Hour() * 3600) + (Minute() * 60) + Second()
	local sec_per= misc_config:get_data().seconds_per_clock_change
	local curr_index= math.floor(curr_second / sec_per)
	local next_index= curr_index + 1
	local percent= (curr_second - (curr_index * sec_per)) / sec_per
	return curr_index, next_index, percent
end
local function hms_update(self)
	local this_stamp= hms_timestamp()
	if this_stamp == prev_timestamp then return end
	prev_timestamp= this_stamp
	hms:settext(this_stamp)
	local curr_index, next_index, percent= get_hour_indices()
	local hour_curr= color_in_set(hset, curr_index, true, false, false)
	local hour_next= color_in_set(hset, next_index, true, false, false)
	hms:diffuse(lerp_color(percent, hour_curr, hour_next))
end

local args= {
	InitCommand= function(self)
		find_actors(self)
		update_cursor_pos()
		april_spin(self)
	end,
	Def.ActorFrame{
		Name= "code_interpreter",
		OnCommand= function(self)
			last_input_time= GetTimeSinceStart()
			SCREENMAN:GetTopScreen():AddInputCallback(input)
			self:SetUpdateFunction(worker_update)
		end,
	},
	Def.ActorFrame(star_args),
	create_actors(),
	Def.ActorFrame{
		Name= "song report",
		InitCommand= function(self)
			self:xy(_screen.cx, 0)
		end,
		normal_text(
			"songs", num_songs.." Songs", fetch_color("initial_menu.song_count"),
			fetch_color("stroke"), 0, line_height*.5),
		normal_text(
			"groups",num_groups.." Groups",fetch_color("initial_menu.song_count"),
			fetch_color("stroke"), 0, line_height*1.5),
	},
  Def.ActorFrame{
		Name="time", InitCommand= function(self)
			hms= self:GetChild("hms")
			self:SetUpdateFunction(hms_update)
		end,
		normal_text(
			"hms", "", fetch_color("text"), fetch_color("stroke"),
			_screen.cx, SCREEN_BOTTOM-24),
  },
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			if misc_config:get_data().show_startup_time then
				self:zoom(.5):xy(_screen.cx, SCREEN_BOTTOM-48)
					:settext("Startup time: " .. startup_time)
					:diffuse(fetch_color("text")):strokecolor(fetch_color("stroke"))
			end
		end
	},
	Def.BitmapText{
		Font= "Common Normal", Text= get_string_wrapper("Common", "special_day"),
		InitCommand= function(self)
			self:zoom(.5):xy(_screen.cx, SCREEN_BOTTOM-60)
				:wrapwidthpixels((SCREEN_WIDTH-32)*2):vertspacing(line_height - 32)
				:diffuse(fetch_color("text")):strokecolor(fetch_color("stroke"))
				:visible(special_day or false)
		end
	},
	credit_reporter(SCREEN_CENTER_X, SCREEN_TOP+(line_height*2.5), true),
	fail_message:create_actors("why", SCREEN_CENTER_X, SCREEN_CENTER_Y-48),
}

return Def.ActorFrame(args)
