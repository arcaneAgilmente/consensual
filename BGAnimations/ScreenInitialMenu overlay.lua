-- Unjoin currently joined players because stuff like going into the options and changing the theme joins players.
GAMESTATE:Reset()
SOUND:StopMusic()
aprf_check()

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

local num_players= 1
local playmode= "PlayMode_Regular"
local function get_prof_choice(pn)
	return PREFSMAN:GetPreference("DefaultLocalProfileID" .. ToEnumShortString(pn))
end
local function set_prof_choice(pn, id)
	PREFSMAN:SetPreference("DefaultLocalProfileID" .. ToEnumShortString(pn), id)
end

dofile(THEME:GetPathO("", "options_menu.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))

local function check_one_player()
	return num_players == 1
end
local function set_one_player()
	num_players= 1
end
local function check_two_player()
	return num_players == 2
end
local function set_two_player()
	if kyzentun_birthday then return end
	num_players= 2
end

local style_menu_init= {
	name= "style_choice", eles= {
		{ name= "Single", init= check_one_player, set= set_one_player,
			unset= noop_false},
		{ name= "Versus", init= check_two_player, set= set_two_player,
			unset= noop_false},
}}
local style_menu= setmetatable({}, options_sets.mutually_exclusive_special_functions)
style_menu:initialize(nil, style_menu_init)

local function check_play_regular()
	return playmode == "Playmode_Regular"
end
local function set_play_regular()
	playmode= "Playmode_Regular"
end
local function check_play_nonstop()
	return playmode == "Playmode_Nonstop"
end
local function set_play_nonstop()
	playmode= "Playmode_Regular" -- Disabled until course mode is worth supporting.
end

local playmode_menu_init= {
	name= "playmode_choice", eles= {
		{ name= "Regular", init= check_play_regular, set= set_play_regular,
			unset= noop_false},
--		{ name= "Nonstop", init= check_play_nonstop, set= set_play_nonstop,
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
local menu_options= {{name= "Play"}}
do
	local menu_config= misc_config:get_data().initial_menu_ops
	for i, op_name in ipairs(sorted_initial_menu_ops) do
		if menu_config[op_name] and op_name ~= "playmode_choice" then
			menu_options[#menu_options+1]= {name= op_name}
		end
	end
end
main_menu:initialize(nil, menu_options, true)
local choosing_menu= 1
local choosing_style= 2
local choosing_playmode= 3
local choosing_profile= 4
local choosing_states= {
	[PLAYER_1]= choosing_menu, [PLAYER_2]= choosing_menu }
local cursor_poses= { [PLAYER_1]= 1, [PLAYER_2]= 1 }
local menu_name_to_number= {
	["style_choice"]= choosing_style,
	["playmode_choice"]= choosing_playmode,
	["profile_choice"]= choosing_profile,
}
local all_menus= { main_menu, style_menu, playmode_menu, profile_menus }
--for i, m in ipairs(all_menus) do
--	Trace("Menu " .. i .. " " .. tostring(m))
--end

local disp_width= (SCREEN_WIDTH / 4) - 8
local menu_display= setmetatable({}, option_display_mt)
local style_display= setmetatable({}, option_display_mt)
local playmode_display= setmetatable({}, option_display_mt)
local profile_displays= {
	[PLAYER_1]= setmetatable({}, option_display_mt),
	[PLAYER_2]= setmetatable({}, option_display_mt)
}
local prod_xs= {
	[PLAYER_1]= SCREEN_CENTER_X - SCREEN_WIDTH / 4,
	[PLAYER_2]= SCREEN_CENTER_X + SCREEN_WIDTH / 4,
}
local all_displays= {
	menu_display, style_display, playmode_display
}
for k, v in pairs(profile_displays) do
	all_displays[#all_displays+1]= v
end
local display_frames= {}
for i, disp in ipairs(all_displays) do
	display_frames[i]= setmetatable({}, frame_helper_mt)
end
local cursors= {
	[PLAYER_1]= setmetatable({}, amv_cursor_mt),
	[PLAYER_2]= setmetatable({}, amv_cursor_mt)
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
			i .. "_frame", 1, 0, 0, solar_colors.f_text(), solar_colors.bg(.5),
			SCREEN_CENTER_X, SCREEN_CENTER_Y)
	end
	for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
		args[#args+1]= cursors[rpn]:create_actors(
			rpn .. "_cursor", 0, 0, 0, 0, 1, solar_colors[rpn]())
	end
	args[#args+1]= menu_display:create_actors(
		"Menu", SCREEN_CENTER_X, SCREEN_CENTER_Y - 0, #menu_options, disp_width,
		24, 1, true, true)
	args[#args+1]= style_display:create_actors(
		"Style", SCREEN_CENTER_X, SCREEN_CENTER_Y - 132, 3, disp_width, 24, 1,
		false, true)
	args[#args+1]= playmode_display:create_actors(
		"Playmode", SCREEN_CENTER_X, SCREEN_CENTER_Y + 120, 3, disp_width, 24, 1,
		false, true)
	for k, prod in pairs(profile_displays) do
		args[#args+1]= prod:create_actors(
			ToEnumShortString(k) .. "_profiles", prod_xs[k], star_y - (24 * 2.75),
			5, disp_width, 24, 1, false, true)
	end
	return Def.ActorFrame(args)
end

local function find_actors(container)
	container= container:GetChild("Displays")
	main_menu:set_display(menu_display)
	style_display:set_underline_color(solar_colors.violet())
	style_menu:set_display(style_display)
	style_display:hide()
	playmode_display:set_underline_color(solar_colors.violet())
	playmode_menu:set_display(playmode_display)
	playmode_display:hide()
	local function size_display_frame(i, frame)
		all_displays[i]:scroll(1)
		local disp_cont= all_displays[i].container
		frame:resize_to_outline(disp_cont, 8)
		frame:move(disp_cont:GetX(), disp_cont:GetY() + frame.h/2-18)
		frame:hide()
	end
	size_display_frame(1, display_frames[1])
	rescale_stars()
	for k, prod in pairs(profile_displays) do
		prod.container:x(star_xs[k])
		prod:set_underline_color(solar_colors[k]())
		profile_menus[k]:set_display(prod)
		prod:hide()
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
				self.frame:create_actors("frame", 1, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0),
				normal_text("text", "")
			}
		end,
		show_message= function(self, message)
			self.text:settext(message)
			self.frame:resize_to_outline(self.text, 12)
			self.container:stoptweening()
			self.container:linear(.125)
			self.container:diffusealpha(1)
			self.container:sleep(2)
			self.container:linear(.25)
			self.container:diffusealpha(0)
		end
}}

local fail_message= setmetatable({}, fail_message_mt)

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

local function interpret_code(pn, code)
	local current_menu= all_menus[choosing_states[pn]]
	if current_menu == profile_menus then
		current_menu= profile_menus[pn]
	end
	--Trace("Code " .. code .. " from " .. pn .. " to " .. tostring(current_menu))
	-- The menu system was designed and created around having one cursor, and
	-- it's really not worth it or necessary to redesign it for the one case
	-- where we have two cursors.
	current_menu.cursor_pos= cursor_poses[pn]
	local handled, extra= current_menu:interpret_code(code)
	cursor_poses[pn]= current_menu.cursor_pos
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
		bucket_man:initialize()
		trans_new_screen("ScreenConsSelectMusic")
	end
	--Trace("(" .. tostring(handled) .. ") (" .. tostring(extra) .. ")")
	if handled then
		if extra then
			extra= extra.name
			if extra == "Play" then
				--Trace("Attempting to start play.")
				if choosing_states[PLAYER_1] == choosing_states[PLAYER_2] and
					cursor_poses[PLAYER_1] == cursor_poses[PLAYER_2] then
					if num_players == 1 then
						--Trace("Single player: " .. pn)
						if play_will_succeed{pn} and cons_join_player(pn) then
							set_current_style("single")
							set_current_playmode(playmode)
							finalize_and_exit{pn}
						else
							SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
							--Trace("Failed to join player.")
							--Trace("CanJoin: " .. tostring(GAMESTATE:PlayersCanJoin()))
							--Trace("IsJoined: " .. tostring(GAMESTATE:IsSideJoined(pn)))
						end
						--Trace("IsJoined: " .. tostring(GAMESTATE:IsSideJoined(pn)))
					else
						--Trace("Versus")
						if play_will_succeed{PLAYER_1, PLAYER_2} then
							for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
								cons_join_player(rpn)
							end
							set_current_style("versus")
							set_current_playmode(playmode)
							finalize_and_exit{PLAYER_1, PLAYER_2}
						else
							SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
						end
					end
				else
					fail_message:show_message(
						"Player " .. ToEnumShortString(other_player[pn]) .. " is unready.")
					SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
				end
			elseif extra == "stepmania_ops" then
				trans_new_screen("ScreenOptionsService")
			elseif extra == "consensual_ops" then
				trans_new_screen("ScreenConsService")
			elseif extra == "edit_choice" then
				
			elseif extra == "exit_choice" then
				trans_new_screen("ScreenExit")
			else
				local new_menu= menu_name_to_number[extra]
				if all_menus[new_menu] then
					if extra == "profile_choice" then
						profile_menus[pn]:initialize(pn)
						profile_menus[pn]:set_display(profile_displays[pn])
					end
					choosing_states[pn]= new_menu
					cursor_poses[pn]= 1
				end
			end
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

local function update_cursor_pos()
	for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
		local current_menu= all_menus[choosing_states[rpn]]
		if current_menu == profile_menus then
			current_menu= profile_menus[rpn]
		end
		current_menu.display:unhide()
		current_menu.cursor_pos= cursor_poses[rpn]
		local item= current_menu:get_cursor_element()
		if item then
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(item.container)
			local xp, yp= rec_calc_actor_pos(item.container)
			cursors[rpn]:refit(xp, yp, xmx - xmn + 4, ymx - ymn + 4)
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
	choosing_states[PLAYER_1] ~= choosing_profile then
		cursors[PLAYER_1]:left_half()
		cursors[PLAYER_2]:right_half()
	else
		cursors[PLAYER_1]:un_half()
		cursors[PLAYER_2]:un_half()
	end
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.DeviceInput.button == "DeviceButton_n" then
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
		solar_colors[PLAYER_1](), 8, star_rot),
	stars[2]:create_actors(
		"rstar", SCREEN_WIDTH * .75, star_y, star_rad, math.pi, star_points,
		solar_colors[PLAYER_2](), 8, -star_rot),
}

local args= {
	InitCommand= function(self)
		find_actors(self)
		update_cursor_pos()
		april_spin(self)
	end,
	Def.Actor{
		Name= "code_interpreter",
		OnCommand= function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(input)
		end,
	},
	Def.ActorFrame(star_args),
	create_actors(),
	Def.ActorFrame{
		Name= "song report",
		InitCommand= function(self)
									 self:xy(SCREEN_CENTER_X, SCREEN_TOP)
								 end,
		normal_text("songs", num_songs .. " Songs", solar_colors.uf_text(), 0, 12),
		normal_text("groups", num_groups .. " Groups", solar_colors.uf_text(), 0, 36),
	},
	credit_reporter(SCREEN_CENTER_X, SCREEN_TOP+60, true),
	fail_message:create_actors("why", SCREEN_CENTER_X, SCREEN_CENTER_Y),
}

args[#args+1]= Def.LogDisplay{
	Name= "FakeError",
	ReplaceLinesWhenHidden= true,
}

return Def.ActorFrame(args)
