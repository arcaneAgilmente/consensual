-- Unjoin currently joined players because stuff like going into the options and changing the theme joins players.
GAMESTATE:Reset()

local profile_list= {}
for p= 0, PROFILEMAN:GetNumLocalProfiles()-1 do
	local profile= PROFILEMAN:GetLocalProfileFromIndex(p)
	profile_list[#profile_list+1]= {
		-- Profile index 0 is apparently reserved for the memory card.
		name= profile:GetDisplayName(), index= p + 1}
end

load_favorites("ProfileSlot_Machine")
load_tags("ProfileSlot_Machine")
load_censored_list()

local num_songs= SONGMAN:GetNumSongs()
local num_groups= SONGMAN:GetNumSongGroups()
local frame_helper= setmetatable({}, frame_helper_mt)

local num_players= 1
local playmode= "regular"
local profile_choices= {}

dofile(THEME:GetPathO("", "consensual_conf.lua"))
dofile(THEME:GetPathO("", "options_menu.lua"))

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
	num_players= 2
end

local style_menu_init= {
	name= "Style", eles= {
		{ name= "Single", init= check_one_player, set= set_one_player,
			unset= noop_false},
		{ name= "Versus", init= check_two_player, set= set_two_player,
			unset= noop_false},
}}
local style_menu= setmetatable({}, options_sets.mutually_exclusive_special_functions)
style_menu:initialize(nil, style_menu_init)

local function check_play_regular()
	return playmode == "regular"
end
local function set_play_regular()
	playmode= "regular"
end
local function check_play_nonstop()
	return playmode == "nonstop"
end
local function set_play_nonstop()
	playmode= "nonstop"
end

local playmode_menu_init= {
	name= "Playmode", eles= {
		{ name= "Regular", init= check_play_regular, set= set_play_regular,
			unset= noop_false},
		{ name= "Nonstop", init= check_play_nonstop, set= set_play_nonstop,
			unset= noop_false},
}}
local playmode_menu= setmetatable({}, options_sets.mutually_exclusive_special_functions)
playmode_menu:initialize(nil, playmode_menu_init)

options_sets.profile_menu= {
	__index= {
		initialize=
			function(self, player_number)
				self.name= ToEnumShortString(player_number) .. " Profile"
				self.cursor_pos= 1
				self.player_number= player_number
				self.info_set= {up_element()}
				if PREFSMAN:GetPreference("MemoryCards") then
					local state= MEMCARDMAN:GetCardState(player_number)
					Trace("Memcard " .. player_number .. " state: " .. state)
					if state == "MemoryCardState_ready" then
						self.info_set[#self.info_set+1]= {text= "Card", index= 0}
					end
				end
				for i, pro in ipairs(profile_list) do
					self.info_set[#self.info_set+1]= {text= pro.name, index= pro.index}
					if i == profile_choices[player_number] then
						self.info_set[#self.info_set].underline= true
					end
				end
			end,
		set_status=
			function(self)
				self.display:set_heading(self.name)
				if profile_choices[player_number] then
					self.display:set_display(profile_choices[self.player_number].name)
				end
			end,
		interpret_start=
			function(self)
				for i, info in ipairs(self.info_set) do
					if info.underline then
						info.underline= false
						self.display:set_element_info(i, info)
					end
				end
				local prinfo= self.info_set[self.cursor_pos]
				profile_choices[self.player_number]= {
					name= prinfo.text, index= prinfo.index}
				self.info_set[self.cursor_pos].underline= true
				self.display:set_element_info(self.cursor_pos,
																			self.info_set[self.cursor_pos])
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
main_menu:initialize(
	nil, {
		{ name= "Play" },
		{ name= "Style" },
		{ name= "Playmode" },
		{ name= "Profile" },
	}, true)
local choosing_menu= 1
local choosing_style= 2
local choosing_playmode= 3
local choosing_profile= 4
local choosing_states= {
	[PLAYER_1]= choosing_menu, [PLAYER_2]= choosing_menu }
local cursor_poses= { [PLAYER_1]= 1, [PLAYER_2]= 1 }
local menu_name_to_number= {
	["Style"]= choosing_style,
	["Playmode"]= choosing_playmode,
	["Profile"]= choosing_profile,
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

local function create_actors()
	local args= {Name= "Displays"}
	for i, frame in ipairs(display_frames) do
		args[#args+1]= frame:create_actors(
			i .. "_frame", 1, 0, 0, solar_colors.f_text(), solar_colors.bg(),
			SCREEN_CENTER_X, SCREEN_CENTER_Y)
	end
	for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
		args[#args+1]= cursors[rpn]:create_actors(
			rpn .. "_cursor", 0, 0, 0, 0, 1, solar_colors[rpn]())
	end
	args[#args+1]= menu_display:create_actors(
		"Menu", SCREEN_CENTER_X, SCREEN_CENTER_Y - 0, 4, disp_width, 24, 1,
		true, true)
	args[#args+1]= style_display:create_actors(
		"Style", SCREEN_CENTER_X, SCREEN_CENTER_Y - 132, 3, disp_width, 24, 1,
		false, true)
	args[#args+1]= playmode_display:create_actors(
		"Playmode", SCREEN_CENTER_X, SCREEN_CENTER_Y + 120, 3, disp_width, 24, 1,
		false, true)
	for k, prod in pairs(profile_displays) do
		args[#args+1]= prod:create_actors(
			ToEnumShortString(k) .. "_profiles", prod_xs[k], SCREEN_CENTER_Y - 48,
			5, disp_width, 24, 1, false, true)
	end
	return Def.ActorFrame(args)
end

local function find_actors(container)
	container= container:GetChild("Displays")
	for i, rpn in ipairs({PLAYER_1, PLAYER_2}) do
		cursors[rpn]:find_actors(container:GetChild(cursors[rpn].name))
	end
	for k, disp in ipairs(all_displays) do
		disp:find_actors(container:GetChild(disp.name))
	end
	main_menu:set_display(menu_display)
	style_display:set_underline_color(solar_colors.violet())
	style_menu:set_display(style_display)
	style_display:hide()
	playmode_display:set_underline_color(solar_colors.violet())
	playmode_menu:set_display(playmode_display)
	playmode_display:hide()
	for k, prod in pairs(profile_displays) do
		prod:set_underline_color(solar_colors[k]())
		profile_menus[k]:set_display(prod)
		prod:hide()
	end
	for i, frame in ipairs(display_frames) do
		all_displays[i]:scroll(1)
		local disp_cont= all_displays[i].container
		frame:find_actors(container:GetChild(frame.name))
		frame:resize_to_outline(disp_cont, 8)
		frame:move(disp_cont:GetX(), disp_cont:GetY() + frame.outer:GetHeight()/2-18)
		frame:hide()
	end
end

local function set_profile_index_for_player(pn)
	local proc= profile_choices[pn]
	if proc then
		Trace("Setting profile for " .. pn .. " to " .. proc.index)
		if not SCREENMAN:GetTopScreen():SetProfileIndex(pn, proc.index) then
			Trace("Could not set profile index.")
			Trace("IsHumanPlayer: " .. tostring(GAMESTATE:IsHumanPlayer(pn)))
			Trace("IsJoined: " .. tostring(GAMESTATE:IsSideJoined(pn)))
		end
	else
		Trace("No proc for " .. pn)
		if PREFSMAN:GetPreference("MemoryCards") == 1 then
			local state= MEMCARDMAN:GetCardState(player_number)
			Trace("Memcard " .. player_number .. " state: " .. state)
			if MEMCARDMAN:GetCardState(player_number) == "MemoryCardState_ready" then
				if not SCREENMAN:GetTopScreen():SetProfileIndex(pn, 0) then
					Trace("Could not set memcard profile index.")
					Trace("IsHumanPlayer: " .. tostring(GAMESTATE:IsHumanPlayer(pn)))
					Trace("IsJoined: " .. tostring(GAMESTATE:IsSideJoined(pn)))
				end
			end
		end
	end
end

-- Players have to be joined before Screen:Finish can be called, but Screen:Finish can fail for various reasons, and joining uses up credits.
-- So this function exists to check the things that can cause Screen:Finish to fail, so a failed attempt doesn't use up credits.
local function play_will_succeed(pns)
	local credits, coins, needed= get_coin_info()
	if needed > 0 and credits < #pns then
		return false
	end
	for i, pn in ipairs(pns) do
		if not profile_choices[pn] then
			return false
		end
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
	function maybe_finalize_and_exit(pns)
		if SCREENMAN:GetTopScreen():Finish() then
			SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
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
			bucket_man:initialize()
			bucket_man:style_filter_songs()
			filter_bucket_songs_by_time()
		else
			local ts= SCREENMAN:GetTopScreen()
			Trace("Finish returned false.")
			Trace("Players enabled: " .. GAMESTATE:GetNumPlayersEnabled())
			Trace("Pindex 1: " .. ts:GetProfileIndex(PLAYER_1))
			Trace("Pindex 2: " .. ts:GetProfileIndex(PLAYER_2))
			Trace("Num local profiles: " .. PROFILEMAN:GetNumLocalProfiles())
			SOUND:PlayOnce("Themes/_fallback/Sounds/Common invalid.ogg")
			GAMESTATE:Reset()
		end
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
							GAMESTATE:ApplyGameCommand("style,single", pn)
							GAMESTATE:ApplyGameCommand("playmode,"..playmode, pn)
							set_profile_index_for_player(pn)
							maybe_finalize_and_exit{pn}
						else
							SOUND:PlayOnce("Themes/_fallback/Sounds/Common invalid.ogg")
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
								GAMESTATE:ApplyGameCommand("playmode,"..playmode, rpn)
								set_profile_index_for_player(rpn)
							end
							GAMESTATE:ApplyGameCommand("style,versus")
							maybe_finalize_and_exit{PLAYER_1, PLAYER_2}
						else
							SOUND:PlayOnce("Themes/_fallback/Sounds/Common invalid.ogg")
						end
					end
				else
					--Trace("Different choice states.")
					SOUND:PlayOnce("Themes/_fallback/Sounds/Common invalid.ogg")
				end
			else
				local new_menu= menu_name_to_number[extra]
				if all_menus[new_menu] then
					if extra == "Profile" then
						profile_menus[pn]:initialize(pn)
						profile_menus[pn]:set_display(profile_displays[pn])
					end
					choosing_states[pn]= new_menu
					cursor_poses[pn]= 1
				end
			end
		end
	else
		if code == "start" then
			if current_menu ~= main_menu then
				current_menu.display:hide()
			end
			cursor_poses[pn]= 1
			choosing_states[pn]= choosing_menu
		end
	end
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

local args= {
	InitCommand= function(self)
								 find_actors(self)
								 update_cursor_pos()
							 end,
	Def.Actor{
		Name= "code_interpreter",
		InitCommand= function(self)
									 self:effectperiod(2^16)
									 timer_actor= self
								 end,
		CodeMessageCommand=
			function(self, param)
				if self:GetSecsIntoEffect() > 0.25 then
					interpret_code(param.PlayerNumber, param.Name)
					update_cursor_pos()
				end
			end
	},
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
}

return Def.ActorFrame(args)
