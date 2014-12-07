GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(1)

local music_wheel= setmetatable({}, music_whale_mt)
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
local title_x= 4
local title_y= SCREEN_TOP + 108
local title_width= (wheel_x - 40) - title_x
local wheel_cursor_y= SCREEN_CENTER_Y - 24 - 1

local pane_text_zoom= .625
local pane_text_height= 16 * (pane_text_zoom / 0.5875)
local pane_text_width= 8 * (pane_text_zoom / 0.5875)
local pane_w= ((wheel_x - 40) - (SCREEN_LEFT + 4)) / 2
local pane_h= pane_text_height * max_pain_rows + 4
local pane_yoff= -pane_h * .5 + pane_text_height * .5 + 2
local pane_ttx= 0
local pad= 4

local pane_y= SCREEN_BOTTOM-(pane_h/2)-pad
local lpane_x= SCREEN_LEFT+(pane_w/2)+pad
local rpane_x= SCREEN_LEFT+(pane_w*1.5)+pad*1.5

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

local function change_sort_text(new_text)
	local overlay= SCREENMAN:GetTopScreen():GetChild("Overlay")
	local stext= overlay:GetChild("sort_text")
	new_text= new_text or stext:GetText()
	local stext2= overlay:GetChild("sort_text2")
	local text_words= split_string_to_words(new_text)
	local first_line= ""
	local second_line= ""
	for i, word in ipairs(text_words) do
		if i == 1 then
			first_line= word
		elseif i == 2 then
			first_line= first_line .. " " .. word
		elseif i == 3 then
			second_line= word
		else
			second_line= second_line .. " " .. word
		end
	end
	stext:settext(first_line)
	width_limit_text(stext, sort_width)
	stext2:settext(second_line)
	width_limit_text(stext2, sort_width)
	overlay:GetChild("sort_prop"):playcommand("Set")
end

local function update_sort_prop()
	SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("sort_prop"):playcommand("Set")
end

local steps_display_interface= {}
local steps_display_interface_mt= { __index= steps_display_interface }

local std_item_w= 56
local std_item_h= 32
local std_items_mt= {
	__index= {
		create_actors= function(self, name)
			self.name= name
			self.tani= setmetatable({}, text_and_number_interface_mt)
			return Def.ActorFrame{
				Name= name, InitCommand= function(subself)
					self.container= subself
					self.bg= subself:GetChild("bg")
					self.tani.number:strokecolor(
						fetch_color("music_select.steps_selector.number_stroke"))
					self.tani.text:strokecolor(
						fetch_color("music_select.steps_selector.name_stroke"))
				end,
				Def.Quad{
					Name= "bg", InitCommand= cmd(setsize, std_item_w, std_item_h)
				},
				self.tani:create_actors(
					"text", {
						tx= -24, tz= 1, ta= left, text_section= "",
						tc= fetch_color("music_select.steps_selector.name_color"),
						nx= 24, nz= 1, na= right,
						nc= fetch_color("music_select.steps_selector.name_color")}),
			}
		end,
		transform= function(self, item_index, num_items, is_focus)
			local changing_edge=
				((self.prev_index == 1 and item_index == num_items) or
						(self.prev_index == num_items and item_index == 1))
			if changing_edge then
				self.bg:diffusealpha(0)
				self.tani:hide()
			end
			local nx= (item_index - 1) * (std_item_w + 6)
			self.container:stoptweening()
			self.container:linear(.1)
			self.container:x(nx)
			self.tani:unhide()
			self.bg:diffusealpha(1)
			self.prev_index= item_index
		end,
		set= function(self, info)
			self.info= info
			if info then
				self.tani:set_text(
					get_string_wrapper("DifficultyNames", self.info:GetStepsType()))
				self.tani:set_number(info:GetMeter())
				width_limit_text(self.tani.text, 18)
				width_limit_text(self.tani.number, 30)
				self.tani:unhide()
				self.bg:diffuse(diff_to_color(info:GetDifficulty()))
				self.bg:diffusealpha(1)
				self.container:visible(true)
			else
				self.container:visible(false)
			end
		end
}}

local steps_display_elements= 6
function steps_display_interface:create_actors(name)
	self.name= name
	local args= {
		Name= name,
		InitCommand= function(subself)
			self.container= subself
			subself:xy(4+(std_item_w/2), 195)
			for k, v in pairs(self.cursors) do
				v:refit(nil, nil, std_item_w+4, std_item_h+4)
				if not GAMESTATE:IsPlayerEnabled(k) then
					v:hide()
				end
			end
		end
	}
	local cursors= {}
	for i, v in ipairs(all_player_indices) do
		local new_curs= {}
		setmetatable(new_curs, cursor_mt)
		args[#args+1]= new_curs:create_actors(
			v .. "curs", 0, 0, 2, pn_to_color(v), fetch_color("player.hilight"),
			false, true)
		cursors[v]= new_curs
	end
	self.cursors= cursors
	self.sick_wheel= setmetatable({disable_wrapping= true}, sick_wheel_mt)
	args[#args+1]= self.sick_wheel:create_actors("wheel", steps_display_elements, std_items_mt, 0, 0)
	return Def.ActorFrame(args)
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
		self.sick_wheel:scroll_to_pos((tot / cnt)+1)
		for k, cursor in pairs(self.cursors) do
			if cursor_poses[k] then
				local item= self.sick_wheel:find_item_by_info(player_steps[k])[1]
				if item then
					local cx= item.container:GetDestX()
					local cy= item.container:GetDestY()
					cursor:refit(cx, cy, nil, nil)
					cursor:unhide()
				else
					cursor:hide()
				end
			else
				cursor:hide()
			end
		end
		if #enabled_players > 1 then
			if cursor_poses[PLAYER_1] and cursor_poses[PLAYER_2] then
				if cursor_poses[PLAYER_1] == cursor_poses[PLAYER_2] then
					self.cursors[PLAYER_1]:left_half()
					self.cursors[PLAYER_2]:right_half()
				else
					self.cursors[PLAYER_1]:un_half()
					self.cursors[PLAYER_2]:un_half()
				end
			end
		else
			self.cursors[PLAYER_1]:un_half()
			self.cursors[PLAYER_2]:un_half()
		end
	end
end

dofile(THEME:GetPathO("", "options_menu.lua"))
dofile(THEME:GetPathO("", "pain_display.lua"))

local steps_display= setmetatable({}, steps_display_interface_mt)
local pain_displays= {
	[PLAYER_1]= setmetatable({}, pain_display_mt),
	[PLAYER_2]= setmetatable({}, pain_display_mt),
}

dofile(THEME:GetPathO("", "song_props_menu.lua"))
dofile(THEME:GetPathO("", "tags_menu.lua"))
dofile(THEME:GetPathO("", "auto_hider.lua"))

set_option_set_metatables()

local special_menu_displays= {
	[PLAYER_1]= setmetatable({}, option_display_mt),
	[PLAYER_2]= setmetatable({}, option_display_mt),
}

local privileged_props= false
local function privileged(pn)
	return privileged_props
end
local song_props= {
	{name= "exit_menu"},
	{name= "prof_favor_inc", req_func= player_using_profile},
	{name= "prof_favor_dec", req_func= player_using_profile},
	{name= "mach_favor_inc", level= 3},
	{name= "mach_favor_dec", level= 3},
	{name= "censor", req_func= privileged},
	{name= "uncensor", req_func= privileged},
	{name= "toggle_censoring", req_func= privileged},
	{name= "edit_tags", level= 3},
	{name= "edit_pain", level= 4},
	{name= "edit_styles", level= 2},
	{name= "convert_xml"},
	{name= "end_credit", level= 4},
}

local function censor_item(item, depth)
	add_to_censor_list(item.el)
end

local function uncensor_item(item, depth)
	remove_from_censor_list(item.el)
end

local song_props_menus= {
	[PLAYER_1]= setmetatable({}, options_sets.menu),
	[PLAYER_2]= setmetatable({}, options_sets.menu),
}

local tag_menus= {
	[PLAYER_1]= setmetatable({}, options_sets.tags_menu),
	[PLAYER_2]= setmetatable({}, options_sets.tags_menu),
}

local function make_visible_style_data(pn)
	local num_players= GAMESTATE:GetNumPlayersEnabled()
	local eles= {}
	for i, style_data in ipairs(cons_players[pn].style_config[num_players]) do
		eles[#eles+1]= {
			name= style_data.style, init= function() return style_data.visible end,
			set= function() style_data.visible= true end,
			unset= function() style_data.visible= false end,
		}
	end
	return {eles= eles}
end

local visible_styles_menus= {
	[PLAYER_1]= setmetatable({}, options_sets.special_functions),
	[PLAYER_2]= setmetatable({}, options_sets.special_functions),
}

local player_cursors= {
	[PLAYER_1]= setmetatable({}, cursor_mt),
	[PLAYER_2]= setmetatable({}, cursor_mt)
}

local in_special_menu= {[PLAYER_1]= 1, [PLAYER_2]= 1}

local function update_pain(pn)
	if GAMESTATE:IsPlayerEnabled(pn) then
		if in_special_menu[pn] == 1 or in_special_menu[pn] == 5 then
			pain_displays[pn]:update_all_items()
			pain_displays[pn]:unhide()
		elseif in_special_menu[pn] == 2 then
			song_props_menus[pn]:update()
		elseif in_special_menu[pn] == 3 then
			tag_menus[pn]:update()
		elseif in_special_menu[pn] == 4 then
			visible_styles_menus[pn]:update()
		end
	else
		pain_displays[pn]:hide()
	end
end

local function start_auto_scrolling(dir)
	local time_before_scroll= GetTimeSinceStart()
	music_wheel:scroll_amount(dir)
	local time_after_scroll= GetTimeSinceStart()
	auto_scrolling= dir
	local curr_time= get_screen_time() + (time_after_scroll - time_before_scroll)
	next_auto_scroll_time= curr_time + time_before_auto_scroll
	fast_scroll_start_time= curr_time + time_before_fast_scroll
end

local function stop_auto_scrolling()
	play_sample_music()
	auto_scrolling= nil
	fast_auto_scroll= nil
end

local function correct_for_overscroll()
	local was_scroll= auto_scrolling
	auto_scrolling= nil
	fast_auto_scroll= nil
	if was_scroll then
		music_wheel:scroll_amount(-was_scroll)
		play_sample_music()
	end
end

local function update_player_cursors()
	local num_enabled= 0
	for i, pn in ipairs{PLAYER_1, PLAYER_2} do
		if GAMESTATE:IsPlayerEnabled(pn) then
			num_enabled= num_enabled + 1
			local cursed_item= false
			local function fit_cursor_to_menu(menu)
				player_cursors[pn].align= 0
				cursed_item= menu:get_cursor_element()
				local xmn, xmx, ymn, ymx= rec_calc_actor_extent(cursed_item.container)
				local xp, yp= rec_calc_actor_pos(cursed_item.container)
				player_cursors[pn]:refit(xp, yp, xmx - xmn + 2, ymx - ymn + 0)
			end
			if in_special_menu[pn] == 1 then
				player_cursors[pn].align= .5
				cursed_item= music_wheel.sick_wheel:get_actor_item_at_focus_pos().text
				local xmn, xmx, ymn, ymx= rec_calc_actor_extent(cursed_item)
				local xp= wheel_x + 2
				player_cursors[pn]:refit(xp, wheel_cursor_y, xmx - xmn + 4, ymx - ymn + 4)
			elseif in_special_menu[pn] == 2 then
				fit_cursor_to_menu(song_props_menus[pn])
			elseif in_special_menu[pn] == 3 then
				fit_cursor_to_menu(tag_menus[pn])
			elseif in_special_menu[pn] == 4 then
				fit_cursor_to_menu(visible_styles_menus[pn])
			end
			if in_special_menu[pn] ~= 5 then
				player_cursors[pn]:unhide()
			end
		else
			player_cursors[pn]:hide()
		end
	end
	if num_enabled == 2 and in_special_menu[PLAYER_1] == 1
	and in_special_menu[PLAYER_2] == 1 then
		player_cursors[PLAYER_1]:left_half()
		player_cursors[PLAYER_2]:right_half()
	else
		player_cursors[PLAYER_1]:un_half()
		player_cursors[PLAYER_2]:un_half()
	end
end

local status_text= false
local status_count= false
local status_container= false
local status_frame= setmetatable({}, frame_helper_mt)
local status_active= false
local status_worker= false
local status_finish_func= false
local function activate_status(worker, after_func)
	status_active= true
	status_worker= worker
	status_finish_func= after_func
	status_container:stoptweening()
	status_container:linear(0.5)
	status_container:diffusealpha(1)
	status_text:settext("")
	status_count:settext("")
end

local function deactivate_status()
	if status_finish_func then
		status_finish_func()
	end
	change_sort_text(music_wheel.current_sort_name)
	status_active= false
	status_worker= false
	status_container:stoptweening()
	status_container:linear(0.5)
	status_container:diffusealpha(0)
end

local function status_update(self)
	if status_worker then
		if coroutine.status(status_worker) ~= "dead" then
			local working, state, count= coroutine.resume(status_worker)
			if working then
				status_text:settext(state or "done")
				status_count:settext(count or "done")
			else
				status_text:settext("Error encountered.")
				status_count:settext("")
				lua.ReportScriptError(state)
				deactivate_status()
			end
		else
			deactivate_status()
		end
	end
end

local function Update(self)
	if entering_song then
		if get_screen_time() > entering_song then
			SCREENMAN:GetTopScreen():queuecommand("real_play_song")
		end
	elseif status_active then
		-- do nothing.
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

local options_message_frame_helper= setmetatable({}, frame_helper_mt)

local input_functions= {
	scroll_left= function()
		if auto_scrolling then stop_auto_scrolling()
		else start_auto_scrolling(-1) end
	end,
	scroll_right= function()
		if auto_scrolling then stop_auto_scrolling()
		else start_auto_scrolling(1) end
	end,
	stop_scroll= function() stop_auto_scrolling() end,
	back= function()
		stop_music()
		SOUND:PlayOnce(THEME:GetPathS("Common", "cancel"))
		if not GAMESTATE:IsEventMode() then
			end_credit_now()
		else
			trans_new_screen("ScreenInitialMenu")
		end
	end
}

local input_functions= {
	InputEventType_FirstPress= {
		MenuLeft= input_functions.scroll_left,
		MenuRight= input_functions.scroll_right,
		Back= input_functions.back
	},
	InputEventType_Release= {
		MenuLeft= input_functions.stop_scroll,
		MenuRight= input_functions.stop_scroll,
	}
}

local function set_closest_steps_to_preferred(pn)
	local preferred_diff= GAMESTATE:GetPreferredDifficulty(pn) or
		"Difficulty_Beginner"
	local pref_style= get_preferred_style(pn)
	local curr_steps_type= GAMESTATE:GetCurrentStyle(pn):GetStepsType()
	local candidates= get_filtered_sorted_steps_list()
	if candidates and #candidates > 0 then
		local steps_set= false
		local closest
		for i, steps in ipairs(candidates) do
			if not closest then
				closest= {
					steps= steps, diff_diff=
						math.abs(Difficulty:Compare(preferred_diff, steps:GetDifficulty())),
					style= stepstype_to_style[steps:GetStepsType()]
						[GAMESTATE:GetNumPlayersEnabled()].name}
			else
				local this_difference= math.abs(
					Difficulty:Compare(preferred_diff, steps:GetDifficulty()))
				local this_style= stepstype_to_style[steps:GetStepsType()]
					[GAMESTATE:GetNumPlayersEnabled()].name
				if closest.style == pref_style then
					if this_style == pref_style and
					this_difference < closest.diff_diff then
						closest= {
							steps= steps, diff_diff= this_difference, style= this_style}
					end
				else
					if this_style == pref_style then
						closest= {
							steps= steps, diff_diff= this_difference, style= this_style}
					elseif this_difference < closest.diff_diff then
						closest= {
							steps= steps, diff_diff= this_difference, style= this_style}
					end
				end
			end
		end
		if closest then
			cons_set_current_steps(pn, closest.steps)
		else
			cons_set_current_steps(pn, candidates[1])
		end
	end
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
					GAMESTATE:SetPreferredDifficulty(player, picked_steps:GetDifficulty())
					set_preferred_style(player, stepstype_to_style[picked_steps:GetStepsType()][GAMESTATE:GetNumPlayersEnabled()].name)
					SOUND:PlayOnce(THEME:GetPathS("_switch", sound))
				else
					SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
				end
				break
			end
		end
	end
end

local function set_special_menu(pn, value)
	in_special_menu[pn]= value
	if in_special_menu[pn] == 1 or in_special_menu[pn] == 5 then
		pain_displays[pn]:unhide()
		pain_displays[pn]:update_all_items()
		special_menu_displays[pn]:hide()
		if in_special_menu[pn] == 5 then
			player_cursors[pn]:hide()
		else
			player_cursors[pn]:unhide()
			update_player_cursors()
		end
	else
		pain_displays[pn]:hide()
		pain_displays[pn]:show_frame()
		special_menu_displays[pn]:unhide()
		if in_special_menu[pn] == 2 then
			song_props_menus[pn]:reset_info()
			song_props_menus[pn]:update()
		elseif in_special_menu[pn] == 3 then
			tag_menus[pn]:reset_info()
			tag_menus[pn]:update()
		else
			visible_styles_menus[pn]:initialize(pn, make_visible_style_data(pn), true)
			visible_styles_menus[pn]:reset_info()
			visible_styles_menus[pn]:update()
		end
	end
end

local keys_down= {[PLAYER_1]= {}, [PLAYER_2]= {}}
local down_count= {[PLAYER_1]= 0, [PLAYER_2]= 0}
local pressed_since_menu_change= {[PLAYER_1]= {}, [PLAYER_2]= {}}
local codes_since_release= {}
local down_map= {
	InputEventType_FirstPress= true, InputEventType_Repeat= true,
	InputEventType_Release= false}
local menu_button_names= {
	MenuLeft= true, MenuRight= true, MenuUp= true, MenuDown= true, Start= true,
	Select= true, Back= true
}
local scroll_affectors= {MenuLeft= true, MenuRight= true}
if not PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
	scroll_affectors.Left= true
	scroll_affectors.Right= true
end

local function menu_code_to_text(code)
	local hold_string= ""
	if #code.hold_buttons > 0 then
		hold_string= "&" .. table.concat(code.hold_buttons, ";&") .. ";+"
	end
	return hold_string .. "&" .. code.release_trigger .. ";"
end

local function code_to_text(code)
	if code.ignore_release then
		return "&" .. table.concat(code, ";&") .. ";"
	else
		return "&" .. table.concat(code, ";+&") .. ";"
	end
end

local menu_codes= {
	{name= "play_song", hold_buttons= {},
	 release_trigger= "Start", canceled_by_others= false, nothing_down= true},
	{name= "close_group", hold_buttons= {"MenuLeft", "MenuRight"},
	 release_trigger= "Start", canceled_by_others= false},
	{name= "close_group", hold_buttons= {"Left", "Right"},
	 release_trigger= "Start", canceled_by_others= false},
}
do
	local function amc(mc)
		menu_codes[#menu_codes+1]= mc
	end
	if misc_config:get_data().have_select_button then
		amc{name= "sort_mode", hold_buttons= {"Select"},
				release_trigger= "Start", canceled_by_others= false}
		amc{name= "open_special", hold_buttons= {},
				release_trigger= "Select", canceled_by_others= true}
		amc{name= "diff_up", hold_buttons= {"Select"},
				release_trigger= "MenuLeft", canceled_by_others= false}
		amc{name= "diff_down", hold_buttons= {"Select"},
				release_trigger= "MenuRight", canceled_by_others= false}
	else
		amc{name= "sort_mode", hold_buttons= {"MenuLeft"},
				release_trigger= "MenuRight", canceled_by_others= false}
		amc{name= "sort_mode", hold_buttons= {"MenuRight"},
				release_trigger= "MenuLeft", canceled_by_others= false}
		amc{name= "open_special", hold_buttons= {"MenuLeft"},
				release_trigger= "Start", canceled_by_others= false,
				nothing_down= true, overscroll= true}
		amc{name= "open_special", hold_buttons= {"MenuRight"},
				release_trigger= "Start", canceled_by_others= false,
				nothing_down= true, overscroll= true}
	end
end

local codes= {
	{ name= "change_song", fake= true, "MenuLeft" },
	{ name= "change_song", fake= true, "MenuRight" },
	{ name= "change_song", fake= true, "Left" },
	{ name= "change_song", fake= true, "Right" },
	{ name= "sort_mode", ignore_release= true, games= {"dance", "techno"},
		"Up", "Down", "Up", "Down" },
	{ name= "sort_mode", ignore_release= true, games= {"pump", "techno"},
		"UpLeft", "UpRight", "UpLeft", "UpRight" },
	{ name= "diff_up", ignore_release= true, games= {"dance", "techno"},
		"Up", "Up" },
	{ name= "diff_up", ignore_release= true, games= {"pump", "techno"},
		"UpLeft", "UpLeft" },
	{ name= "diff_up", ignore_release= true, games= {"kickbox"},
		"UpLeftFoot" },
	{ name= "diff_down", ignore_release= true, games= {"dance", "techno"},
		"Down", "Down" },
	{ name= "diff_down", ignore_release= true, games= {"pump", "techno"},
		"UpRight", "UpRight" },
	{ name= "diff_down", ignore_release= true, games= {"kickbox"},
		"DownLeftFoot" },
	{ name= "noob_mode", ignore_release= true, games= {"dance", "techno"},
		"Up", "Up", "Down", "Down", "Left", "Right", "Left", "Right"},
	{ name= "simple_options_mode", ignore_release= true, games= {"dance", "techno"},
	"Left", "Down", "Right", "Left", "Down", "Right" },
	{ name= "all_options_mode", ignore_release= true, games= {"dance", "techno"},
	"Right", "Down", "Left", "Right", "Down", "Left" },
	{ name= "excessive_options_mode", ignore_release= true, games= {"dance", "techno"},
		"Left", "Up", "Right", "Up", "Left", "Down", "Right", "Down", "Left"},
	{ name= "kyzentun_mode", ignore_release= true, games= {"none"},
		"Right", "Up", "Left", "Right", "Up", "Left" },
	{ name= "unjoin", ignore_release= true, games= {"none"},
		"Down", "Left", "Up", "Down", "Left", "Up", "Down", "Left", "Up"},
}
for i, v in ipairs(codes) do
	v.curr_pos= {[PLAYER_1]= 1, [PLAYER_2]= 1}
end

local function update_keys_down(pn, key_pressed, press_type)
	if PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
		if menu_button_names[key_pressed] then
			keys_down[pn][key_pressed]= down_map[press_type]
		end
	else
		keys_down[pn][key_pressed]= down_map[press_type]
	end
	if press_type == "InputEventType_FirstPress" then
		pressed_since_menu_change[pn][key_pressed]= true
	end
	down_count[pn]= 0
	for keyname, status in pairs(keys_down[pn]) do
		if status then down_count[pn]= down_count[pn] + 1 end
	end
end

local function update_code_status(pn, key_pressed, press_type)
	local triggered= {}
	local press_handlers= {
		InputEventType_FirstPress= function(to_check)
			if key_pressed == to_check[to_check.curr_pos[pn]] then
				to_check.curr_pos[pn]= to_check.curr_pos[pn] + 1
				if to_check.curr_pos[pn] > #to_check then
					triggered[#triggered+1]= to_check.name
					to_check.curr_pos[pn]= 1
					if to_check.repeat_first_on_end then
						to_check.curr_pos[pn]= #to_check
					end
				end
			else
				if not string_in_table(key_pressed, to_check.ignore_press_list) then
					to_check.curr_pos[pn]= 1
				end
			end
		end,
		InputEventType_Release= function(to_check)
			if not to_check.ignore_release and
			not string_in_table(key_pressed, to_check.ignore_release_list) then
				to_check.curr_pos[pn]= 1
			end
		end
	}
	local handler= press_handlers[press_type]
	if handler then
		if scroll_affectors[key_pressed] then
			stop_auto_scrolling()
		end
		for i, v in ipairs(codes) do
			if not v.fake then
				handler(v)
			end
		end
	end
	if press_type == "InputEventType_Release" then
		for i, check in ipairs(menu_codes) do
			if not codes_since_release[pn] or not check.canceled_by_others then
				if key_pressed == check.release_trigger then
					local held_count= 0
					for keyname, down in pairs(keys_down[pn]) do
						if down and string_in_table(keyname, check.hold_buttons) then
							held_count= held_count+1
						elseif down and check.nothing_down then
							held_count= -1
							break
						end
					end
					if held_count == #check.hold_buttons then
						triggered[#triggered+1]= check.name
						if check.overscroll then
							correct_for_overscroll()
						end
						if not check.nothing_down then
							codes_since_release[pn]= true
						end
					end
				end
			end
		end
	end
	return triggered
end

local code_functions= {
		sort_mode= function(pn)
			stop_auto_scrolling()
			music_wheel:show_sort_list()
			change_sort_text(music_wheel.current_sort_name)
		end,
		play_song= function(pn)
			local needs_work, after_func= music_wheel:interact_with_element()
			if needs_work then
				activate_status(needs_work, after_func)
			else
				change_sort_text(music_wheel.current_sort_name)
			end
		end,
		diff_up= function(pn)
			stop_auto_scrolling()
			adjust_difficulty(pn, -1, "up")
		end,
		diff_down= function(pn)
			stop_auto_scrolling()
			adjust_difficulty(pn, 1, "down")
		end,
		open_special= function(pn)
			if ops_level(pn) >= 2 or privileged(pn) then
				stop_auto_scrolling()
				set_special_menu(pn, 2)
			end
		end,
		close_group= function(pn)
			stop_auto_scrolling()
			music_wheel:close_group()
		end,
		unjoin= function(pn)
			SOUND:PlayOnce(THEME:GetPathS("Common", "Cancel"))
			do return end -- crashes?
			Trace("Master player: " .. GAMESTATE:GetMasterPlayerNumber())
			Trace("Unjoining player: " .. pn)
			GAMESTATE:ApplyGameCommand("style,double")
			GAMESTATE:UnjoinPlayer(other_player[pn])
			Trace("NPE: " .. GAMESTATE:GetNumPlayersEnabled())
			lua.Flush()
			GAMESTATE:ApplyGameCommand("style,single")
			Trace("Master player after unjoin: " .. GAMESTATE:GetMasterPlayerNumber())
			steps_display:update_steps_set()
			steps_display:update_cursors()
		end
}

local function handle_triggered_codes(pn, key_pressed, button, press_type)
	local triggered= update_code_status(pn, key_pressed, press_type)
	for i, v in ipairs(triggered) do
		local ctext= SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("code_text")
		if ctext then
			if convert_code_name_to_display_text[v] then
				ctext:settext(convert_code_name_to_display_text[v])
				ctext:DiffuseAndStroke(
					Alpha(fetch_color("stroke"), 0), fetch_color("text"))
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
		if code_functions[v] then code_functions[v](pn) end
		if cons_players[pn] and cons_players[pn][v] then
			cons_players[pn][v](cons_players[pn])
			if update_rating_cap() then
				activate_status(music_wheel:resort_for_new_style())
			end
			pain_displays[pn]:fetch_config()
			pain_displays[pn]:update_all_items()
		end
	end
	if #triggered == 0 and down_count[pn] <= 1 and not codes_since_release[pn] then
		if input_functions[press_type] and input_functions[press_type][button] then
			input_functions[press_type][button]()
		end
	end
end

local function input(event)
	local pn= event.PlayerNumber
	local key_pressed= event.GameButton
	local press_type= event.type
	if press_type == "InputEventType_FirstPress"
	and event.DeviceInput.button == misc_config:get_data().censor_privilege_key then
		privileged_props= not privileged_props
		for i, pn in ipairs({PLAYER_1, PLAYER_2}) do
			local was_hidden= special_menu_displays[pn].hidden
			song_props_menus[pn]:recheck_levels(true)
			if was_hidden then
				special_menu_displays[pn]:hide()
			end
		end
	end
	if not pn then return end
	if GAMESTATE:IsSideJoined(pn) then
		if entering_song then
			if key_pressed == "Start" and press_type == "InputEventType_FirstPress" then
				SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
				entering_song= 0
				go_to_options= true
			end
		else
			local function common_menu_change(next_menu)
				pressed_since_menu_change[pn]= {}
				set_special_menu(pn, next_menu)
			end
			local function common_select_handler(next_menu, attempt, level)
				if key_pressed == "Select" then
					if press_type == "InputEventType_Release"
					and pressed_since_menu_change[pn].Select then
						if attempt then
							attempt()
						else
							if level and level > ops_level(pn) then
								next_menu= 1
							end
							common_menu_change(next_menu)
						end
						pressed_since_menu_change[pn].Select= false
						return true
					end
				end
			end
			local menu_func= {
				function()
					handle_triggered_codes(pn, event.button, key_pressed, press_type)
				end,
				function()
					if common_select_handler(3, nil, 3) then return end
					if press_type == "InputEventType_Release" then return end
					local handled, extra= song_props_menus[pn]:interpret_code(key_pressed)
					if handled and extra then
						if extra.name == "exit_menu" then
							common_menu_change(1)
						elseif extra.name == "edit_tags" then
							common_menu_change(3)
						elseif extra.name == "edit_styles" then
							common_menu_change(4)
						elseif extra.name == "edit_pain" then
							pain_displays[pn]:enter_edit_mode()
							common_menu_change(5)
						elseif extra.name == "censor" then
							if gamestate_get_curr_song() then
								add_to_censor_list(gamestate_get_curr_song())
								activate_status(music_wheel:resort_for_new_style())
							else
								local bucket= music_wheel.sick_wheel:get_info_at_focus_pos()
								if bucket.bucket_info and not bucket.is_special then
									bucket_traverse(bucket.bucket_info.contents, nil, censor_item)
									activate_status(music_wheel:resort_for_new_style())
								end
							end
							common_menu_change(1)
						elseif extra.name == "uncensor" then
							if gamestate_get_curr_song() then
								remove_from_censor_list(gamestate_get_curr_song())
								activate_status(music_wheel:resort_for_new_style())
							else
								local bucket= music_wheel.sick_wheel:get_info_at_focus_pos()
								if bucket.bucket_info and not bucket.is_special then
									bucket_traverse(bucket.bucket_info.contents, nil, uncensor_item)
									activate_status(music_wheel:resort_for_new_style())
								end
							end
							common_menu_change(1)
						elseif extra.name == "toggle_censoring" then
							toggle_censoring()
							activate_status(music_wheel:resort_for_new_style())
							common_menu_change(1)
						elseif extra.name == "convert_xml" then
							local cong= GAMESTATE:GetCurrentSong()
							if cong then
								if convert_xml_bgs then
									convert_xml_bgs(cong:GetSongDir())
								else
									lua.ReportScriptError("Converting xml scripted simfiles is an abandoned project.  See http://www.stepmania.com/forums/news/show/1121 to learn why.")
								end
							end
							common_menu_change(1)
						elseif interpret_common_song_props_code(pn, extra.name) then
							common_menu_change(1)
						end
						update_sort_prop()
					end
				end,
				function()
					if common_select_handler(1) then return end
					if press_type == "InputEventType_Release" then return end
					local handled, close= tag_menus[pn]:interpret_code(key_pressed)
					if close then
						common_menu_change(1)
					end
				end,
				function()
					local function close_attempt()
						if enough_sourses_of_visible_styles() then
							style_config:set_dirty(pn_to_profile_slot(pn))
							activate_status(music_wheel:resort_for_new_style())
							common_menu_change(1)
							return
						else
							SOUND:PlayOnce(THEME:GetPathS("Common", "Invalid"))
						end
					end
					if common_select_handler(1, close_attempt) then return end
					if press_type == "InputEventType_Release" then return end
					local handled, close=
						visible_styles_menus[pn]:interpret_code(key_pressed)
					if close then close_attempt() end
				end,
				function()
					if press_type == "InputEventType_Release" then return end
					local handled, close=pain_displays[pn]:interpret_code(key_pressed)
					if close then
						common_menu_change(1)
					end
				end
			}
			update_keys_down(pn, key_pressed, press_type)
			if not status_active and pressed_since_menu_change[pn][key_pressed] then
				menu_func[in_special_menu[pn]]()
			end
			if down_count[pn] == 0 then codes_since_release[pn]= false end
		end
	else
		if key_pressed == "Start" then
			local curr_style_type= GAMESTATE:GetCurrentStyle(pn):GetStyleType()
			if curr_style_type == "StyleType_OnePlayerOneSide" and not kyzentun_birthday then
				if cons_join_player(pn) then
					-- Give everybody enough tokens to play, as a way of disabling the stage system.
					for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
						while GAMESTATE:GetNumStagesLeft(pn) < 3 do
							GAMESTATE:AddStageToPlayer(pn)
						end
					end
					GAMESTATE:LoadProfiles()
					local prof= PROFILEMAN:GetProfile(pn)
					if prof then
						if prof ~= PROFILEMAN:GetMachineProfile() then
							cons_players[pn]:set_ops_from_profile(prof)
							load_favorites(pn_to_profile_slot(pn))
							load_tags(pn_to_profile_slot(pn))
						end
					end
					SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
					pain_displays[pn]:fetch_config()
					if GAMESTATE:GetCurrentGame():GetSeparateStyles() then
						set_current_style(first_compat_style(2), PLAYER_1)
						set_current_style(first_compat_style(2), PLAYER_2)
					else
						set_current_style(first_compat_style(2))
					end
					activate_status(music_wheel:resort_for_new_style())
					set_closest_steps_to_preferred(pn)
				end
			end
		end
	end
	update_player_cursors()
end

local function get_code_texts_for_game()
	local game= GAMESTATE:GetCurrentGame():GetName():lower()
	local ret= {}
	for i, code in ipairs(codes) do
		local in_game= (not code.games) or (string_in_table(game, code.games))
		if in_game then
			if not ret[code.name] then ret[code.name]= {} end
			local add_to= ret[code.name]
			add_to[#add_to+1]= code_to_text(code)
		end
	end
	for i, code in ipairs(menu_codes) do
		if not ret[code.name] then ret[code.name]= {} end
		local add_to= ret[code.name]
		add_to[#add_to+1]= menu_code_to_text(code)
	end
	return ret
end

local to_open= THEME:GetString("SelectMusic", "to_open")
local function exp_text(exp_name, x, y, attrib_color)
	local str= THEME:GetString("SelectMusic", exp_name)
	return normal_text(
		exp_name, str .. " " .. to_open, fetch_color("help.text"), fetch_color("help.stroke"), x, y, .75, left, {
			InitCommand= function(self)
				self:AddAttribute(0, {Length=#str, Diffuse= fetch_color(attrib_color)})
			end
	})
end

local help_args= {
	HideTime= misc_config:get_data().select_music_help_time,
	Def.Quad{
		InitCommand= function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
			self:setsize(SCREEN_WIDTH, SCREEN_HEIGHT)
			self:diffuse(fetch_color("help.bg"))
		end
	},
	exp_text("group_exp", 8, 12, "music_select.music_wheel.group"),
	exp_text("current_group_exp", 8, 36, "music_select.music_wheel.current_group"),
	exp_text("song_exp", 8, 60, "music_select.music_wheel.song"),
	Def.ActorFrame{
		Name= "diffex", InitCommand= cmd(xy, 156, 195),
		-- TODO?  duplicate the actual entry in the steps_display that is being
		-- covered.
		Def.Quad{
			InitCommand= function(self)
				self:diffuse(fetch_color("accent.yellow"))
				self:setsize(std_item_w, std_item_h)
			end
		},
		normal_text(
			"style", "S", fetch_color("help.text"), fetch_color("help.stroke"),
				-24, 0, 1, left),
		normal_text(
			"number", "5", fetch_color("help.text"), fetch_color("help.stroke"),
				24, 0, 1, right),
		normal_text(
			"diff", THEME:GetString("SelectMusic", "difficulty"),
			fetch_color("help.text"), fetch_color("help.stroke"), -32,0,.75, right),
	},
	normal_text(
		"dismiss", THEME:GetString("SelectMusic", "dismiss_help"),
		fetch_color("help.text"), fetch_color("help.stroke"), _screen.cx,
		SCREEN_BOTTOM - 28, 1.5),
}
do
	local menu_help_start= 300
	local code_positions= {
		change_song= {wheel_x-24, 24},
		play_song= {wheel_x-24, 56},
		sort_mode= {wheel_x-24, 168, true},
		close_group= {wheel_x-24, 288, true},
		diff_up= {8, 229},
		diff_down= {8, 253},
	}
	if misc_config:get_data().ssm_advanced_help then
		code_positions.open_special= {8, menu_help_start}
		code_positions.noob_mode= {8, menu_help_start+24}
		code_positions.simple_options_mode= {8, menu_help_start+48}
		code_positions.all_options_mode= {8, menu_help_start+72}
		code_positions.excessive_options_mode= {8, menu_help_start+96}
	end
	local game_codes= get_code_texts_for_game()
	for code_name, code_set in pairs(game_codes) do
		local pos= code_positions[code_name]
		if pos then
			local help= THEME:GetString("SelectMusic", code_name)
			local or_word= " "..THEME:GetString("Common", "or").." "
			local code_text= ""
			for i, sintext in ipairs(code_set) do
				if pos[3] and i % 2 == 1 and i > 1 then
					code_text= code_text .. "\n"
				end
				code_text= code_text .. sintext
				if i < #code_set then
					code_text= code_text .. or_word
				end
			end
			help_args[#help_args+1]= normal_text(
				code_name .. "_help", help .. " " .. code_text,
				fetch_color("help.text"), fetch_color("help.stroke"), pos[1], pos[2],
					.75, left)
		end
	end
end

local function maybe_help()
	if misc_config:get_data().select_music_help_time > 0 then
		return Def.AutoHider(help_args)
	end
end

return Def.ActorFrame {
	InitCommand= function(self)
		self:SetUpdateFunction(Update)
		for i, pn in ipairs({PLAYER_1, PLAYER_2}) do
			song_props_menus[pn]:initialize(pn, song_props, true)
			song_props_menus[pn]:set_display(special_menu_displays[pn])
			tag_menus[pn]:initialize(pn)
			tag_menus[pn]:set_display(special_menu_displays[pn])
			visible_styles_menus[pn]:initialize(pn, make_visible_style_data(pn), true)
			visible_styles_menus[pn]:set_display(special_menu_displays[pn])
			special_menu_displays[pn]:set_underline_color(pn_to_color(pn))
			special_menu_displays[pn]:hide()
			update_pain(pn)
		end
		music_wheel:find_actors(self:GetChild(music_wheel.name))
		-- Give everybody enough tokens to play, as a way of disabling the stage system.
		for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			while GAMESTATE:GetNumStagesLeft(pn) < 3 do
				GAMESTATE:AddStageToPlayer(pn)
			end
		end
		april_spin(self)
	end,
	OnCommand= function(self)
							 local top_screen= SCREENMAN:GetTopScreen()
							 top_screen:SetAllowLateJoin(true)
							 top_screen:AddInputCallback(input)
							 change_sort_text(music_wheel.current_sort_name)
	end,
	play_songCommand= function(self)
		local can, reason= GAMESTATE:CanSafelyEnterGameplay()
		if can then
			SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
			local om= self:GetChild("options message")
			om:accelerate(0.25)
			om:diffusealpha(1)
			entering_song= get_screen_time() + options_time
			prev_picked_song= gamestate_get_curr_song()
			save_all_favorites()
			save_all_tags()
			save_censored_list()
		else
			SOUND:PlayOnce(THEME:GetPathS("Common", "Invalid"))
			lua.ReportScriptError("Cannot safely enter gameplay: " .. tostring(reason))
		end
	end,
	real_play_songCommand= function(self)
													 if go_to_options then
														 trans_new_screen("ScreenSickPlayerOptions")
													 else
														 trans_new_screen("ScreenStageInformation")
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
			update_pain(PLAYER_1)
			update_pain(PLAYER_2)
			steps_display:update_cursors()
			update_player_cursors()
		end,
	},
	steps_display:create_actors("StepsDisplay"),
	pain_displays[PLAYER_1]:create_actors(
		"P1_pain", lpane_x, pane_y + pane_yoff - pane_text_height, PLAYER_1, pane_w, pane_text_zoom),
	pain_displays[PLAYER_2]:create_actors(
		"P2_pain", rpane_x, pane_y + pane_yoff - pane_text_height, PLAYER_2, pane_w, pane_text_zoom),
	special_menu_displays[PLAYER_1]:create_actors(
		"P1_menu", lpane_x, pane_y + pane_yoff, max_pain_rows, pane_w - 16,
		pane_text_height, pane_text_zoom, true, true),
	special_menu_displays[PLAYER_2]:create_actors(
		"P2_menu", rpane_x, pane_y + pane_yoff, max_pain_rows, pane_w - 16,
		pane_text_height, pane_text_zoom, true, true),
	Def.Sprite {
		Name="CDTitle", InitCommand=cmd(x,346;y,146),
		OnCommand= cmd(playcommand, "Set"),
		CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
		SetCommand= function(self)
			-- Courses can't have CDTitles, so gamestate_get_curr_song isn't used.
			local song= GAMESTATE:GetCurrentSong()
			if song and song:HasCDTitle()then
				self:LoadBanner(song:GetCDTitlePath())
				self:visible(true)
				-- Jousway suggests fucking people with fucking huge cdtitles.
				scale_to_fit(self, 48, 48)
			else
				self:visible(false)
			end
		end
	},
	Def.Sprite {
		Name="Banner", InitCommand=cmd(xy, banner_x, banner_y),
		CurrentCourseChangedMessageCommand= cmd(playcommand, "Set"),
		CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
		SetCommand= function(self)
			local song= gamestate_get_curr_song()
			if song and song:HasBanner()then
				self:LoadBanner(song:GetBannerPath())
				scale_to_fit(self, banner_w, banner_h)
				self:visible(true)
			else
				self:visible(false)
			end
		end,
		current_group_changedMessageCommand= function(self, param)
			local name= param[1]
			if songman_does_group_exist(name) then
				local path= songman_get_group_banner_path(name)
				if path and path ~= "" then
					self:LoadBanner(path)
					scale_to_fit(self, banner_w, banner_h)
					self:visible(true)
				else
					self:visible(false)
				end
			else
				self:visible(false)
			end
		end
	},
	normal_text("SongName", "", fetch_color("music_select.song_name"), nil,
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
	normal_text("length", "", fetch_color("music_select.song_length"), nil,
							SCREEN_LEFT + 4, title_y + 24, 1, left,
							{ CurrentCourseChangedMessageCommand= cmd(playcommand, "Set"),
								CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
								SetCommand=
									function(self)
										local song= gamestate_get_curr_song()
										if song then
											local lenstr= secs_to_str(song_get_length(song))
											self:settext("song length: " .. lenstr)
											self:visible(true)
										else
											self:visible(false)
										end
									end
							}),
	normal_text("remain", "", fetch_color("music_select.remaining_time"), nil,
							SCREEN_LEFT + 4, title_y + 48, 1, left, {
								OnCommand=
									function(self)
										local remstr= secs_to_str(get_time_remaining())
										self:settext(remstr .. " remaining")
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
					set_closest_steps_to_preferred(v)
				end
			end,
	},
	normal_text("code_text", "", Alpha(fetch_color("text"), 0), nil, 0, 0, .75),
	normal_text("sort", "Sort",
							fetch_color("music_select.music_wheel.sort_head"), nil,
							sort_text_x, SCREEN_TOP + 12),
	normal_text("sort_text", "NO SORT",
							fetch_color("music_select.music_wheel.sort_type"),
							nil, sort_text_x, SCREEN_TOP + 36),
	normal_text("sort_text2", "",
							fetch_color("music_select.music_wheel.sort_type"), nil,
							sort_text_x, SCREEN_TOP + 60),
	normal_text("sort_prop", "",
							fetch_color("music_select.music_wheel.sort_value"), nil,
							sort_text_x, SCREEN_TOP + 84, 1, center, {
								CurrentCourseChangedMessageCommand= cmd(playcommand, "Set"),
								CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
								SetCommand= function(self)
									local item= music_wheel.sick_wheel:get_info_at_focus_pos()
									local name= ""
									if item.bucket_info then
										name= item.bucket_info.name.value
									elseif item.random_info then
										if music_wheel.curr_bucket.name then
											name= music_wheel.curr_bucket.name.value
										end
									elseif item.song_info then
										-- TODO?  If support is ever added for building a custom
										-- list of sort_factors, this needs to change, probably.
										-- The last entry in the name set is the title, because
										-- that is forced.
										if item.item then
											local ns= item.item.name_set
											name= ns[#ns-1].names[1]
										elseif music_wheel.curr_bucket.name then
											name= music_wheel.curr_bucket.name.value
										end
									elseif item.sort_info then
										if music_wheel.curr_bucket.name then
											name= music_wheel.curr_bucket.name.value
										end
									end
									self:settext(name)
									width_clip_limit_text(self, sort_width)
									self:visible(true)
								end
	}),
	player_cursors[PLAYER_1]:create_actors(
		"P1_cursor", 0, 0, 1, pn_to_color(PLAYER_1),
		fetch_color("player.hilight"), true, false, .5),
	player_cursors[PLAYER_2]:create_actors(
		"P2_cursor", 0, 0, 1, pn_to_color(PLAYER_2),
		fetch_color("player.hilight"), true, false, .5),
	-- FIXME:  There's not a place for the credit count on the screen anymore.
	-- credit_reporter(SCREEN_LEFT+120, SCREEN_BOTTOM - 24 - (pane_h * 2), true),
	Def.ActorFrame{
		Name= "status report", InitCommand= function(self)
			status_text= self:GetChild("status_text")
			status_count= self:GetChild("status_count")
			status_container= self
			self:xy(_screen.cx, _screen.cy)
			self:SetUpdateFunction(status_update)
			self:diffusealpha(0)
		end,
		status_frame:create_actors(
			"frame", 2, 200, 56, fetch_color("prompt.frame"), fetch_color("prompt.bg"),
			0, 0),
		normal_text("status_text", "", fetch_color("prompt.text"), nil, 0, -6, 1.5),
		normal_text("status_count", "", fetch_color("prompt.text"), nil, 0, 18, .5),
	},
	Def.ActorFrame{
		Name= "options message",
		InitCommand= function(self)
									 self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
									 self:diffusealpha(0)
								 end,
		OnCommand= function(self)
								 local xmn, xmx, ymn, ymx= rec_calc_actor_extent(self)
								 options_message_frame_helper:move((xmx+xmn)/2, (ymx+ymn)/2)
								 options_message_frame_helper:resize(xmx-xmn+20, ymx-ymn+20)
							 end,
		options_message_frame_helper:create_actors(
			"omf", 2, 0, 0, fetch_color("prompt.frame"), fetch_color("prompt.bg"),
			0, 0),
		normal_text("omm","Press &Start; for options.",fetch_color("prompt.text"),
								nil, 0, 0, 2),
	},
	maybe_help(),
}
