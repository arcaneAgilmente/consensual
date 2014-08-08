local config_data= misc_config:get_data()
misc_config:set_dirty()

dofile(THEME:GetPathO("", "options_menu.lua"))
options_sets.settable_thing= {
	__index= {
		initialize= function(self, extra)
			self.name= extra.name
			self.get= extra.get
			self.set= extra.set
			self.cursor_pos= 1
			self.info_set= {up_element(), {text= self.get()}}
		end,
		set_status= function(self) self.display:set_heading(self.name) end,
		update_text= function(self)
			self.info_set[2].text= self.get()
			self.display:set_element_info(2, self.info_set[2])
		end,
		interpret_start= function(self)
			if self.cursor_pos == 2 then
				self.set()
				return true
			end
			return false
		end
}}
set_option_set_metatables()
dofile(THEME:GetPathO("", "auto_hider.lua"))

local main_display= setmetatable({}, option_display_mt)
local sec_display= setmetatable({}, option_display_mt)

local function make_extra_for_conf_val(name, min_scale, scale, max_scale)
	return {
		name= name,
		min_scale= min_scale,
		scale= scale,
		max_scale= max_scale,
		initial_value= function()
			return config_data[name]
		end,
		set= function(pn, value)
			config_data[name]= value
		end
	}
end

local config_num_args= {
	default_credit_time= {0, 1, 2},
	min_remaining_time= {0, 1, 2},
	song_length_grace= {0, 1, 2},
	min_score_for_reward= {-2, -1, 0},
	min_reward_pct= {-2, -1, 0},
	max_reward_pct= {-2, -1, 0},
	min_reward_time= {0, 1, 2},
	max_reward_time= {0, 1, 2},
	select_music_help_time= {-3, 0, 2},
	evaluation_help_time= {-3, 0, 2},
	service_help_time= {-3, 0, 2},
}

local function make_extra_for_bool_val(name, on, off)
	return {
		name= name,
		true_text= on,
		false_text= off,
		get= function()
			return config_data[name]
		end,
		set= function(pn, value)
			config_data[name]= value
		end
	}
end

local config_bool_args= {
	reward_time_by_pct= {"Percent", "Flat"},
}

local config_menu= setmetatable({}, options_sets.menu)
local menu_items= {
	{name= "exit_config"},
	{name= "default_credit_time"},
	{name= "min_remaining_time"},
	{name= "song_length_grace"},
	{name= "min_score_for_reward"},
	{name= "reward_time_by_pct"},
	{name= "min_reward_pct"},
	{name= "max_reward_pct"},
	{name= "min_reward_time"},
	{name= "max_reward_time"},
	{name= "select_music_help_time"},
	{name= "evaluation_help_time"},
	{name= "service_help_time"},
	{name= "set_config_key"},
}
config_menu:initialize(nil, menu_items, true)

local secondary_menu= {}
local on_main_menu= true
local return_on_start= false
local on_press_prompt= false

local cursor= setmetatable({}, amv_cursor_mt)

local hider_frame= setmetatable({}, frame_helper_mt)
local hider_text= {}
local hider_params= {
	Name="help",
	hider_frame:create_actors(
		"frame", 1, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0),
	normal_text("text", "", solar_colors.f_text(), _screen.cx, _screen.cy, 1,
							center, {InitCommand= function(self) hider_text= self end}),
}

local function update_hider_time()
	if config_data.service_help_time > 0 then
		hider_params.HideTime= config_data.service_help_time
	else
		hider_params.HideTime= 2^16
	end
end
update_hider_time()

local function update_hider_text()
	local pos= config_menu.cursor_pos
	hider_text:settext(get_string_wrapper("ConsService", menu_items[pos].name))
	local xmn, xmx, ymn, ymx= rec_calc_actor_extent(hider_text)
	hider_frame:move((xmx+xmn)/2 + _screen.cx, (ymx+ymn)/2 + _screen.cy)
	hider_frame:resize(xmx-xmn+20, ymx-ymn+20)
end

local prompt_frame= setmetatable({}, frame_helper_mt)
local press_prompt= {}
local function update_cursor_pos()
	local item
	if on_main_menu then
		item= config_menu:get_cursor_element()
		update_hider_text()
	else
		item= secondary_menu:get_cursor_element()
	end
	if item then
		local xmn, xmx, ymn, ymx= rec_calc_actor_extent(item.container)
		local xp, yp= rec_calc_actor_pos(item.container)
		cursor:refit(xp, yp, xmx - xmn + 4, ymx - ymn + 4)
	end
end

local function key_get()
	return ToEnumShortString(config_data.config_menu_key)
end

local function key_set()
	press_prompt:visible(true)
	on_press_prompt= 1
end

local function input(event)
	if on_press_prompt then
		if on_press_prompt == 1 then
			if event.type == "InputEventType_Release" then
				on_press_prompt= 2
			end
		else
			if event.type == "InputEventType_FirstPress" then
				config_data.config_menu_key= event.DeviceInput.button
				secondary_menu:update_text()
				update_cursor_pos()
				press_prompt:visible(false)
			elseif event.type == "InputEventType_Release" then
				on_press_prompt= false
			end
		end
		return false
	end
	if event.type == "InputEventType_Release" then return false end
	if event.PlayerNumber and event.GameButton then
		if on_main_menu then
			local handled, extra= config_menu:interpret_code(event.GameButton)
			if handled and extra then
				extra= extra.name
				if extra == "exit_config" then
					misc_config:save()
					SCREENMAN:SetNewScreen("ScreenInitialMenu")
				elseif extra == "set_config_key" then
					secondary_menu= setmetatable({}, options_sets.settable_thing)
					secondary_menu:initialize{
						name= "set_config_key", get= key_get, set= key_set}
					secondary_menu:set_display(sec_display)
					on_main_menu= false
					return_on_start= false
				else
					if config_num_args[extra] then
						secondary_menu= setmetatable({}, options_sets.adjustable_float)
						secondary_menu:initialize(
							nil, make_extra_for_conf_val(
								extra, unpack(config_num_args[extra])))
						secondary_menu:set_display(sec_display)
						on_main_menu= false
						return_on_start= false
					elseif config_bool_args[extra] then
						secondary_menu= setmetatable({}, options_sets.boolean_option)
						secondary_menu:initialize(
							nil, make_extra_for_bool_val(
								extra, unpack(config_bool_args[extra])))
						secondary_menu:set_display(sec_display)
						on_main_menu= false
						return_on_start= true
					end
				end
			end
		else
			local handled= secondary_menu:interpret_code(event.GameButton)
			if event.GameButton == "Start" and
			(secondary_menu.cursor_pos == 1 or return_on_start) then
				secondary_menu= {}
				update_hider_time()
				on_main_menu= true
				sec_display:hide()
			end
		end
		update_cursor_pos()
		return true
	end
	return false
end

return Def.ActorFrame{
	InitCommand= function(self)
		main_display:set_underline_color(solar_colors.violet())
		config_menu:set_display(main_display)
		sec_display:set_underline_color(solar_colors.violet())
		sec_display:hide()
		update_cursor_pos()
	end,
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	main_display:create_actors(
		"Main Menu", _screen.cx*.5, 60, (_screen.h / 24) - 5, _screen.w / 3, 24,
		1, true, true),
	sec_display:create_actors(
		"Sec Menu", _screen.cx*1.5, 60, (_screen.h / 24) - 5, _screen.w / 3, 24,
		1, false, false),
	cursor:create_actors("cursor", 0, 0, 0, 0, 1, solar_colors.violet()),
	Def.AutoHider(hider_params),
	Def.ActorFrame{
		Name= "press prompt",
		InitCommand= function(self)
			press_prompt= self
			self:xy(_screen.cx, _screen.cy)
			self:visible(false)
		end,
		OnCommand= function(self)
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(self)
			prompt_frame:move((xmx+xmn)/2, (ymx+ymn)/2)
			prompt_frame:resize(xmx-xmn+20, ymx-ymn+20)
		end,
		prompt_frame:create_actors(
			"ppf", 1, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0),
		normal_text("ppt", "Press key.", solar_colors.green(), 0, 0, 1),
	}
}
