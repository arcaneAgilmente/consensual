local line_height= get_line_height()
local option_set_elements= (SCREEN_HEIGHT / line_height) - 5
local sect_width= SCREEN_WIDTH/2
local sect_height= SCREEN_HEIGHT

-- SPEED RATE COORDINATION
-- Each speed option row and each rate mod option line registers with this
-- structure so they can coordinate their displayed values.  This is
-- important because the speed mod is effectively multiplied by the rate mod.
--
-- add_to_notify(line)
--   Adds line to a list of things that will be notified when the rate
--     changes.  line must have a function named "notify_of_rate_change" that
--     takes no arguments.
--
-- notify_of_rate_change(new_rate)
--   Notifies all things in the list of the rate change.  Things that change
--     the rate should call this function.
--
-- get_current_rate()
--   Returns the current rate.

local rate_coordinator= setmetatable({}, rate_coordinator_interface_mt)
rate_coordinator:initialize()
-- The current rate is a leftover from the previous song.  It might slow the
-- current song down enough to go over the time limit.  So it needs to be
-- adjusted to bring the song within that limit.
if GAMESTATE:GetCoinMode() ~= "CoinMode_Home" then
	local remain= get_time_remaining()
	local song_len= get_current_song_length()
	local rate= rate_coordinator:get_current_rate()
	if song_len / rate > remain then
		local new_rate= song_len / remain
		new_rate= force_to_range(0.5, new_rate, 2.0)
		new_rate= math.round(new_rate * 100) / 100
		GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(new_rate)
		rate_coordinator:notify(new_rate, true)
	end
end

local function mod_player(pn, mod_name, value)
	local mod_func= PlayerOptions[mod_name]
	if mod_func then
		return mod_func(cons_players[pn].preferred_options, value)
	else
		Warn("mod '" .. tostring(mod_name) .. "' does not exist.")
	end
end

local profiles= {}
for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	profiles[pn]= PROFILEMAN:GetProfile(pn)
end

local bpm_disps= {}
local bpm_disp_mt= {
	__index= {
		create_actors= function(self, name, player_number, x, y)
			self.name= name
			self.player_number= player_number
			rate_coordinator:add_to_notify(self)
			local args= {
				Name=name, InitCommand= function(subself)
					self.container= subself
					self.text= subself:GetChild("bpm")
					self.text:maxwidth(sect_width-16)
					subself:xy(x, y)
					self:bpm_text()
				end,
				normal_text("bpm", "", fetch_color("text"), fetch_color("stroke"))
			}
			return Def.ActorFrame(args)
		end,
		bpm_text= function(self)
			-- TODO:  Find a way to call bpm_text when verbose_bpm changes.
			local steps= gamestate_get_curr_steps(self.player_number)
			if steps then
				local bpms= steps_get_bpms(steps, gamestate_get_curr_song())
				local curr_rate= rate_coordinator:get_current_rate()
				bpms[1]= bpms[1] * curr_rate
				bpms[2]= bpms[2] * curr_rate
				local parts= {{"BPM: ", fetch_color("text")}}
				local function add_bpms_to_parts(parts, a, b, color_func)
					parts[#parts+1]= {format_bpm(a), color_func(a)}
					parts[#parts+1]= {" to ", fetch_color("text")}
					parts[#parts+1]= {format_bpm(b), color_func(b)}
				end
				if cons_players[self.player_number].flags.interface.verbose_bpm then
					local mode= cons_players[self.player_number].speed_info.mode
					local speed= cons_players[self.player_number].speed_info.speed
					if mode == "x" then
						local xmod= {" * "..format_xmod(speed).." = ",fetch_color("text")}
						if bpms[1] == bpms[2] then
							local rbpm= bpms[1]
							parts[#parts+1]= {format_bpm(rbpm), color_for_bpm(rbpm)}
							parts[#parts+1]= xmod
							parts[#parts+1]= {format_bpm(rbpm * speed), color_for_read_speed(rbpm*speed)}
						else
							add_bpms_to_parts(parts, bpms[1], bpms[2], color_for_bpm)
							parts[#parts+1]= xmod
							add_bpms_to_parts(
								parts, bpms[1] * speed, bpms[2] * speed, color_for_read_speed)
						end
					else
						if bpms[1] == bpms[2] then
							parts[#parts+1]= {format_bpm(bpms[1]), color_for_bpm(bpms[1])}
						else
							add_bpms_to_parts(parts, bpms[1], bpms[2], color_for_bpm)
						end
						parts[#parts+1]= {" (" .. mode, fetch_color("text")}
						parts[#parts+1]= {format_bpm(speed), color_for_read_speed(speed)}
						parts[#parts+1]= {")", fetch_color("text")}
					end
				else
					if bpms[1] == bpms[2] then
						parts[#parts+1]= {format_bpm(bpms[1]), color_for_bpm(bpms[1])}
					else
						add_bpms_to_parts(parts, bpms[1], bpms[2], color_for_bpm)
					end
				end
				set_text_from_parts(self.text, parts)
			end
		end,
		notify_of_rate_change= function(self)
			if self.container then
				self:bpm_text()
			end
		end,
}}

dofile(THEME:GetPathO("", "art_helpers.lua"))
dofile(THEME:GetPathO("", "options_menu.lua"))

local speed_inc_base= 25
local speed_inc_base_recip= 1/speed_inc_base

options_sets.speed= {
	__index= {
		initialize= function(self, player_number)
			self.info_set= {
				up_element(), {text= ""}, {text= ""}, {text= ""}, {text= ""},
				{text= "Xmod"}, {text= "Cmod"}, {text= "Mmod"},
			}
			if cons_players[player_number].options_level >= 3 then
				self.info_set[#self.info_set+1]= {text= "CXmod"}
			end
			if cons_players[player_number].options_level >= 4 then
				self.info_set[#self.info_set+1]= {text= "Driven"}
				self.info_set[#self.info_set+1]= {text= "Alt Driven"}
			end
			local speed_info= cons_players[player_number]:get_speed_info()
			self.current_speed= speed_info.speed
			self:set_mode_data_work(speed_info.mode)
			self.cursor_pos= 1
		end,
		set_status= function(self)
			self.display:set_heading("Speed")
			self:update_speed_text()
		end,
		set_player_speed_info= function(self)
			local spi= cons_players[self.player_number].speed_info
			spi.mode= self.mode
			spi.speed= self.current_speed
			bpm_disps[self.player_number]:bpm_text()
		end,
		update_speed_text= function(self)
			if self.display then
				local form_speed= ("%.2f"):format(self.current_speed)
				if self.mode == "x" then
					self.display:set_display(form_speed .. "x")
				elseif self.mode == "D" and cons_players[self.player_number].dspeed.alternate then
					self.display:set_display(self.mode .. "A" .. form_speed)
				else
					self.display:set_display(self.mode .. form_speed)
				end
			end
		end,
		inc_lock_speed= function(self, mode, speed)
			if mode == "x" then
				return (math.round((speed * 100) * speed_inc_base_recip) * speed_inc_base) * .01
			else
				return math.round(speed * speed_inc_base_recip) * speed_inc_base
			end
		end,
		set_mode_data_work= function(self, new_mode)
			local function get_song_speed()
				--Trace("Speed pn: " .. tostring(self.player_number))
				local bpms= steps_get_bpms(gamestate_get_curr_steps(self.player_number), gamestate_get_curr_song())
				return bpms[2] or bpms[1]
			end
			if new_mode == "x" then
				-- You might think this is redundant, because "of course the current mode isn't x", but set_mode_data_work is also used in initializing.
				if self.mode and self.mode ~= "x" then
					self.current_speed= self.current_speed / get_song_speed()
					self.current_speed= self:inc_lock_speed("x", self.current_speed)
				end
			else
				if self.mode == "x" then
					self.current_speed= self.current_speed * get_song_speed()
					self.current_speed= self:inc_lock_speed("m", self.current_speed)
				end
			end
			local bi= 1
			if new_mode == "x" then
				bi= speed_inc_base * .01
			else
				bi= speed_inc_base
			end
			self:update_el_text(2, "+" .. (bi * 4))
			self:update_el_text(3, "+" .. (bi))
			self:update_el_text(4, "" .. (bi * -1))
			self:update_el_text(5, "" .. (bi * -4))
			self.mode= new_mode
			self:update_speed_text()
		end,
		set_mode= function(self, new_mode)
			if new_mode == self.mode then return end
			if not new_mode then
				Trace("options_sets.speed.set_mode:  Attempted to set nil mode")
				return
			end
			if new_mode ~= "m" and new_mode ~= "x" and new_mode ~= "C"
			and new_mode ~= "CX" and new_mode ~= "D" then
				Trace("options_sets.speed.set_mode:  Attempted to set invalid mode " .. new_mode)
				return
			end
			self:set_mode_data_work(new_mode)
			self:set_player_speed_info()
			--Trace(self.player_number .. " speed info:")
			--rec_print_table(cons_players[self.player_number].speed_info)
		end,
		interpret_start= function(self)
			local cp= self.cursor_pos
			if cp == 6 then
				self:set_mode("x")
			elseif cp == 7 then
				self:set_mode("C")
			elseif cp == 8 then
				self:set_mode("m")
			elseif cp == 9 then
				self:set_mode("CX")
			elseif cp == 10 then
				self:set_mode("D")
				if not cons_players[self.player_number].dspeed then
					cons_players[self.player_number].dspeed= {min= dspeed_default_min, max= dspeed_default_max, alternate= false}
				end
				cons_players[self.player_number].dspeed.alternate= false
			elseif cp == 11 then
				self:set_mode("D")
				if not cons_players[self.player_number].dspeed then
					cons_players[self.player_number].dspeed= {min= dspeed_default_min, max= dspeed_default_max, alternate= false}
				end
				cons_players[self.player_number].dspeed.alternate= true
			elseif self.info_set[cp] then
				self.current_speed=
					self:inc_lock_speed(
						self.mode, self.current_speed + tonumber(self.info_set[cp].text))
				self:update_speed_text()
				self:set_player_speed_info()
				--Trace(self.player_number .. " speed info:")
				--rec_print_table(cons_players[self.player_number].speed_info)
			end
			return true
		end,
}}

options_sets.assorted_bools= {
	__index= {
		initialize= function(self, player_number, extra)
			self.player_number= player_number
			self.name= extra.name
			self.info_set= {up_element()}
			self.ops= self.ops or {}
			for i, op in ipairs(extra.ops) do
				local opsind= #self.ops+1
				self.ops[opsind]= op
				local is_set= mod_player(self.player_number, op)
				self.info_set[#self.info_set+1]= {text= op, underline= is_set}
			end
			if player_using_profile(self.player_number) then
				self.info_set[#self.info_set+1]= persist_element()
				self.info_set[#self.info_set+1]= unpersist_element()
			end
			self.cursor_pos= 1
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display("")
		end,
		interpret_start= function(self)
			local ops_pos= self.cursor_pos - 1
			local info= self.info_set[self.cursor_pos]
			if self.ops[ops_pos] then
				if info.underline then
					mod_player(self.player_number, self.ops[ops_pos], false)
				else
					mod_player(self.player_number, self.ops[ops_pos], true)
				end
				self:update_el_underline(self.cursor_pos, not info.underline)
				return true
			end
			if player_using_profile(self.player_number) then
				if self.cursor_pos == #self.info_set-1 then
					for i= 1, #self.ops do
						local op= self.ops[i]
						cons_players[self.player_number]:persist_mod(op, self.info_set[i+1].underline)
					end
					self:update_el_underline(self.cursor_pos, true)
					return true
				elseif self.cursor_pos == #self.info_set then
					for i= 1, #self.ops do
						local op= self.ops[i]
						cons_players[self.player_number]:unpersist_mod(op)
					end
					local persist_pos= #self.info_set-1
					self:update_el_underline(persist_pos, false)
					return true
				end
			end
			return false
		end
}}

options_sets.song_ops_bools= {
	__index= {
		initialize= function(self, player_number, extra)
			self.player_number= player_number
			self.name= extra.name
			self.info_set= {up_element()}
			self.ops= self.ops or {}
			local songops= GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
			for i, op in ipairs(extra.ops) do
				local opsind= #self.ops+1
				self.ops[opsind]= op
				local is_set= songops[op](songops)
				self.info_set[#self.info_set+1]= {text= op, underline= is_set}
			end
			self.cursor_pos= 1
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display("")
		end,
		interpret_start= function(self)
			local ops_pos= self.cursor_pos - 1
			local info= self.info_set[self.cursor_pos]
			local songops= GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
			if self.ops[ops_pos] then
				if info.underline then
					songops[self.ops[ops_pos]](songops, false)
				else
					songops[self.ops[ops_pos]](songops, true)
				end
				self:update_el_underline(self.cursor_pos, not info.underline)
				return true
			else
				return false
			end
		end
}}

options_sets.rate_mod= {
	__index= {
		initialize= function(self, player_number, extra)
			self.player_number= player_number
			self.cursor_pos= 1
			self.name= extra.name
			self.info_set= {up_element()}
			self.increments= {}
			self.current_value= rate_coordinator:get_current_rate()
			self.menu_functions= {noop_false}
			local function general_inc(pos)
				self:set_new_val(self.current_value + self.increments[pos])
				return true
			end
			for i, v in ipairs(extra.incs) do
				self.increments[i]= v
				local vt= tostring(v)
				if v > 0 then vt= "+" .. vt end
				self.info_set[#self.info_set+1]= {text= vt}
				self.menu_functions[#self.menu_functions+1]= general_inc
			end
			self.info_set[#self.info_set+1]= {text= "Reset"}
			self.menu_functions[#self.menu_functions+1]= function()
				self:set_new_val(1)
				return true
			end
			if player_using_profile(self.player_number) then
				self.persist_el_pos= #self.info_set+1
				self.info_set[self.persist_el_pos]= persist_element()
				self.menu_functions[#self.menu_functions+1]= function()
					cons_players[self.player_number]:persist_mod(
						"MusicRate", self.current_value, "song")
					self:update_el_text(
						self.persist_val_pos, persist_value_text(self.current_value))
					return true
				end
				self.info_set[#self.info_set+1]= unpersist_element()
				self.menu_functions[#self.menu_functions+1]= function()
					cons_players[self.player_number]:unpersist_mod("MusicRate", "song")
					self:update_el_text(self.persist_val_pos, persist_value_text(nil))
					return true
				end
				self.persist_val_pos= #self.info_set+1
				self.info_set[self.persist_val_pos]= persist_value_element(
					cons_players[self.player_number]:get_persist_mod_value(
						"MusicRate", "song"))
				self.menu_functions[#self.menu_functions+1]= noop_true
			end
			rate_coordinator:add_to_notify(self)
		end,
		destructor= function(self)
			rate_coordinator:remove_from_notify(self)
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display(self:get_eltext())
		end,
		interpret_start= function(self)
			if self.menu_functions[self.cursor_pos] then
				return self.menu_functions[self.cursor_pos](self.cursor_pos-1)
			end
			return false
		end,
		set_new_val= function(self, nval)
			if nval == -0 then nval= 0 end
			if self:valid_value(nval) then
				self.current_value= nval
			end
			self.display:set_display(self:get_eltext())
			self:mod_command()
			rate_coordinator:notify(self.current_value, true)
		end,
		get_eltext= function(self)
			return ("%.2fx"):format(self.current_value)
		end,
		mod_command= function(self)
			GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(self.current_value)
		end,
		valid_value= function(self, value)
			if in_edit_mode then
				if value <= 0.1 or value > 2.001 then return false end
			else
				if value <= 0.499 or value > 2.001 then return false end
			end
			if GAMESTATE:GetCoinMode() == "CoinMode_Home" then return true end
			local modified_length= get_current_song_length() / value
			return modified_length <= get_time_remaining()
		end,
		notify_of_rate_change= function(self)
			self.current_value= rate_coordinator:get_current_rate()
			self.display:set_display(self:get_eltext())
		end
}}

options_sets.steps_list= {
	__index= {
		initialize= function(self, player_number)
			self.cursor_pos= 1
			self.player_number= player_number
			self.steps_list= sort_steps_list(get_filtered_steps_list())
			if not self.steps_list or #self.steps_list < 1 then
				Trace("Could not get steps_list.")
				return
			end
			self.info_set= {up_element()}
			for i, st in ipairs(self.steps_list) do
				self.info_set[#self.info_set+1]=
					{text= self:get_steps_string(st), underline= false}
			end
			local steps= gamestate_get_curr_steps(player_number)
			if steps then
				for i, st in ipairs(self.steps_list) do
					if steps == st then
						self.player_choice= i
						self.info_set[i+1].underline= true
						break
					end
				end
			else
				Trace("GetCurrentSteps returned nil dude.")
			end
			if not self.player_choice then
				Trace("Somehow, the player hasn't picked a difficulty.")
				self.player_choice= 1
			end
		end,
		set_status= function(self)
			self.display:set_heading("Steps")
			self.display:set_display(self:get_steps_string())
		end,
		get_steps_string= function(self, steps)
			steps= steps or self.steps_list[self.player_choice]
			return steps_to_string(steps) .. " " .. steps:GetMeter()
		end,
		interpret_start= function(self)
			local spos= self.cursor_pos - 1
			local steps= self.steps_list[spos]
			if steps then
				cons_set_current_steps(self.player_number, steps)
				GAMESTATE:SetPreferredDifficulty(
					self.player_number, steps:GetDifficulty())
				set_preferred_steps_type(self.player_number, steps:GetStepsType())
				self:update_el_underline(self.player_choice+1, false)
				self.player_choice= spos
				-- Note the line above updating player_choice.
				self:update_el_underline(self.player_choice+1, true)
				return true
			else
				return false
			end
		end
}}

options_sets.noteskins= {
	__index= {
		disallow_unset= true,
		scroll_to_move_on_start= true,
		initialize= function(self, player_number)
			self.player_number= player_number
			self.cursor_pos= 1
			self.ops= NOTESKIN:GetNoteSkinNames()
			local player_noteskin= mod_player(self.player_number, "NoteSkin")
			function find_matching_noteskin()
				for ni, nv in ipairs(self.ops) do
					Trace("Noteskin found: '" .. tostring(nv) .. "'")
					if player_noteskin == nv then
						return ni
					end
				end
				return nil
			end
			self.selected_skin= find_matching_noteskin()
			self.info_set= {up_element()}
			for ni, nv in ipairs(self.ops) do
				self.info_set[#self.info_set+1]= {
					text= nv, underline= ni == self.selected_skin}
			end
		end,
		interpret_start= function(self)
			local ops_pos= self.cursor_pos - 1
			local info= self.info_set[self.cursor_pos]
			if self.ops[ops_pos] then
				for i, tinfo in ipairs(self.info_set) do
					if i ~= self.cursor_pos and tinfo.underline then
						self:update_el_underline(i, false)
					end
				end
				local prev_note, succeeded= mod_player(self.player_number, "NoteSkin", self.ops[ops_pos])
				if not succeeded then
					Trace("Failed to set noteskin '" .. tostring(self.ops[ops_pos]) .. "'.  Leaving noteskin setting at '" .. prev_note .. "'")
				end
				self:update_el_underline(self.cursor_pos, true)
				self:set_status()
				return true
			else
				return false
			end
		end,
		set_status= function(self)
			self.display:set_heading("Noteskin")
			self.display:set_display(mod_player(self.player_number, "NoteSkin"))
		end
}}

dofile(THEME:GetPathO("", "tags_menu.lua"))

set_option_set_metatables()

local function generic_fake_judge_element(judge_name)
	return {name= judge_name, init= check_fake_judge(judge_name),
					set= set_fake_judge(judge_name), unset= unset_fake_judge}
end

local function generic_mine_effect_element(name)
	return {name= name, init= check_mine_effect(name),
					set= set_mine_effect(name), unset= unset_mine_effect}
end

local function extra_for_adj_float_mod(mod_name, is_angle)
	return {
		name= mod_name,
		can_persist= true,
		min_scale= -4,
		scale= -1,
		max_scale= 1,
		is_angle= is_angle,
		initial_value= function(player_number)
			return mod_player(player_number, mod_name)
		end,
		set= function(player_number, value)
			mod_player(player_number, mod_name, value)
		end,
		scale_to_text= function(player_number, value)
			if cons_players[player_number].flags.interface.straight_floats then
				return value
			else
				return value * 100
			end
		end,
		val_to_text= function(player_number, value)
			if cons_players[player_number].flags.interface.straight_floats then
				if value == -0 then return "0" end
				return tostring(value)
			else
				if value == -0 then return "0%" end
				return (value * 100) .. "%"
			end
		end
	}
end

local function extra_for_dspeed_min(name)
	local receptor_min= THEME:GetMetric("Player", "ReceptorArrowsYStandard")
	local receptor_max= THEME:GetMetric("Player", "ReceptorArrowsYReverse")
	local arrow_height= THEME:GetMetric("ArrowEffects", "ArrowSpacing")
	local field_height= receptor_max - receptor_min
	local center_effect_size= field_height / 2
	return {
		name= name,
		min_scale= -4,
		scale= -1,
		max_scale= 1,
		reset_value= (SCREEN_CENTER_Y + receptor_min) / -center_effect_size,
		initial_value= function(player_number)
			return cons_players[player_number].dspeed.min
		end,
		set= function(player_number, value)
			cons_players[player_number].dspeed.min= value
		end,
	}
end

local function extra_for_dspeed_max(name)
	local receptor_min= THEME:GetMetric("Player", "ReceptorArrowsYStandard")
	local receptor_max= THEME:GetMetric("Player", "ReceptorArrowsYReverse")
	local arrow_height= THEME:GetMetric("ArrowEffects", "ArrowSpacing")
	local field_height= receptor_max - receptor_min
	local center_effect_size= field_height / 2
	return {
		name= name,
		min_scale= -4,
		scale= -1,
		max_scale= 1,
		reset_value= (SCREEN_CENTER_Y + receptor_max) / center_effect_size,
		initial_value= function(player_number)
			return cons_players[player_number].dspeed.max
		end,
		set= function(player_number, value)
			cons_players[player_number].dspeed.max= value
		end,
	}
end

local function extra_for_sigil_detail()
	return {
		name= "Sigil Detail",
		min_scale= 0,
		scale= 0,
		max_scale= 1,
		initial_value= function(player_number)
			return cons_players[player_number].sigil_data.detail
		end,
		validator= function(value)
			return value >= 1 and value <= 32
		end,
		set= function(player_number, value)
			cons_players[player_number].sigil_data.detail= value
		end,
	}
end

local function player_conf_float(
		disp_name, field_name, level, mins, scal, maxs, minv, maxv)
	return {
		name= disp_name, meta= options_sets.adjustable_float, level= level,
		args= {
			can_persist= persist, persist_type= persist, persist_name= field_name,
			name= disp_name, min_scale= mins, scale= scal, max_scale= maxs,
			initial_value= function(pn)
				return get_element_by_path(cons_players[pn], field_name) or 0
			end,
			validator= function(value)
				return gte_nil(value, minv) and lte_nil(value, maxv)
			end,
			set= function(pn, value)
				set_element_by_path(cons_players[pn], field_name, value)
			end
	}}
end

local function player_cons_mod(
		disp_name, field_name, level, mins, scal, maxs, minv, maxv, persist)
	return {
		name= disp_name, meta= options_sets.adjustable_float, level= level,
		args= {
			can_persist= persist, persist_type= persist, persist_name= field_name,
			name= disp_name, min_scale= mins, scale= scal, max_scale= maxs,
			initial_value= function(pn)
				return get_element_by_path(cons_players[pn], field_name) or 0
			end,
			validator= function(value)
				return gte_nil(value, minv) and lte_nil(value, maxv)
			end,
			set= function(pn, value)
				cons_players[pn]:set_cons_mod(field_name, value)
			end
	}}
end

local function extra_for_lives()
	return {
		name= "Battery Lives",
		min_scale= 0,
		scale= 0,
		max_scale= 4,
		can_persist= true,
		initial_value= function(player_number)
			return mod_player(player_number, "BatteryLives")
		end,
		validator= function(value)
			return value >= 1
		end,
		set= function(player_number, value)
			mod_player(player_number, "BatteryLives", value)
		end
	}
end

local function extra_for_haste()
	return {
		name= "Haste",
		min_scale= -2,
		scale= 0,
		max_scale= 0,
		can_persist= true, persist_type= "song",
		initial_value= function(player_number)
			return GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):Haste()
		end,
		validator= function(value)
			return value >= -1 and value <= 1
		end,
		set= function(player_number, value)
			GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):Haste(value)
		end
	}
end

local function extra_for_bg_bright()
	return {
		name= "BG Brightness",
		min_scale= -2, scale= -1, max_scale= 0,
		initial_value= function(pn)
			return PREFSMAN:GetPreference("BGBrightness")
		end,
		validator= function(value)
			return value >= 0 and value <= 1
		end,
		set= function(pn, value)
			PREFSMAN:SetPreference("BGBrightness", value)
		end
	}
end

local function extra_for_agen_arg(arg)
	return {
		name= "Autogen Arg " .. arg,
		min_scale= -2, scale= -1, max_scale= 0,
		initial_value= function(pn)
			return GAMESTATE:GetAutoGenFarg(arg)
		end,
		set= function(pn, value)
			GAMESTATE:SetAutoGenFarg(arg, value)
		end
	}
end

local function make_profile_float_extra(func_name)
	return {
		name= func_name,
		min_scale= 0,
		scale= 0,
		max_scale= 3,
		initial_value= function(pn)
			if profiles[pn] then
				return profiles[pn]["Get"..func_name](profiles[pn])
			end
			return 0
		end,
		set= function(pn, val)
			if profiles[pn] then
				profiles[pn]["Set"..func_name](profiles[pn], val)
			end
		end,
		validator= function(val)
			return val >= 0
		end
	}
end

local function make_profile_bool_extra(name, true_text, false_text, func_name)
	return {
		true_text= true_text, false_text= false_text,
		get= function(pn)
			if profiles[pn] then
				return profiles[pn]["Get"..func_name](profiles[pn])
			end
			return false
		end,
		set= function(pn, val)
			if profiles[pn] then
				profiles[pn]["Set"..func_name](profiles[pn], val)
			end
		end
	}
end

local function make_menu_of_float_set(float_set, is_angle)
	local margs= {}
	for i, fl in ipairs(float_set) do
		margs[#margs+1]= {
			name= fl, meta= options_sets.adjustable_float,
			args= extra_for_adj_float_mod(fl, is_angle)
		}
	end
	return margs
end

local function ass_bools(name, bool_names)
	return {
		name= name, meta= options_sets.assorted_bools, args= {ops= bool_names}}
end

local function song_bools(name, bool_names)
	return {
		name= name, meta= options_sets.song_ops_bools, args= {ops= bool_names}}
end

local function pops_get(pn)
	return GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
end

local function player_enum(name, enum, func_name)
	-- We need to inform GameState if we set the fail type so it doesn't
	-- override it with the beginner/easy preferences.
	local function set_wrapper(obj, val)
		GAMESTATE:SetFailTypeExplicitlySet()
		PlayerOptions[func_name](obj, val)
	end
	local set= PlayerOptions[func_name]
	if func_name == "FailSetting" then
		set= set_wrapper
	end
	return {
		name= name, meta= options_sets.enum_option, args= {
			can_persist= true, persist_name= func_name,
			get= PlayerOptions[func_name], set= set,
			enum= enum, obj_get= pops_get }}
end

local function song_enum(name, enum, func_name)
	return {
		name= name, meta= options_sets.enum_option, args= {
			can_persist= true, persist_name= func_name, persist_type= "song",
			get= SongOptions[func_name], set= SongOptions[func_name], enum= enum,
			obj_get= function() return GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred") end }}
end

local args= {}
local menus= {}
local frames= {}
local color_manips= {}
local color_manip_x= (sect_width * .5) + 48
local color_manip_y= 100 + (line_height * 3)
local menu_y= 0
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
		bpm:create_actors("bpm", pn, sect_width/2, line_height*1.5),
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

local in_color_manip= {}
local color_manip_targets= {}

local function refit_cursor_to_color_manip(pn)
	local fit= color_manips[pn]:get_cursor_fit()
	fit[2]= fit[2] - menu_y
	menus[pn]:refit_cursor(fit)
end

local function color_manip_extern(params, pn)
	in_color_manip[pn]= true
	local target_color= get_element_by_path(cons_players[pn], params.path)
	color_manip_targets[pn]= target_color
	color_manips[pn]:initialize(params.name, target_color)
	color_manips[pn]:unhide()
	menus[pn]:hide_disp()
end

local function color_manip_deextern(pn)
	in_color_manip[pn]= false
	for i= 1, 4 do
		color_manip_targets[pn][i]= color_manips[pn].example_color[i]
	end
	color_manips[pn]:hide()
	menus[pn]:exit_external_mode()
	menus[pn]:update_cursor_pos()
end

local function color_manip_option(color_name, color_path)
	return {
		name= color_name, meta= "external_interface", extern= color_manip_extern,
		args= {name= color_name, path= color_path}}
end

local mine_effect_eles= {}
for i, name in ipairs(sorted_mine_effect_names) do
	mine_effect_eles[#mine_effect_eles+1]=
		generic_mine_effect_element(name)
end

local boost_mods= {
	"Boost", "Brake", "Wave", "Expand", "Boomerang",
}

local hidden_mods= {
	"Hidden", "HiddenOffset", "Sudden", "SuddenOffset",
}

local perspective_mods= {
	"Incoming", "Space", "Hallway", "Distant", "Skew", "Tilt"
}

local sickness_mods= {
	 "Beat", "Bumpy","Drunk", "Tipsy", "Tornado",
}

local size_mods= {
	"Mini", "Tiny",
}

local spin_mods= {
	"Confusion", "Dizzy", "Roll", "Twirl",
}

local target_mods= {
	"Reverse", "Alternate", "Centered", "Cross", "Flip", "Invert", "Split",
	"Xmode", "Blind", "Dark",
}

local visibility_mods= {
	"Blink", "RandomVanish", "Stealth", "Cover"
	-- "PlayerAutoPlay", "Passmark", TODO?  Add support for these mods.
}

local floaty_mods= {
	{ name= "Boost", meta= options_sets.menu,
		args= make_menu_of_float_set(boost_mods) },
	{ name= "Hidden", meta= options_sets.menu,
		args= make_menu_of_float_set(hidden_mods) },
	{ name= "Sickness", meta= options_sets.menu,
		args= make_menu_of_float_set(sickness_mods) },
	{ name= "Size", meta= options_sets.menu,
		args= make_menu_of_float_set(size_mods) },
	{ name= "Spin", meta= options_sets.menu,
		args= make_menu_of_float_set(spin_mods, true) },
	{ name= "Target", meta= options_sets.menu,
		args= make_menu_of_float_set(target_mods) },
	{ name= "Visibility", meta= options_sets.menu,
		args= make_menu_of_float_set(visibility_mods) },
	player_cons_mod("Side Swap", "side_swap", 5, -2, 0, 0, nil, nil, "cons"),
	player_cons_mod("Chuunibyou", "chuunibyou", 4, -2, 0, 4, nil, nil, "cons"),
	player_cons_mod("Confidence Shaker", "confidence", 4, 0, 0, 2, 0, 100, "cons"),
	player_cons_mod("Column Angle", "column_angle", 4, 0, 0, 2, nil, nil, "cons"),
	player_conf_float("Toasty Level", "toasty_level", 4, 0, 0, 0, 1, 16),
}

local function make_x_y_s_for_set(layout_options, set)
	for i, info in ipairs(set) do
		local gepi= "gameplay_element_positions."..info[2]
		table.insert(layout_options, player_conf_float(info[1].." X",
			gepi.."_xoffset", 1, 0, 1, 2, nil, nil))
		table.insert(layout_options, player_conf_float(info[1].." Y",
			gepi.."_yoffset", 1, 0, 1, 2, nil, nil))
		table.insert(layout_options, player_conf_float(info[1].." Scale",
			gepi.."_scale", 1, -2, -1, 0, nil, nil))
	end
end

local gameplay_layout= {
	player_conf_float("Notefield X",
		"gameplay_element_positions.notefield_xoffset", 1, 0, 1, 2, nil, nil),
	player_conf_float("Notefield Y",
		"gameplay_element_positions.notefield_yoffset", 1, 0, 1, 2, nil, nil),
}
make_x_y_s_for_set(
	gameplay_layout, {
		{"Judgment", "judgment"}, {"Combo", "combo"}, {"Error Bar", "error_bar"},
		{"Judge List", "judge_list"}, {"BPM", "bpm"}, {"Sigil", "sigil"},
		{"Score", "score"}, {"Chart Info", "chart_info"}})

local gameplay_colors= {
	color_manip_option("Filter", "gameplay_element_colors.filter"),
	color_manip_option("Life Full Outer", "gameplay_element_colors.life_full_outer"),
	color_manip_option("Life Full Inner", "gameplay_element_colors.life_full_inner"),
	color_manip_option("Life Empty Outer", "gameplay_element_colors.life_empty_outer"),
	color_manip_option("Life Empty Inner", "gameplay_element_colors.life_empty_inner"),
}

local chart_mods= {
	ass_bools("Turn", {"Mirror", "Backwards", "Left", "Right",
										 "Shuffle", "SoftShuffle", "SuperShuffle"}),
	ass_bools("Inserts", {"Big", "BMRize", "Echo", "Floored", "Little",
												"Planted", "AttackMines", "Quick", "Skippy", "Stomp",
												"Twister", "Wide"}),
	ass_bools("No", {"HoldRolls", "NoJumps","NoHands","NoQuads", "NoStretch",
									 "NoLifts", "NoFakes", "NoMines"}),
}

local song_options= {
	--song_enum("Autosync", AutosyncType, "AutosyncSetting"),
	--song_enum("Sound Effect", SoundEffectType, "SoundEffectSetting"),
}

local unacceptable_options= {
	{name= "Enabled", meta= options_sets.boolean_option, args= {
		 true_text= "On", false_text= "Off",
		 get= function(pn)
			 return cons_players[pn].unacceptable_score.enabled
		 end,
		 set= function(pn, val)
			 cons_players[pn].unacceptable_score.enabled= val
	end}},
	{name= "Condition", meta= options_sets.boolean_option, args= {
		 true_text= "dance_points", false_text= "score_pct",
		 get= function(pn)
			 return cons_players[pn].unacceptable_score.condition == "dance_points"
		 end,
		 set= function(pn, val)
			 if val then
				 cons_players[pn].unacceptable_score.condition= "dance_points"
			 else
				 cons_players[pn].unacceptable_score.condition= "score_pct"
			 end
	end}},
	{name= "Value", meta= options_sets.adjustable_float, args= {
		 min_scale= -4, scale= 0, max_scale= 4,
		 initial_value= function(pn)
			 return cons_players[pn].unacceptable_score.value
		 end,
		 validator= function(value) return value >= 0 end,
		 set= function(pn, value)
			 cons_players[pn].unacceptable_score.value= value
		 end
	}},
	{name= "Reset Limit", meta= options_sets.adjustable_float, args= {
		 min_scale= 0, scale= 0, max_scale= 1,
		 initial_value= function(pn)
			 return cons_players[pn].unacceptable_score.limit
		 end,
		 validator= function(value)
			 return value >= 0 and
			 value <= misc_config:get_data().gameplay_reset_limit
		 end,
		 set= function(pn, value)
			 cons_players[pn].unacceptable_score.limit= value
		 end
	}},
}

local function player_conf_set(conf_name, conf_value)
	return {
		name= conf_value, unset= noop_nil, init= function(pn)
			return cons_players[pn][conf_name] == conf_value
		end,
		set= function(pn)
			cons_players[pn][conf_name]= conf_value
		end,
	}
end
local combo_threshold_options= {}
local combo_graph_threshold_options= {}
local error_threshold_options= {}
for i, tns in ipairs{
	"TapNoteScore_Miss", "TapNoteScore_W5", "TapNoteScore_W4",
	"TapNoteScore_W3", "TapNoteScore_W2", "TapNoteScore_W1"} do
	combo_threshold_options[#combo_threshold_options+1]=
		player_conf_set("combo_splash_threshold", tns)
	combo_graph_threshold_options[#combo_graph_threshold_options+1]=
		player_conf_set("combo_graph_threshold", tns)
	error_threshold_options[#error_threshold_options+1]=
		player_conf_set("error_history_threshold", tns)
end

local function bool_effect_setter(disp_name, demo_name)
	return {
		name= disp_name,
		init= function(pn) return cons_players[pn][demo_name] end,
		set= function(pn) cons_players[pn]:set_cons_mod(demo_name, true) end,
		unset= function(pn) cons_players[pn]:set_cons_mod(demo_name, false) end,
	}
end

local ultra_special_effects= {
	eles= {
		{ name= "Distortion", init= function() return global_distortion_mode end,
			set= function() global_distortion_mode= true end,
			unset= function() global_distortion_mode= false end},
		{ name= "Permfetti", init= function() return get_confetti("perm") end,
			set= function() activate_confetti("perm", true) end,
			unset= function() activate_confetti("perm", false) end},
		{ name= "April Fools", init= function() return april_fools end,
			set= function() april_fools= true end,
			unset= function() april_fools= false end},
}}

local special_effects= {
	eles= {
		{ name= "Confetti", init= function() return get_confetti("credit") end,
			set= function() activate_confetti("credit", true) end,
			unset= function() activate_confetti("credit", false) end},
		{ name= "Scrambler", init= function() return scrambler_mode end,
			set= function() scrambler_mode= true end,
			unset= function() scrambler_mode= false end},
		{ name= "Input Tilt", init= function() return tilt_mode end,
			set= function() tilt_mode= true end,
			unset= function() tilt_mode= false end},
		bool_effect_setter("Spatial Arrows", "spatial_arrows"),
		bool_effect_setter("Spatial Turning", "spatial_turning"),
		bool_effect_setter("Let's Have Fun!", "man_lets_have_fun"),
}}

local function sorting_options()
	local ret= {}
	for i, item in ipairs(bucket_man:get_sort_names_for_menu()) do
		ret[#ret+1]= {
			name= item, init= function(pn)
				return cons_players[pn].preferred_sort == item
			end, set= function(pn) cons_players[pn].preferred_sort= item end,
			unset= function(pn) cons_players[pn].preferred_sort= nil end,
		}
	end
	return {eles= ret}
end

local special= {
	{ name= "Preferred Sort", args= sorting_options(),
		meta= options_sets.mutually_exclusive_special_functions, level= 4},
	{ name= "Spline Demos", meta= options_sets.special_functions, level= 4,
		args= {
			eles= {
				bool_effect_setter("Position", "pos_splines_demo"),
				bool_effect_setter("Rotation", "rot_splines_demo"),
				bool_effect_setter("Zoom", "zoom_splines_demo"),
	}}},
	{ name= "Tokubetsu Effects", meta= options_sets.special_functions, level= 5,
		args= ultra_special_effects},
	{ name= "Effects", meta= options_sets.special_functions, level= 4,
		args= special_effects},
	{ name= "Go To Select Music" ,meta= "execute", level= 4,
		execute= function()
			SOUND:PlayOnce(THEME:GetPathS("Common", "cancel"))
			trans_new_screen("ScreenConsSelectMusic")
		end, unset= noop_nil},
	{ name= "Unacceptable Score", meta= options_sets.menu, args= unacceptable_options, level= 4},
	{ name= "Judgement", meta= options_sets.mutually_exclusive_special_functions, level= 4,
		args= {eles= {
						 generic_fake_judge_element("Random"),
						 generic_fake_judge_element("TapNoteScore_Miss"),
						 generic_fake_judge_element("TapNoteScore_W5"),
						 generic_fake_judge_element("TapNoteScore_W4"),
						 generic_fake_judge_element("TapNoteScore_W3"),
						 generic_fake_judge_element("TapNoteScore_W2"),
						 generic_fake_judge_element("TapNoteScore_W1"),
			 }}},
	player_enum("MinTNSToHideNotes", TapNoteScore, "MinTNSToHideNotes"),
	{ name= "BG Brightness", meta= options_sets.adjustable_float, level= 2,
		args= extra_for_bg_bright()},
	{ name= "Mine Effects", level= 3,
		meta= options_sets.mutually_exclusive_special_functions,
		args= { eles= mine_effect_eles }},
	song_bools("Assist", {"AssistClap", "AssistMetronome", "SaveScore", }),
--	{ name= "Song Options", meta= options_sets.menu, args= song_options},
	{ name= "Driven Min", meta= options_sets.adjustable_float, level= 4,
		args= extra_for_dspeed_min("Driven Min")},
	{ name= "Driven Max", meta= options_sets.adjustable_float, level= 4,
		args= extra_for_dspeed_max("Driven Max")},
	player_conf_float("Options Level", "options_level", 1, 0, 0, 0, 1, 4),
	player_conf_float("Rating Cap", "rating_cap", 2, 0, 0, 1, nil, nil),
	{ name= "Kick Recover Time", meta= options_sets.adjustable_float, level= 4,
		args= extra_for_agen_arg(1), req_func= function()
			if GAMESTATE.GetAutoGenFarg
			and GAMESTATE:GetCurrentGame():GetName():lower() == "kickbox" then
				return true end return false end},
	-- TODO?  Add support for these?
	--"StaticBackground", "RandomBGOnly", "SaveReplay" }),
}

local eval_flag_eles= {}
for i, fname in ipairs(sorted_eval_flag_names) do
	eval_flag_eles[i]= generic_flag_control_element("eval", fname)
end
local gameplay_flag_eles= {}
for i, fname in ipairs(sorted_gameplay_flag_names) do
	gameplay_flag_eles[i]= generic_flag_control_element("gameplay", fname)
end
local interface_flag_eles= {}
for i, fname in ipairs(sorted_interface_flag_names) do
	interface_flag_eles[i]= generic_flag_control_element("interface", fname)
end

local playback_options= {
	{ name= "Rate", meta= options_sets.rate_mod,
		args= { default_value= 1, incs= {.1, .01, -.01, -.1}}},
	{ name= "Haste", meta= options_sets.adjustable_float,
		args= extra_for_haste()},
}

local decorations= {
	{ name= "Gameplay Layout", meta= options_sets.menu, args= gameplay_layout},
	{ name= "Gameplay Colors", meta= options_sets.menu, args= gameplay_colors},
	{ name= "Evaluation Flags", meta= options_sets.special_functions,
		args= { eles= eval_flag_eles}},
	{ name= "Gameplay Flags", meta= options_sets.special_functions,
		args= { eles= gameplay_flag_eles}},
	{ name= "Interface Flags", meta= options_sets.special_functions,
		args= { eles= interface_flag_eles}},
	{ name= "Combo Splash Threshold", meta= options_sets.mutually_exclusive_special_functions,
		args= {eles= combo_threshold_options, disallow_unset= true}},
	{ name= "Combo Graph Threshold", meta= options_sets.mutually_exclusive_special_functions,
		args= {eles= combo_graph_threshold_options, disallow_unset= true}},
	{ name= "Error History Threshold", meta= options_sets.mutually_exclusive_special_functions,
		args= {eles= error_threshold_options, disallow_unset= true}},
	player_conf_float("Error History Size", "error_history_size", 4, 0, 1, 2, 0, 512),
	player_conf_float("Low Score Random Threshold",
										"low_score_random_threshold", 3, -4, -2, -1, 0, 1),
	player_conf_float("Life Blank Area", "life_blank_percent", 3, -2, -1, 0, -1, 2),
	player_conf_float("Life Use Width", "life_use_width", 3, -2, -1, 0, -1, 2),
	{ name= "Sigil Detail", meta= options_sets.adjustable_float,
		args= extra_for_sigil_detail()},
	{ name= "Noteskin", meta= options_sets.noteskins},
}

local profile_options= {
	{ name= "Weight", meta= options_sets.adjustable_float,
	  args= make_profile_float_extra("WeightPounds")},
	{ name= "Voomax", meta= options_sets.adjustable_float,
	  args= make_profile_float_extra("Voomax")},
	{ name= "Birth Year", meta= options_sets.adjustable_float,
	  args= make_profile_float_extra("BirthYear")},
	{ name= "Calorie Method", meta= options_sets.boolean_option,
		args= make_profile_bool_extra(
			"Calorie Method","Heart Rate","Step Count","IgnoreStepCountCalories")},
	{ name= "Gender", meta= options_sets.boolean_option,
		args= make_profile_bool_extra("Gender", "Male", "Female", "IsMale")},
}

local life_options= {
	player_enum("Life", LifeType, "LifeSetting"),
	player_enum("Drain", DrainType, "DrainSetting"),
	player_enum("Fail", FailType, "FailSetting"),
	{ name= "Battery Lives", meta= options_sets.adjustable_float,
		args= extra_for_lives()},
}

local base_options= {
	{ name= "Speed", meta= options_sets.speed, level= 1},
	{ name= "Perspective", meta= options_sets.menu,
		args= make_menu_of_float_set(perspective_mods), level= 1},
	{ name= "Playback Options", meta= options_sets.menu, args= playback_options,
		level= 3},
	{ name= "Steps", meta= options_sets.steps_list, level= 1},
	{ name= "Noteskin", meta= options_sets.noteskins, level= -1},
	player_conf_float("Options Level", "options_level", -1, 0, 0, 0, 1, 4),
	player_conf_float("Rating Cap", "rating_cap", -1, 0, 0, 1, nil, nil),
	{ name= "Decorations", meta= options_sets.menu, args= decorations, level= 2},
	{ name= "Special", meta= options_sets.menu, args= special, level= 2},
	{ name= "Profile Options", meta= options_sets.menu, args= profile_options,
		level= 1, req_func= player_using_profile},
	{ name= "Life Options", meta= options_sets.menu, args= life_options,
		level= 4},
	{ name= "Song tags", meta= options_sets.tags_menu, args= true, level= 4},
	{ name= "Chart mods", meta= options_sets.menu, args= chart_mods, level= 2},
	{ name= "Floaty mods", meta= options_sets.menu, args= floaty_mods, level= 2},
	{ name= "Reset Mods", meta= "execute", level= 1,
		execute= function(pn) cons_players[pn]:reset_to_persistent_mods() end,},
}

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
	if in_color_manip[pn] then
		color_manips[pn]:interpret_code(code)
		if color_manips[pn].done then
			color_manip_deextern(pn)
		else
			refit_cursor_to_color_manip(pn)
		end
	elseif menus[pn] then
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
		if in_color_manip[pn] then
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
