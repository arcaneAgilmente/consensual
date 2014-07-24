options_sets.tags_menu= {
	__index= {
		initialize= function(self, player_number, have_up_el)
			self.player_number= player_number
			self.have_up_el= have_up_el
			self.in_machine_tag_mode= false
			self:reset_info()
			self:update()
			self.cursor_pos= 1
		end,
		reset_info= function(self)
			self.real_info_set= {}
			if self.have_up_el then
				self.real_info_set[1]= up_element()
			else
				self.real_info_set[#self.real_info_set+1]= {text="Exit Tags menu"}
			end
			self.real_info_set[#self.real_info_set+1]= {text= "Reload tags"}
			if self.in_machine_tag_mode then
				self.prof_slot= "ProfileSlot_Machine"
				self.real_info_set[#self.real_info_set+1]= {text= "Edit Player tags"}
			else
				self.prof_slot= pn_to_profile_slot(self.player_number)
				self.real_info_set[#self.real_info_set+1]= {text="Edit Machine tags"}
			end
			self.tags_offset= #self.real_info_set
			self.tag_set= usable_tags[self.prof_slot] or {}
			for i, tag_name in ipairs(self.tag_set) do
				self.real_info_set[#self.real_info_set+1]= {text= tag_name}
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
			if self.cursor_pos == 1 and self.have_up_el then return false end
			local menu_pos= self.cursor_pos - self.tags_offset
			if menu_pos == -2 then
				return true, true
			end
			if menu_pos == -1 then
				load_usable_tags(self.prof_slot)
				self:reset_info()
				self:update()
				return true
			end
			if menu_pos == 0 then
				self.in_machine_tag_mode= not self.in_machine_tag_mode
				self:reset_info()
				self:update()
				return true
			end
			local tag_name= self.tag_set[menu_pos]
			if tag_name then
				local song= gamestate_get_curr_song()
				if not song then return true end
				local tag_value= toggle_tag_value(self.prof_slot, song, tag_name)
				self.info_set[self.cursor_pos].underline= int_to_bool(tag_value)
				self.display:set_element_info(
					self.cursor_pos, self.info_set[self.cursor_pos])
				return true
			end
			return false
		end,
		update= function(self)
			local song= gamestate_get_curr_song()
			local song_tags= get_tags_for_song(self.prof_slot, song)
			for i, el in ipairs(self.real_info_set) do
				if i > self.tags_offset then
					el.underline= song and string_in_table(
						self.tag_set[i - self.tags_offset], song_tags)
					self.info_set[i].underline= el.underline
					if self.display then
						self.display:set_element_info(i, self.info_set[i])
					end
				end
			end
		end
}}

