local line_height= get_line_height()
local done_pos= #sorted_workout_field_names + 1
local field_width= 120
local enabled_players= GAMESTATE:GetEnabledPlayers()
local slots= {}
for i, pn in ipairs(enabled_players) do
	slots[i]= pn_to_profile_slot(pn)
end
update_steps_types_to_show()

local workout_menu_mt= {
	__index= {
		create_actors= function(self, pn, x, y, data)
			local args= {
				Name= pn.."_menu", InitCommand= function(subself)
					self.container= subself:xy(x, y)
					self:update()
			end}
			self.data= data
			self.pn= pn
			self.values= {}
			for i, name in ipairs(sorted_workout_field_names) do
				args[#args+1]= normal_text(
					name, "", fetch_color("text"), fetch_color("stroke"), 0,
					(i-1) * line_height, 1, nil, {
						InitCommand= function(subself)
							self.values[i]= subself:maxwidth(120)
						end
				})
			end
			args[#args+1]= normal_text(
				name, get_string_wrapper("WorkoutConfig", "done"),
				fetch_color("text"), fetch_color("stroke"), 0,
				(done_pos-1) * line_height, 1, nil, {
					InitCommand= function(subself)
						self.values[#self.values+1]= subself:maxwidth(field_width)
					end
			})
			self.cursor_pos= 1
			self.cursor= setmetatable({}, cursor_mt)
			local button_list= {{"left", "MenuLeft"}, {"right", "MenuRight"}}
			if ud_menus() then
				button_list[#button_list+1]= {"top", "MenuUp"}
				button_list[#button_list+1]= {"bottom", "MenuDown"}
			else
				button_list[#button_list+1]= {"top", "Select"}
				button_list[#button_list+1]= {"bottom", "Start"}
			end
			args[#args+1]= self.cursor:create_actors(
				"cursor", 0, 0, 1, pn_to_color(pn), fetch_color("player.hilight"),
				button_list)
			return Def.ActorFrame(args)
		end,
		update= function(self)
			for i, name in ipairs(sorted_workout_field_names) do
				local field_type= type(self.data[name])
				local text= ""
				if field_type == "boolean" or field_type == "string" then
					text= get_string_wrapper("WorkoutConfig", tostring(self.data[name]))
				elseif field_type == "number" then
					if name == "goal_target" then
						if self.data.goal_type == "time" then
							text= secs_to_str(self.data[name])
						else
							text= ("%.0f"):format(
								self.data[name]*workout_step_or_calorie_multiplier)
						end
					elseif name == "start_meter" then
						text= ("%.0f"):format(self.data[name])
					else
						text= ("%.0f%%"):format(self.data[name]*100)
					end
				end
				self.values[i]:settext(text)
			end
			self.cursor:refit(0, (self.cursor_pos-1)*line_height + 1, 128, 28)
		end,
		interpret_code= function(self, code)
			if code == "Start" or code == "MenuDown" then
				if self.cursor_pos == done_pos then
					self.done= true
				else
					self.cursor_pos= self.cursor_pos + 1
				end
			elseif code == "Select" or code == "MenuUp" then
				if self.cursor_pos > 1 then
					self.cursor_pos= self.cursor_pos - 1
				else
					self.cursor_pos= done_pos
				end
			elseif code == "MenuLeft" and self.cursor_pos < done_pos then
				local field_name= sorted_workout_field_names[self.cursor_pos]
				local field_type= type(self.data[field_name])
				if field_type == "boolean" then
					self.data[field_name]= not self.data[field_name]
				elseif field_name == "goal_type" then
					local goal_pos= string_in_table(
						self.data[field_name], workout_goal_types)
					if goal_pos > 1 then
						goal_pos= goal_pos - 1
					else
						goal_pos= #workout_goal_types
					end
					self.data[field_name]= workout_goal_types[goal_pos]
				elseif field_name == "easier_threshold"
				or field_name == "harder_threshold" then
					self.data[field_name]= self.data[field_name] - .01
				elseif field_type == "number" then
					self.data[field_name]= self.data[field_name] - 1
				end
			elseif code == "MenuRight" and self.cursor_pos < done_pos then
				local field_name= sorted_workout_field_names[self.cursor_pos]
				local field_type= type(self.data[field_name])
				if field_type == "boolean" then
					self.data[field_name]= not self.data[field_name]
				elseif field_name == "goal_type" then
					local goal_pos= string_in_table(
						self.data[field_name], workout_goal_types)
					if goal_pos < #workout_goal_types then
						goal_pos= goal_pos + 1
					else
						goal_pos= 1
					end
					self.data[field_name]= workout_goal_types[goal_pos]
				elseif field_name == "easier_threshold"
				or field_name == "harder_threshold" then
					self.data[field_name]= self.data[field_name] + .01
				elseif field_type == "number" then
					self.data[field_name]= self.data[field_name] + 1
				end
			end
			self:update()
		end,
}}

local menus= {}
local positions= {
	[PLAYER_1]= _screen.w * .25, [PLAYER_2]= _screen.w * .75}
local menu_y= 120

local song_count= false

local function workout_tag_filter(song)
	for i= 1, #enabled_players do
		if get_tag_value(slots[i], song, "workout") > 0 then return true end
	end
	return false
end

local function workout_favor_filter(song)
	for i= 1, #enabled_players do
		if get_favor(slots[i], song) > 0 then return true end
	end
	return false
end

local worker= false
local function worker_update()
	if worker then
		if coroutine.status(worker) ~= "dead" then
			local working, state, count= coroutine.resume(worker)
			if not working then
				lua.ReportScriptError(state)
				worker= false
			elseif count then
				song_count:settext(count .. " Songs")
			end
		else
			song_count:settext(#bucket_man.filtered_songs .. " Songs")
			worker= false
		end
	end
end

local function get_filter_status(name)
	for pn, data in pairs(workout_mode) do
		if data[name] then return true end
	end
	return false
end

local function add_or_rem(cond, func)
	if cond then
		bucket_man:add_filter_function(func)
	else
		bucket_man:remove_filter_function(func)
	end
end

local function update_song_count()
	add_or_rem(get_filter_status("use_workout_tag"), workout_tag_filter)
	add_or_rem(get_filter_status("use_favor_level"), workout_favor_filter)
	worker= make_song_filter_worker()
end

local function input(event)
	if not event.PlayerNumber then return end
	if event.type == "InputEventType_Release" then return end
	if not menus[event.PlayerNumber] then return end
	if worker then return end
	local was_done= menus[event.PlayerNumber].done
	local old_use_tag= get_filter_status("use_workout_tag")
	local old_use_favor= get_filter_status("use_favor_level")
	menus[event.PlayerNumber]:interpret_code(event.GameButton)
	if menus[event.PlayerNumber].done and not was_done then
		SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
		local everyone_done= true
		for pn, menu in pairs(menus) do
			if not menu.done then everyone_done= false end
		end
		if everyone_done then
			local all_use_nps= true
			local all_use_meter= true
			for pn, menu in pairs(menus) do
				if workout_mode[pn].use_workout_tag then use_workout_tag= true end
				if workout_mode[pn].use_favor_level then use_favor= true end
				if workout_mode[pn].use_nps_to_rate then
					all_use_meter= false
				else
					all_use_nps= false
				end
				workout_config:set_dirty(pn_to_profile_slot(pn))
				workout_config:save(pn_to_profile_slot(pn))
				workout_mode[pn].current_meter= workout_mode[pn].start_meter
				if workout_mode[pn].goal_type == "calories" then
					local profile= PROFILEMAN:GetProfile(pn)
					if profile then
						workout_mode[pn].start_calories= profile:GetTotalCaloriesBurned()
						workout_mode[pn].end_calories= profile:GetTotalCaloriesBurned() +
							workout_mode[pn].goal_target *
							workout_step_or_calorie_multiplier
					end
				end
			end
			if all_use_nps then
				bucket_man.cur_sort_info= get_nps_sort_info()
			elseif all_use_meter then
				bucket_man.cur_sort_info= get_any_meter_sort_info()
			else
				bucket_man.cur_sort_info= get_group_sort_info()
			end
			worker= make_song_sort_worker()
			trans_new_screen("ScreenWorkoutPick")
		end
	end
	if event.GameButton == "Back" then
		SOUND:PlayOnce(THEME:GetPathS("Common", "cancel"))
		trans_new_screen("ScreenInitialMenu")
	end
	local new_use_tag= get_filter_status("use_workout_tag")
	local new_use_favor= get_filter_status("use_favor_level")
	if new_use_tag ~= old_use_tag or new_use_favor ~= old_use_favor then
		update_song_count()
	end
end

local args= {
	Def.ActorFrame{
		OnCommand= function(self)
			bucket_man:initialize()
			SCREENMAN:GetTopScreen():AddInputCallback(input)
			self:SetUpdateFunction(worker_update)
			update_song_count()
		end
	},
	normal_text("song_count", "", fetch_color("text"), fetch_color("stroke"),
							_screen.cx, 24, 1, nil, {
								InitCommand= function(self) song_count= self end})
}

local function y_at_i(i)
	return menu_y + ((i-1) * line_height)
end

for i, name in ipairs(sorted_workout_field_names) do
	local quad_color= fetch_color("bg_shadow")
	if i % 2 == 1 then quad_color= fetch_color("bg") end
	args[#args+1]= Def.Quad{
		InitCommand= function(self)
			self:xy(_screen.cx, y_at_i(i)+2):setsize(_screen.w, line_height)
				:diffuse(quad_color)
		end
	}
end

for i, name in ipairs(sorted_workout_field_names) do
	args[#args+1]= normal_text(
		name, get_string_wrapper("WorkoutConfig", name),
		fetch_color("text"), fetch_color("stroke"), _screen.cx, y_at_i(i), 1, nil,
		{
			InitCommand= function(self)
				self:maxwidth((_screen.w*.5) - field_width - 8)
			end
	})
end


for i, pn in ipairs(enabled_players) do
	workout_config:load(pn_to_profile_slot(pn))
	workout_mode[pn]= workout_config:get_data(pn_to_profile_slot(pn))
	menus[pn]= setmetatable({}, workout_menu_mt)
	args[#args+1]= menus[pn]:create_actors(
		pn, positions[pn], menu_y, workout_mode[pn])
end

return Def.ActorFrame(args)
