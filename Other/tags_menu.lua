local function go_to_text_entry(settings)
	settings.InitialAnswer= ""
	settings.MaxInputLength= 512
	MESSAGEMAN:Broadcast("went_to_text_entry")
	SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
	SCREENMAN:GetTopScreen():Load(settings)
end

options_sets.tags_menu= {
	__index= {
		initialize= function(self, player_number, have_up_el)
			self.player_number= player_number
			self.have_up_el= have_up_el
			self.in_machine_tag_mode= false
			if not player_using_profile(player_number) then
				self.in_machine_tag_mode= true
				self.machine_only= true
			end
			self:reset_info()
			self:update()
			self.cursor_pos= 1
		end,
		reset_info= function(self)
			self.cursor_pos= 1
			self.real_info_set= {}
			if self.have_up_el then
				self.real_info_set[1]= up_element()
			else
				self.real_info_set[#self.real_info_set+1]= {text="Exit Tags menu"}
				self.op_functions= {function() return true, true end}
			end
			if input_came_from_keyboard then
				self.real_info_set[#self.real_info_set+1]= {text= "Reload tags file"}
				self.op_functions[#self.op_functions+1]= function()
					load_usable_tags(self.prof_slot)
					lua.ReportScriptError(#usable_tags[self.prof_slot] .. " tags in list.")
					self:reset_info()
					self:update()
					return true
				end
				self.real_info_set[#self.real_info_set+1]= {text= "Add new tag"}
				self.op_functions[#self.op_functions+1]= function()
					go_to_text_entry{
						Question= get_string_wrapper("TagsMenu", "add_tag_prompt"),
						OnOK= function(answer)
							curr_tags_set= usable_tags[self.prof_slot] or {}
							if not answer or answer == ""
								or string_in_table(answer, curr_tags_set) then
									return
							end
							insert_into_sorted_table(curr_tags_set, answer)
							self:save_reset_preserve_cursor()
						end
					}
					return true
				end
				self.real_info_set[#self.real_info_set+1]= {text= "Remove tag"}
				self.op_functions[#self.op_functions+1]= function()
					go_to_text_entry{
						Question= get_string_wrapper("TagsMenu", "remove_tag_prompt"),
						OnOK= function(answer)
							curr_tags_set= usable_tags[self.prof_slot] or {}
							local index= string_in_table(answer, curr_tags_set)
							if not index then return end
							table.remove(curr_tags_set, index)
							self:save_reset_preserve_cursor()
						end
					}
					return true
				end
				self.real_info_set[#self.real_info_set+1]= {text= "Rename tag"}
				self.op_functions[#self.op_functions+1]= function()
					go_to_text_entry{
						Question= get_string_wrapper("TagsMenu", "rename_tag_prompt"),
						OnOK= function(answer)
							local old_name, new_name= answer:match(" *([^,]+) *, *([^,]+)")
							if not old_name or not new_name or old_name == new_name then
								return
							end
							rename_tag(self.prof_slot, old_name, new_name)
							self:save_reset_preserve_cursor()
						end
					}
					return true
				end
			end
			if not self.machine_only then
				if self.in_machine_tag_mode then
					self.prof_slot= "ProfileSlot_Machine"
					table.insert(self.real_info_set, {text= "Edit Player tags"})
				else
					self.prof_slot= pn_to_profile_slot(self.player_number)
					table.insert(self.real_info_set, {text= "Edit Machine tags"})
				end
				self.op_functions[#self.op_functions+1]= function()
					self.in_machine_tag_mode= not self.in_machine_tag_mode
					self:reset_info()
					self:update()
					return true
				end
			end
			self.tags_offset= #self.real_info_set
			self.op_functions[#self.op_functions+1]= function()
				local tag_name= self.tag_set[self.cursor_pos - self.tags_offset]
				if tag_name then
					local apply_group= {gamestate_get_curr_song()}
					if not apply_group[1] then
						self.music_wheel= nil
						MESSAGEMAN:Broadcast("get_music_wheel", {pn= self.player_number})
						if self.music_wheel then
							local function add_item(item, depth)
								apply_group[#apply_group+1]= item.el
							end
							local bucket= self.music_wheel.sick_wheel:get_info_at_focus_pos()
							if bucket.bucket_info and not bucket.is_special then
								bucket_traverse(bucket.bucket_info.contents, nil, add_item)
							end
						end
					end
					local number_set= 0
					local set_to= 1
					for i, song in ipairs(apply_group) do
						if get_tag_value(self.prof_slot, song, tag_name) then
							number_set= number_set + 1
						end
					end
					if number_set > #apply_group * .5 then
						set_to= 0
					end
					for i, song in ipairs(apply_group) do
						tag_value= set_tag_value(self.prof_slot, song, tag_name, set_to)
					end
					self.info_set[self.cursor_pos].underline= int_to_bool(set_to)
					self.display:set_element_info(
						self.cursor_pos, self.info_set[self.cursor_pos])
					return true
				end
			end
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
		save_reset_preserve_cursor= function(self)
			save_usable_tags(self.prof_slot)
			local cursor_pos= self.cursor_pos
			self:reset_info()
			self:update()
			self.cursor_pos= cursor_pos
		end,
		set_status= function(self)
			if not self.display.no_heading then
				self.display:set_heading("Tags")
				if self.in_machine_tag_mode then
					self.display:set_display("Machine")
				else
					self.display:set_display("Player")
				end
			end
		end,
		interpret_start= function(self)
			if self.cursor_pos == 1 and self.have_up_el then return false end
			local op_fun= self.op_functions[self.cursor_pos]
			if not op_fun then op_fun= self.op_functions[#self.op_functions] end
			return op_fun()
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

