if not arrow_amv then
	dofile(THEME:GetPathO("", "art_helpers.lua"))
end

-- pain menu structure: (back and done are in each level, but omitted here)
-- done
-- make wide/make narrow
-- clear
-- chart info
--   bpm
--   meter
--   (generated entries from RadarCategory)
-- favor
--   machine/player
-- score
--   machine/player
--   index selector
-- tag
--   machine/player
--   index selector

-- pain item config:
-- {
--   is_wide= bool,
--   -- the following are for type determination, only one should exist.
--   bpm= bool, -- optional
--   rating= bool, -- optional
--   author= bool, -- optional
--   radar_category= string, -- optional
--   favor= string, -- "machine" or "player", optional
--   score= {machine= bool, slot= number}, -- optional
--   tag= {machine= bool, slot= number}, -- optional
-- }

local function clear_pain_item_config(item_config)
	item_config.bpm= nil
	item_config.rating= nil
	item_config.author= nil
	item_config.radar_category= nil
	item_config.favor= nil
	item_config.score= nil
	item_config.tag= nil
end

local function set_pain_item_field(item_config, field_name, value)
	if not item_config[field_name] then
		clear_pain_item_config(item_config)
		item_config[field_name]= value
	end
end

local function porm_flag_text(flag)
	if flag then return "Make Player" end
	return "Make Machine"
end

local function bool_text(flag, hontou, uso)
	if flag then return hontou end
	return uso
end

local function done_element() return {text= "done"} end
local function back_element() return {text= "back"} end

local machine_hs_limit= PREFSMAN:GetPreference("MaxHighScoresPerListForMachine")
local player_hs_limit= PREFSMAN:GetPreference("MaxHighScoresPerListForPlayer")

options_sets.pain_menu= {
	__index= {
		create_actors= function(self, name, player_number)
			local args= {
				Name= name,
				InitCommand= function(subself)
					self.container= subself
					self.dec_arrow= subself:GetChild("dec_arrow")
					self.inc_arrow= subself:GetChild("inc_arrow")
					self.dec_arrow:visible(false)
					self.inc_arrow:visible(false)
					self.container:visible(false)
					self.info_set= {}
					self:set_display(self.own_display)
					self.display:set_underline_color(solar_colors[self.player_number]())
				end
			}
			self.name= name
			self.player_number= player_number
			self.frame= setmetatable({}, frame_helper_mt)
			args[#args+1]= self.frame:create_actors(
				"frame", .5, 80, 68, solar_colors.rbg(), solar_colors.bg(), 0, 24)
			self.own_display= setmetatable({}, option_display_mt)
			args[#args+1]= self.own_display:create_actors(
				"display", 0, 0, 5, 80, 12, .5, true, true)
			args[#args+1]= arrow_amv(
				"dec_arrow", -10, 0, 6, 12, 4, solar_colors.uf_text())
			args[#args+1]= arrow_amv(
				"inc_arrow", 10, 0, -6, 12, 4, solar_colors.uf_text())
			self.cursor= setmetatable({}, amv_cursor_mt)
			args[#args+1]= self.cursor:create_actors(
				"cursor", 0, 0, 0, 12, .5, solar_colors[player_number]())
			self.cursor_pos= 1
			self.depth= 1
			self.mode= 1
			return Def.ActorFrame(args)
		end,
		activate= function(self, x, y, item_config)
			self.item_config= item_config
			self.cursor_pos= 1
			self.depth= 1
			self.mode= 1
			self.number_val= 1
			self:change_mode()
			self.container:xy(x, y)
			self.container:visible(true)
			self.inc_arrow:visible(false)
			self.dec_arrow:visible(false)
			self:update_cursor()
		end,
		deactivate= function(self)
			self.container:visible(false)
		end,
		update_number= function(self)
			if self.item_config.score then
				self.item_config.score.slot= self.number_val
			elseif self.item_config.tag then
				self.item_config.tag.slot= self.number_val
			end
			self.info_set[4].text= tostring(self.number_val)
			self.display:set_element_info(4, self.info_set[4])
			self:update_cursor()
		end,
		get_limit= function(self)
			if self.item_config then
				if self.item_config.score then
					if self.item_config.score.machine then
						return machine_hs_limit
					end
					return player_hs_limit
				end
			end
			return 10
		end,
		interpret_code= function(self, code)
			-- return code:  handled, config_changed, close
			if self.depth < 3 then
				local sub_ret= {
					option_set_general_mt.__index.interpret_code(self, code)}
				self:update_cursor()
				return unpack(sub_ret)
			end
			local num_limit= self:get_limit()
			if code == "MenuLeft" or code == "MenuUp" then
				self.number_val= self.number_val - 1
				if self.number_val < 1 then self.number_val= num_limit end
				self:update_number()
				return true, true, false
			elseif code == "MenuRight" or code == "MenuDown" then
				self.number_val= self.number_val + 1
				if self.number_val > num_limit then self.number_val= 1 end
				self:update_number()
				return true, true, false
			elseif code == "Start" then
				return true, false, true
			end
			return false, false, false
		end,
		interpret_start= function(self)
			local chart_pos_map= {
				function()
					set_pain_item_field(self.item_config, "bpm", true)
					return true, true, true
				end,
				function()
					set_pain_item_field(self.item_config, "meter", true)
					return true, true, true
				end,
				function()
					set_pain_item_field(self.item_config, "author", true)
					return true, true, true
				end
			}
			for i, cat in ipairs(RadarCategory) do
				chart_pos_map[#chart_pos_map+1]= function()
					set_pain_item_field(self.item_config, "radar_category", cat)
					return true, true, true
				end
			end
			local code_map= {
				-- depth
				{ -- mode
					-- top level
					function()
						if self.cursor_pos == 1 then
							return true, false, true
						elseif self.cursor_pos == 2 then
							self.item_config.is_wide= not self.item_config.is_wide
							return true, true, false
						elseif self.cursor_pos == 3 then
							clear_pain_item_config(self.item_config)
							return true, true, true
						end
						self.mode= self.cursor_pos - 3
						self.depth= 2
						if self.cursor_pos == 5 then
							set_pain_item_field(self.item_config, "favor", "machine")
						elseif self.cursor_pos == 6 then
							set_pain_item_field(self.item_config, "score", {slot= 1})
							self.number_val= self.item_config.score.slot
						elseif self.cursor_pos == 7 then
							set_pain_item_field(self.item_config, "tag", {slot= 1})
							self.number_val= self.item_config.tag.slot
						end
						self:change_mode()
						return true, true, false
					end
				},{ -- second level
					function() -- chart info
						if chart_pos_map[self.cursor_pos-2] then
							return chart_pos_map[self.cursor_pos-2]()
						end
					end,
					function() -- favor
						if self.cursor_pos == 3 then
							self.item_config.favor= "machine"
						elseif self.cursor_pos == 4 then
							self.item_config.favor= "player"
						end
						return true, true, true
					end,
					function() -- score
						if self.cursor_pos == 3 then
							self.item_config.score.machine=
								not self.item_config.score.machine
							self:update_flag()
							return true, true, false
						else
							self.depth= 3
							self:change_mode()
							return true, false, false
						end
					end,
					function() -- tag
						if self.cursor_pos == 3 then
							self.item_config.tag.machine=
								not self.item_config.machine
							self:update_flag()
							return true, true, false
						else
							self.depth= 3
							self:change_mode()
							return true, false, false
						end
					end
			}}
			local m, d= self.mode, self.depth
			if d > 1 then
				if self.cursor_pos == 1 then -- back
					self.depth= self.depth - 1
					if self.depth == 1 then self.mode= 1 end
					self.cursor_pos= 1
					self:change_mode()
					return true, false, false
				elseif self.cursor_pos == 2 then -- done
					return true, false, true
				end
			end
			if code_map[d] and code_map[d][m] then
				return code_map[d][m]()
			end
			return false, false, false
		end,
		change_mode= function(self)
			if self.depth == 1 then
				self.info_set= {
					done_element(), {text= "make wide"}, {text= "clear"},
					{text= "chart info"}, {text= "favor"}, {text= "score"},
					{text= "tag"}}
				if self.item_config and self.item_config.is_wide then
					self.info_set[2].text= "make narrow"
				end
				self.cursor_pos= 1
			elseif self.depth == 2 then
				if self.mode == 1 then
					self.info_set= {
						back_element(), done_element(), {text= "bpm"}, {text= "meter"},
						{text= "author"}}
					for i, cat in ipairs(RadarCategory) do
						self.info_set[#self.info_set+1]= {text= cat}
					end
				elseif self.mode == 2 then
					self.info_set= {back_element(), done_element()}
					self.info_set[3]= {text= "machine"}
					self.info_set[4]= {text= "player"}
					if self.item_config.favor == "machine" then
						self.info_set[3].underline= true
					else
						self.info_set[4].underline= true
					end
				elseif self.mode == 3 then
					self.info_set= {back_element(), done_element()}
					self.info_set[3]= {
						text= porm_flag_text(self.item_config.score.machine)}
					self.info_set[4]= {text= tostring(self.item_config.score.slot)}
				elseif self.mode == 4 then
					self.info_set= {back_element(), done_element()}
					self.info_set[3]= {
						text= porm_flag_text(self.item_config.tag.machine)}
					self.info_set[4]= {text= tostring(self.item_config.tag.slot)}
				end
				self.cursor_pos= 3
			elseif self.depth == 3 then
				local aru= self:get_cursor_element().container:GetY()
				self.inc_arrow:y(aru)
				self.dec_arrow:y(aru)
				self.inc_arrow:visible(true)
				self.dec_arrow:visible(true)
			end
			if self.display then
				self.display:set_info_set(self.info_set)
			end
		end,
		update_flag= function(self)
			if self.mode == 3 then
				self.info_set[3].text= porm_flag_text(self.item_config.score.machine)
			elseif self.mode == 4 then
				self.info_set[3].text= porm_flag_text(self.item_config.tag.machine)
			end
			self.display:set_element_info(3, self.info_set[3])
		end,
		update_cursor= function(self)
			local item= self:get_cursor_element()
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(item.container)
			local xp= item.container:GetDestX()
			local yp= item.container:GetDestY()
			local w, h= xmx - xmn + 2, ymx - ymn + 2
			self.cursor:refit(xp, yp, w, h)
		end
}}

pain_display_mt= {
	__index= {
		create_actors= function(self, name, x, y, player_number, el_w, el_z)
			local args= {
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.cursor:hide()
				end
			}
			self.player_number= player_number
			self:fetch_config()
			self.name= name
			self.el_w= el_w
			self.items= {}
			self.el_z= el_z
			self.left_x= el_w * -.25
			self.right_x= el_w * .25
			self.half_sep= (el_w * .25) - 4
			self.full_sep= (el_w * .5) - 4
			self.narrow_el_w= (el_w * .5) - 8
			self.wide_el_w= el_w - 8
			self.text_height= 16 * (el_z / 0.5875)
			-- Height was originally 16 in default theme, zoom was originally
			--   0.5875, so that is used as the base point.
			local tani_args= {
				tt= "", nt= "", tx= -self.half_sep, nx= self.half_sep,
				tz= self.el_z, nz= self.el_z, ta= left, na= right,
				tf= "Common SemiBold", nf= "Common SemiBold",
				text_section= "PaneDisplay"}
			self.left_items= {}
			self.right_items= {}
			for r= 1, pain_rows do
				tani_args.sy= (r - 1) * self.text_height
				tani_args.sx= self.left_x
				self.left_items[r]= setmetatable({}, text_and_number_interface_mt)
				args[#args+1]= self.left_items[r]:create_actors("litem"..r,tani_args)
				tani_args.sx= self.right_x
				self.right_items[r]= setmetatable({}, text_and_number_interface_mt)
				args[#args+1]=self.right_items[r]:create_actors("ritem"..r,tani_args)
			end
			self.cursor= setmetatable({}, amv_cursor_mt)
			args[#args+1]= self.cursor:create_actors(
				"cursor", 0, 0, 0, 12, .5, solar_colors[player_number]())
			self.cursor_pos= 1
			self.mode= 1
			self.menu= setmetatable({}, options_sets.pain_menu)
			args[#args+1]= self.menu:create_actors("menu", player_number)
			return Def.ActorFrame(args)
		end,
		fetch_config= function(self)
			self.config= cons_players[self.player_number].pain_config
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end,
		enter_edit_mode= function(self)
			self.mode= 2
			self:update_all_items()
			self.cursor:unhide()
			self:update_cursor()
		end,
		interpret_code= function(self, code)
			-- return code: handled, close
			if code == "Select" then
				self.menu:deactivate()
				self.cursor:hide()
				self.mode= 1
				self:update_all_items()
				return true, true
			end
			local two_menu_directions=
				PREFSMAN:GetPreference("ArcadeOptionsNavigation")
			if two_menu_directions then
				if code == "MenuLeft" then
					code= "MenuUp"
				elseif code == "MenuRight" then
					code= "MenuDown"
				end
			end
			if self.mode == 2 then
				if code == "MenuUp" then
					self.cursor_pos= self.cursor_pos - 1
					if self.cursor_pos < 1 then self.cursor_pos= pain_rows * 2 end
					self:update_cursor()
					return true, false
				elseif code == "MenuDown" then
					self.cursor_pos= self.cursor_pos + 1
					if self.cursor_pos > pain_rows * 2 then self.cursor_pos= 1 end
					self:update_cursor()
					return true, false
				elseif code == "MenuLeft" then
					self.cursor_pos= self.cursor_pos - pain_rows
					if self.cursor_pos < 1 then
						self.cursor_pos= self.cursor_pos + (pain_rows * 2)
					end
					self:update_cursor()
					return true, false
				elseif code == "MenuRight" then
					self.cursor_pos= self.cursor_pos + pain_rows
					if self.cursor_pos > pain_rows * 2 then
						self.cursor_pos= self.cursor_pos - (pain_rows * 2)
					end
					self:update_cursor()
					return true, false
				elseif code == "Start" then
					local menu_x
					local item_config
					if self.cursor_pos <= pain_rows then
						menu_x= self.right_x
						item_config= self.config[1][self.cursor_pos]
					else
						menu_x= self.left_x
						item_config= self.config[2][self.cursor_pos - pain_rows]
					end
					local itemy= ((self.cursor_pos - 1) % pain_rows) + 1
					local menu_y= self.left_items[itemy].container:GetY() - 24
					local maxy= (pain_rows * self.text_height) - (12 * 5.5)
					menu_y= force_to_range(1, menu_y, maxy)
					self.menu:activate(menu_x, menu_y, item_config)
					self.mode= 3
					return true, false
				end
			elseif self.mode == 3 then
				local handled, config_changed, close= self.menu:interpret_code(code)
				if handled then
					if config_changed then
						self:update_cursor_item()
					end
					if close then
						self.menu:deactivate()
						self.mode= 2
					end
					return true, false
				end
				return false, false
			end
			return false, false
		end,
		update_cursor= function(self)
			local cursy= (self.cursor_pos - 1) % pain_rows
			local xp
			if self.cursor_pos <= pain_rows then
				xp= self.left_x
			else
				xp= self.right_x
			end
			local yp= cursy * self.text_height
			self.cursor:refit(xp, yp, self.narrow_el_w + 4, self.text_height)
		end,
		width_limit_item= function(self, item)
			local total_width= item.number:GetX() - item.text:GetX()
			local text_width= item.text:GetZoomedWidth()
			local number_width= item.number:GetZoomedWidth()
			width_limit_text(item.number, total_width * .375, self.el_z)
			local tw= total_width - item.number:GetZoomedWidth() - 4
			width_clip_limit_text(item.text, tw, self.el_z)
		end,
		make_item_narrow= function(self, item, left)
			if left then
				item.container:x(self.left_x)
			else
				item.container:x(self.right_x)
			end
			item.text:x(-self.half_sep)
			item.number:x(self.half_sep)
		end,
		make_item_wide= function(self, item)
			item.container:x(0)
			item.text:x(-self.full_sep)
			item.number:x(self.full_sep)
		end,
		get_prof= function(self, machine)
			if machine then
				return PROFILEMAN:GetMachineProfile()
			else
				return PROFILEMAN:GetProfile(self.player_number)
			end
		end,
		get_hs_list= function(self, machine)
			local steps= gamestate_get_curr_steps(self.player_number)
			local song= gamestate_get_curr_song()
			local prof= self:get_prof(machine)
			if not song or not steps or not prof then return nil end
			local hs_list= prof:GetHighScoreListIfExists(song, steps)
			if hs_list then return hs_list:GetHighScores() end
			return nil
		end,
		set_score_item= function(self, item, slot, hs_list)
			if hs_list then
				local score= hs_list[slot]
				if score then
					local dp= score:GetPercentDP()
					item:set_text(score:GetName())
					item:set_number(("%.2f%%"):format(dp * 100))
					item.number:diffuse(color_for_score(dp))
					if dp > .9999 then
						if global_distortion_mode then
							item.number:undistort()
						else
							item.number:distort(.5)
						end
					elseif not global_distortion_mode then
						item.number:undistort()
					end
					return
				end
			end
			item:set_text("")
			item:set_number("")
		end,
		get_tag_list= function(self, machine)
			local prof_slot
			if machine then
				prof_slot= "ProfileSlot_Machine"
			else
				prof_slot= pn_to_profile_slot(self.player_number)
			end
			return get_tags_for_song(prof_slot, gamestate_get_curr_song())
		end,
		set_tag_item= function(self, item, slot, tag_list)
			item:set_number("")
			if tag_list[slot] then
				item:set_text(tag_list[slot])
			else
				item:set_text("")
			end
		end,
		set_favor_item= function(self, item, ftype, is_wide)
			local song= gamestate_get_curr_song()
			if ftype == "machine" then
				if is_wide then
					item:set_text("Machine Favor")
				else
					item:set_text("MFav")
				end
				item:set_number(get_favor("ProfileSlot_Machine", song))
			else
				if is_wide then
					item:set_text("Player Favor")
				else
					item:set_text("PFav")
				end
				item:set_number(
					get_favor(pn_to_profile_slot(self.player_number), song))
			end
		end,
		set_chart_info_item= function(self, item, item_config, radars)
			local steps= gamestate_get_curr_steps(self.player_number)
			local song= gamestate_get_curr_song()
			if not song or not steps then
				item:set_text("")
				item:set_number("")
				return
			end
			if item_config.bpm then
				item:set_text("BPM")
				item:set_number(steps_get_bpms_as_text(steps))
			elseif item_config.rating then
				item:set_text(steps_to_string(steps))
				item:set_number(steps:GetMeter())
			elseif item_config.author then
				item:set_text(steps_get_author(steps))
				local width= self.narrow_el_w
				if item_config.is_wide then width= self.wide_el_w end
				width_limit_text(item.text, width, self.el_z)
				item:set_number("")
			elseif item_config.radar_category then
				item:set_text(item_config.radar_category)
				item:set_number(radars:GetValue(item_config.radar_category))
			else
				item:set_text("")
				item:set_number("")
			end
		end,
		set_edit_mode_item= function(self, item, item_config)
			if item_config.score then
				item:set_text(
					bool_text(item_config.score.machine, "MScore", "PScore"))
				item:set_number(item_config.score.slot)
			elseif item_config.tag then
				item:set_text(bool_text(item_config.tag.machine, "MTag", "PTag"))
				item:set_number(item_config.tag.slot)
			elseif item_config.favor then
				item:set_text(
					bool_text(item_config.favor == "machine", "MFavor", "PFavor"))
				item:set_number("X")
			elseif item_config.bpm then
				item:set_text("BPM")
				item:set_number("XXX")
			elseif item_config.rating then
				item:set_text("Rating")
				item:set_number("XX")
			elseif item_config.author then
				item:set_text("Author")
				item:set_number("")
			elseif item_config.radar_category then
				item:set_text("Radar")
				item:set_number(
					get_string_wrapper("PaneDisplay", item_config.radar_category))
			else
				item:set_text("")
				item:set_number("")
			end
			item.text:diffuse(solar_colors.f_text())
			item.number:diffuse(solar_colors.f_text())
		end,
		update_cursor_item= function(self)
			local item_config
			local item
			if self.cursor_pos <= pain_rows then
				item_config= self.config[1][self.cursor_pos]
				item= self.left_items[self.cursor_pos]
			else
				item_config= self.config[2][self.cursor_pos - pain_rows]
				item= self.right_items[self.cursor_pos - pain_rows]
			end
			if item_config.is_wide then
				self:make_item_wide(item)
			else
				self:make_item_narrow(item, self.cursor_pos <= pain_rows)
			end
			if self.mode == 1 then
				if item_config.score then
					local hs_list= self:get_hs_list(item_config.score.machine)
					self:set_score_item(item, item_config.score.slot, hs_list)
				elseif item_config.tag then
					local tag_list= self:get_tag_list(item_config.tag.machine)
					self:set_tag_item(item, item_config.tag.slot, tag_list)
				elseif item_config.favor then
					self:set_favor_item(item, item_config.favor, item_config.is_wide)
				else
					local steps= gamestate_get_curr_steps(self.player_number)
					local radars= steps and steps:GetRadarValues(self.player_number)
					self:set_chart_info_item(item, item_config, radars)
				end
			else
				self:set_edit_mode_item(item, item_config)
			end
			self:width_limit_item(item)
			self:update_cursor()
		end,
		update_all_items= function(self)
			if not GAMESTATE:IsPlayerEnabled(self.player_number) then
				self:hide()
				return
			end
			local song= gamestate_get_curr_song()
			local steps= gamestate_get_curr_steps(self.player_number)
			local radars= steps and steps:GetRadarValues(self.player_number)
			local mhs_list= self:get_hs_list(true)
			local phs_list= self:get_hs_list(false)
			local mtag_list= self:get_tag_list(true)
			local ptag_list= self:get_tag_list(false)
			local function update_half(half_items, half_config, left)
				for i, item in ipairs(half_items) do
					if song then
						local item_config= half_config[i]
						if not item_config then
							Trace("No config for item " .. i .. " on " .. tostring(left))
						end
						if item_config.is_wide then
							self:make_item_wide(item)
						else
							self:make_item_narrow(item, left)
						end
						if item_config.score then
							local list=(item_config.score.machine and mhs_list) or phs_list
							self:set_score_item(item, item_config.score.slot, list)
						elseif item_config.tag then
							local list=(item_config.tag.machine and mtag_list) or ptag_list
							self:set_tag_item(item, item_config.tag.slot, list)
						elseif item_config.favor then
							self:set_favor_item(
								item, item_config.favor, item_config.is_wide)
						else
							self:set_chart_info_item(item, item_config, radars)
						end
					else
						item:set_text("")
						item:set_number("")
					end
					self:width_limit_item(item)
				end
			end
			local function update_half_edit(half_items, half_config)
				for i, item in ipairs(half_items) do
					local item_config= half_config[i]
					self:set_edit_mode_item(item, item_config)
					self:width_limit_item(item)
				end
			end
			if self.mode == 1 then
				update_half(self.left_items, self.config[1], true)
				update_half(self.right_items, self.config[2], false)
			else
				update_half_edit(self.left_items, self.config[1])
				update_half_edit(self.right_items, self.config[2])
			end
			self:update_cursor()
		end
}}
