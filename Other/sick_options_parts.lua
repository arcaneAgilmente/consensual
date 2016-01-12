bpm_disp_mt= {
	__index= {
		create_actors= function(self, name, player_number, x, y, width)
			self.name= name
			self.player_number= player_number
			local args= {
				Name=name, InitCommand= function(subself)
					self.container= subself
					self.text= subself:GetChild("bpm")
					self.text:maxwidth(width-16)
					subself:xy(x, y)
					self:bpm_text()
				end,
				rate_changedMessageCommand= function(subself)
					self:bpm_text()
				end,
				player_flags_changedMessageCommand= function(subself)
					self:bpm_text()
				end,
				normal_text("bpm", "", fetch_color("text"), fetch_color("stroke"))
			}
			return Def.ActorFrame(args)
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end,
		bpm_text= function(self)
			-- TODO:  Find a way to call bpm_text when verbose_bpm changes.
			local steps= gamestate_get_curr_steps(self.player_number)
			local song= gamestate_get_curr_song()
			if steps and song then
				local bpms= steps_get_bpms(steps, song)
				local curr_rate= get_rate_from_songopts()
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
}}

function get_sick_options(rate_coordinator, color_manips, bpm_disps)

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

-- The current rate is a leftover from the previous song.  It might slow the
-- current song down enough to go over the time limit.  So it needs to be
-- adjusted to bring the song within that limit.
if GAMESTATE:GetCoinMode() ~= "CoinMode_Home" then
	local remain= get_time_remaining()
	local song_len= get_current_song_length()
	local rate= get_rate_from_songopts()
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
		if value then
			mod_func(cons_players[pn].song_options, value)
			mod_func(cons_players[pn].current_options, value)
		end
		return mod_func(cons_players[pn].preferred_options, value)
	else
		Warn("mod '" .. tostring(mod_name) .. "' does not exist.")
	end
end

local profiles= {}
for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	profiles[pn]= PROFILEMAN:GetProfile(pn)
end

local speed_inc_base= 25
local speed_inc_base_recip= 1/speed_inc_base
local speed_large_mult= 4

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
			MESSAGEMAN:Broadcast("entered_gameplay_config", {pn= player_number})
		end,
		destructor= function(self, pn)
			MESSAGEMAN:Broadcast("exited_gameplay_config", {pn= pn})
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
			MESSAGEMAN:Broadcast("gameplay_conf_changed", {pn= self.player_number, thing= "notefield"})
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
			self:update_el_text(2, "+" .. (bi * speed_large_mult))
			self:update_el_text(3, "+" .. (bi))
			self:update_el_text(4, "" .. (bi * -1))
			self:update_el_text(5, "" .. (bi * -speed_large_mult))
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
			self.current_value= get_rate_from_songopts()
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
			self.ops= filter_noteskin_list_with_shown_config(
				player_number, NOTESKIN:GetNoteSkinNames())
			local player_noteskin= mod_player(self.player_number, "NoteSkin")
			local function find_matching_noteskin()
				for ni, nv in ipairs(self.ops) do
					--Trace("Noteskin found: '" .. tostring(nv) .. "'")
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

options_sets.newskins= {
	__index= {
		disallow_unset= true,
		scroll_to_move_on_start= true,
		initialize= function(self, pn)
			self.player_number= pn
			self.cursor_pos= 1
			self.stepstype= find_current_stepstype(pn)
			self.ops= filter_noteskin_list_with_shown_config(
				pn, NEWSKIN:get_skin_names_for_stepstype(self.stepstype))
			self.player_skin= profiles[pn]:get_preferred_noteskin(self.stepstype)
			local function find_matching_newskin()
				for ni, nv in ipairs(self.ops) do
					--Trace("Noteskin found: '" .. tostring(nv) .. "'")
					if self.player_skin == nv then
						return ni
					end
				end
				return nil
			end
			self.selected_skin= find_matching_newskin()
			self.info_set= {up_element()}
			for ni, nv in ipairs(self.ops) do
				self.info_set[#self.info_set+1]= {
					text= nv, underline= ni == self.selected_skin}
			end
			MESSAGEMAN:Broadcast("entered_gameplay_config", {pn= pn})
		end,
		destructor= function(self, pn)
			MESSAGEMAN:Broadcast("exited_gameplay_config", {pn= pn})
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
				self.player_skin= self.ops[ops_pos]
				mod_player(self.player_number, "NewSkin", self.player_skin)
				profiles[self.player_number]:set_preferred_noteskin(self.stepstype, self.player_skin)
				self:update_el_underline(self.cursor_pos, true)
				self:set_status()
				MESSAGEMAN:Broadcast("gameplay_conf_changed", {pn= self.player_number, thing= "noteskin"})
				return true
			else
				return false
			end
		end,
		set_status= function(self)
			self.display:set_heading("Newskin")
			self.display:set_display(self.player_skin)
		end
}}

local function get_noteskin_param_translation(param_name, type_info)
	local translation_table= type_info.translation
	local ret= {title= param_name, explanation= param_name}
	if type(translation_table) == "table" then
		local language= PREFSMAN:GetPreference("Language")
		if translation_table[language] then
			ret= translation_table[language]
		else
			local base_language= "en"
			if translation_table[base_language] then
				ret= translation_table[base_language]
			else
				local lang, text= next(translation_table)
				if text then ret= text end
			end
		end
	end
	if type_info.choices and not ret.choices then
		ret.choices= type_info.choices
	end
	return ret
end
local function int_val_text(pn, val)
	return ("%d"):format(val)
end
local function float_val_text(pn, val)
	return ("%.2f"):format(val)
end
local function noteskin_param_float_val(param_name, param_section, type_info)
	local min_scale= 0
	local max_scale= 0
	local val_text= int_val_text
	if type_info.type ~= "int" then
		min_scale= -2
		val_text= float_val_text
	end
	local val_min= type_info.min
	local val_max= type_info.max
	if type_info.max then
		max_scale= math.floor(math.log(type_info.max) / math.log(10))
	else
		max_scale= 2
	end
	local translation= get_noteskin_param_translation(param_name, type_info)
	return {
		name= translation.title, meta= options_sets.adjustable_float, args= {
			name= translation.title, min_scale= min_scale, scale= 0,
			max_scale= max_scale, initial_value= function()
				return param_section[param_name]
			end,
			set= function(pn, value) param_section[param_name]= value end,
			val_to_text= val_to_text, val_min= val_min, val_max= val_max,
	}}
end
local function noteskin_param_choice_val(param_name, param_section, type_info)
	local eles= {}
	local translation= get_noteskin_param_translation(param_name, type_info)
	for i, choice in ipairs(type_info.choices) do
		eles[#eles+1]= {
			name= translation.choices[i], init= function(pn)
				return param_section[param_name] == choice
			end,
			set= function(pn)
				param_section[param_name]= choice
			end,
			unset= noop_nil,
		}
	end
	return {name= translation.title, args= {eles= eles, disallow_unset= true},
					meta= options_sets.mutually_exclusive_special_functions}
end
local function noteskin_param_bool_val(param_name, param_section, type_info)
	local translation= get_noteskin_param_translation(param_name, type_info)
	local eles= {}
	for i, val in ipairs{true, false} do
		eles[#eles+1]= {
			name= tostring(val), init= function(pn)
				return param_section[param_name] == val
			end,
			set= function(pn) param_section[param_name]= val end, unset= noop_nil}
	end
	return {name= translation.title, args= {eles= eles, disallow_unset= true},
					meta= options_sets.mutually_exclusive_special_functions}
end
local function gen_noteskin_param_submenu(pn, param_section, type_info, skin_defaults, add_to)
	for field, info in pairs(type_info) do
		if field ~= "translation" then
			local field_type= type(skin_defaults[field])
			local translation= get_noteskin_param_translation(field, type_info[field])
			local submenu= {name= translation.title}
			if not param_section[field] then
				if field_type == "table" then
					param_section[field]= DeepCopy(skin_defaults[field])
				else
					param_section[field]= skin_defaults[field]
				end
			end
			if field_type == "table" then
				submenu.meta= options_sets.menu
				local menu_args= {}
				gen_noteskin_param_submenu(pn, param_section[field], info, skin_defaults[field], menu_args)
				submenu.args= menu_args
			elseif field_type == "string" then
				if info.choices then
					submenu= noteskin_param_choice_val(field, param_section, info)
				else
					submenu= nil
				end
			elseif field_type == "number" then
				if info.choices then
					submenu= noteskin_param_choice_val(field, param_section, info)
				else
					submenu= noteskin_param_float_val(field, param_section, info)
				end
			elseif field_type == "boolean" then
				submenu= noteskin_param_bool_val(field, param_section, info)
			end
			add_to[#add_to+1]= submenu
		end
	end
	local function submenu_cmp(a, b)
		return a.name < b.name
	end
	table.sort(add_to, submenu_cmp)
end
local function gen_noteskin_param_menu(pn)
	local stepstype= find_current_stepstype(pn)
	local player_skin= profiles[pn]:get_preferred_noteskin(stepstype)
	local skin_info= NEWSKIN:get_skin_parameter_info(player_skin)
	local skin_defaults= NEWSKIN:get_skin_parameter_defaults(player_skin)
	local player_params= profiles[pn]:get_noteskin_params(player_skin, stepstype)
	if not player_params then
		player_params= {}
		profiles[pn]:set_noteskin_params(player_skin, stepstype, player_params)
	end
	local ret= {
		recall_init_on_pop= true,
		name= "noteskin_params",
		destructor= function(self, pn)
			MESSAGEMAN:Broadcast("gameplay_conf_changed", {pn= pn, thing= "noteskin"})
		end,
	}
	gen_noteskin_param_submenu(pn, player_params, skin_info, skin_defaults, ret)
	return ret
end
local function show_noteskin_param_menu(pn)
	if not newskin_available() then return false end
	local stepstype= find_current_stepstype(pn)
	local player_skin= profiles[pn]:get_preferred_noteskin(stepstype)
	local skin_info= NEWSKIN:get_skin_parameter_info(player_skin)
	local skin_defaults= NEWSKIN:get_skin_parameter_defaults(player_skin)
	return skin_defaults ~= nil and skin_info ~= nil
end

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
		val_min= 1, val_max= 32,
		set= function(player_number, value)
			cons_players[player_number].sigil_data.detail= value
			MESSAGEMAN:Broadcast("gameplay_conf_changed", {pn= player_number, thing= "sigil"})
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
			val_min= minv, val_max= maxv,
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
			val_min= minv, val_max= maxv,
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
		val_min= 1,
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
		val_min= -1, val_max= 1,
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
		val_min= 0, val_max= 1,
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
		val_min= 0,
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

local function player_conf_enum(name, vals)
	return {
		name= name, meta= options_sets.enum_option, args= {
			name= name, enum= vals, fake_enum= true,
			obj_get= function(pn) return cons_players[pn] end,
			get= function(cp) return cp[name] end,
			set= function(cp, value) cp[name]= value end,
	}}
end

local function song_enum(name, enum, func_name)
	return {
		name= name, meta= options_sets.enum_option, args= {
			can_persist= true, persist_name= func_name, persist_type= "song",
			get= SongOptions[func_name], set= SongOptions[func_name], enum= enum,
			obj_get= function() return GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred") end }}
end

local color_manip_targets= {}
local function color_manip_extern(menu, params, pn)
	local target_color= get_element_by_path(cons_players[pn], params.path)
	color_manip_targets[pn]= target_color
	color_manips[pn]:initialize(params.name, target_color, true, params.path, pn)
	color_manips[pn]:unhide()
	menu.external_thing= color_manips[pn]
	menu:hide_disp()
end

local function color_manip_deextern(menu, pn)
	for i= 1, 4 do
		color_manip_targets[pn][i]= color_manips[pn].example_color[i]
	end
	color_manips[pn]:hide()
	menu:update_cursor_pos()
end

local function color_manip_option(color_name, color_path)
	return {
		name= color_name, meta= "external_interface", extern= color_manip_extern,
		deextern= color_manip_deextern,
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
	"Incoming", "Space", "Hallway", "Distant", "Skew", "Tilt", "Reverse",
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
	"Alternate", "Centered", "Cross", "Flip", "Invert", "Split",
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
	player_cons_mod("Chuunibyou", "chuunibyou", 4, -2, 0, 4, nil, nil, "cons"),
	player_cons_mod("Confidence Shaker", "confidence", 4, 0, 0, 2, 0, 100, "cons"),
	player_cons_mod("Column Angle", "column_angle", 4, 0, 0, 2, nil, nil, "cons"),
	player_conf_float("Toasty Level", "toasty_level", 4, 0, 0, 0, 1, 16),
}

local function gameplay_conf_float(
		disp_name, field_name, field_thing, level, mins, scal, maxs, minv, maxv)
	local pcf= player_conf_float(disp_name, field_name, level, mins, scal, maxs, minv, maxv)
	pcf.args.set= function(pn, value)
		set_element_by_path(cons_players[pn], field_name, value)
		MESSAGEMAN:Broadcast("gameplay_conf_changed", {pn= pn, thing= field_thing})
	end
	return pcf
end

local function gameplay_conf_bool(disp_name, field_name, field_thing, level)
	return {
		name= disp_name, meta= "execute", underline= function(pn)
			return get_element_by_path(cons_players[pn], field_name)
		end,
		execute= function(pn)
			local val= get_element_by_path(cons_players[pn], field_name)
			set_element_by_path(cons_players[pn], field_name, not val)
			MESSAGEMAN:Broadcast("gameplay_conf_changed", {pn= pn, thing= field_thing})
		end,
	}
end

local function make_x_y_s_for_set(layout_options, set)
	for i, info in ipairs(set) do
		local gepi= "gameplay_element_positions."..info[2]
		table.insert(layout_options, gameplay_conf_float(info[1].." X",
			gepi.."_xoffset", info[2], 1, 0, 1, 2, nil, nil))
		table.insert(layout_options, gameplay_conf_float(info[1].." Y",
			gepi.."_yoffset", info[2], 1, 0, 1, 2, nil, nil))
		table.insert(layout_options, gameplay_conf_float(info[1].." Scale",
			gepi.."_scale", info[2], 1, -2, -1, 0, nil, nil))
	end
end

local gameplay_layout= {
	gameplay_conf_float("Notefield X",
		"gameplay_element_positions.notefield_xoffset", "notefield_pos", 1, 0, 1, 2, nil, nil),
	gameplay_conf_float("Notefield Y",
		"gameplay_element_positions.notefield_yoffset", "notefield_pos", 1, 0, 1, 2, nil, nil),
}
make_x_y_s_for_set(
	gameplay_layout, {
		{"Judgment", "judgment"}, {"Combo", "combo"}, {"Error Bar", "error_bar"},
		{"Judge List", "judge_list"}, {"BPM", "bpm"}, {"Sigil", "sigil"},
		{"Score", "score"}, {"Chart Info", "chart_info"}})

local function gen_notefield_config(pn)
	MESSAGEMAN:Broadcast("entered_gameplay_config", {pn= pn})
	return {
		name= "NoteField Config",
		destructor= function(self, pn)
			MESSAGEMAN:Broadcast("exited_gameplay_config", {pn= pn})
		end,
		gameplay_conf_float(
			"Reverse", "notefield_config.reverse", "notefield", 1, -2, 0, 2, nil, nil),
		gameplay_conf_float(
			"Field Zoom", "notefield_config.zoom", "notefield", 1, -2, -1, 2, nil, nil),
		gameplay_conf_float(
			"Note YOffset", "notefield_config.yoffset", "notefield", 1, 0, 1, 3, nil, nil),
		gameplay_conf_float(
			"Field Rotation X", "notefield_config.rot_x", "notefield", 1, 0, 1, 3, nil, nil),
		gameplay_conf_float(
			"Field Rotation Y", "notefield_config.rot_y", "notefield", 1, 0, 1, 3, nil, nil),
		gameplay_conf_float(
			"Field Rotation Z", "notefield_config.rot_z", "notefield", 1, 0, 1, 3, nil, nil),
		gameplay_conf_float(
			"Field FOV", "notefield_config.fov", "notefield", 1, 0, 1, 3, nil, nil),
		gameplay_conf_float(
			"Skew X", "notefield_config.vanish_x", "notefield", 1, 0, 1, 3, nil, nil),
		gameplay_conf_float(
			"Skew Y", "notefield_config.vanish_y", "notefield", 1, 0, 1, 3, nil, nil),
		gameplay_conf_float(
			"Field Zoom X", "notefield_config.zoom_x", "notefield", 1, -2, -1, 2, nil, nil),
		gameplay_conf_float(
			"Field Zoom Y", "notefield_config.zoom_y", "notefield", 1, -2, -1, 2, nil, nil),
		gameplay_conf_float(
			"Field Zoom Z", "notefield_config.zoom_z", "notefield", 1, -2, -1, 2, nil, nil),
		gameplay_conf_bool(
			"Use Separate Zooms", "notefield_config.use_separate_zooms", "notefield"),
	}
end

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
									 "NoLifts", "NoFakes", "NoMines", "NoRolls"}),
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
		 val_min= 0,
		 set= function(pn, value)
			 cons_players[pn].unacceptable_score.value= value
		 end
	}},
	{name= "Reset Limit", meta= options_sets.adjustable_float, args= {
		 min_scale= 0, scale= 0, max_scale= 1,
		 initial_value= function(pn)
			 return cons_players[pn].unacceptable_score.limit
		 end,
		 val_min= 0, val_max= misc_config:get_data().gameplay_reset_limit,
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
	{ name= "Effects", meta= options_sets.special_functions, level= 4,
		args= special_effects},
	{ name= "Go To Select Music" ,meta= "execute", level= 4,
		req_func= function()
			return SCREENMAN:GetTopScreen():GetName() == "ScreenSickPlayerOptions"
		end,
		execute= function()
			SOUND:PlayOnce(THEME:GetPathS("Common", "cancel"))
			trans_new_screen("ScreenConsSelectMusic")
		end, unset= noop_nil},
	player_conf_float("Pause Hold Time", "pause_hold_time", 1, -3, -1, 0, -1, 3),
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

local experimental_options= {
	float_pref_val("GlobalOffsetSeconds", 5, -6, -2, 0),
	float_pref_val("RegenComboAfterMiss", 5, 0, 0, 0),
	{ name= "Tokubetsu Effects", meta= options_sets.special_functions, level= 5,
		args= ultra_special_effects},
	player_cons_mod("Side Swap", "side_swap", 5, -2, 0, 0, nil, nil, "cons"),
}
add_timing_prefs_to_menu_choices(experimental_options)

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
	gameplay_conf_float("Life Blank Area", "life_blank_percent", "lifebar", 3, -2, -1, 0, -1, 2),
	gameplay_conf_float("Life Use Width", "life_use_width", "lifebar", 3, -2, -1, 0, -1, 2),
	gameplay_conf_float("Life Stages", "life_stages", "lifebar", 3, 0, 0, 0, 1, 16),
	{ name= "Sigil Detail", meta= options_sets.adjustable_float,
		args= extra_for_sigil_detail()},
	{ name= "Noteskin", meta= options_sets.noteskins, req_func= not_newskin_available},
	{ name= "Newskin", meta= options_sets.newskins, req_func= newskin_available},
	{ name= "Shown Noteskins", meta= options_sets.shown_noteskins, args= {}},
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
	{ name= "Experimental", meta= options_sets.menu, args= experimental_options, level= 5},
	{ name= "Speed", meta= options_sets.speed, level= 1},
	{ name= "Perspective", meta= options_sets.menu,
		req_func= not_newskin_available,
		args= make_menu_of_float_set(perspective_mods), level= 1},
	{ name= "Notefield Config", meta= options_sets.menu,
		args= gen_notefield_config, req_func= newskin_available},
	{ name= "Newskin", meta= options_sets.newskins, level= 1,
		req_func= newskin_available},
	{ name= "Newskin params", meta= options_sets.menu,
		args= gen_noteskin_param_menu, req_func= show_noteskin_param_menu},
	{ name= "Shown Noteskins", meta= options_sets.shown_noteskins, args= {}},
	{ name= "Playback Options", meta= options_sets.menu, args= playback_options,
		level= 3},
	{ name= "Steps", meta= options_sets.steps_list, level= 1},
	{ name= "Noteskin", meta= options_sets.noteskins, level= -1,
		req_func= not_newskin_available},
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
	{ name= "Floaty mods", meta= options_sets.menu, args= floaty_mods, level= 2, req_func= not_newskin_available},
	{ name= "Reset Mods", meta= "execute", level= 1,
		execute= function(pn) cons_players[pn]:reset_to_persistent_mods() end,},
}

return base_options
end
