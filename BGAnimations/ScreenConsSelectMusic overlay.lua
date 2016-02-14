GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(1)
update_steps_types_to_show()
--[[
local skin_params= {tap_graphic= "Chromatic", rots= {Left= -5, Right= 45}}
GAMESTATE:set_noteskin_params(PLAYER_2, skin_params)
Trace("skin params after first set:")
rec_print_table(GAMESTATE:get_noteskin_params(PLAYER_2))
skin_params.tap_graphic= "3_9"
Trace("skin params after second set:")
rec_print_table(GAMESTATE:get_noteskin_params(PLAYER_2))
Trace("done")
local skin_info= NEWSKIN:get_skin_parameter_info("judgmental")
rec_print_table(skin_info)
lua.ReportScriptError("dumped skin_info from SCSM")
skin_info= NEWSKIN:get_skin_parameter_info("default")
rec_print_table(skin_info)
lua.ReportScriptError("dumped skin_info for default")
]]

local press_ignore_reporter= false
local function show_ignore_message(message)
--	press_ignore_reporter:settext(message):finishtweening()
--		:linear(.2):diffusealpha(1):sleep(5):linear(.5):diffusealpha(0)
	Trace(message)
end

local auto_scrolling= nil
local next_auto_scroll_time= 0
local time_before_auto_scroll= .15
local time_between_auto_scroll= .08
local fast_auto_scroll= nil
local fast_scroll_start_time= 0
local time_before_fast_scroll= .8
local time_between_fast_scroll= .02

local sort_width= _screen.w*.25
local pad= 4
local hpad= 2
local header_size= 32
local footer_size= 32
local hhead_size= header_size * .5
local hfoot_size= footer_size * .5

local pane_text_zoom= .625
local pane_text_height= 16 * (pane_text_zoom / 0.5875)
local pane_w= 200
local pane_h= pane_text_height * max_pain_rows + 4
local pane_y= SCREEN_BOTTOM-(pane_h/2)-pad
local pane_yoff= -32 -pane_h * .5 + pane_text_height * .5 + 2
local pane_ttx= 0
local menu_text_zoom= pane_text_zoom
local pane_menu_h= pane_h
local pane_menu_w= pane_w - 8
local pane_menu_y= pane_y + pane_yoff
local pane_manip_y= pane_y + pane_yoff + 40

local pane_x_off= (pane_w*.5) + pad
local lpane_x= pane_x_off
local rpane_x= _screen.w - pane_x_off

local width_pane_takes_from_wheel= pane_w + (pad * 2)
local wheel_x= _screen.cx
local wheel_width= _screen.w
local wheel_move_time= .1
local banner_w= wheel_width - 4
local banner_h= 80
local curr_group_name= ""
local basic_info_height= 48
local extra_info_height= 40
local expanded_info_height= basic_info_height + (extra_info_height * 2)
local focus_element_info= false
local player_stuff= {}

local entering_song= false
local options_time= 1.5
local go_to_options= false
local picking_steps= false
local double_tap_time= .5

local update_player_cursors= noop_nil
local reset_pressed_since_menu_change= noop_nil

local options_message= false
local timer_actor= false
local function get_screen_time()
	if timer_actor then
		return timer_actor:GetSecsIntoEffect()
	else
		return 0
	end
end

dofile(THEME:GetPathO("", "music_wheel.lua"))
local music_wheel= setmetatable({}, music_whale_mt)
local activate_status

local player_profiles= {}
local machine_profile= PROFILEMAN:GetMachineProfile()

function update_player_profile(pn)
	player_profiles[pn]= PROFILEMAN:GetProfile(pn)
end
update_player_profile(PLAYER_1)
update_player_profile(PLAYER_2)

local function save_profile_stuff()
	save_all_favorites()
	save_all_tags()
	save_censored_list()
end

do
	local song_ops= GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		for name, value in pairs(cons_players[pn].persistent_song_mods) do
			if song_ops[name] then
				song_ops[name](song_ops, value)
			end
		end
	end
end

local function ensure_enough_stages()
	-- Give everybody enough tokens to play, as a way of disabling the stage system.
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		while GAMESTATE:GetNumStagesLeft(pn) < 3 do
			GAMESTATE:AddStageToPlayer(pn)
		end
	end
end

local show_inactive_pane= false
local active_pane_info= {}
local function calc_wheel_width()
	local active_pane_count= 0
	if show_inactive_pane then
		active_pane_count= 2
	else
		for pane, active in pairs(active_pane_info) do
			if active then
				active_pane_count= active_pane_count + 1
			end
		end
	end
	wheel_width= _screen.w - (width_pane_takes_from_wheel * active_pane_count)
end
local normal_layout_choices= 3
local wheel_layout_choices= {
	"left", "middle", "right", "opposite", "same", "random",
}
local wheel_layouts= {
	left= function()
		if show_inactive_pane or active_pane_info[PLAYER_2] then
			rpane_x= _screen.w - pane_x_off
		else
			rpane_x= _screen.w + pane_x_off
		end
		lpane_x= rpane_x - (pane_w + (pad*2))
		wheel_x= wheel_width * .5
	end,
	middle= function()
		lpane_x= pane_x_off
		rpane_x= _screen.w - pane_x_off
		if show_inactive_pane then
			wheel_x= _screen.cx
		else
			if active_pane_info[PLAYER_1] then
				if active_pane_info[PLAYER_2] then
					wheel_x= _screen.cx
				else
					wheel_x= _screen.w - (wheel_width * .5)
				end
			else
				if active_pane_info[PLAYER_2] then
					wheel_x= wheel_width * .5
				else
					wheel_x= _screen.cx
				end
			end
		end
	end,
	right= function()
		if show_inactive_pane or active_pane_info[PLAYER_1] then
			lpane_x= pane_x_off
		else
			lpane_x= -pane_x_off
		end
		rpane_x= lpane_x + (pane_w + (pad*2))
		wheel_x= _screen.w - (wheel_width * .5)
	end,
	unset= noop_nil,
}
local curr_wheel_layout= "unset"
local function update_wheel_layout()
	calc_wheel_width()
	wheel_layouts[curr_wheel_layout]()
	music_wheel:move_resize(wheel_x, wheel_width)
	focus_element_info:resize()
	local pane_x= {[PLAYER_1]= lpane_x, [PLAYER_2]= rpane_x}
	for pn, stuff in pairs(player_stuff) do
		stuff:stoptweening():april_linear(wheel_move_time):x(pane_x[pn])
	end
end
local function set_wheel_layout(layout)
	if layout == curr_wheel_layout then return end
	curr_wheel_layout= layout
	update_wheel_layout()
end
local function set_show_inactive_pane(show)
	if show == show_inactive_pane then return end
	show_inactive_pane= show
	update_wheel_layout()
end
local function update_show_inactive_pane()
	local show= false
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		show= show or cons_players[pn].select_music.show_inactive_pane
	end
	set_show_inactive_pane(show)
end
local function set_pane_active(pane, active)
	if active_pane_info[pane] == active then return end
	active_pane_info[pane]= active
	update_wheel_layout()
end
local opposite_layouts= {[PLAYER_1]= "right", [PLAYER_2]= "left"}
local same_layouts= {[PLAYER_1]= "left", [PLAYER_2]= "right"}
local function update_curr_wheel_layout()
	local votes= {left= 0, middle= 0, right= 0}
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local lay= cons_players[pn].select_music.wheel_layout
		if lay == "random" then
			lay= wheel_layout_choices[math.random(1, normal_layout_choices)]
		end
		if lay == "opposite" then
			lay= opposite_layouts[pn]
		elseif lay == "same" then
			lay= same_layouts[pn]
		end
		if votes[lay] then
			votes[lay]= votes[lay] + 1
		end
	end
	local new_layout= "middle"
	if votes.middle > 0 or votes.left == votes.right then
		new_layout= "middle"
	elseif votes.left > votes.right then
		new_layout= "left"
	else
		new_layout= "right"
	end
	set_wheel_layout(new_layout)
end

local function set_closest_steps_to_preferred(pn)
	local song= gamestate_get_curr_song()
	if not song then
		gamestate_set_curr_steps(pn, nil)
		return
	end
	local preferred_diff= GAMESTATE:GetPreferredDifficulty(pn) or
		"Difficulty_Beginner"
	local pref_steps_type= get_preferred_steps_type(pn)
	local curr_steps_type= GAMESTATE:GetCurrentStyle(pn):GetStepsType()
	local candidates= sort_steps_list(get_filtered_steps_list())
	if candidates and #candidates > 0 then
		local steps_set= false
		local closest
		for i, steps in ipairs(candidates) do
			if not closest then
				closest= {
					steps= steps, diff_diff=
						math.abs(Difficulty:Compare(preferred_diff, steps:GetDifficulty())),
					steps_type= steps:GetStepsType()}
			else
				local this_difference= math.abs(
					Difficulty:Compare(preferred_diff, steps:GetDifficulty()))
				local this_steps_type= steps:GetStepsType()
				if closest.steps_type == pref_steps_type then
					if this_steps_type == pref_steps_type and
					this_difference < closest.diff_diff then
						closest= {steps= steps, diff_diff= this_difference,
											steps_type= this_steps_type}
					end
				else
					if this_steps_type == pref_steps_type
					or this_difference < closest.diff_diff then
						closest= {steps= steps, diff_diff= this_difference,
											steps_type= this_steps_type}
					end
				end
			end
		end
		if closest then
			cons_set_current_steps(pn, closest.steps)
		else
			cons_set_current_steps(pn, candidates[1])
		end
	end
end

local curr_group= false

local function change_sort_text(new_text)
	local overlay= SCREENMAN:GetTopScreen():GetChild("Overlay")
	local stext= overlay:GetChild("header"):GetChild("sort_text")
	new_text= new_text or stext:GetText()
	stext:settext(new_text)
	width_clip_limit_text(stext, sort_width)
	curr_group:playcommand("Set")
end

local function update_curr_group()
	curr_group:playcommand("Set")
end

local cdtitle_size= (extra_info_height*2) - (pad * 2)
local function cdtitle()
	if scrambler_mode then
		return swapping_amv(
			"CDTitle", 0, 0, cdtitle_size, cdtitle_size, 8, 8, nil, "_", false, true, true, {
				OnCommand= play_set,
				CurrentSongChangedMessageCommand= play_set,
				SetCommand= function(self)
					local song= GAMESTATE:GetCurrentSong()
					if song and song:HasCDTitle()then
						self:playcommand("ChangeTexture", {song:GetCDTitlePath()})
						self:visible(true)
					else
						self:visible(false)
					end
				end,
		})
	else
		return Def.Sprite{
			Name="CDTitle", OnCommand= cmd(playcommand, "Set"),
			CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
			SetCommand= function(self)
				-- Courses can't have CDTitles, so gamestate_get_curr_song isn't used.
				local song= GAMESTATE:GetCurrentSong()
				if song and song:HasCDTitle()then
					self:LoadBanner(song:GetCDTitlePath())
					self:visible(true)
					-- Jousway suggests fucking people with fucking huge cdtitles.
					scale_to_fit(self, cdtitle_size, cdtitle_size)
				else
					self:visible(false)
				end
			end
		}
	end
end

local banner_act= false
local function banner(x, y)
	if scrambler_mode then
		return swapping_amv(
			"Banner", x, y, banner_w, banner_h, 16, 5, nil, "_",
			false, true, true, {
				SubInitCommand= function(self) banner_act= self end,
				CurrentCourseChangedMessageCommand= play_set,
				CurrentSongChangedMessageCommand= play_set,
				SetCommand= function(self)
					local song= GAMESTATE:GetCurrentSong() or GAMESTATE:GetCurrentCourse()
					if song and song:HasBanner() then
						self:playcommand("ChangeTexture", {song:GetBannerPath()})
						self:diffusealpha(1)
					else
						self:diffusealpha(0)
					end
				end,
				current_group_changedMessageCommand= function(self, param)
					local name= param[1]
					if songman_does_group_exist(name) then
						local path= songman_get_group_banner_path(name)
						if path and path ~= "" then
							self:playcommand("ChangeTexture", {path})
							self:diffusealpha(1)
						else
							self:diffusealpha(0)
						end
					else
						self:diffusealpha(0)
					end
				end,
		})
	else
		return Def.Sprite{
			InitCommand= function(self) banner_act= self:xy(x, y) end,
			CurrentCourseChangedMessageCommand= cmd(playcommand, "Set"),
			CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
			SetCommand= function(self)
				local song= gamestate_get_curr_song()
				if song and song:HasBanner() then
					self:LoadBanner(song:GetBannerPath())
					self:diffusealpha(1)
					scale_to_fit(self, banner_w, banner_h)
				else
					self:diffusealpha(0)
				end
			end,
			current_group_changedMessageCommand= function(self, param)
				local name= param[1]
				if songman_does_group_exist(name) then
					local path= songman_get_group_banner_path(name)
					if path and path ~= "" then
						self:LoadBanner(path)
						self:diffusealpha(1)
						scale_to_fit(self, banner_w, banner_h)
					else
						self:diffusealpha(0)
					end
				else
					self:diffusealpha(0)
				end
			end
		}
	end
end

local focus_element_info_mt= {
	__index= {
		create_actors= function(self, x, y)
			self.middle_height= basic_info_height
			local bihd= (basic_info_height*2)
			self.jacket_width= bihd - (pad*2)
			self.symbol_size= 12
			local symbol_spacing= (bihd - self.symbol_size - pad * 2) / (#Difficulty-1)
			self.hsymw= self.symbol_size * .5
			local symbol_y= -basic_info_height + self.hsymw + pad
			self.title_y= -22
			self.split_title_top_y= self.title_y - 12
			self.split_title_bot_y= self.title_y + 12
			self.full_title= ""
			self.full_genre= ""
			self.full_artist= ""
			self.full_subtitle= ""
			self.full_group= ""
			local cdtitle_y= 0
			local auth_start= -extra_info_height+hpad
			local args= {
				InitCommand= function(subself)
					self.container= subself
					self.title= subself:GetChild("title")
					self.sec_title= subself:GetChild("sec_title")
					self.subtitle= subself:GetChild("subtitle")
					self.length= subself:GetChild("length")
					self.genre= subself:GetChild("genre")
					self.artist= subself:GetChild("artist")
					self.group= subself:GetChild("group")
					rot_color_text(self.title, fetch_color("text"))
					rot_color_text(self.sec_title, fetch_color("text"))
					alt_rot_color_text(self.subtitle, fetch_color("text"))
					local stroke= fetch_color("stroke")
					for i, difft in pairs(self.difficulty_counts) do
						difft.text:strokecolor(stroke)
						difft.number:strokecolor(stroke)
					end
					for i, part in ipairs{self.song_count, self.diff_range, self.nps_range} do
						part.text:strokecolor(stroke)
						part.number:strokecolor(stroke)
					end
					subself:xy(x, y)
					self:resize()
				end,
				Def.Quad{
					InitCommand= function(subself)
						self.bg= subself
						subself:diffusealpha(0)
					end
				},
				Def.Sprite{
					InitCommand= function(subself)
						self.jacket= subself
					end
				},
				normal_text("title", "", fetch_color("text"), fetch_color("stroke"), 0, self.title_y, 1),
				normal_text("sec_title", "", fetch_color("text"), fetch_color("stroke"), 0, self.title_y, 1),
				normal_text("subtitle", "", fetch_color("text"), fetch_color("stroke"), 0, 12, .5),
				normal_text("length", "", fetch_color("text"), fetch_color("stroke"), 0, 24, .5, left),
				normal_text("genre", "", fetch_color("text"), fetch_color("stroke"), 0, 24, .5, right),
				normal_text("group", "", fetch_color("text"), fetch_color("stroke"), 0, 36, .5, left),
				normal_text("artist", "", fetch_color("text"), fetch_color("stroke"), 0, 36, .5, right),
			}
			local above_args= {
				InitCommand= function(subself)
					self.above_info= subself
					subself:xy(0, -self.middle_height):zoomy(0)
				end,
				banner(0, 0),
			}
			local below_args= {
				InitCommand= function(subself)
					self.below_info= subself
					self.cdtitle= subself:GetChild("CDTitle")
					self.cdtitle:y(cdtitle_y)
					self.steps_by= subself:GetChild("steps_by")
					subself:xy(0, self.middle_height):zoomy(0)
					self.steps_by:settext(
						get_string_wrapper("SelectMusicExtraInfo", "steps_by"))
				end,
				cdtitle(),
				normal_text("steps_by", "", fetch_color("text"), fetch_color("stroke"), 0, auth_start, .5),
			}
			self.song_count= setmetatable({}, text_and_number_interface_mt)
			args[#args+1]= self.song_count:create_actors(
				"song_count", {sy= 12, tx= -4, tz= .5, nx= 4,
											 nz= .5, ts= ":", tt= "song_count",
											 text_section= "SelectMusicExtraInfo"})
			self.auth_entries= {}
			self.auth_limit= 5
			for i= 1, self.auth_limit do
				below_args[#below_args+1]= normal_text(
					"auth"..i, "", fetch_color("text"), fetch_color("stroke"),
					0, auth_start + (i*12), .5, center, {
						InitCommand= function(subself) self.auth_entries[i]= subself end
				})
			end
			self.diff_range= setmetatable({}, text_and_number_interface_mt)
			self.nps_range= setmetatable({}, text_and_number_interface_mt)
			self.difficulty_symbols= {}
			self.difficulty_counts= {}
			local diff_tani_args= {
				tx= -4, tz= .5, nx= 4, nz= .5, ts= ":",
				text_section= "DifficultyNames"
			}
			for i, diff in ipairs(Difficulty) do
				args[#args+1]= Def.Sprite{
					Texture= "big_circle", InitCommand= function(subself)
						self.difficulty_symbols[diff]= subself
						subself:visible(false):zoom(self.symbol_size/big_circle_size)
							:diffuse(diff_to_color(diff))
							:y(symbol_y + ((i-1) * symbol_spacing))
					end
				}
				local new_tani= setmetatable({}, text_and_number_interface_mt)
				diff_tani_args.tt= diff
				diff_tani_args.tc= diff_to_color(diff)
				self.difficulty_counts[diff]= new_tani
				diff_tani_args.sy= 12 * i - extra_info_height
				below_args[#below_args+1]= new_tani:create_actors(
					"tani_" .. diff, diff_tani_args)
			end
			args[#args+1]= self.diff_range:create_actors(
				"diff_range", {sy= 24, tx= -4, tz= .5, nx= 4, nz= .5, ts= ":",
											 tt= "difficulty_range", text_section= "SelectMusicExtraInfo"})
			args[#args+1]= self.nps_range:create_actors(
				"nps_range", {sy= 36, tx= -4, tz= .5, nx= 4, nz= .5, ts= ":",
											 tt= "nps_range", text_section= "SelectMusicExtraInfo"})
			args[#args+1]= Def.ActorFrame(above_args)
			args[#args+1]= Def.ActorFrame(below_args)
			return Def.ActorFrame(args)
		end,
		resize= function(self)
			self.bg:setsize(wheel_width-hpad, expanded_info_height*2)
			self.left_x= wheel_width * -.15
			self.right_x= wheel_width * .25
			local hwheelw= wheel_width * .5
			local hjackw= self.jacket_width * .5
			local jacket_x= -hwheelw + hjackw + hpad
			local symbol_x= hwheelw - self.hsymw - hpad
			self.title_width= symbol_x - jacket_x - hjackw - self.hsymw - (pad*2)
			local title_x= jacket_x + hjackw + pad + (self.title_width * .5)
			local len_x= jacket_x + hjackw + pad
			local genre_x= symbol_x - self.hsymw - pad
			local artist_x= genre_x
			local group_x= len_x
			local cdtitle_x= hwheelw - cdtitle_size*.5 - pad
			self.auth_width= ((hwheelw - self.right_x) * 2) - pad

			self.container:stoptweening():april_linear(wheel_move_time):x(wheel_x)
			self.jacket:x(jacket_x)
			self.title:x(title_x)
			self.sec_title:x(title_x)
			self.subtitle:x(title_x)
			self.length:x(len_x)
			self.genre:x(genre_x)
			self.group:x(group_x)
			self.artist:x(artist_x)
			self:width_clip_text()
			for d, sym in pairs(self.difficulty_symbols) do
				sym:x(symbol_x)
			end
			self.cdtitle:x(cdtitle_x)
			self.steps_by:x(self.right_x)
			self.song_count.container:x(title_x)
			for i, ent in ipairs(self.auth_entries) do
				ent:x(self.right_x)
			end
			for d, tani in pairs(self.difficulty_counts) do
				tani.container:x(self.left_x)
			end
			self.diff_range.container:x(title_x)
			self.nps_range.container:x(title_x)
		end,
		width_clip_text= function(self)
			self:set_title_text(self.full_title)
			if self.full_genre ~= "" then
				self.genre:settext(
					get_string_wrapper("SelectMusicExtraInfo", "song_genre") ..
						": " .. self.full_genre):visible(true)
			end
			if self.full_group ~= "" then
				self.group:settext(
					get_string_wrapper("SelectMusicExtraInfo", "song_group") ..
						": " .. self.full_group):visible(true)
			end
			if self.full_artist ~= "" then
				self.artist:settext(
					get_string_wrapper("SelectMusicExtraInfo", "song_artist") ..
						": " .. self.full_artist):visible(true)
			end
			if self.full_subtitle ~= "" then
				self.subtitle:settext(self.full_subtitle):visible(true)
			end
			width_clip_limit_text(self.subtitle, self.title_width, .5)
			width_clip_limit_text(self.artist, self.title_width*.5, .5)
			local artist_len= self.artist:GetZoomedWidth()
			width_clip_limit_text(self.group, self.title_width-artist_len - pad*2, .5)
			local len_len= self.length:GetZoomedWidth()
			width_clip_limit_text(self.genre, self.title_width-len_len - pad*2, .5)
		end,
		hide_song_bucket_info= function(self)
			self.song_count:hide()
			for i, diff in ipairs(Difficulty) do
				self.difficulty_counts[diff]:set_number("")
				self.difficulty_counts[diff]:hide()
				self.difficulty_symbols[diff]:visible(false)
			end
			self.diff_range:hide()
			self.nps_range:hide()
			self.steps_by:visible(false)
			for i= 1, #self.auth_entries do
				self.auth_entries[i]:visible(false)
			end
		end,
		hide_song_info= function(self)
			self.length:visible(false)
			self.genre:visible(false)
			self.artist:visible(false)
			self.group:visible(false)
		end,
		set_jacket_to_image= function(self, path)
			if path and path ~= "" then
				self.jacket:LoadBanner(path)
				self.jacket:visible(true)
				scale_to_fit(self.jacket, self.jacket_width, self.jacket_width)
			end
		end,
		set_title_text= function(self, text)
			self.full_title= text
			self.title:zoomx(1)
			self.title:settext(text)
			local total_width= self.title:GetWidth()
			if total_width > self.title_width then
				if total_width > self.title_width * 2 then
					width_clip_limit_text(self.title, self.title_width * 2)
					text= self.title:GetText()
				end
				local split_point= math.floor(#text / 2)
				local space_before_split= text:sub(1, split_point):reverse():find(" ")
				local space_after_split= text:sub(split_point):find(" ")
				if space_before_split then
					if not space_after_split
					or space_before_split < space_after_split then
						split_point= split_point - space_before_split
					else
						split_point= split_point + space_after_split - 1
					end
				elseif space_after_split then
					split_point= split_point + space_after_split - 1
				end
				local first_part= text:sub(1, split_point)
				local second_part= text:sub(split_point + 1)
				self.title:settext(first_part):y(self.split_title_top_y)
				width_limit_text(self.title, self.title_width)
				self.sec_title:settext(second_part)
					:y(self.split_title_bot_y):visible(true)
				width_clip_limit_text(self.sec_title, self.title_width)
			else
				self.title:y(self.title_y)
				self.sec_title:visible(false)
			end
		end,
		update_title= function(self, item)
			self:hide_song_bucket_info()
			self:hide_song_info()
			self.subtitle:visible(false)
			self.jacket:visible(false)
			if item.bucket_info then
				self:set_title_text(nice_bucket_disp_name(item.bucket_info))
				if item.is_current_group then
					rot_color_text(self.bg, wheel_colors.current_group)
				else
					self.bg:diffuse(wheel_colors.group)
					rot_color_text(self.bg, wheel_colors.group)
				end
			elseif item.sort_info then
				self:set_title_text(item.sort_info.name)
				rot_color_text(self.bg, wheel_colors.sort)
			else
				if item.random_info then
					rot_color_text(self.bg, wheel_colors.random)
				elseif item.is_prev then
					rot_color_text(self.bg, wheel_colors.prev_song)
				else
					rot_color_text(self.bg, wheel_colors.song)
				end
				local song= gamestate_get_curr_song()
				if song then
					self.full_title= song_get_main_title(song)
					self.length:settext(
						get_string_wrapper("SelectMusicExtraInfo", "song_len") .. ": " ..
							secs_to_str(song_get_length(song))):visible(true)
					self.full_genre= song:GetGenre()
					self.full_artist= song:GetDisplayArtist()
					self.full_group= song:GetGroupName()
					self.full_subtitle= song:GetDisplaySubTitle()
				else
					self.title:visible(false)
				end
			end
			width_clip_limit_text(self.title, self.title_width)
			self:width_clip_text()
			self.bg:diffusealpha(.75)
		end,
		update= function(self, item)
			self.full_genre= ""
			self.full_artist= ""
			self.full_subtitle= ""
			self.full_group= ""
			self.info= item
			self:update_title(item)
			if item.bucket_info then
				local item_group_name= nice_bucket_disp_name(item.bucket_info)
				if songman_does_group_exist(item_group_name) then
					self:set_jacket_to_image(
						songman_get_group_banner_path(item_group_name))
					banner_act:playcommand("current_group_changed", {item_group_name})
				end
				if item.bucket_info.song_count then
					local song_count= item.bucket_info.song_count or 0
					self.song_count:unhide()
					self.song_count:set_number(song_count)
					for i, diff in ipairs(Difficulty) do
						local count= item.bucket_info.difficulties[diff]
						self.difficulty_counts[diff]:set_text(diff)
						if count then
							self.difficulty_counts[diff]:set_number(("%03d"):format(count))
							self.difficulty_counts[diff]:unhide()
							self.difficulty_symbols[diff]:visible(true)
								:diffusealpha(count / song_count)
						else
							self.difficulty_counts[diff]:set_number(("%03d"):format(0))
						end
					end
					local mins= item.bucket_info.mins
					local maxs= item.bucket_info.maxs
					self.diff_range:unhide()
					self.diff_range:set_number(mins.meter .. " - " .. maxs.meter)
					local function npsfm(nps)
						return ("%.2f"):format(nps)
					end
					self.nps_range:unhide()
					self.nps_range:set_number(npsfm(mins.nps).." - "..npsfm(maxs.nps))
					local auth_count= 0
					foreach_ordered(
						item.bucket_info.step_artists,
						function(key, value)
							if auth_count > self.auth_limit then return end
							auth_count= auth_count + 1
							local entry= self.auth_entries[auth_count]
							if not entry then return end
							entry:settext(key):visible(true)
							width_clip_limit_text(entry, self.auth_width, .5)
						end
					)
					if auth_count > self.auth_limit then
						local entry= self.auth_entries[#self.auth_entries]
						entry:settext(
							get_string_wrapper("SelectMusicExtraInfo", "and_more"))
						width_clip_limit_text(entry, self.auth_width, .5)
					end
					self.steps_by:visible(true)
				end
			else
				local song= gamestate_get_curr_song()
				if song then
					if song:HasJacket() then
						self:set_jacket_to_image(song:GetJacketPath())
					elseif song:HasBackground() then
						self:set_jacket_to_image(song:GetBackgroundPath())
					end
					local steps_list= get_filtered_steps_list()
					local steps_texts= {}
					local steps_counts= {}
					local list_limit= 5
					for i, steps in ipairs(steps_list) do
						local diff= steps:GetDifficulty()
						local text_list= steps_texts[diff] or {}
						steps_counts[diff]= 1 + (steps_counts[diff] or 0)
						self.difficulty_symbols[diff]:visible(true):diffusealpha(1)
						if steps_counts[diff] < list_limit then
							text_list[#text_list+1]= get_string_wrapper(
							"DifficultyNames", steps:GetStepsType()) .. "-" ..
								steps:GetMeter()
							steps_texts[diff]= text_list
						end
					end
					for diff, text in pairs(steps_texts) do
						if steps_counts[diff] >= list_limit then
							text[list_limit]= get_string_wrapper(
								"SelectMusicExtraInfo", "and_more")
						end
						self.difficulty_counts[diff]:set_number(table.concat(text, ", "))
						self.difficulty_counts[diff]:set_text(
							"(" .. steps_counts[diff] .. ")  " ..
								get_string_wrapper("DifficultyNames", diff))
						self.difficulty_counts[diff]:unhide()
					end
				end
			end
		end,
		hide= function(self)
			self.container:visible(false)
			self.hidden= true
		end,
		unhide= function(self)
			self.container:visible(true)
			self.hidden= false
		end,
		collapse= function(self)
			local newy= self.middle_height
			self.expanded= false
			self.above_info:stoptweening():april_linear(wheel_move_time):zoomy(0):y(-newy)
			self.below_info:stoptweening():april_linear(wheel_move_time):zoomy(0):y(newy)
			self.bg:stoptweening():april_linear(wheel_move_time)
				:zoomy((basic_info_height*2)/(expanded_info_height*2))
		end,
		expand= function(self)
			local newy= self.middle_height + extra_info_height
			self.expanded= true
			self.above_info:stoptweening():april_linear(wheel_move_time):zoomy(1):y(-newy+hpad)
			self.below_info:stoptweening():april_linear(wheel_move_time):zoomy(1):y(newy-hpad)
			self.bg:stoptweening():april_linear(wheel_move_time):zoomy(1)
		end
}}
focus_element_info= setmetatable({}, focus_element_info_mt)

local filter_reason_item_mt= {
	__index= {
		create_actors= function(self, name)
			return Def.ActorFrame{
				InitCommand= function(subself)
					self.container= subself
					self.group_name= subself:GetChild("group_name")
					self.song_name= subself:GetChild("song_name")
					self.filter_name= subself:GetChild("filter_name")
				end,
				normal_text("group_name", "", fetch_color("music_select.music_wheel.group"), fetch_color("stroke"), 0, 0, .5),
				normal_text("song_name", "", fetch_color("music_select.music_wheel.song"), fetch_color("stroke"), 0, 12, .5),
				normal_text("filter_name", "", fetch_color("music_select.music_wheel.sort"), fetch_color("stroke"), 0, 24, .5),
			}
		end,
		transform= function(self, item_index, num_items)
			self.container:y(item_index * 40)
		end,
		set= function(self, info)
			self.info= info
			if not info then
				self.group_name:settext("")
				self.song_name:settext("")
				self.filter_name:settext("")
				return
			end
			self.group_name:settext(info.song:GetGroupName())
			self.song_name:settext(info.song:GetDisplayMainTitle())
			self.filter_name:settext(info.filter)
			for i, part in ipairs{self.group_name, self.song_name, self.filter_name} do
				width_limit_text(part, pane_w - 8, .5)
			end
		end,
}}

local filter_reason_viewer_mt= {
	__index= {
		create_actors= function(self, x, y, pn)
			self.framer= setmetatable({disable_wrapping= true}, frame_helper_mt)
			self.scroller= setmetatable({}, sick_wheel_mt)
			self.cursor_pos= 1
			return Def.ActorFrame{
				InitCommand= function(subself)
					self.container= subself:xy(x, y)
					self:hide()
				end,
				self.framer:create_actors(
					"frame", 2, pane_w, 416, pn_to_color(pn), fetch_color("bg"), 0, 0),
				self.scroller:create_actors("scroller", 10, filter_reason_item_mt, 0, -240),
			}
		end,
		interpret_code= function(self, button)
			local funs= {
				Up= function()
					if self.cursor_pos > 1 then
						self.cursor_pos= self.cursor_pos - 1
					end
				end,
				Down= function()
					if self.cursor_pos < #self.reasons then
						self.cursor_pos= self.cursor_pos + 1
					end
				end,
			}
			funs.MenuUp= funs.Up
			funs.MenuLeft= funs.Up
			funs.Left= funs.Up
			funs.MenuDown= funs.Down
			funs.MenuRight= funs.Down
			funs.Right= funs.Down
			if funs[button] then
				funs[button]()
				self.scroller:scroll_to_pos(self.cursor_pos)
			end
		end,
		update_filter_reaons= function(self)
			self.reasons= {}
			for i, removal in ipairs(bucket_man.style_filter_removals) do
				self.reasons[#self.reasons+1]= removal
			end
			for i, removal in ipairs(bucket_man.filter_removals) do
				self.reasons[#self.reasons+1]= removal
			end
			local file_handle= RageFileUtil.CreateRageFile()
			local fname= "Save/consensual_settings/filter_reasons.txt"
			local save_message= ""
			if not file_handle:Open(fname, 2) then
				save_message= "Could not open '" .. fname .. "' to write filter reasons."
			else
				for i, reason in ipairs(self.reasons) do
					file_handle:Write("Group: " .. reason.song:GetGroupName() .. "\n")
					file_handle:Write("Song: " .. reason.song:GetDisplayMainTitle() .. "\n")
					file_handle:Write("Filter: " .. reason.filter .. "\n")
					file_handle:Write("\n")
				end
				file_handle:Close()
				file_handle:destroy()
				save_message= "Filter reasons written to '" .. fname .. "' successfully."
			end
			SCREENMAN:SystemMessage(save_message)
			self.cursor_pos= 1
			self.scroller:set_info_set(self.reasons, 1)
		end,
		hide= function(self)
			self.hidden= true
			self.container:hibernate(math.huge)
		end,
		unhide= function(self)
			self.hidden= false
			self.container:hibernate(0)
		end,
}}

dofile(THEME:GetPathO("", "steps_menu.lua"))
dofile(THEME:GetPathO("", "options_menu.lua"))
dofile(THEME:GetPathO("", "pain_display.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))
dofile(THEME:GetPathO("", "song_props_menu.lua"))
dofile(THEME:GetPathO("", "tags_menu.lua"))
dofile(THEME:GetPathO("", "favor_menu.lua"))
dofile(THEME:GetPathO("", "sick_options_parts.lua"))
dofile(THEME:GetPathO("", "gameplay_preview.lua"))

local rate_coordinator= setmetatable({}, rate_coordinator_interface_mt)
rate_coordinator:initialize()
local color_manips= {}
local bpm_disps= {}
local pain_displays= {}
local special_menus= {}
local steps_menus= {}
local song_props_menus= {}
local tag_menus= {}
local player_cursors= {}
local gameplay_previews= {}
local filter_viewers= {}
local base_mods= get_sick_options(rate_coordinator, color_manips, bpm_disps)

for i, pn in ipairs(all_player_indices) do
	color_manips[pn]= setmetatable({}, color_manipulator_mt)
	bpm_disps[pn]= setmetatable({}, bpm_disp_mt)
	special_menus[pn]= setmetatable({}, menu_stack_mt)
	steps_menus[pn]= setmetatable({}, steps_menu_mt)
	pain_displays[pn]= setmetatable({}, pain_display_mt)
	song_props_menus[pn]= setmetatable({}, options_sets.menu)
	tag_menus[pn]= setmetatable({}, options_sets.tags_menu)
	player_cursors[pn]= setmetatable({}, cursor_mt)
	gameplay_previews[pn]= setmetatable({}, gameplay_preview_mt)
	filter_viewers[pn]= setmetatable({}, filter_reason_viewer_mt)
end

local base_options= {}
local function close_menu(pn)
	special_menus[pn]:clear_options_set_stack()
	special_menus[pn]:hide()
end

local function open_menu(pn)
	special_menus[pn]:unhide()
	special_menus[pn]:push_options_set_stack(
		options_sets.menu, base_options, "Pick Song")
	special_menus[pn]:update_cursor_pos()
end

local in_special_menu= {[PLAYER_1]= "wheel", [PLAYER_2]= "wheel"}
local select_press_times= {}
local expansion_toggle_times= {}
local ignore_next_open_special= {}

local function update_pain(pn)
	if GAMESTATE:IsPlayerEnabled(pn) then
		if in_special_menu[pn] == "wheel" or in_special_menu[pn] == "pain"
		or in_special_menu[pn] == "steps" then
			pain_displays[pn]:update_all_items()
			if pain_displays[pn]:empty() and cons_players[pn].select_music.hide_empty_pane then
				pain_displays[pn]:hide()
			else
				pain_displays[pn]:unhide()
			end
		elseif in_special_menu[pn] == "menu" then
		end
	else
		pain_displays[pn]:hide()
	end
end

local function update_pain_active()
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if in_special_menu[pn] == "wheel" then
			if not cons_players[pn].select_music.show_pane_during_song_select or
				(cons_players[pn].select_music.hide_empty_pane
				 and pain_displays[pn]:empty()) then
					set_pane_active(pn, false)
					pain_displays[pn]:hide()
			else
				set_pane_active(pn, true)
			end
		else
			set_pane_active(pn, true)
		end
	end
end

local delayed_set_special_menu= {}
local function set_special_menu(pn, next_menu)
	reset_pressed_since_menu_change(pn)
	if picking_steps and next_menu == "wheel" then
		next_menu= "steps"
	end
	if next_menu == "menu" and ignore_next_open_special[pn] then
		ignore_next_open_special[pn]= false
		return
	end
	in_special_menu[pn]= next_menu
	if in_special_menu[pn] == "wheel" or in_special_menu[pn] == "pain"
	or in_special_menu[pn] == "steps" then
		close_menu(pn)
		if picking_steps and in_special_menu[pn] == "steps" then
			steps_menus[pn]:unhide_cursor()
		end
		pain_displays[pn]:unhide()
		pain_displays[pn]:update_all_items()
		if in_special_menu[pn] == "pain" then
			player_cursors[pn]:hide()
		else
			player_cursors[pn]:unhide()
			update_player_cursors()
		end
	else
		if picking_steps then
			steps_menus[pn]:hide_cursor()
		end
		pain_displays[pn]:hide()
		pain_displays[pn]:show_frame()
		if in_special_menu[pn] ~= "filter" then
			open_menu(pn)
		end
	end
	update_pain_active()
end

local function convert_xml_exists()
	if convert_xml_bgs then return true end
	return false
end

local privileged_props= false
local function privileged(pn)
	return privileged_props
end

local function censor_item(item, depth)
	add_to_censor_list(item.el)
end

local function uncensor_item(item, depth)
	remove_from_censor_list(item.el)
end

local misc_options= {
	{name= "edit_pain", meta= "execute", level= 2, execute= function(pn)
		 pain_displays[pn]:enter_edit_mode()
		 delayed_set_special_menu[pn]= "pain"
	end},
	{name= "convert_xml", req_func= convert_xml_exists, meta= "execute",
	 level= 4, execute= function(pn)
		 if not convert_xml_bgs then return end
		 local cong= GAMESTATE:GetCurrentSong()
		 if cong then
			 convert_xml_bgs(cong:GetSongDir())
		 else
			 local function convert_item(item, depth)
				 convert_xml_bgs(item.el:GetSongDir())
			 end
			 local bucket= music_wheel.sick_wheel:get_info_at_focus_pos()
			 if bucket.bucket_info and not bucket.is_special then
				 bucket_traverse(bucket.bucket_info.contents, nil, convert_item)
			 end
		 end
--		 delayed_set_special_menu[pn]= "wheel"
	end},
	{name= "censor", req_func= privileged, meta= "execute",
	 execute= function(pn)
		 if gamestate_get_curr_song() then
			 add_to_censor_list(gamestate_get_curr_song())
			 activate_status(music_wheel:resort_for_new_style())
		 else
			 local bucket= music_wheel.sick_wheel:get_info_at_focus_pos()
			 if bucket.bucket_info and not bucket.is_special then
				 bucket_traverse(bucket.bucket_info.contents, nil, censor_item)
				 activate_status(music_wheel:resort_for_new_style())
			 end
		 end
--		 delayed_set_special_menu[pn]= "wheel"
	end},
	{name= "uncensor", req_func= privileged, meta= "execute",
	 execute= function(pn)
		 if gamestate_get_curr_song() then
			 remove_from_censor_list(gamestate_get_curr_song())
			 activate_status(music_wheel:resort_for_new_style())
		 else
			 local bucket= music_wheel.sick_wheel:get_info_at_focus_pos()
			 if bucket.bucket_info and not bucket.is_special then
				 bucket_traverse(bucket.bucket_info.contents, nil, uncensor_item)
				 activate_status(music_wheel:resort_for_new_style())
			 end
		 end
--		 delayed_set_special_menu[pn]= "wheel"
	end},
	{name= "toggle_censoring", req_func= privileged, meta= "execute",
	 execute= function(pn)
		 toggle_censoring()
		 activate_status(music_wheel:resort_for_new_style())
--		 delayed_set_special_menu[pn]= "wheel"
	end},
	{name= "edit_chart", level= 5, meta= "execute", execute= function(pn)
		 local song= GAMESTATE:GetCurrentSong()
		 local steps= GAMESTATE:GetCurrentSteps(pn)
		 if song and steps then
			 GAMESTATE:SetStepsForEditMode(song, steps)
			 trans_new_screen("ScreenEdit")
		 end
	end},
	{name= "end_credit", meta= "execute", level= 4, execute= function(pn)
		 save_profile_stuff()
		 stop_music()
		 SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
		 if not GAMESTATE:IsEventMode() then
			 end_credit_now()
		 else
			 trans_new_screen("ScreenInitialMenu")
		 end
	end},
}

local layout_options= {
	reeval_init_on_change= true,
	eles= {
		{name= "show_inactive_pane",
		 init= function(pn)
			 return cons_players[pn].select_music.show_inactive_pane end,
		 set= function(pn)
			 cons_players[pn].select_music.show_inactive_pane= true
			 update_show_inactive_pane()
		 end,
		 unset= function(pn)
			 cons_players[pn].select_music.show_inactive_pane= false
			 update_show_inactive_pane()
		end},
		{name= "hide_empty_pane",
		 init= function(pn)
			 return cons_players[pn].select_music.hide_empty_pane end,
		 set= function(pn)
			 cons_players[pn].select_music.hide_empty_pane= true
			 update_pain_active()
		 end,
		 unset= function(pn)
			 cons_players[pn].select_music.hide_empty_pane= false
			 update_pain_active()
		end},
		{name= "show_pane_during_song_select",
		 init= function(pn)
			 return cons_players[pn].select_music.show_pane_during_song_select end,
		 set= function(pn)
			 cons_players[pn].select_music.show_pane_during_song_select= true
			 update_pain_active()
		 end,
		 unset= function(pn)
			 cons_players[pn].select_music.show_pane_during_song_select= false
			 update_pain_active()
		end},
}}
for i, choice in ipairs(wheel_layout_choices) do
	layout_options.eles[#layout_options.eles+1]= {
		name= "wheel_layout_" .. choice,
		init= function(pn)
			return cons_players[pn].select_music.wheel_layout == choice
		end,
		set= function(pn)
			cons_players[pn].select_music.wheel_layout= choice
			update_curr_wheel_layout()
		end,
		unset= noop_nil
	}
end

local function make_visible_style_data(pn)
	local num_players= GAMESTATE:GetNumPlayersEnabled()
	local eles= {}
	for i, style_data in ipairs(cons_players[pn].style_config[num_players]) do
		eles[#eles+1]= {
			name= style_data.style, init= function() return style_data.visible end,
			set= function() style_data.visible= true end,
			unset= function() style_data.visible= false end,
		}
	end
	return {eles= eles}
end

local function close_visible_styles(pn)
	if enough_sourses_of_visible_styles() then
		update_steps_types_to_show()
		style_config:set_dirty(pn_to_profile_slot(pn))
		activate_status(music_wheel:resort_for_new_style())
		common_menu_change(1)
		return
	else
		SOUND:PlayOnce(THEME:GetPathS("Common", "Invalid"))
	end
end

local function execute_add_favorite(pn)
	local curr_song= gamestate_get_curr_song()
	local prof_slot= pn_to_profile_slot(pn)
	if curr_song then
		change_favor(prof_slot, curr_song, 1)
		add_song_to_favor_folder(curr_song)
		delayed_set_special_menu[pn]= "wheel"
		return
	end
	local function add_to_favor(item, depth)
		change_favor(prof_slot, item.el, 1)
		add_song_to_favor_folder_internal(item.el)
	end
	local bucket= music_wheel.sick_wheel:get_info_at_focus_pos()
	if bucket.bucket_info and not bucket.is_special then
		bucket_traverse(bucket.bucket_info.contents, nil, add_to_favor)
		finalize_favor_folder()
	end
	delayed_set_special_menu[pn]= "wheel"
end

local function execute_remove_favorite(pn)
	local curr_song= gamestate_get_curr_song()
	if curr_song then
		change_favor(pn_to_profile_slot(pn), curr_song, -1)
		remove_song_from_favor_folder(curr_song)
		delayed_set_special_menu[pn]= "wheel"
		return
	end
	local function remove_from_favor(item, depth)
		change_favor(prof_slot, item.el, -1)
		remove_song_from_favor_folder_internal(item.el)
	end
	local bucket= music_wheel.sick_wheel:get_info_at_focus_pos()
	if bucket.bucket_info and not bucket.is_special then
		bucket_traverse(bucket.bucket_info.contents, nil, remove_from_favor)
		finalize_favor_folder()
	end
	delayed_set_special_menu[pn]= "wheel"
end

local function show_filter_reasons(pn)
	filter_viewers[pn]:update_filter_reaons()
	filter_viewers[pn]:unhide()
	delayed_set_special_menu[pn]= "filter_reasons"
end

base_options= {
	{name= "scsm_mods", meta= options_sets.menu, level= 1, args= base_mods},
	{name= "add_favorite", meta= "execute", execute= execute_add_favorite},
	{name= "remove_favorite", meta= "execute", execute= execute_remove_favorite},
	{name= "scsm_misc", meta= options_sets.menu, level= 1, args= misc_options},
--	{name= "scsm_favor", meta= options_sets.favor_menu, level= 1, args= {}},
	{name= "scsm_tags", meta= options_sets.tags_menu, level= 1, args= true},
	{name= "scsm_layout", meta= options_sets.special_functions, level= 1, args= layout_options},
	{name= "view_filter_reasons", meta= "execute", execute= show_filter_reasons,
	 req_func= function() return misc_config:get_data().track_song_filter_reasons end},
--	{name= "scsm_stepstypes", meta= options_sets.special_functions, level= 1,
--	args= make_visible_style_data, exec_args= true},
}

dofile(THEME:GetPathO("", "auto_hider.lua"))

local function hide_focus()
	focus_element_info:hide()
	music_wheel:set_center_expansion(0)
	update_player_cursors()
end

local function expand_center_for_more()
	if picking_steps then return end
	music_wheel:set_center_expansion(expanded_info_height)
	if focus_element_info.hidden then
		focus_element_info:unhide()
	end
	focus_element_info:expand()
	update_player_cursors()
end

local function collapse_center_for_less()
	if picking_steps then return end
	music_wheel:set_center_expansion(basic_info_height)
	if focus_element_info.hidden then
		focus_element_info:unhide()
	end
	focus_element_info:collapse()
	update_player_cursors()
end

local function set_preferred_expansion()
	local expansion= misc_config:get_data().default_expansion_mode
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local nopan= cons_players[pn].music_info_expansion_mode
		if nopan and nopan ~= "" then
			expansion= nopan
		end
	end
	if expansion == "full" then
		expand_center_for_more()
	elseif expansion == "basic" then
		collapse_center_for_less()
	else
		hide_focus()
	end
end

local function unhide_focus()
	focus_element_info:unhide()
	set_preferred_expansion()
	update_player_cursors()
end

local function toggle_expansion()
	if focus_element_info.expanded then
		collapse_center_for_less()
		return "basic"
	else
		expand_center_for_more()
		return "full"
	end
end

local function switch_to_picking_steps()
	music_wheel.container:april_linear(wheel_move_time):diffusealpha(0)
	expand_center_for_more()
	focus_element_info.container:april_linear(wheel_move_time)
		:y(_screen.h - expanded_info_height-32-pad)
	for i, dpn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		steps_menus[dpn]:activate()
		if in_special_menu[dpn] == "wheel" then
			set_special_menu(dpn, "steps")
		end
	end
	picking_steps= true
	update_player_cursors()
end

local function switch_to_not_picking_steps()
	picking_steps= false
	for i, dpn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		steps_menus[dpn]:deactivate()
		if in_special_menu[dpn] == "steps" then
			set_special_menu(dpn, "wheel")
		end
	end
	music_wheel.container:april_linear(wheel_move_time):diffusealpha(1)
	focus_element_info.container:april_linear(wheel_move_time):y(_screen.cy)
	set_preferred_expansion()
	update_player_cursors()
end

local player_cursor_button_list= {{"top", "MenuLeft"}, {"bottom", "MenuRight"}}
reverse_button_list(player_cursor_button_list)

local function update_all_info()
	update_curr_group()
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	for i, v in ipairs(enabled_players) do
		set_closest_steps_to_preferred(v)
	end
	focus_element_info:update(music_wheel.sick_wheel:get_info_at_focus_pos())
	update_prev_song_bpm()
	update_pain(PLAYER_1)
	update_pain(PLAYER_2)
	update_player_cursors()
	for pn, preview in pairs(gameplay_previews) do
		if not preview.hidden then
			preview:update_steps()
		end
	end
end

local function start_auto_scrolling(dir)
	local time_before_scroll= GetTimeSinceStart()
	music_wheel:scroll_amount(dir)
	local time_after_scroll= GetTimeSinceStart()
	auto_scrolling= dir
	local curr_time= get_screen_time() + (time_after_scroll - time_before_scroll)
	next_auto_scroll_time= curr_time + time_before_auto_scroll
	fast_scroll_start_time= curr_time + time_before_fast_scroll
end

local function stop_auto_scrolling()
	play_sample_music()
	auto_scrolling= nil
	fast_auto_scroll= nil
	update_all_info()
end

local function correct_for_overscroll()
	local was_scroll= auto_scrolling
	auto_scrolling= nil
	fast_auto_scroll= nil
	if was_scroll then
		music_wheel:scroll_amount(-was_scroll)
		play_sample_music()
	end
end

update_player_cursors= function()
	local num_enabled= 0
	for i, pn in ipairs{PLAYER_1, PLAYER_2} do
		if GAMESTATE:IsPlayerEnabled(pn) then
			num_enabled= num_enabled + 1
			local cursed_item= false
			local function fit_cursor_to_menu(menu)
				player_cursors[pn].align= 0
				cursed_item= menu:get_cursor_element()
				local xmn, xmx, ymn, ymx= rec_calc_actor_extent(cursed_item.container)
				local xp, yp= rec_calc_actor_pos(cursed_item.container)
				player_cursors[pn]:refit(xp, yp, xmx - xmn + 2, ymx - ymn + 0)
			end
			if in_special_menu[pn] == "wheel" then
				player_cursors[pn]:unhide()
				player_cursors[pn].align= 0
				local height= basic_info_height * 2
				if focus_element_info.hidden then
					height= music_wheel:get_item_height()
				elseif focus_element_info.expanded then
					height= expanded_info_height * 2
				end
				player_cursors[pn]:refit(wheel_x, _screen.cy, wheel_width, height)
			else
				player_cursors[pn]:hide()
			end
		else
			player_cursors[pn]:hide()
		end
	end
	if num_enabled == 2 and in_special_menu[PLAYER_1] == "wheel"
	and in_special_menu[PLAYER_2] == "wheel" then
		player_cursors[PLAYER_1]:left_half()
		player_cursors[PLAYER_2]:right_half()
	else
		player_cursors[PLAYER_1]:un_half()
		player_cursors[PLAYER_2]:un_half()
	end
end

local status_text= false
local status_count= false
local status_container= false
local status_frame= setmetatable({}, frame_helper_mt)
local status_active= false
local status_worker= false
local status_finish_func= false
activate_status= function(worker, after_func)
	status_active= true
	status_worker= worker
	status_finish_func= after_func
	status_container:stoptweening():april_linear(0.5):diffusealpha(1)
	status_text:settext("")
	status_count:settext("")
end

local function deactivate_status()
	if status_finish_func then
		status_finish_func()
	end
	change_sort_text(music_wheel.current_sort_name)
	update_all_info()
	status_active= false
	status_worker= false
	status_container:stoptweening():linear(0.5):diffusealpha(0)
	unhide_focus()
end

local function status_update(self)
	if status_worker then
		if coroutine.status(status_worker) ~= "dead" then
			local working, state, count= coroutine.resume(status_worker)
			if working then
				status_text:settext(state or "done")
				status_count:settext(count or "done")
			else
				status_text:settext("Error encountered.")
				status_count:settext("")
				lua.ReportScriptError(state)
				deactivate_status()
			end
		else
			deactivate_status()
		end
	end
end

local function Update(self)
	if entering_song then
		if get_screen_time() > entering_song then
			SCREENMAN:GetTopScreen():queuecommand("real_play_song")
		end
	elseif status_active then
		-- do nothing.
	else
		if auto_scrolling then
			if get_screen_time() > next_auto_scroll_time then
				local time_before_scroll= GetTimeSinceStart()
				music_wheel:scroll_amount(auto_scrolling)
				local time_after_scroll= GetTimeSinceStart()
				local curr_time= get_screen_time()
				curr_time= curr_time + (time_after_scroll - time_before_scroll)
				if fast_auto_scroll then
					next_auto_scroll_time= curr_time + time_between_fast_scroll
				else
					next_auto_scroll_time= curr_time + time_between_auto_scroll
					if curr_time > fast_scroll_start_time then
						fast_auto_scroll= true
					end
				end
				focus_element_info:update_title(music_wheel.sick_wheel:get_info_at_focus_pos())
				pain_displays[PLAYER_1]:hide_elements()
				pain_displays[PLAYER_2]:hide_elements()
			end
		end
	end
end

local options_message_frame_helper= setmetatable({}, frame_helper_mt)

local input_functions= {
	scroll_left= function()
		if auto_scrolling then stop_auto_scrolling()
		else start_auto_scrolling(-1) end
	end,
	scroll_right= function()
		if auto_scrolling then stop_auto_scrolling()
		else start_auto_scrolling(1) end
	end,
	stop_scroll= function() stop_auto_scrolling() end,
	back= function()
		save_profile_stuff()
		stop_music()
		SOUND:PlayOnce(THEME:GetPathS("Common", "cancel"))
		if not GAMESTATE:IsEventMode() then
			end_credit_now()
		else
			trans_new_screen("ScreenInitialMenu")
		end
	end
}

local input_functions= {
	InputEventType_FirstPress= {
		MenuLeft= input_functions.scroll_left,
		MenuRight= input_functions.scroll_right,
		Back= input_functions.back
	},
	InputEventType_Release= {
		MenuLeft= input_functions.stop_scroll,
		MenuRight= input_functions.stop_scroll,
	}
}

local function adjust_difficulty(player, dir, sound)
	local steps= gamestate_get_curr_steps(player)
	if steps then
		local steps_list= sort_steps_list(get_filtered_steps_list())
		local next_steps= false
		for i, v in ipairs(steps_list) do
			if v == steps then
				next_steps= i + dir
			end
		end
		local picked_steps= steps_list[next_steps]
		if picked_steps then
			cons_set_current_steps(player, picked_steps)
			GAMESTATE:SetPreferredDifficulty(player, picked_steps:GetDifficulty())
			set_preferred_steps_type(player, picked_steps:GetStepsType())
			SOUND:PlayOnce(THEME:GetPathS("_switch", sound))
		else
			SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
		end
	end
	update_pain(player)
	if not gameplay_previews[player].hidden then
		gameplay_previews[player]:update_steps()
	end
end

local keys_down= {[PLAYER_1]= {}, [PLAYER_2]= {}}
local down_count= {[PLAYER_1]= 0, [PLAYER_2]= 0}
local pressed_since_menu_change= {[PLAYER_1]= {}, [PLAYER_2]= {}}
local codes_since_release= {}
local down_map= {
	InputEventType_FirstPress= true, InputEventType_Repeat= true,
	InputEventType_Release= false}
local menu_button_names= {
	MenuLeft= true, MenuRight= true, MenuUp= true, MenuDown= true, Start= true,
	Select= true, Back= true
}
local scroll_affectors= {MenuLeft= true, MenuRight= true}
if not PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
	scroll_affectors.Left= true
	scroll_affectors.Right= true
end

reset_pressed_since_menu_change= function(pn)
	pressed_since_menu_change[pn]= {}
end

local function menu_code_to_text(code)
	local hold_string= ""
	if #code.hold_buttons > 0 then
		hold_string= "&" .. table.concat(code.hold_buttons, ";&") .. ";+"
	end
	return hold_string .. "&" .. code.release_trigger .. ";"
end

local function code_to_text(code)
	if code.ignore_release then
		return "&" .. table.concat(code, ";&") .. ";"
	else
		return "&" .. table.concat(code, ";+&") .. ";"
	end
end

local menu_codes= {
	{name= "play_song", hold_buttons= {},
	 release_trigger= "Start", canceled_by_others= false, nothing_down= true},
	{name= "close_group", hold_buttons= {"MenuLeft", "MenuRight"},
	 release_trigger= "Start", canceled_by_others= false},
	{name= "close_group", hold_buttons= {"Left", "Right"},
	 games= {"dance", "techno"},
	 release_trigger= "Start", canceled_by_others= false},
}
do
	local function amc(mc)
		menu_codes[#menu_codes+1]= mc
	end
	if misc_config:get_data().have_select_button then
		amc{name= "sort_mode", hold_buttons= {"Select"},
				release_trigger= "Start", canceled_by_others= false}
		amc{name= "open_special", hold_buttons= {},
				release_trigger= "Select", canceled_by_others= true}
		amc{name= "diff_up", hold_buttons= {"Select"},
				release_trigger= "MenuLeft", canceled_by_others= false}
		amc{name= "diff_down", hold_buttons= {"Select"},
				release_trigger= "MenuRight", canceled_by_others= false}
	else
		amc{name= "sort_mode", hold_buttons= {"MenuLeft"},
				release_trigger= "MenuRight", canceled_by_others= false}
		amc{name= "sort_mode", hold_buttons= {"MenuRight"},
				release_trigger= "MenuLeft", canceled_by_others= false}
		amc{name= "open_special", hold_buttons= {"MenuLeft"},
				release_trigger= "Start", canceled_by_others= false,
				nothing_down= true, overscroll= true}
		amc{name= "open_special", hold_buttons= {"MenuRight"},
				release_trigger= "Start", canceled_by_others= false,
				nothing_down= true, overscroll= true}
	end
end

local codes= {
	{ name= "change_song", fake= true, "MenuLeft" },
	{ name= "change_song", fake= true, "MenuRight" },
	{ name= "change_song", fake= true, games= {"dance", "techno"}, "Left" },
	{ name= "change_song", fake= true, games= {"dance", "techno"}, "Right" },
	{ name= "play_song", ignore_release= true, games= {"pump"}, "Center" },
	{ name= "sort_mode", ignore_release= true, games= {"dance", "techno"},
		"Up", "Down", "Up", "Down" },
	{ name= "sort_mode", ignore_release= true, games= {"pump", "techno"},
		"UpLeft", "UpRight", "UpLeft", "UpRight" },
	{ name= "diff_up", ignore_release= true, games= {"dance", "techno"},
		"Up", "Up" },
	{ name= "diff_up", ignore_release= true, games= {"pump", "techno"},
		"UpLeft", "UpLeft" },
	{ name= "diff_up", ignore_release= true, games= {"kickbox"},
		"UpLeftFoot" },
	{ name= "diff_up", ignore_release= true, games= {"popn"},
		"Left White" },
	{ name= "diff_down", ignore_release= true, games= {"dance", "techno"},
		"Down", "Down" },
	{ name= "diff_down", ignore_release= true, games= {"pump", "techno"},
		"UpRight", "UpRight" },
	{ name= "diff_down", ignore_release= true, games= {"kickbox"},
		"DownLeftFoot" },
	{ name= "diff_down", ignore_release= true, games= {"popn"},
		"Right White" },
--	{ name= "noob_mode", ignore_release= true, games= {"dance", "techno"},
--		"Up", "Up", "Down", "Down", "Left", "Right", "Left", "Right"},
	{ name= "simple_options_mode", ignore_release= true, games= {"dance", "techno"},
	"Left", "Down", "Right", "Left", "Down", "Right" },
	{ name= "all_options_mode", ignore_release= true, games= {"dance", "techno"},
	"Right", "Down", "Left", "Right", "Down", "Left" },
	{ name= "excessive_options_mode", ignore_release= true, games= {"dance", "techno"},
		"Left", "Up", "Right", "Up", "Left", "Down", "Right", "Down", "Left"},
	{ name= "kyzentun_mode", ignore_release= true, games= {"none"},
		"Right", "Up", "Left", "Right", "Up", "Left" },
	{ name= "unjoin", ignore_release= true, games= {"none"},
		"Down", "Left", "Up", "Down", "Left", "Up", "Down", "Left", "Up"},
}
for i, code in ipairs(codes) do
	code.curr_pos= {[PLAYER_1]= 1, [PLAYER_2]= 1}
end

local function update_keys_down(pn, key_pressed, press_type)
	if PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
		if menu_button_names[key_pressed] then
			keys_down[pn][key_pressed]= down_map[press_type]
		end
	else
		keys_down[pn][key_pressed]= down_map[press_type]
	end
	Trace("Updated down status of " .. key_pressed .. " to " .. tostring(keys_down[pn][key_pressed]))
	if press_type == "InputEventType_FirstPress" then
		Trace("pressed_since_menu_change set to true")
		pressed_since_menu_change[pn][key_pressed]= true
	end
	down_count[pn]= 0
	for keyname, status in pairs(keys_down[pn]) do
		if status then down_count[pn]= down_count[pn] + 1 end
	end
end

local function update_code_status(pn, key_pressed, press_type)
	local triggered= {}
	local press_handlers= {
		InputEventType_FirstPress= function(to_check)
			if key_pressed == to_check[to_check.curr_pos[pn]] then
				to_check.curr_pos[pn]= to_check.curr_pos[pn] + 1
				if to_check.curr_pos[pn] > #to_check then
					triggered[#triggered+1]= to_check.name
					to_check.curr_pos[pn]= 1
					if to_check.repeat_first_on_end then
						to_check.curr_pos[pn]= #to_check
					end
				end
			else
				if not string_in_table(key_pressed, to_check.ignore_press_list) then
					to_check.curr_pos[pn]= 1
				end
			end
		end,
		InputEventType_Release= function(to_check)
			if not to_check.ignore_release and
			not string_in_table(key_pressed, to_check.ignore_release_list) then
				to_check.curr_pos[pn]= 1
			end
		end
	}
	local handler= press_handlers[press_type]
	if handler then
		if scroll_affectors[key_pressed] then
			stop_auto_scrolling()
		end
		for i, v in ipairs(codes) do
			if not v.fake then
				handler(v)
			end
		end
	end
	if press_type == "InputEventType_Release" then
		for i, check in ipairs(menu_codes) do
			if not codes_since_release[pn] or not check.canceled_by_others then
				if key_pressed == check.release_trigger then
					local held_count= 0
					for keyname, down in pairs(keys_down[pn]) do
						if down and string_in_table(keyname, check.hold_buttons) then
							held_count= held_count+1
						elseif down and check.nothing_down then
							held_count= -1
							break
						end
					end
					if held_count == #check.hold_buttons then
						triggered[#triggered+1]= check.name
						if check.overscroll then
							correct_for_overscroll()
						end
						if not check.nothing_down then
							codes_since_release[pn]= true
						end
					end
				end
			end
		end
	end
	return triggered
end

local code_functions= {
		sort_mode= function(pn)
			stop_auto_scrolling()
			hide_focus()
			music_wheel:show_sort_list()
			change_sort_text(music_wheel.current_sort_name)
			update_all_info()
		end,
		play_song= function(pn)
			local needs_work, after_func= music_wheel:interact_with_element(pn)
			if needs_work then
				activate_status(needs_work, after_func)
			else
				change_sort_text(music_wheel.current_sort_name)
			end
			focus_element_info:update(music_wheel.sick_wheel:get_info_at_focus_pos())
		end,
		diff_up= function(pn)
			stop_auto_scrolling()
			adjust_difficulty(pn, -1, "up")
		end,
		diff_down= function(pn)
			stop_auto_scrolling()
			adjust_difficulty(pn, 1, "down")
		end,
		open_special= function(pn)
			if ops_level(pn) >= 2 or privileged(pn) then
				stop_auto_scrolling()
				set_special_menu(pn, "menu")
			end
		end,
		close_group= function(pn)
			stop_auto_scrolling()
			music_wheel:close_group()
			update_all_info()
		end,
		unjoin= function(pn)
			SOUND:PlayOnce(THEME:GetPathS("Common", "Cancel"))
			do return end -- crashes?
			Trace("Master player: " .. GAMESTATE:GetMasterPlayerNumber())
			Trace("Unjoining player: " .. pn)
			GAMESTATE:ApplyGameCommand("style,double")
			GAMESTATE:UnjoinPlayer(other_player[pn])
			Trace("NPE: " .. GAMESTATE:GetNumPlayersEnabled())
			lua.Flush()
			GAMESTATE:ApplyGameCommand("style,single")
			Trace("Master player after unjoin: " .. GAMESTATE:GetMasterPlayerNumber())
		end
}

local function handle_triggered_codes(pn, key_pressed, button, press_type)
	local triggered= update_code_status(pn, key_pressed, press_type)
	for i, v in ipairs(triggered) do
		local ctext= SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("code_text")
		if ctext then
			if convert_code_name_to_display_text[v] then
				ctext:settext(convert_code_name_to_display_text[v])
					:DiffuseAndStroke(
						Alpha(fetch_color("stroke"), 0), fetch_color("text"))
					:finishtweening()
				local w= ctext:GetWidth()
				local h= ctext:GetHeight()
				local z= ctext:GetZoom()
				ctext:xy(SCREEN_LEFT+(w*z/2)+2, SCREEN_TOP+(h*z/2)+4)
					:ease(.5,-100):diffusealpha(1):sleep(2):ease(.5,100)
					:diffusealpha(0)
			end
		end
		if code_functions[v] then code_functions[v](pn) end
		if cons_players[pn] and cons_players[pn][v] then
			cons_players[pn][v](cons_players[pn])
			if update_rating_cap() then
				activate_status(music_wheel:resort_for_new_style())
			end
			pain_displays[pn]:fetch_config()
			pain_displays[pn]:update_all_items()
		end
	end
	if #triggered == 0 and down_count[pn] <= 1 and not codes_since_release[pn] then
		if input_functions[press_type] and input_functions[press_type][button] then
			input_functions[press_type][button]()
		end
	end
end

local function interpret_config_key(key)
	
end

local saw_first_press= {}
local function input(event)
	input_came_from_keyboard= event.DeviceInput.device == "InputDevice_Key"
	local pn= event.PlayerNumber
	local key_pressed= event.GameButton
	local press_type= event.type
	Trace("Input: " .. tostring(pn) .. ", " .. key_pressed .. ", " .. event.DeviceInput.button .. ", " .. event.type)
	if press_type == "InputEventType_FirstPress" then
		Trace("Added to saw_first_press")
		saw_first_press[event.DeviceInput.button]= true
	end
	if not saw_first_press[event.DeviceInput.button] then
		local ignore_message= "Did not see first press for " ..
			event.DeviceInput.button .. ", ignoring " .. event.type
		show_ignore_message(ignore_message)
		Trace("Event info:")
		rec_print_table(event)
		Trace("saw_first_press info:")
		rec_print_table(saw_first_press)
		return
	end
	if press_type == "InputEventType_Release" then
		Trace("Removed from saw_first_press")
		saw_first_press[event.DeviceInput.button]= nil
	end
	--[[
	if event.DeviceInput.button == "DeviceButton_s" then
		if press_type == "InputEventType_FirstPress" then
			expand_center_for_more()
		elseif press_type == "InputEventType_Release" then
			collapse_center_for_less()
		end
	end
	]]
	if press_type == "InputEventType_FirstPress"
	and event.DeviceInput.button == "DeviceButton_F9" then
		PREFSMAN:SetPreference("ShowNativeLanguage", not PREFSMAN:GetPreference("ShowNativeLanguage"))
		SCREENMAN:SystemMessage("ShowNativeLanguage: " .. tostring(PREFSMAN:GetPreference("ShowNativeLanguage")))
	end
	if press_type == "InputEventType_FirstPress"
	and event.DeviceInput.button == misc_config:get_data().censor_privilege_key then
		privileged_props= not privileged_props
	end
	if press_type ~= "InputEventType_Release" then
		if picking_steps then
			for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
				steps_menus[pn]:interpret_key(event.DeviceInput.button)
			end
		else
			interpret_config_key(event.DeviceInput.button)
		end
	end
	if not pn then
		show_ignore_message("Input does not have a pn, ignoring.")
		return
	end
	if GAMESTATE:IsSideJoined(pn) then
		if entering_song then
			show_ignore_message("Currently entering song, ignoring non-Start input")
			if misc_config:get_data().enable_player_options
				and key_pressed == "Start"
			and press_type == "InputEventType_FirstPress" then
				Trace("Going to options")
				SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
				entering_song= 0
				go_to_options= true
			end
		else
			local function common_menu_change(next_menu)
				set_special_menu(pn, next_menu)
			end
			local closed_menu= false
			if key_pressed == "Select"
				and press_type == "InputEventType_FirstPress" then
				if select_press_times[pn]
					and get_screen_time() < select_press_times[pn] + double_tap_time
					and special_menus[pn]:can_exit_screen()
				and in_special_menu[pn] == "menu" then
					if expansion_toggle_times[pn]
					and get_screen_time() < expansion_toggle_times[pn] + (double_tap_time) then
						cons_players[pn].music_info_expansion_mode= "title_only"
						hide_focus()
					else
						local current_expansion= toggle_expansion()
						cons_players[pn].music_info_expansion_mode= current_expansion
						expansion_toggle_times[pn]= get_screen_time()
					end
					common_menu_change("wheel")
					closed_menu= true
					ignore_next_open_special[pn]= true
				else
					select_press_times[pn]= get_screen_time()
				end
			end
			local menu_func= {
				wheel= function()
					handle_triggered_codes(pn, event.button, key_pressed, press_type)
				end,
				menu= function()
					if press_type == "InputEventType_Release" then return end
					if not special_menus[pn]:interpret_code(key_pressed) then
						if key_pressed == "Back" or key_pressed == "Start" then
							common_menu_change("wheel")
						end
					end
					if special_menus[pn].external_thing then
						local fit= color_manips[pn]:get_cursor_fit()
						fit[2]= fit[2] - pane_menu_y
						special_menus[pn]:refit_cursor(fit)
					end
					if delayed_set_special_menu[pn] then
						common_menu_change(delayed_set_special_menu[pn])
						delayed_set_special_menu[pn]= nil
					end
				end,
				filter_reasons= function()
					if press_type == "InputEventType_Release" then return end
					if key_pressed == "Back" or key_pressed == "Select" then
						filter_viewers[pn]:hide()
						common_menu_change("menu")
					else
						filter_viewers[pn]:interpret_code(key_pressed)
					end
				end,
				pain= function()
					if press_type == "InputEventType_Release" then return end
					local handled, close=pain_displays[pn]:interpret_code(key_pressed)
					if close then
						common_menu_change("wheel")
					end
				end,
				steps= function()
					if press_type == "InputEventType_Release" then
						if key_pressed == "Select" then
							common_menu_change("menu")
						end
						steps_menus[pn]:interpret_release(key_pressed)
						if steps_menus[pn].needs_deactivate then
							switch_to_not_picking_steps()
						end
						if steps_menus[pn].chosen_steps then
							local all_chosen= true
							for i, dpn in ipairs(GAMESTATE:GetEnabledPlayers()) do
								if not steps_menus[dpn].chosen_steps
								or in_special_menu[dpn] ~= "steps" then
									all_chosen= false
								end
							end
							if all_chosen then
								local function do_entry()
									SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
									if misc_config:get_data().enable_player_options then
										options_message:accelerate(0.25):diffusealpha(1)
										entering_song= get_screen_time() + options_time
									else
										entering_song= get_screen_time()
									end
									prev_picked_song= gamestate_get_curr_song()
									save_profile_stuff()
								end
								if not GAMESTATE.CanSafelyEnterGameplay then
									do_entry()
									return
								end
								local can, reason= GAMESTATE:CanSafelyEnterGameplay()
								if can then
									do_entry()
								else
									SOUND:PlayOnce(THEME:GetPathS("Common", "Invalid"))
									lua.ReportScriptError("Cannot safely enter gameplay: " .. tostring(reason))
								end
							end
						end
						return
					end
					steps_menus[pn]:interpret_code(key_pressed)
					update_pain(pn)
				end,
			}
			update_keys_down(pn, key_pressed, press_type)
			if not status_active and pressed_since_menu_change[pn][key_pressed]
			and not closed_menu then
				menu_func[in_special_menu[pn]]()
			else
				local ignore_message= "Status window is active, or button not pressed since menu change, or closed menu this frame.  Ignoring " .. key_pressed .. " " .. press_type
				show_ignore_message(ignore_message)
				Trace("status_active: " .. tostring(status_active))
				Trace("closed_menu: " .. tostring(closed_menu))
				Trace("pressed_since_menu_change: ")
				rec_print_table(pressed_since_menu_change[pn])
			end
			if down_count[pn] == 0 then codes_since_release[pn]= false end
		end
	else
		if key_pressed == "Start" then
			local curr_style_type= GAMESTATE:GetCurrentStyle(pn):GetStyleType()
			if curr_style_type == "StyleType_OnePlayerOneSide" and not picking_steps and not kyzentun_birthday then
				if cons_join_player(pn) then
					ensure_enough_stages()
					GAMESTATE:LoadProfiles()
					local prof= PROFILEMAN:GetProfile(pn)
					if prof then
						if prof ~= PROFILEMAN:GetMachineProfile() then
							cons_players[pn]:set_ops_from_profile(prof)
							load_favorites(pn_to_profile_slot(pn))
							load_tags(pn_to_profile_slot(pn))
						end
					end
					SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
					pain_displays[pn]:fetch_config()
					if Game.GetSeparateStyles
					and GAMESTATE:GetCurrentGame():GetSeparateStyles() then
						set_current_style(first_compat_style(2), PLAYER_1)
						set_current_style(first_compat_style(2), PLAYER_2)
					else
						set_current_style(first_compat_style(2))
					end
					activate_status(music_wheel:resort_for_new_style())
					set_closest_steps_to_preferred(pn)
				end
			end
		else
			show_ignore_message("Ignoring " .. key_pressed .. " from " .. pn .. " because they are not joined.")
		end
	end
	update_player_cursors()
end

local function get_code_texts_for_game()
	local game= GAMESTATE:GetCurrentGame():GetName():lower()
	local ret= {}
	for i, code in ipairs(codes) do
		local in_game= (not code.games) or (string_in_table(game, code.games))
		if in_game then
			if not ret[code.name] then ret[code.name]= {} end
			local add_to= ret[code.name]
			add_to[#add_to+1]= code_to_text(code)
		end
	end
	for i, code in ipairs(menu_codes) do
		if not ret[code.name] then ret[code.name]= {} end
		local add_to= ret[code.name]
		add_to[#add_to+1]= menu_code_to_text(code)
	end
	return ret
end

local to_open= get_string_wrapper("SelectMusic", "to_open")
local to_close= get_string_wrapper("SelectMusic", "to_close")
local to_play= get_string_wrapper("SelectMusic", "to_play")
local function exp_text(exp_name, x, y, to_interact, attrib_color)
	local str= get_string_wrapper("SelectMusic", exp_name)
	return normal_text(
		exp_name, str .. " " .. to_interact, fetch_color("help.text"), fetch_color("help.stroke"), x, y, .75, left, {
			InitCommand= function(self)
				self:AddAttribute(0, {Length=#str, Diffuse= fetch_color(attrib_color)})
			end
	})
end

local help_args= {
	HideTime= misc_config:get_data().select_music_help_time,
	Def.Quad{
		InitCommand= function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
				:setsize(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(fetch_color("help.bg"))
		end
	},
	exp_text("group_exp", 8, 12, to_open, "music_select.music_wheel.group"),
	exp_text("current_group_exp", 8, 36, to_close, "music_select.music_wheel.current_group"),
	exp_text("song_exp", 8, 60, to_play, "music_select.music_wheel.song"),
	normal_text(
		"dismiss", get_string_wrapper("SelectMusic", "dismiss_help"),
		fetch_color("help.text"), fetch_color("help.stroke"), _screen.cx,
		SCREEN_BOTTOM - 28, 1.5),
}
do
	local menu_help_start= 300
	local code_positions= {
		change_song= {wheel_x-24, 24},
		play_song= {wheel_x-24, 56},
		sort_mode= {wheel_x-24, 168, true},
		close_group= {wheel_x-24, 288, true},
		diff_up= {8, 229},
		diff_down= {8, 253},
	}
	if misc_config:get_data().ssm_advanced_help then
		code_positions.open_special= {8, menu_help_start}
		code_positions.noob_mode= {8, menu_help_start+24}
		code_positions.simple_options_mode= {8, menu_help_start+48}
		code_positions.all_options_mode= {8, menu_help_start+72}
		code_positions.excessive_options_mode= {8, menu_help_start+96}
	end
	local game_codes= get_code_texts_for_game()
	for code_name, code_set in pairs(game_codes) do
		local pos= code_positions[code_name]
		if pos then
			local help= get_string_wrapper("SelectMusic", code_name)
			local or_word= " "..get_string_wrapper("Common", "or").." "
			local code_text= ""
			for i, sintext in ipairs(code_set) do
				if pos[3] and i % 2 == 1 and i > 1 then
					code_text= code_text .. "\n"
				end
				code_text= code_text .. sintext
				if i < #code_set then
					code_text= code_text .. or_word
				end
			end
			help_args[#help_args+1]= normal_text(
				code_name .. "_help", help .. " " .. code_text,
				fetch_color("help.text"), fetch_color("help.stroke"), pos[1], pos[2],
					.75, left)
		end
	end
end

local function maybe_help()
	if misc_config:get_data().select_music_help_time > 0 then
		return Def.AutoHider(help_args)
	end
end

local function player_actors(pn, x, y)
	local header_bottom= header_size + pad
	local menu_top= _screen.h - footer_size - pane_h - pad - pad
	local preview_height= menu_top - header_bottom
	local preview_scale= preview_height / _screen.h
	local preview_width= (_screen.w * .5) * preview_scale
	return Def.ActorFrame{
		Name= pn .. "_stuff", InitCommand= function(self)
			player_stuff[pn]= self
			self:xy(x, y)
		end,
		pain_displays[pn]:create_actors(
			"pain", 0, pane_y + pane_yoff - pane_text_height, pn, pane_w,
			pane_text_zoom),
		steps_menus[pn]:create_actors(0, _screen.cy*.5, pn),
		gameplay_previews[pn]:create_actors(0, (header_bottom + menu_top) * .5, preview_width, preview_height, preview_scale, pn),
		bpm_disps[pn]:create_actors("bpm", pn, 0, pane_y + pane_yoff - 36, pane_w),
		color_manips[pn]:create_actors("color_manip", 0, pane_manip_y, nil, .5),
		special_menus[pn]:create_actors(
			"menu", 0, pane_menu_y, pane_menu_w, pane_menu_h, pn, 1,
			pane_text_height, menu_text_zoom),
		filter_viewers[pn]:create_actors(0, _screen.cy, pn),
	}
end

return Def.ActorFrame {
	InitCommand= function(self)
		hms_split()
		hms_unfade()
		self:SetUpdateFunction(Update)
		for i, pn in ipairs({PLAYER_1, PLAYER_2}) do
			special_menus[pn]:hide()
			color_manips[pn]:hide()
			bpm_disps[pn]:hide()
		end
		music_wheel:find_actors(self:GetChild(music_wheel.name))
		set_preferred_expansion()
		ensure_enough_stages()
		april_spin(self)
	end,
	OnCommand= function(self)
		local top_screen= SCREENMAN:GetTopScreen()
		top_screen:SetAllowLateJoin(false):AddInputCallback(input)
		change_sort_text(music_wheel.current_sort_name)
		update_all_info()
		update_show_inactive_pane()
		update_pain_active()
		update_curr_wheel_layout()
		update_player_cursors()
	end,
	play_songCommand= function(self)
		switch_to_picking_steps()
	end,
	real_play_songCommand= function(self)
		if go_to_options then
			trans_new_screen("ScreenSickPlayerOptions")
		else
			trans_new_screen("ScreenStageInformation")
		end
	end,
	went_to_text_entryMessageCommand= function(self)
		saw_first_press= {}
		for pn, downs in pairs(keys_down) do
			keys_down[pn]= {}
		end
	end,
	get_music_wheelMessageCommand= function(self, param)
		if not music_wheel.ready then return end
		if param.requester then param.requester.music_wheel= music_wheel end
	end,
	PlayerJoinedMessageCommand= function(self)
		update_steps_types_to_show()
		self:playcommand("Set")
	end,
	current_group_changedMessageCommand= function(self, param)
		curr_group_name= param[1] or ""
	end,
	entered_gameplay_configMessageCommand= function(self, param)
		if not_newskin_available() then return end
		if picking_steps then
			steps_menus[param.pn]:deactivate()
		end
		local preview= gameplay_previews[param.pn]
		preview:unhide()
		preview:update_steps()
	end,
	exited_gameplay_configMessageCommand= function(self, param)
		if not_newskin_available() then return end
		gameplay_previews[param.pn]:hide()
		if picking_steps then
			steps_menus[param.pn]:activate()
		end
	end,
	music_wheel:create_actors(wheel_x, wheel_width, wheel_move_time),
	focus_element_info:create_actors(_screen.cx, _screen.cy),
	player_actors(PLAYER_1, lpane_x, 0),
	player_actors(PLAYER_2, rpane_x, 0),
	Def.Actor{
		Name= "code_interpreter",
		InitCommand= function(self)
			self:effectperiod(2^16)
			timer_actor= self
		end,
	},
	normal_text("code_text", "", Alpha(fetch_color("text"), 0), nil, 0, 0, .75),
	Def.ActorFrame{
		Name= "header",
		Def.Quad{
			InitCommand= function(self)
				self:xy(_screen.cx, hhead_size):setsize(_screen.w, header_size)
					:diffuse({0, 0, 0, 1})
			end
		},
		normal_text("sort_text", "NO SORT",
								fetch_color("music_select.sort_type"),
								nil, 8, hhead_size, 1, left),
		normal_text("curr_group", "",
								fetch_color("music_select.curr_group"), nil,
								_screen.cx, hhead_size, 1, center, {
									InitCommand= function(self)
										curr_group= self
									end,
									SetCommand= function(self, param)
										if music_wheel.curr_bucket.name then
											self:settext(bucket_disp_name(music_wheel.curr_bucket))
										else
											self:settext("")
										end
										width_clip_limit_text(self, wheel_width)
									end,
		}),
		normal_text("remain", "", fetch_color("music_select.remaining_time"), nil,
								_screen.w - 8, hhead_size, 1, right, {
									OnCommand= function(self)
										if GAMESTATE:IsCourseMode() then
											self:visible(false)
											return
										end
										local remstr= secs_to_str(get_time_remaining())
										self:settext(remstr)
									end
		}),
	},
	Def.ActorFrame{
		Name= "footer", InitCommand= function(self)
			self:xy(_screen.cx, _screen.h - hfoot_size)
		end,
		Def.Quad{
			InitCommand= function(self)
				self:xy(0, 0):setsize(_screen.w, footer_size)
					:diffuse({0, 0, 0, 1})
			end
		},
		normal_text("help_prompt", get_string_wrapper("SelectMusic", "open_special_prompt"), fetch_color("text"), fetch_color("stroke"), 0, 0, .5),
	},
	player_cursors[PLAYER_1]:create_actors(
		"P1_cursor", 0, 0, 1, pn_to_color(PLAYER_1),
		fetch_color("player.hilight"), player_cursor_button_list, .5),
	player_cursors[PLAYER_2]:create_actors(
		"P2_cursor", 0, 0, 1, pn_to_color(PLAYER_2),
		fetch_color("player.hilight"), player_cursor_button_list, .5),
	-- FIXME:  There's not a place for the credit count on the screen anymore.
	-- credit_reporter(SCREEN_LEFT+120, _screen.cy, true),
	Def.ActorFrame{
		Name= "status report", InitCommand= function(self)
			status_text= self:GetChild("status_text")
			status_count= self:GetChild("status_count")
			status_container= self
			self:xy(_screen.cx, _screen.cy):SetUpdateFunction(status_update)
				:diffusealpha(0)
		end,
		status_frame:create_actors(
			"frame", 2, 200, 56, fetch_color("prompt.frame"), fetch_color("prompt.bg"),
			0, 0),
		normal_text("status_text", "", fetch_color("prompt.text"), nil, 0, -6, 1.5),
		normal_text("status_count", "", fetch_color("prompt.text"), nil, 0, 18, .5),
	},
	Def.ActorFrame{
		Name= "options message",
		InitCommand= function(self)
									 self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
									 self:diffusealpha(0)
									 options_message= self
								 end,
		OnCommand= function(self)
								 local xmn, xmx, ymn, ymx= rec_calc_actor_extent(self)
								 options_message_frame_helper:move((xmx+xmn)/2, (ymx+ymn)/2)
								 options_message_frame_helper:resize(xmx-xmn+20, ymx-ymn+20)
							 end,
		options_message_frame_helper:create_actors(
			"omf", 2, 0, 0, fetch_color("prompt.frame"), fetch_color("prompt.bg"),
			0, 0),
		normal_text("omm","Press &Start; for options.",fetch_color("prompt.text"),
								nil, 0, 0, 2),
	},
	normal_text("press_ignore", "", fetch_color("text"), fetch_color("stroke"), _screen.cx, 16, .5, center, {InitCommand= function(self) press_ignore_reporter= self end}),
	maybe_help(),
}
