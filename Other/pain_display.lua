if not arrow_amv then
	dofile(THEME:GetPathO("", "art_helpers.lua"))
end

local line_height= get_line_height()

local timing_segments= {
	{"Stops", "GetStops"},
	{"Delays", "GetDelays"},
	{"BPM Changes", "GetBPMs"},
	{"Warps", "GetWarps"},
	{"Tickcounts", "GetTickcounts"},
	{"Speed Changes", "GetSpeeds"},
	{"Scroll Changes", "GetScrolls"},
	{"Combo Multipliers", "GetCombos"},
}

-- pain menu structure: (back and done are in each level, but omitted here)
-- done
-- make wide/make narrow
-- clear
-- chart info
--   bpm
--   meter
--   (generated entries from RadarCategory)
-- timing info
--   (generated entries from timing_segments)
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
--   genre= bool, -- optional
--   nps= bool, --optional
--   radar_category= string, -- optional
--   favor= string, -- "machine" or "player", optional
--   score= {machine= bool, slot= number}, -- optional
--   tag= {machine= bool, slot= number}, -- optional
-- }

local function clear_pain_item_config(item_config)
	for k in pairs(item_config) do
		if k ~= "is_wide" then
			item_config[k]= nil
		end
	end
end

local function clear_unused_half_tail(config_half)
	if #config_half > 0 then
		repeat
			local has_item= false
			for k, v in pairs(config_half[#config_half]) do
				if k ~= "is_wide" then
					has_item= true
					break
				end
			end
			if not has_item then
				config_half[#config_half]= nil
			end
		until has_item or #config_half < 1
	end
end

local function set_pain_item_field(item_config, field_name, value)
	clear_pain_item_config(item_config)
	item_config[field_name]= value
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
					self.cursor:refit(nil, nil, 0, 12)
					self.display:set_underline_color(pn_to_color(self.player_number))
				end
			}
			self.name= name
			self.player_number= player_number
			self.frame= setmetatable({}, frame_helper_mt)
			args[#args+1]= self.frame:create_actors(
				"frame", .5, 80, 68, fetch_color("rev_bg"), fetch_color("bg"), 0, 24)
			self.own_display= setmetatable({}, option_display_mt)
			args[#args+1]= self.own_display:create_actors(
				"display", 0, 0, 60, 80, 12, .5, true, true)
			args[#args+1]= arrow_amv(
				"dec_arrow", -10, 0, 6, 12, 4, fetch_color("text_other"))
			args[#args+1]= arrow_amv(
				"inc_arrow", 10, 0, -6, 12, 4, fetch_color("text_other"))
			self.cursor= setmetatable({}, cursor_mt)
			args[#args+1]= self.cursor:create_actors(
				"cursor", 0, 0, .5, pn_to_color(player_number),
				fetch_color("player.hilight"), button_list_for_menu_cursor())
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
			self.container:xy(x, y):visible(true)
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
				end,
				function()
					set_pain_item_field(self.item_config, "genre", true)
					return true, true, true
				end,
				function()
					set_pain_item_field(self.item_config, "nps", true)
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
						if self.cursor_pos == 4 then
							set_pain_item_field(self.item_config, "chart_info", true)
						elseif self.cursor_pos == 5 then
							set_pain_item_field(self.item_config, "timing_info", timing_segments[1])
						elseif self.cursor_pos == 6 then
							set_pain_item_field(self.item_config, "favor", "machine")
						elseif self.cursor_pos == 7 then
							set_pain_item_field(self.item_config, "score", {slot= 1})
							self.number_val= self.item_config.score.slot
						elseif self.cursor_pos == 8 then
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
					function() -- timing info
						local seg_info= timing_segments[self.cursor_pos-2]
						if seg_info then
							set_pain_item_field(self.item_config, "timing_info", seg_info)
							return true, true, true
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
								not self.item_config.tag.machine
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
					{text= "chart info"}, {text= "timing info"}, {text= "favor"},
					{text= "score"}, {text= "tag"}}
				if self.item_config and self.item_config.is_wide then
					self.info_set[2].text= "make narrow"
				end
				self.cursor_pos= 1
			elseif self.depth == 2 then
				if self.mode == 1 then
					self.info_set= {
						back_element(), done_element(), {text= "bpm"}, {text= "meter"},
						{text= "author"}, {text= "genre"}, {text= "nps"}}
					for i, cat in ipairs(RadarCategory) do
						self.info_set[#self.info_set+1]= {text= cat}
					end
				elseif self.mode == 2 then
					self.info_set= {back_element(), done_element()}
					for i, seg in ipairs(timing_segments) do
						self.info_set[#self.info_set+1]= {text= seg[1]}
					end
				elseif self.mode == 3 then
					self.info_set= {back_element(), done_element()}
					self.info_set[3]= {text= "machine"}
					self.info_set[4]= {text= "player"}
					if self.item_config.favor == "machine" then
						self.info_set[3].underline= true
					else
						self.info_set[4].underline= true
					end
				elseif self.mode == 4 then
					self.info_set= {back_element(), done_element()}
					self.info_set[3]= {
						text= porm_flag_text(self.item_config.score.machine)}
					self.info_set[4]= {text= tostring(self.item_config.score.slot)}
				elseif self.mode == 5 then
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
			if self.mode == 4 then
				self.info_set[3].text= porm_flag_text(self.item_config.score.machine)
			elseif self.mode == 5 then
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
					self.cursor:refit(nil, nil, 0, 12)
					self.cursor:hide()
					self:hide()
					self:stroke_items(self.left_items)
					self:stroke_items(self.right_items)
				end,
			}
			self.original_y= y
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
			self.disp_row_limit= max_pain_rows + 1 -- One for "Exit Pain Edit"
			-- Height was originally 16 in default theme, zoom was originally
			--   0.5875, so that is used as the base point.
			local frame_height= self.text_height * self.disp_row_limit + 4
			local frame_y= (frame_height / 2) - (self.text_height/2)
			local shadow_args= {
				Name= "shadows", InitCommand= function(subself)
					self.shadow_container= subself
				end,
			}
			self.frame_main= setmetatable({}, frame_helper_mt)
			shadow_args[#shadow_args+1]= self.frame_main:create_actors(
				"frame", 2, el_w, frame_height, pn_to_color(player_number),
				fetch_color("bg", 0), 0, 0)
			self.shadows= {}
			for i= 1, self.disp_row_limit do
				local scolor= fetch_color("bg_shadow", .5)
				if i % 2 == 1 then scolor= fetch_color("bg", .5) end
				shadow_args[#shadow_args+1]= Def.Quad{
					Name= "q"..i, InitCommand= function(subself)
						self.shadows[#self.shadows+1]= subself
						subself:visible(false):xy(0, (i-1)*self.text_height)
							:setsize(el_w - 2, self.text_height+1):diffuse(scolor)
					end
				}
			end
			args[#args+1]= Def.ActorFrame(shadow_args)
			local el_args= {
				Name= "elements", InitCommand= function(subself)
					self.element_container= subself
				end
			}
			local tani_args= {
				tt= "", nt= "", tx= -self.half_sep, nx= self.half_sep,
				tz= self.el_z, nz= self.el_z, ta= left, na= right,
				tf= "Common SemiBold", nf= "Common SemiBold",
				text_section= "PaneDisplay"}
			self.left_items= {}
			self.right_items= {}
			for r= 1, self.disp_row_limit do
				tani_args.sy= (r - 1) * self.text_height
				tani_args.sx= self.left_x
				self.left_items[r]= setmetatable({}, text_and_number_interface_mt)
				el_args[#el_args+1]= self.left_items[r]:create_actors("litem"..r,tani_args)
				tani_args.sx= self.right_x
				self.right_items[r]= setmetatable({}, text_and_number_interface_mt)
				el_args[#el_args+1]=self.right_items[r]:create_actors("ritem"..r,tani_args)
			end
			self.cursor= setmetatable({}, cursor_mt)
			el_args[#el_args+1]= self.cursor:create_actors(
				"cursor", 0, 0, .5, pn_to_color(player_number),
				fetch_color("player.hilight"), button_list_for_menu_cursor())
			self.cursor_pos= {1, 1}
			self.mode= 1
			self.menu= setmetatable({}, options_sets.pain_menu)
			el_args[#el_args+1]= self.menu:create_actors("menu", player_number)
			args[#args+1]= Def.ActorFrame(el_args)
			return Def.ActorFrame(args)
		end,
		stroke_items= function(self, set)
			local stroke= fetch_color("stroke")
			for i, item in ipairs(set) do
				item.text:strokecolor(stroke)
				item.number:strokecolor(stroke)
			end
		end,
		fetch_config= function(self)
			if self.player_number then
				self.config= cons_players[self.player_number].pain_config
			end
		end,
		set_config= function(self, config)
			self.config= config
		end,
		hide_elements= function(self)
			self.element_container:visible(false)
		end,
		hide= function(self)
			self.container:visible(false)
			self.shadow_container:visible(false)
			self:hide_elements()
			self.frame_main.outer:hide()
		end,
		unhide= function(self)
			self.container:visible(true)
			self.shadow_container:visible(true)
			self.element_container:visible(true)
			self.frame_main.outer:unhide()
		end,
		show_frame= function(self, rows)
			rows= rows or max_pain_rows
			self.container:visible(true)
			self.shadow_container:visible(true)
			self.frame_main.outer:unhide()
			for i, shadow in ipairs(self.shadows) do
				shadow:visible(i <= rows)
			end
			local revealed_height= rows * self.text_height + 4
			local row_limit= self.disp_row_limit - 1
			local hidden_height= (self.disp_row_limit - rows) * self.text_height
			local center_y= revealed_height/2 - (self.text_height/2)
			self.frame_main:resize(self.el_w, revealed_height)
			self.frame_main:move(nil, center_y-2)
			self.container:finishtweening():linear(.1)
				:y(self.original_y+hidden_height)
		end,
		enter_edit_mode= function(self)
			self.mode= 2
			if self.player_number then
				self.container:addy(-self.text_height)
			end
			self:update_all_items()
			self.cursor_pos= {1, 1}
			self.cursor:unhide()
			self:update_cursor()
		end,
		interpret_code= function(self, code)
			-- return code: handled, close
			function exit_edit()
				self.menu:deactivate()
				self.cursor:hide()
				for ch, config_half in ipairs(self.config) do
					clear_unused_half_tail(config_half)
				end
				self.mode= 1
				self:update_all_items()
				return true, true
			end
			if code == "Select" then
				return exit_edit()
			end
			local two_menu_directions= PREFSMAN:GetPreference("ThreeKeyNavigation")
			if two_menu_directions then
				if code == "MenuLeft" then
					code= "MenuUp"
				elseif code == "MenuRight" then
					code= "MenuDown"
				end
			end
			if self.mode == 2 then
				local config_half= self.config[self.cursor_pos[1]]
				local other_side= ({2, 1})[self.cursor_pos[1]]
				local max_row= math.min(self.used_rows+2, self.disp_row_limit)
				if code == "MenuUp" then
					self.cursor_pos[2]= self.cursor_pos[2] - 1
					if self.cursor_pos[2] < 1 then
						if two_menu_directions then
							self.cursor_pos[1]= other_side
						end
						self.cursor_pos[2]= max_row
					end
					self:update_cursor()
					return true, false
				elseif code == "MenuDown" then
					self.cursor_pos[2]= self.cursor_pos[2] + 1
					if self.cursor_pos[2] > max_row then
						if two_menu_directions then
							self.cursor_pos[1]= other_side
						end
						self.cursor_pos[2]= 1
					end
					self:update_cursor()
					return true, false
				elseif code == "MenuLeft" then
					self.cursor_pos[1]= other_side
					self:update_cursor()
					return true, false
				elseif code == "MenuRight" then
					self.cursor_pos[1]= other_side
					self:update_cursor()
					return true, false
				elseif code == "Start" then
					if self.cursor_pos[2] >= max_row then
						return exit_edit()
					end
					local menu_x= ({self.right_x, self.left_x})[self.cursor_pos[1]]
					local config_pos= self.cursor_pos[2]
					local item_config= config_half[config_pos]
					if not item_config then
						for i= #config_half+1, config_pos do
							config_half[i]= {}
						end
						item_config= config_half[config_pos]
					end
					local itemy= self.cursor_pos[2]
					local menu_y= self.left_items[itemy].container:GetY() - 24
					local maxy= (max_row * self.text_height) - (12 * 5.5)
					menu_y= force_to_range(1, menu_y, maxy)
					self.menu:activate(menu_x, menu_y, item_config)
					self.mode= 3
					return true, false
				end
			elseif self.mode == 3 then
				local handled, config_changed, close= self.menu:interpret_code(code)
				if handled then
					if config_changed then
						clear_unused_half_tail(self.config[self.cursor_pos[1]])
						self:update_all_items()
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
			local cursy= self.cursor_pos[2] - 1
			local xp= ({self.left_x, self.right_x})[self.cursor_pos[1]]
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
		make_item_semi_wide= function(self, item, left)
			local avg_sep= (self.full_sep + self.half_sep) / 2
			if left then
				item.container:x(self.left_x)
				item.text:x(-self.half_sep)
				item.number:x(avg_sep)
			else
				item.container:x(self.right_x)
				item.text:x(-avg_sep)
				item.number:x(self.half_sep)
			end
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
			local song= gamestate_get_curr_song()
			if song then
				return get_tags_for_song(prof_slot, song)
			else
				self.music_wheel= nil
				MESSAGEMAN:Broadcast("get_music_wheel", {pn= self.player_number})
				if self.music_wheel then
					return get_tags_for_bucket(
						prof_slot, self.music_wheel.sick_wheel:get_info_at_focus_pos())
				end
			end
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
			local favor_val= 0
			if ftype == "machine" then
				if is_wide then
					item:set_text("Machine Favor")
				else
					item:set_text("MFav")
				end
				favor_val= get_favor("ProfileSlot_Machine", song)
			else
				if is_wide then
					item:set_text("Player Favor")
				else
					item:set_text("PFav")
				end
				favor_val= get_favor(pn_to_profile_slot(self.player_number), song)
			end
			item:set_number(favor_val)
			item.number:diffuse(color_percent_above(favor_val / 16, 0))
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
				set_bmt_to_bpms(item.number, steps_get_bpms(steps, song))
			elseif item_config.meter then
				item:set_text(steps_to_string(steps))
				item:set_number(steps:GetMeter())
				item.text:diffuse(diff_to_color(steps:GetDifficulty()))
				item.number:diffuse(color_number_above(steps:GetMeter(), 12))
			elseif item_config.author then
				item:set_text(steps_get_author(steps, song))
				local width= self.narrow_el_w
				if item_config.is_wide then width= self.wide_el_w end
				width_limit_text(item.text, width, self.el_z)
				item:set_number("")
			elseif item_config.genre then
				if song.GetGenre then
					item:set_text(song:GetGenre())
					local width= self.narrow_el_w
					if item_config.is_wide then width= self.wide_el_w end
					width_limit_text(item.text, width, self.el_z)
					item:set_number("")
				end
			elseif item_config.radar_category then
				item:set_text(item_config.radar_category)
				local rval= radars:GetValue(item_config.radar_category)
				if rval == -1 then
					item:set_number("N/A")
					item.number:diffuse(fetch_color("text"))
				else
					if rval == math.floor(rval) then
						item:set_number(rval)
						item.number:diffuse(fetch_color("text"))
					else
						item:set_number(("%.2f"):format(rval))
						item.number:diffuse(color_percent_above(rval, .5))
					end
				end
			elseif item_config.nps then
				item:set_text("NPS")
				local taps= radars:GetValue("RadarCategory_TapsAndHolds")
				local jumps= radars:GetValue("RadarCategory_Jumps")
				local hands= radars:GetValue("RadarCategory_Hands")
				local length= song_get_length(song)
				local nps= (taps + jumps + hands) / length
				if length <= 0 then
					item:set_number("N/A")
					item.number:diffuse(fetch_color("text"))
				else
					item:set_number(("%.2f"):format(nps))
					item.number:diffuse(color_percent_above(nps/10, .5))
				end
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
				item.number:ClearAttributes()
			elseif item_config.meter then
				item:set_text("Meter")
				item:set_number("XX")
			elseif item_config.author then
				item:set_text("Author")
				item:set_number("")
			elseif item_config.genre then
				item:set_text("Genre")
				item:set_number("")
			elseif item_config.radar_category then
				item:set_text("Radar")
				item:set_number(
					get_string_wrapper("PaneDisplay", item_config.radar_category))
			elseif item_config.nps then
				item:set_text("NPS")
				item:set_number("X.XX")
			elseif item_config.timing_info then
				item:set_text(item_config.timing_info[1] or "err")
				item:set_number("XX")
			else
				item:set_text("")
				item:set_number("")
			end
			item.text:diffuse(fetch_color("text"))
			item.number:diffuse(fetch_color("text"))
		end,
		edit_mode_update_all= function(self)
			self.used_rows= math.max(#self.config[1], #self.config[2])
			local show_rows= self.used_rows + 1
			if self.used_rows < max_pain_rows then
				show_rows= show_rows + 1
			end
			self:show_frame(show_rows)
			local function update_half_edit(half_items, half_config, other_half, left)
				for i, item in ipairs(half_items) do
					local item_config= half_config[i]
					local other_config= other_half[i]
					local other_blocks= other_config and other_config.is_wide
					if not other_blocks then
						if item_config then
							if item_config.is_wide then
								self:make_item_semi_wide(item, left)
							else
								self:make_item_narrow(item, left)
							end
							self:set_edit_mode_item(item, item_config)
						else
							if i <= show_rows-1 then
								item:set_text("Add Item")
								item:set_number("")
							elseif i == show_rows then
								item:set_text("Exit Edit")
								item:set_number("")
							else
								item:set_text("")
								item:set_number("")
							end
						end
					else
						item:set_text("")
						item:set_number("")
					end
					self:width_limit_item(item)
				end
			end
			update_half_edit(self.left_items, self.config[1], self.config[2], true)
			update_half_edit(self.right_items, self.config[2], self.config[1], false)
			self:update_cursor()
		end,
		update_all_items= function(self)
			if self.mode ~= 1 then
				self:edit_mode_update_all()
				return
			end
			if not self.player_number or
			not GAMESTATE:IsPlayerEnabled(self.player_number) then
				self:hide()
				return
			end
			self.used_rows= math.max(#self.config[1], #self.config[2])
			local show_rows= self.used_rows
			self:show_frame(show_rows)
			local song= gamestate_get_curr_song()
			local steps= gamestate_get_curr_steps(self.player_number)
			local timing_data= steps and steps.GetTimingData and steps:GetTimingData()
			local radars= steps and steps:GetRadarValues(self.player_number)
			local mhs_list= self:get_hs_list(true)
			local phs_list= self:get_hs_list(false)
			local mtag_list= self:get_tag_list(true)
			local ptag_list= self:get_tag_list(false)
			local function update_half(half_items, half_config, other_half, left)
				for i, item in ipairs(half_items) do
					local item_config= half_config[i]
					local other_config= other_half[i]
					local other_blocks= other_config and other_config.is_wide
					if song and item_config and not other_blocks then
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
						elseif item_config.timing_info then
							if timing_data and item_config.timing_info[1] then
								local func_name= item_config.timing_info[2]
								item:set_text(item_config.timing_info[1])
								item:set_number(
									("%02d"):format(#timing_data[func_name](timing_data)))
							else
								item:set_text("")
								item:set_number("")
							end
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
			update_half(self.left_items, self.config[1], self.config[2], true)
			update_half(self.right_items, self.config[2], self.config[1], false)
			self:update_cursor()
		end
}}
