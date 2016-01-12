dofile(THEME:GetPathO("", "sick_options_parts.lua"))

gameplay_pause_count= 0
local menu_y= 56
local menu_width= _screen.cx*.75
local menu_height= _screen.h*.75
local menu_frames= {}
local pause_menus= {}
local menu_x= {
	[PLAYER_1]= _screen.cx*.5,
	[PLAYER_2]= _screen.cx*1.5,
}

local enabled_players= {}
local pause_buttons= {Start= true, Select= true, Back= true}
if not ScreenGameplay.begin_backing_out then
	pause_buttons.Back= false
end
local pause_press_times= {}
local hit_texts= {}
local screen_gameplay= false

local rate_coordinator= setmetatable({}, rate_coordinator_interface_mt)
rate_coordinator:initialize()
local color_manips= {}
local bpm_disps= {}
local mods_menu= get_sick_options(rate_coordinator, color_manips, bpm_disps)
local old_fg_visible= false

local function close_menu(pn)
	pause_menus[pn]:clear_options_set_stack()
	pause_menus[pn]:hide()
	menu_frames[pn]:hide()
	hit_texts[pn]:visible(false)
	local stay_paused= false
	for pn, menu in pairs(pause_menus) do
		if not menu.hidden then
			stay_paused= true
		end
	end
	if not stay_paused then
		local fg= screen_gameplay:GetChild("SongForeground")
		if fg then fg:visible(old_fg_visible) end
		screen_gameplay:PauseGame(false)
	end
end

local function backout(screen)
	screen_gameplay:SetPrevScreenName(screen):begin_backing_out()
end

local function forfeit(pn)
	backout("ScreenConsSelectMusic")
end

local function restart_song(pn)
	backout("ScreenGameplay")
end

local menu_options= {
	{name= "Mods", meta= options_sets.menu, args= mods_menu},
}
if Screen.SetPrevScreenName then
	table.insert(menu_options, {name= "Forfeit", meta= "execute", execute= forfeit})
	table.insert(menu_options, {name= "Restart Song", meta= "execute", execute= restart_song})
end

local function show_menu(pn)
	menu_frames[pn]:unhide()
	pause_menus[pn]:unhide()
	hit_texts[pn]:visible(true)
	pause_menus[pn]:push_options_set_stack(options_sets.menu, menu_options, "Play Song")
	pause_menus[pn]:update_cursor_pos()
end

local function set_hit_text(pn, button, press)
	local press_text= ""
	if press then
		press_text= get_string_wrapper("ScreenGameplay", "pressed")
	else
		press_text= get_string_wrapper("ScreenGameplay", "released")
	end
	local trigger_text= get_string_wrapper("ScreenGameplay", "menu_triggered")
	hit_texts[pn]:settext(trigger_text .. " " .. button .. " " .. press_text)
end

local function input(event)
	local pn= event.PlayerNumber
	if not enabled_players[pn] then return end
	local button= event.GameButton
	if not button then return end
	local is_paused= screen_gameplay:IsPaused()
	if event.type == "InputEventType_Release" then
		if not is_paused and pause_buttons[button] and pause_press_times[pn] then
			if GetTimeSinceStart() - pause_press_times[pn] >= cons_players[pn].pause_hold_time then
				screen_gameplay:PauseGame(true)
				set_hit_text(pn, button, false)
				show_menu(pn)
			end
			pause_press_times[pn]= nil
		end
		return
	end
	if is_paused then
		if pause_menus[pn].hidden then
			if pause_buttons[button] then
				show_menu(pn)
			end
		else
			if not pause_menus[pn]:interpret_code(button) then
				if button == "Start" then
					close_menu(pn)
				end
			end
			if pause_menus[pn].external_thing then
				local fit= color_manips[pn]:get_cursor_fit()
				fit[2]= fit[2] - menu_y
				pause_menus[pn]:refit_cursor(fit)
			end
		end
		return true
	elseif pause_buttons[button] then
		if cons_players[pn].pause_hold_time > 0 then
			pause_press_times[pn]= GetTimeSinceStart()
		else
			if GAMESTATE:GetCurMusicSeconds() > GAMESTATE:GetCurrentSong():GetFirstSecond() then
				gameplay_pause_count= gameplay_pause_count + 1
			end
			screen_gameplay:PauseGame(true)
			local fg= screen_gameplay:GetChild("SongForeground")
			if fg then
				old_fg_visible= fg:GetVisible()
				fg:visible(false)
			end
			set_hit_text(pn, button, true)
			show_menu(pn)
		end
		return true
	end
end

local main_frame= Def.ActorFrame{
	OnCommand= function(self)
		for pn, on in pairs(enabled_players) do
			menu_frames[pn]:hide()
			pause_menus[pn]:hide()
			bpm_disps[pn]:hide()
			color_manips[pn]:hide()
			hit_texts[pn]:visible(false)
		end
		screen_gameplay= SCREENMAN:GetTopScreen()
		screen_gameplay:AddInputCallback(input)
	end,
}

for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	enabled_players[pn]= true
	menu_frames[pn]= setmetatable({}, frame_helper_mt)
	pause_menus[pn]= setmetatable({}, menu_stack_mt)
	color_manips[pn]= setmetatable({}, color_manipulator_mt)
	bpm_disps[pn]= setmetatable({}, bpm_disp_mt)
	local player_frame= Def.ActorFrame{
		Name= "pause_stuff", InitCommand= function(self)
			self:x(menu_x[pn])
			hit_texts[pn]= self:GetChild("hit_text")
		end,
		gameplay_xversionMessageCommand= function(self, param)
			self:zoomx(self:GetZoomX() * -1):x(_screen.w - self:GetDestX())
		end,
		gameplay_yversionMessageCommand= function(self, param)
			self:zoomy(self:GetZoomY() * -1):y(_screen.h - self:GetDestY())
		end,
		menu_frames[pn]:create_actors(
			"pause_frame", 2, menu_width, menu_height+12, pn_to_color(pn),
			fetch_color("bg", .5), 0, menu_y-6 + (menu_height * .5)),
		pause_menus[pn]:create_actors(
			pn .. "_menu", 0, menu_y, menu_width, menu_height,
			pn, 1, 24, 1),
		bpm_disps[pn]:create_actors("bpm", pn, 0, 0, 0),
		color_manips[pn]:create_actors("color_manip", 0, menu_y+64, nil, .5),
		normal_text("hit_text", "", fetch_color("text"), fetch_color("stroke"), 0, menu_y + menu_height - 12, .5),
	}
	main_frame[#main_frame+1]= player_frame
end

return main_frame
