local keyboard_special_names= {"down", "up", "shift", "backspace",
															 "sc_left", "sc_right", "screenshot", "enter"}
local keyboard_num_rows= 4
local keyboard_mt= {
	__index={
		calculate_top=
			function(self)
				local row_height= 24
				return SCREEN_BOTTOM - ((keyboard_num_rows+1) * row_height)
			end,
		create_actors=
			function(self, name)
				self.name= name
				self.key_spacing= 24
				local row_height= 24
				local key_names= THEME:GetStringNamesInGroup("NameEntryKeyboard")
				local ur_keys_per_row= #key_names / keyboard_num_rows
				local keys_per_row= math.floor(ur_keys_per_row)
				local rows= {}
				local curr_row= 1
				local fraction= 0
				for c= 1, #key_names do
					if not rows[curr_row] then
						rows[curr_row]= {}
					end
					local row_len= #rows[curr_row]
					local str= THEME:GetString("NameEntryKeyboard", key_names[c])
					rows[curr_row][row_len+1]= str
					if row_len > keys_per_row-1 then
						fraction= fraction + (ur_keys_per_row - keys_per_row)
						if fraction < 1 then
							curr_row= curr_row+1
							fraction= fraction - 1
						end
					end
				end
				for i, row in ipairs(rows) do
					table.insert(row, 1,
											 get_string_wrapper("NameEntryKeyboardSpecials", "down"))
					row[#row+1]= get_string_wrapper("NameEntryKeyboardSpecials", "up")
				end
				do
					local special_row= {}
					for i, spec in ipairs(keyboard_special_names) do
						special_row[#special_row+1]=
							get_string_wrapper("NameEntryKeyboardSpecials", spec)
					end
					rows[#rows+1]= special_row
				end
				local x= SCREEN_CENTER_X
				local y= SCREEN_BOTTOM - (#rows * row_height)
				local args= {
					Name= name,
					InitCommand= function(subself)
						subself:xy(x, y)
						self.container= subself
						local enabled_players= GAMESTATE:GetEnabledPlayers()
						self.key_actors= {}
						for name, child in pairs(subself:GetChildren()) do
							local r, c= name:match("key(%d+)c(%d+)")
							if r and c then
								r= tonumber(r)
								c= tonumber(c)
								if not self.key_actors[r] then
									self.key_actors[r]= {}
								end
								self.key_actors[r][c]= child
							end
						end
						for r, row in ipairs(self.key_actors) do
							local keyw= (SCREEN_WIDTH-self.key_spacing) / #row
							for c, key in ipairs(row) do
								width_limit_text(key, keyw, 1)
							end
						end
						self:update_cursors()
					end
				}
				self.cursors= {}
				self.cursor_poses= {}
				local enabled_players= GAMESTATE:GetEnabledPlayers()
				for i, pn in ipairs(enabled_players) do
					self.cursors[pn]= setmetatable({}, amv_cursor_mt)
					self.cursor_poses[pn]= {1, 1}
					args[#args+1]= self.cursors[pn]:create_actors(
						"cursor"..pn, 0, 0, 0, 0, 1, solar_colors[pn]())
				end
				for i, r in ipairs(rows) do
					local keyw= (SCREEN_WIDTH-self.key_spacing) / #r
					local xmin= 0
					if #r % 2 == 0 then
						xmin= -(keyw * ((#r / 2) - .5))
					else
						xmin= -(keyw * math.floor(#r / 2))
					end
					for c, v in ipairs(r) do
						local cx= xmin + (keyw * (c-1))
						local cy= (i-1) * row_height
						args[#args+1]= normal_text("key"..i.."c"..c, v, nil, cx, cy)
					end
				end
				return Def.ActorFrame(args)
			end,
		update_cursors=
			function(self)
				local other_cur= false
				local other_pos= false
				for k, cur in pairs(self.cursors) do
					local curpos= self.cursor_poses[k]
					local curactor= self.key_actors[curpos[1]][curpos[2]]
					local xmn, xmx, ymn, ymx= rec_calc_actor_extent(curactor)
					local xp, yp= curactor:GetX(), curactor:GetY()
					cur:refit(xp, yp, xmx - xmn + 4, ymx - ymn + 4)
					if other_cur then
						if other_pos[1] == curpos[1] and other_pos[2] == curpos[2] then
							self.cursors[PLAYER_1]:left_half()
							self.cursors[PLAYER_2]:right_half()
						else
							self.cursors[PLAYER_1]:un_half()
							self.cursors[PLAYER_2]:un_half()
						end
					else
						other_cur= cur
						other_pos= curpos
					end
				end
			end,
		move_cursor_x=
			function(self, pn, dir)
				if not self.cursors[pn] then return end
				local pos= self.cursor_poses[pn]
				pos[2]= pos[2] + dir
				if pos[2] < 1 then
					pos[2]= #self.key_actors[pos[1]]
				end
				if pos[2] > #self.key_actors[pos[1]] then
					pos[2]= 1
				end
				self:update_cursors()
			end,
		move_cursor_y=
			function(self, pn, dir)
				if not self.cursors[pn] then return end
				local pos= self.cursor_poses[pn]
				local old_row_len= #self.key_actors[pos[1]]
				pos[1]= pos[1] + dir
				if pos[1] < 1 then
					pos[1]= #self.key_actors
				end
				if pos[1] > #self.key_actors then
					pos[1]= 1
				end
				local new_row_len= #self.key_actors[pos[1]]
				if old_row_len ~= new_row_len then
					pos[2]= math.round(scale(pos[2], 1, old_row_len, 1, new_row_len))
					if pos[2] < 1 then
						pos[2]= #self.key_actors[pos[1]]
					end
					if pos[2] > #self.key_actors[pos[1]] then
						pos[2]= 1
					end
				end
				self:update_cursors()
			end,
		move_to_exit=
			function(self, pn)
				self.cursor_poses[pn][1]= #self.key_actors
				self.cursor_poses[pn][2]= #self.key_actors[#self.key_actors]
				self:update_cursors()
			end,
		interact=
			function(self, pn)
				if not self.cursors[pn] then return nil end
				local pos= self.cursor_poses[pn]
				if pos[1] < #self.key_actors then
					if pos[2] == 1 then
						return keyboard_special_names[1]
					elseif pos[2] == #self.key_actors[pos[1]] then
						return keyboard_special_names[2]
					end
					return self.key_actors[pos[1]][pos[2]]:GetText()
				else
					return keyboard_special_names[pos[2]]
				end
			end,
}}

local name_display_mt= {
	__index= {
		create_actors=
			function(self, name, x, y, color, player_number)
				self.name= name
				self.max_len= 10
				local profile= PROFILEMAN:GetProfile(player_number)
				local player_name= profile:GetLastUsedHighScoreName()
				local args= {
					Name= name,
					InitCommand= function(subself)
						subself:xy(x, y)
						self.container= subself
						self.cursor= subself:GetChild("cursor")
						self.text= subself:GetChild("text")
						self:update_cursor()
					end
				}
				local time_x= 160
				if player_number == PLAYER_2 then
					time_x= time_x * -1
				end
				args[#args+1]= normal_text("text", player_name, color, 0, 0, 1)
				args[#args+1]= normal_text(
					"time", secs_to_str(cons_players[player_number].credit_time),
					color, time_x, 0, 1)
				args[#args+1]= Def.Quad{
					Name= "cursor", InitCommand= cmd(xy, 0, 12; diffuse, color;
																					 setsize, 12, 2)}
				return Def.ActorFrame(args)
			end,
		add_text=
			function(self, new_text)
				if self.shift then new_text= new_text:upper() end
				--Trace("Adding '" .. new_text .. "' to name.")
				local cur_text= self.text:GetText()
				if #cur_text < self.max_len then
					self.text:settext(cur_text .. new_text)
				end
				--Trace("'" .. self.text:GetText() .. "'")
				self:update_cursor()
				return #cur_text + #new_text >= self.max_len
			end,
		remove_text=
			function(self)
				--Trace("Removing last letter from name.")
				self.text:settext(self.text:GetText():sub(1, -2))
				--Trace("'" .. self.text:GetText() .. "'")
				self:update_cursor()
			end,
		get_text=
			function(self)
				return self.text:GetText()
			end,
		update_cursor=
			function(self)
				local xmn, xmx, ymn, ymx= rec_calc_actor_extent(self.text)
				self.cursor:finishtweening()
				self.cursor:linear(.1)
				self.cursor:x(xmx + 6)
			end,
		toggle_shift=
			function(self)
				self.shift= not self.shift
				if self.shift then
					self.cursor:y(-12)
				else
					self.cursor:y(12)
				end
			end,
		set_name_from_text=
			function(self)
			end
}}

local combined_play_history= {}
for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	for h, history_entry in ipairs(cons_players[pn].play_history) do
		local already_in_combined_history= false
		for c, cph_ent in ipairs(combined_play_history) do
			if (history_entry.song == cph_ent.song and
					history_entry.steps == cph_ent.steps and
					history_entry.start == cph_ent.start) then
				already_in_combined_history= true
				break
			end
		end
		if not already_in_combined_history then
			combined_play_history[#combined_play_history+1]= history_entry
		end
	end
end
local machine_profile= PROFILEMAN:GetMachineProfile()
local arrow_width= 16
local arrow_height= 32
local arrow_detail= 4
local arrow_pad= 2
local banner_height= 80
local banner_width= 256
local banner_ratio= banner_height / banner_width
local score_pad= 16
local score_disp_width= banner_width + score_pad
local disps_on_screen= math.floor(SCREEN_WIDTH / score_disp_width)
local min_on_screen= 3
-- Adjust width so that at least 3 will fit on screen.
local function recalc_sizes_to_fit_width(width)
	score_disp_width= width / min_on_screen
	banner_width= score_disp_width - score_pad
	banner_height= banner_width * banner_ratio
	disps_on_screen= math.floor(width / score_disp_width)
end
if disps_on_screen < min_on_screen and #combined_play_history >= min_on_screen then
	recalc_sizes_to_fit_width(SCREEN_WIDTH)
end
local all_scores_on_screen= #combined_play_history <= disps_on_screen
if not all_scores_on_screen then
	recalc_sizes_to_fit_width(SCREEN_WIDTH - (arrow_width*2) - (arrow_pad*4))
end

local hbanner_height= banner_height/2
local hbanner_width= banner_width/2
local entry_width= banner_width*.75
local hentry_width= entry_width/2

dofile(THEME:GetPathO("", "art_helpers.lua"))

local score_display_mt= {
	__index= {
		banner_center_y=
			function(self)
				local tz= .75
				local line_height= 24 * tz
				return hbanner_height + (line_height)
			end,
		create_actors=
			function(self, name)
				self.name= name
				local tz= .75
				local line_height= 24 * tz
				local args= {
					Name= name,
					InitCommand= function(subself)
						self.container= subself
						self.banner= subself:GetChild("banner")
						self.title= subself:GetChild("title")
						self.timeframe= subself:GetChild("timeframe")
						self.chart_info= subself:GetChild("chart_info")
						self.shadows= {}
						for s, tani in ipairs(self.tanis) do
							self.shadows[s]= subself:GetChild("shadow" .. s)
						end
					end
				}
				local next_y= line_height / 2
				args[#args+1]= normal_text("timeframe", "", nil, 0, next_y, tz)
				next_y= next_y + banner_height + line_height
				local why= self:banner_center_y()
				-- The arrows used to indicate that there are scores to scroll
				-- through need to be placed at the same y as the banner.
				args[#args+1]= Def.Sprite{InitCommand=cmd(y,why),Name="banner"}
				args[#args+1]= normal_text("title", "", nil, 0, next_y, tz)
				next_y= next_y + line_height
				args[#args+1]= normal_text("chart_info", "", nil, 0, next_y, tz)
				next_y= next_y + line_height
				local score_entries= 10
				self.tanis= {}
				local tani_params= { tx= -hentry_width, nx= hentry_width,
														 tz= tz, nz= tz, ta= left, na= right,
														 text_section= ""}
				for s= 1, score_entries do
					tani_params.sy= (line_height * (s-1)) + next_y
					self.tanis[s]= setmetatable({}, text_and_number_interface_mt)
					local quad_y= tani_params.sy
					if s % 2 == 1 then
						args[#args+1]= Def.Quad{
							Name= "shadow" .. s,
							InitCommand= function(self)
								self:y(quad_y)
								self:SetHeight(line_height)
								self:SetWidth(entry_width)
								self:diffuse(solar_colors.bg_shadow())
							end}
					end
					args[#args+1]= self.tanis[s]:create_actors("entry"..s, tani_params)
				end
				return Def.ActorFrame(args)
			end,
		transform=
			function(self, item_index, num_items, is_focus)
				self.container:finishtweening()
				self.container:linear(.1)
				local disp_start= 0
				if num_items % 2 == 0 then
					disp_start= -(((num_items/2)-.5) * score_disp_width)
				else
					disp_start= -(math.floor(num_items/2) * score_disp_width)
				end
				local myx= disp_start + ((item_index-1) * score_disp_width)
				self.container:x(myx)
				if math.abs(myx) + hbanner_width > SCREEN_WIDTH/2 then
					self.container:diffusealpha(0)
				else
					self.container:diffusealpha(1)
				end
			end,
		set=
			function(self, info)
				self.info= info
				if not info then return end
				-- info is a {song= Song, steps= Steps, start= time, finish= time}
				if info.song:HasBanner() then
					self.banner:LoadFromSongBanner(info.song)
					scale_to_fit(self.banner, banner_width, banner_height)
					self.banner:visible(true)
				else
					self.banner:visible(false)
				end
				self.title:settext(info.song:GetDisplayFullTitle())
				width_limit_text(self.title, banner_width)
				self.timeframe:settext(info.start .. "-" .. info.finish)
				width_limit_text(self.timeframe, banner_width)
				self.chart_info:settext(chart_info_text(info.steps))
				width_limit_text(self.chart_info, banner_width)
				local high_scores= machine_profile:GetHighScoreList(
					info.song, info.steps):GetHighScores()
				for i, tani in ipairs(self.tanis) do
					if high_scores[i] then
						local score= high_scores[i]:GetPercentDP()
						local score_color= color_for_score(score)
						tani:set_number(("%.2f%%"):format(score*100))
						tani.number:diffuse(score_color)
						tani:set_text(high_scores[i]:GetName())
						local num_width= tani.number:GetZoomedWidth()
						width_limit_text(tani.text, entry_width - num_width - 8)
						--Trace("tani " .. i .. " unhidden with score " .. score)
						if self.shadows[i] then
							self.shadows[i]:visible(true)
						end
						tani:unhide()
					else
						--Trace("tani " .. i .. " should be hidden.")
						--TODO: Track down why hide isn't working.
						tani:set_text("")
						tani:set_number("")
						tani:hide()
						if self.shadows[i] then
							self.shadows[i]:visible(false)
						end
					end
				end
			end
}}

local score_wheel= setmetatable({disable_wrapping= all_scores_on_screen}, sick_wheel_mt)
local keyboard= setmetatable({}, keyboard_mt)
local name_displays= {}
local unfinished_players= {}
for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	name_displays[pn]= setmetatable({}, name_display_mt)
end
for i, play_entry in ipairs(combined_play_history) do
	local score_list= machine_profile:GetHighScoreList(play_entry.song, play_entry.steps):GetHighScores()
	for h, score in ipairs(score_list) do
		if score:IsFillInMarker() then
			if score:GetName():find("P1") then
				unfinished_players[PLAYER_1]= true
			elseif score:GetName():find("P2") then
				unfinished_players[PLAYER_2]= true
			end
		end
	end
end

local keyboard_top= keyboard:calculate_top()
local nd_poses= {
	[PLAYER_1]= {SCREEN_CENTER_X * .5, keyboard_top-24},
	[PLAYER_2]= {SCREEN_CENTER_X * 1.5, keyboard_top-24}}

local function maybe_finish()
	for k, fin in pairs(unfinished_players) do
		if fin then return end
	end
	SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
end

local function input(event)
	local pn= event.PlayerNumber
	local code= event.GameButton
	local press= event.type
	if not name_displays[pn] then return end
	if press == "InputEventType_Release" then return end
	if code == "MenuLeft" then
		keyboard:move_cursor_x(pn, -1)
	elseif code == "MenuRight" then
		keyboard:move_cursor_x(pn, 1)
	elseif code == "MenuUp" then
		keyboard:move_cursor_y(pn, -1)
	elseif code == "MenuDown" or code == "Select" then
		keyboard:move_cursor_y(pn, 1)
	elseif code == "Start" then
		local key_ret= keyboard:interact(pn)
		if key_ret == "up" then
			keyboard:move_cursor_y(pn, -1)
		elseif key_ret == "down" then
			keyboard:move_cursor_y(pn, 1)
		elseif key_ret == "shift" then
			name_displays[pn]:toggle_shift()
		elseif key_ret == "backspace" then
			if unfinished_players[pn] then
				name_displays[pn]:remove_text()
			end
		elseif key_ret == "enter" then
			local screen= SCREENMAN:GetTopScreen()
			SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
			local player_name= name_displays[pn]:get_text()
			local profile= PROFILEMAN:GetProfile(pn)
			if profile then
				profile:SetLastUsedHighScoreName(player_name)
			end
			GAMESTATE:StoreRankingName(pn, player_name)
			unfinished_players[pn]= false
			maybe_finish()
		elseif key_ret == "sc_left" then
			if disps_on_screen < #combined_play_history then
				score_wheel:scroll_by_amount(-1)
			end
		elseif key_ret == "sc_right" then
			if disps_on_screen < #combined_play_history then
				score_wheel:scroll_by_amount(1)
			end
		elseif key_ret == "screenshot" then
			local prefix= "name_entry_"
			local saved, screenshotname= SaveScreenshot(pn, true, false, prefix, "")
			if not saved then
				Trace("Failed to save a screenshot?")
			end
		elseif key_ret then
			if unfinished_players[pn] then
				local full= name_displays[pn]:add_text(key_ret)
				if full then
					keyboard:move_to_exit(pn)
				end
			end
		end
	end
end

local args= {
	InitCommand= function(self)
		score_wheel:set_info_set(combined_play_history, 1)
	end,
	keyboard:create_actors("keyboard"),
	Def.ActorFrame{
		Name= "code_interpreter",
		OnCommand= function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(input)
		end,
	}
}

local score_wheel_y= SCREEN_TOP+4
if all_scores_on_screen then
	args[#args+1]= score_wheel:create_actors(
		#combined_play_history, score_display_mt, SCREEN_CENTER_X,
		score_wheel_y)
else
	args[#args+1]= score_wheel:create_actors(
		disps_on_screen+2, score_display_mt, SCREEN_CENTER_X, score_wheel_y)
	local arrow_y= score_wheel_y+score_display_mt.__index.banner_center_y()
	args[#args+1]= arrow_amv(
		"left_arrow", SCREEN_LEFT + arrow_width + arrow_pad,
		arrow_y, arrow_width, arrow_height, arrow_detail,
		solar_colors.uf_text())
	args[#args+1]= arrow_amv(
		"right_arrow", SCREEN_RIGHT - arrow_width - arrow_pad,
		arrow_y, -arrow_width, arrow_height, arrow_detail,
		solar_colors.uf_text())
end
for pn, nd in pairs(name_displays) do
	args[#args+1]= nd:create_actors("nd"..pn, nd_poses[pn][1], nd_poses[pn][2],
																	solar_colors[pn](), pn)
end

return Def.ActorFrame(args)
