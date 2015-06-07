local line_height= get_line_height()
local option_set_elements= (SCREEN_HEIGHT / line_height) - 5
local sect_width= SCREEN_WIDTH/2
local sect_height= SCREEN_HEIGHT
local rate_coordinator= setmetatable({}, rate_coordinator_interface_mt)
rate_coordinator:initialize()

dofile(THEME:GetPathO("", "art_helpers.lua"))
dofile(THEME:GetPathO("", "options_menu.lua"))
dofile(THEME:GetPathO("", "sick_options_parts.lua"))

local bpm_disps= {}
local args= {}
local menus= {}
local frames= {}
local in_color_manip= {}
local color_manips= {}
local color_manip_x= (sect_width * .5) + 48
local color_manip_y= 100 + (line_height * 3)
local menu_y= 0
local base_options= get_sick_options(rate_coordinator, color_manips, bpm_disps)
for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	local menu= setmetatable({}, menu_stack_mt)
	local bpm= setmetatable({}, bpm_disp_mt)
	local frame= setmetatable({}, frame_helper_mt)
	local manip= setmetatable({}, color_manipulator_mt)
	local mx, my= 0, 0
	if pn == PLAYER_2 then
		mx= sect_width
	end
	local pcolor= pn_to_color(pn)
	local pname= pn
	local pro= PROFILEMAN:GetProfile(pn)
	if pro and pro:GetDisplayName() ~= "" then
		pname= pro:GetDisplayName()
	end
	args[#args+1]= Def.ActorFrame{
		Name= "decs" .. pn, InitCommand= function(self)
			self:xy(mx, my)
			manip:hide()
		end,
		frame:create_actors(
			"frame", 2, sect_width, sect_height, pcolor, fetch_color("bg", .5),
			sect_width/2, sect_height/2),
		normal_text("name", pname, pcolor, nil, 8, line_height / 2, 1, left),
		bpm:create_actors("bpm", pn, sect_width/2, line_height*1.5, sect_width),
		manip:create_actors("color_manip", color_manip_x, color_manip_y),
	}
	local status_size= line_height*2.5
	menu_y= status_size
	args[#args+1]= menu:create_actors(
		"m" .. pn, mx, menu_y, sect_width, sect_height-status_size, pn)
	menus[pn]= menu
	bpm_disps[pn]= bpm
	frames[pn]= frame
	color_manips[pn]= manip
end

local function refit_cursor_to_color_manip(pn)
	local fit= color_manips[pn]:get_cursor_fit()
	fit[2]= fit[2] - menu_y
	menus[pn]:refit_cursor(fit)
end

function args:InitCommand()
	for pn, menu in pairs(menus) do
		menu:push_options_set_stack(options_sets.menu, base_options, "Play Song")
		menu:update_cursor_pos()
	end
end

local function apply_preferred_mods()
	GAMESTATE:GetPlayerState(PLAYER_1):ApplyPreferredOptionsToOtherLevels()
	GAMESTATE:GetPlayerState(PLAYER_2):ApplyPreferredOptionsToOtherLevels()
	GAMESTATE:ApplyPreferredSongOptionsToOtherLevels()
end

local saw_first_press= {}
local function input(event)
	input_came_from_keyboard= event.DeviceInput.device == "InputDevice_Key"
	local press_type= event.type
	if press_type == "InputEventType_FirstPress" then
		saw_first_press[event.DeviceInput.button]= true
	end
	if not saw_first_press[event.DeviceInput.button] then return end
	if press_type == "InputEventType_Release" then
		saw_first_press[event.DeviceInput.button]= nil
	end
	if event.type == "InputEventType_Release" then return end
	local pn= event.PlayerNumber
	local code= event.GameButton
	if menus[pn] then
		if not menus[pn]:interpret_code(code) then
			if code == "Start" then
				local all_on_exit= true
				for k, m in pairs(menus) do
					if not m:can_exit_screen() then
						all_on_exit= false
					end
				end
				if all_on_exit then
					SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
					if in_edit_mode then
						set_speed_from_speed_info(cons_players[PLAYER_1])
						apply_preferred_mods()
						trans_new_screen("none")
					else
						trans_new_screen("ScreenStageInformation")
					end
				end
			elseif code == "Back" then
				SOUND:PlayOnce(THEME:GetPathS("Common", "cancel"))
				if in_edit_mode then
					apply_preferred_mods()
					trans_new_screen("none")
				else
					trans_new_screen("ScreenConsSelectMusic")
				end
			end
		end
		if menus[pn].external_thing then
			refit_cursor_to_color_manip(pn)
		end
	end
end

if in_edit_mode then
	cons_players[PLAYER_1].options_level= 4
	cons_players[PLAYER_2].options_level= 4
end

args[#args+1]= Def.Actor{
	Name= "code_interpreter", OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	went_to_text_entryMessageCommand= function(self)
		saw_first_press= {}
	end,
}

return Def.ActorFrame(args)
