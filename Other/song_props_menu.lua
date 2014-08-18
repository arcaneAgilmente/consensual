options_sets.song_props_menu= {
	__index= {
		initialize= function(self, player_number, have_pane_edit, have_flag_edit)
			self.player_number= player_number
			self.cursor_pos= 1
			self.have_pane_edit= have_pane_edit
			self.have_flag_edit= have_flag_edit
			self:reset_info()
		end,
		reset_info= function(self)
			self.cursor_pos= 1
			self.real_info_set= {
				{text= "Exit Props Menu"},
				{text= "Profile favorite+"}, {text= "Profile favorite-"},
				{text= "Machine favorite+"}, {text= "Machine favorite-"},
				{text= "Censor"}, {text= "Edit Tags"}, {text= "End Credit"},
			}
			if self.have_pane_edit then
				self.real_info_set[#self.real_info_set+1]= {text= "Edit Pane Settings"}
			end
			if self.have_flag_edit then
				self.real_info_set[#self.real_info_set+1]= {text= "Edit Flag Settings"}
			end
			self.info_set= {}
			for i, info in ipairs(self.real_info_set) do
				self.info_set[i]= {text= info.text, underline= info.underline}
			end
			if self.display then
				self.display:set_info_set(self.info_set)
			end
		end,
		interpret_start= function(self)
			if self.cursor_pos == 7 then
				return true, true, "tags"
			elseif self.cursor_pos == 8 then
				SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
				end_credit_now()
				return true, true
			elseif self.cursor_pos > 8 then
				if self.have_pane_edit and self.cursor_pos == 9 then
					profile_pain_setting:set_dirty(pn_to_profile_slot(self.player_number))
					return true, true, "pain"
				else
					return true, true, "flags"
				end
			end
			local player_slot= pn_to_profile_slot(self.player_number)
			local song= gamestate_get_curr_song()
			if not song then return true, true end
			if self.cursor_pos == 1 then
				return true, true
			elseif self.cursor_pos == 2 then
				change_favor(player_slot, song, 1)
				return true, true
			elseif self.cursor_pos == 3 then
				change_favor(player_slot, song, -1)
				return true, true
			elseif self.cursor_pos == 4 then
				change_favor("ProfileSlot_Machine", song, 1)
				return true, true
			elseif self.cursor_pos == 5 then
				change_favor("ProfileSlot_Machine", song, -1)
				return true, true
			elseif self.cursor_pos == 6 then
				add_to_censor_list(song)
				return true, true
			end
			return false
		end,
		update= function(self)
			if GAMESTATE:IsPlayerEnabled(self.player_number) then
				self.display:unhide()
			else
				self.display:hide()
			end
		end
}}
