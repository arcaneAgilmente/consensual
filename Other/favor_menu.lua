options_sets.favor_menu= {
	__index= {
		initialize= function(self, player_number, extra)
			self.player_number= player_number
			self.name= extra.name
			self.info_set= {
				up_element(),
				{text= "prof_favor_inc"},
				{text= "prof_favor_dec"},
				{text= "mach_favor_inc"},
				{text= "mach_favor_dec"},
			}
			self.cursor_pos= 1
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			local song= gamestate_get_curr_song()
			if song then
				local mfav_str= get_string_wrapper("Favor", "machine_favor_short")
				local mfav= get_favor("ProfileSlot_Machine", song)
				local pfav_str= get_string_wrapper("Favor", "profile_favor_short")
				local pfav= get_favor(pn_to_profile_slot(self.player_number), song)
				self.display:set_display(
					mfav_str .. ": " .. mfav .. "  |  " .. pfav_str .. ": " .. pfav)
			else
				self.display:set_display("")
			end
		end,
		interpret_start= function(self)
			local song= gamestate_get_curr_song()
			local ops= {
				nil,
				function()
					change_favor(pn_to_profile_slot(self.player_number), song, 1)
				end,
				function()
					change_favor(pn_to_profile_slot(self.player_number), song, -1)
				end,
				function()
					change_favor("ProfileSlot_Machine", song, 1)
				end,
				function()
					change_favor("ProfileSlot_Machine", song, -1)
				end,
			}
			if not ops[self.cursor_pos] or not song then return false end
			ops[self.cursor_pos]()
			self:set_status()
			return true
		end,
}}
