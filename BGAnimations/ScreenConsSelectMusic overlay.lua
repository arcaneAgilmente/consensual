GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(1)
update_steps_types_to_show()

local press_ignore_reporter= false
local function show_ignore_message(message)
	press_ignore_reporter:settext(message):finishtweening()
		:linear(.2):diffusealpha(1):sleep(5):linear(.5):diffusealpha(0)
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

local wheel_x= _screen.cx
local wheel_width= _screen.w - ((pane_w + (pad * 2)) * 2)
local wheel_move_time= .1
local banner_w= wheel_width - 4
local banner_h= 80
local curr_group_name= ""
local basic_info_height= 48
local extra_info_height= 40
local expanded_info_height= basic_info_height + (extra_info_height * 2)

local entering_song= false
local options_time= 1.5
local go_to_options= false
local picking_steps= false
local was_picking_steps= false
local double_tap_time= .5

local update_player_cursors= noop_nil

local options_message= false
local timer_actor= false
local function get_screen_time()
	if timer_actor then
		return timer_actor:GetSecsIntoEffect()
	else
		return 0
	end
end

local player_profiles= {}
local machine_profile= PROFILEMAN:GetMachineProfile()

function update_player_profile(pn)
	player_profiles[pn]= PROFILEMAN:GetProfile(pn)
end
update_player_profile(PLAYER_1)
update_player_profile(PLAYER_2)

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

local function set_closest_steps_to_preferred(pn)
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

local sort_prop= false

local function change_sort_text(new_text)
	local overlay= SCREENMAN:GetTopScreen():GetChild("Overlay")
	local stext= overlay:GetChild("header"):GetChild("sort_text")
	new_text= new_text or stext:GetText()
	stext:settext(new_text)
	width_limit_text(stext, sort_width)
	sort_prop:playcommand("Set")
end

local function update_sort_prop()
	sort_prop:playcommand("Set")
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

local function banner(x, y)
	if scrambler_mode then
		return swapping_amv(
			"Banner", x, y, banner_w, banner_h, 16, 5, nil, "_",
			false, true, true, {
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
			Name="Banner", InitCommand=cmd(xy, x, y),
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
			self.left_x= wheel_width * -.15
			self.right_x= wheel_width * .25
			self.jacket_width= (basic_info_height*2) - (pad*2)
			local hwheelw= wheel_width * .5
			local hjackw= self.jacket_width * .5
			local jacket_x= -hwheelw + hjackw + hpad
			local symbol_size= 16
			local hsymw= symbol_size * .5
			local symbol_x= hwheelw - hsymw - hpad
			local symbol_y= -basic_info_height + hsymw
			local len_x= jacket_x + hjackw + pad
			local genre_x= symbol_x - hsymw - pad
			self.title_width= symbol_x - jacket_x - hjackw - hsymw - (pad*2)
			local title_x= jacket_x + hjackw + pad + (self.title_width * .5)
			self.title_y= -22
			self.split_title_top_y= self.title_y - 12
			self.split_title_bot_y= self.title_y + 12
			local cdtitle_x= hwheelw - cdtitle_size*.5 - pad
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
				end,
				Def.Quad{
					InitCommand= function(subself)
						self.bg= subself
						subself:diffusealpha(0):setsize(wheel_width-hpad, expanded_info_height*2)
					end
				},
				Def.Sprite{
					InitCommand= function(subself)
						self.jacket= subself
						subself:xy(jacket_x, 0)
					end
				},
				normal_text("title", "", fetch_color("text"), fetch_color("stroke"), title_x, self.title_y, 1),
				normal_text("sec_title", "", fetch_color("text"), fetch_color("stroke"), title_x, self.title_y, 1),
				normal_text("subtitle", "", fetch_color("text"), fetch_color("stroke"), title_x, 12, .5),
				normal_text("length", "", fetch_color("text"), fetch_color("stroke"), len_x, 24, .5, left),
				normal_text("genre", "", fetch_color("text"), fetch_color("stroke"), genre_x, 24, .5, right),
				normal_text("artist", "", fetch_color("text"), fetch_color("stroke"), title_x, 36, .5, center),
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
					self.cdtitle:xy(cdtitle_x, cdtitle_y)
					self.steps_by= subself:GetChild("steps_by")
					subself:xy(0, self.middle_height):zoomy(0)
					self.steps_by:settext(
						get_string_wrapper("SelectMusicExtraInfo", "steps_by"))
				end,
				cdtitle(),
				normal_text("steps_by", "", fetch_color("text"), fetch_color("stroke"), self.right_x, auth_start, .5),
			}
			self.song_count= setmetatable({}, text_and_number_interface_mt)
			args[#args+1]= self.song_count:create_actors(
				"song_count", {sx= title_x, sy= 12, tx= -4, tz= .5, nx= 4,
											 nz= .5, ts= ":", tt= "song_count",
											 text_section= "SelectMusicExtraInfo"})
			self.auth_entries= {}
			self.auth_limit= 5
			self.auth_width= ((hwheelw - self.right_x) * 2) - pad
			for i= 1, self.auth_limit do
				below_args[#below_args+1]= normal_text(
					"auth"..i, "", fetch_color("text"), fetch_color("stroke"),
					self.right_x, auth_start + (i*12), .5, center, {
						InitCommand= function(subself) self.auth_entries[i]= subself end
				})
			end
			self.diff_range= setmetatable({}, text_and_number_interface_mt)
			self.nps_range= setmetatable({}, text_and_number_interface_mt)
			self.difficulty_symbols= {}
			self.difficulty_counts= {}
			local diff_tani_args= {
				sx= self.left_x, tx= -4, tz= .5, nx= 4, nz= .5, ts= ":",
				text_section= "DifficultyNames"
			}
			for i, diff in ipairs(Difficulty) do
				args[#args+1]= Def.Sprite{
					Texture= "big_circle", InitCommand= function(subself)
						self.difficulty_symbols[diff]= subself
						subself:visible(false):zoom(symbol_size/big_circle_size)
							:diffuse(diff_to_color(diff))
							:xy(symbol_x, symbol_y + ((i-1) * symbol_size))
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
				"diff_range", {sx= title_x, sy= 24, tx= -4, tz= .5, nx= 4, nz= .5, ts= ":",
											 tt= "difficulty_range", text_section= "SelectMusicExtraInfo"})
			args[#args+1]= self.nps_range:create_actors(
				"nps_range", {sx= title_x, sy= 36, tx= -4, tz= .5, nx= 4, nz= .5, ts= ":",
											 tt= "nps_range", text_section= "SelectMusicExtraInfo"})
			args[#args+1]= Def.ActorFrame(above_args)
			args[#args+1]= Def.ActorFrame(below_args)
			return Def.ActorFrame(args)
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
		end,
		set_jacket_to_image= function(self, path)
			if path and path ~= "" then
				self.jacket:LoadBanner(path)
				self.jacket:visible(true)
				scale_to_fit(self.jacket, self.jacket_width, self.jacket_width)
			end
		end,
		set_title_text= function(self, text)
			self.title:zoomx(1)
			self.title:settext(text)
			local total_width= self.title:GetWidth()
			if total_width > self.title_width then
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
				self.sec_title:settext(second_part)
					:y(self.split_title_bot_y):visible(true)
				width_limit_text(self.sec_title, self.title_width)
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
					self.bg:diffuse(wheel_colors.current_group)
				else
					self.bg:diffuse(wheel_colors.group)
				end
			elseif item.sort_info then
				self:set_title_text(item.sort_info.name)
				self.bg:diffuse(wheel_colors.sort)
			else
				if item.random_info then
					self.bg:diffuse(wheel_colors.random)
				elseif item.is_prev then
					self.bg:diffuse(wheel_colors.prev_song)
				else
					self.bg:diffuse(wheel_colors.song)
				end
				local song= gamestate_get_curr_song()
				if song then
					self:set_title_text(song_get_main_title(song))
					self.length:settext(
						get_string_wrapper("SelectMusicExtraInfo", "song_len") .. ": " ..
							secs_to_str(song_get_length(song))):visible(true)
					local genre= song:GetGenre()
					if genre ~= "" then
						self.genre:settext(
							get_string_wrapper("SelectMusicExtraInfo", "song_genre") ..
								": " .. genre):visible(true)
					end
					local artist= song:GetDisplayArtist()
					if artist ~= "" then
						self.artist:settext(
							get_string_wrapper("SelectMusicExtraInfo", "song_artist") ..
								": " .. artist):visible(true)
					end
					if song.GetDisplaySubTitle then
						self.subtitle:settext(song:GetDisplaySubTitle()):visible(true)
					end
				else
					self.title:visible(false)
				end
			end
			width_limit_text(self.title, self.title_width)
			width_limit_text(self.subtitle, self.title_width, .5)
			width_limit_text(self.artist, self.title_width, .5)
			local len_len= self.length:GetWidth()
			width_limit_text(self.genre, self.title_width - len_len - pad*2, .5)
			self.bg:diffusealpha(.5)
		end,
		update= function(self, item)
			self:update_title(item)
			if item.bucket_info then
				if songman_does_group_exist(curr_group_name) then
					self:set_jacket_to_image(
						songman_get_group_banner_path(curr_group_name))
				end
				if item.bucket_info.song_count then
					local song_count= item.bucket_info.song_count or 0
					self.song_count:unhide()
					self.song_count:set_number(song_count)
					for i, diff in ipairs(Difficulty) do
						local count= item.bucket_info.difficulties[diff]
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
					for i, steps in ipairs(steps_list) do
						local diff= steps:GetDifficulty()
						self.difficulty_symbols[diff]:visible(true):diffusealpha(1)
						local num_text= self.difficulty_counts[diff].number:GetText()
						if num_text ~= "" then num_text= num_text .. ", " end
						num_text= num_text .. get_string_wrapper(
							"DifficultyNames", steps:GetStepsType()) .. "-" ..
							steps:GetMeter()
						self.difficulty_counts[diff]:set_number(num_text)
						self.difficulty_counts[diff]:unhide()
					end
				end
			end
		end,
		collapse= function(self)
			local newy= self.middle_height
			self.expanded= false
			self.above_info:stoptweening():linear(wheel_move_time):zoomy(0):y(-newy)
			self.below_info:stoptweening():linear(wheel_move_time):zoomy(0):y(newy)
			self.bg:stoptweening():linear(wheel_move_time)
				:zoomy((basic_info_height*2)/(expanded_info_height*2))
		end,
		expand= function(self)
			local newy= self.middle_height + extra_info_height
			self.expanded= true
			self.above_info:stoptweening():linear(wheel_move_time):zoomy(1):y(-newy+hpad)
			self.below_info:stoptweening():linear(wheel_move_time):zoomy(1):y(newy-hpad)
			self.bg:stoptweening():linear(wheel_move_time):zoomy(1)
		end
}}
local focus_element_info= setmetatable({}, focus_element_info_mt)

dofile(THEME:GetPathO("", "steps_menu.lua"))
dofile(THEME:GetPathO("", "options_menu.lua"))
dofile(THEME:GetPathO("", "pain_display.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))
dofile(THEME:GetPathO("", "song_props_menu.lua"))
dofile(THEME:GetPathO("", "tags_menu.lua"))
dofile(THEME:GetPathO("", "favor_menu.lua"))
dofile(THEME:GetPathO("", "sick_options_parts.lua"))

local rate_coordinator= setmetatable({}, rate_coordinator_interface_mt)
rate_coordinator:initialize()
local color_manips= {}
local bpm_disps= {}
local special_menus= {}
local steps_menus= {}
local pain_displays= {}
local song_props_menus= {}
local tag_menus= {}
local player_cursors= {}
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
local ignore_next_open_special= {}

local function update_pain(pn)
	if GAMESTATE:IsPlayerEnabled(pn) then
		if in_special_menu[pn] == "wheel" or in_special_menu[pn] == "pain"
		or in_special_menu[pn] == "steps" then
			pain_displays[pn]:update_all_items()
			pain_displays[pn]:unhide()
		elseif in_special_menu[pn] == "menu" then
		end
	else
		pain_displays[pn]:hide()
	end
end

local function set_special_menu(pn, value)
	if value == "menu" and ignore_next_open_special[pn] then
		ignore_next_open_special[pn]= false
		return
	end
	in_special_menu[pn]= value
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
		open_menu(pn)
	end
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
		 set_special_menu(pn, "pain")
	end},
	{name= "convert_xml", req_func= convert_xml_exists, meta= "execute",
	 level= 4, execute= function()
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
		 close_menu(pn)
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
		 close_menu(pn)
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
		 close_menu(pn)
	end},
	{name= "toggle_censoring", req_func= privileged, meta= "execute",
	 execute= function(pn)
		 toggle_censoring()
		 activate_status(music_wheel:resort_for_new_style())
		 close_menu(pn)
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
		 stop_music()
		 SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
		 if not GAMESTATE:IsEventMode() then
			 end_credit_now()
		 else
			 trans_new_screen("ScreenInitialMenu")
		 end
	end},
}

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

base_options= {
	{name= "scsm_mods", meta= options_sets.menu, level= 1, args= base_mods},
	{name= "scsm_misc", meta= options_sets.menu, level= 1, args= misc_options},
	{name= "scsm_favor", meta= options_sets.favor_menu, level= 1, args= {}},
	{name= "scsm_tags", meta= options_sets.tags_menu, level= 1, args= true},
--	{name= "scsm_stepstypes", meta= options_sets.special_functions, level= 1,
--	args= make_visible_style_data, exec_args= true},
}

dofile(THEME:GetPathO("", "auto_hider.lua"))
dofile(THEME:GetPathO("", "music_wheel.lua"))
local music_wheel= setmetatable({}, music_whale_mt)

local function expand_center_for_more()
	if picking_steps then return end
	if focus_element_info.expanded then return end
	music_wheel:set_center_expansion(expanded_info_height)
	focus_element_info:expand()
	update_player_cursors()
end

local function collapse_center_for_less()
	if picking_steps then return end
	if focus_element_info.expanded == false then return end
	music_wheel:set_center_expansion(basic_info_height)
	focus_element_info:collapse()
	update_player_cursors()
end

local function toggle_expansion()
	scsm_center_expanded= not scsm_center_expanded
	if focus_element_info.expanded then
		collapse_center_for_less()
	else
		expand_center_for_more()
	end
end

local function switch_to_picking_steps()
	music_wheel.container:linear(wheel_move_time):diffusealpha(0)
	expand_center_for_more()
	focus_element_info.container:linear(wheel_move_time)
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
	music_wheel.container:linear(wheel_move_time):diffusealpha(1)
	focus_element_info.container:linear(wheel_move_time):y(_screen.cy)
	for i, dpn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		steps_menus[dpn]:deactivate()
		if in_special_menu[dpn] == "steps" then
			set_special_menu(dpn, "wheel")
		end
	end
	picking_steps= false
	was_picking_steps= true
	update_player_cursors()
end

local player_cursor_button_list= {{"top", "MenuLeft"}, {"bottom", "MenuRight"}}
reverse_button_list(player_cursor_button_list)

local function update_all_info()
	update_sort_prop()
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	for i, v in ipairs(enabled_players) do
		set_closest_steps_to_preferred(v)
	end
	focus_element_info:update(music_wheel.sick_wheel:get_info_at_focus_pos())
	update_prev_song_bpm()
	update_pain(PLAYER_1)
	update_pain(PLAYER_2)
	update_player_cursors()
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
				if focus_element_info.expanded then
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
local function activate_status(worker, after_func)
	status_active= true
	status_worker= worker
	status_finish_func= after_func
	status_container:stoptweening():linear(0.5):diffusealpha(1)
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
		for i, v in ipairs(steps_list) do
			if v == steps then
				local picked_steps= steps_list[i+dir]
				if picked_steps then
					cons_set_current_steps(player, picked_steps)
					GAMESTATE:SetPreferredDifficulty(player, picked_steps:GetDifficulty())
					set_preferred_steps_type(player, picked_steps:GetStepsType())
					SOUND:PlayOnce(THEME:GetPathS("_switch", sound))
				else
					SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
				end
				break
			end
		end
	end
	update_pain(player)
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
			music_wheel:show_sort_list()
			change_sort_text(music_wheel.current_sort_name)
			update_all_info()
		end,
		play_song= function(pn)
			if was_picking_steps then was_picking_steps= false return end
			local needs_work, after_func= music_wheel:interact_with_element(pn)
			if needs_work then
				activate_status(needs_work, after_func)
			else
				change_sort_text(music_wheel.current_sort_name)
			end
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
	if event.DeviceInput.button == "DeviceButton_s" then
		if press_type == "InputEventType_FirstPress" then
			expand_center_for_more()
		elseif press_type == "InputEventType_Release" then
			collapse_center_for_less()
		end
	end
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
			if key_pressed == "Start" and press_type == "InputEventType_FirstPress" then
				Trace("Going to options")
				SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
				entering_song= 0
				go_to_options= true
			end
		else
			local function common_menu_change(next_menu)
				pressed_since_menu_change[pn]= {}
				if picking_steps and next_menu == "wheel" then
					next_menu= "steps"
				end
				set_special_menu(pn, next_menu)
			end
			local closed_menu= false
			if key_pressed == "Select"
				and press_type == "InputEventType_FirstPress" then
				if select_press_times[pn]
					and get_screen_time() < select_press_times[pn] + double_tap_time
					and special_menus[pn]:can_exit_screen()
				and in_special_menu[pn] == "menu" then
					toggle_expansion()
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
						if key_pressed == "Start" then
							common_menu_change("wheel")
						end
					end
					if special_menus[pn].external_thing then
						local fit= color_manips[pn]:get_cursor_fit()
						fit[2]= fit[2] - pane_menu_y
						special_menus[pn]:refit_cursor(fit)
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
						return
					end
					steps_menus[pn]:interpret_code(key_pressed)
					if steps_menus[pn].needs_deactivate then
						switch_to_not_picking_steps()
					elseif steps_menus[pn].chosen_steps then
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
								options_message:accelerate(0.25):diffusealpha(1)
								entering_song= get_screen_time() + options_time
								prev_picked_song= gamestate_get_curr_song()
								save_all_favorites()
								save_all_tags()
								save_censored_list()
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
			if curr_style_type == "StyleType_OnePlayerOneSide" and not kyzentun_birthday then
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
	return Def.ActorFrame{
		Name= pn .. "_stuff", InitCommand= function(self) self:xy(x, y) end,
		pain_displays[pn]:create_actors(
			"pain", 0, pane_y + pane_yoff - pane_text_height, pn, pane_w,
			pane_text_zoom),
		steps_menus[pn]:create_actors(0, _screen.cy*.5, pn),
		bpm_disps[pn]:create_actors("bpm", pn, 0, pane_y + pane_yoff - 36, pane_w),
		color_manips[pn]:create_actors("color_manip", 0, pane_manip_y, nil, .5),
		special_menus[pn]:create_actors(
			"menu", 0, pane_menu_y, pane_menu_w, pane_menu_h, pn, 1,
			pane_text_height, menu_text_zoom),
	}
end

return Def.ActorFrame {
	InitCommand= function(self)
		self:SetUpdateFunction(Update)
		for i, pn in ipairs({PLAYER_1, PLAYER_2}) do
			special_menus[pn]:hide()
			color_manips[pn]:hide()
			bpm_disps[pn]:hide()
			update_pain(pn)
		end
		music_wheel:find_actors(self:GetChild(music_wheel.name))
		if scsm_center_expanded then
			expand_center_for_more()
		else
			collapse_center_for_less()
		end
		ensure_enough_stages()
		april_spin(self)
	end,
	OnCommand= function(self)
		local top_screen= SCREENMAN:GetTopScreen()
		top_screen:SetAllowLateJoin(true):AddInputCallback(input)
		change_sort_text(music_wheel.current_sort_name)
		update_all_info()
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
	Def.ActorFrame{
		Name= "If these commands were in the parent actor frame, they would not activate.",
		went_to_text_entryMessageCommand= function(self)
			saw_first_press= {}
			for pn, downs in pairs(keys_down) do
				keys_down[pn]= {}
			end
		end,
		get_music_wheelMessageCommand= function(self, param)
			tag_menus[param.pn].music_wheel= music_wheel
		end,
		PlayerJoinedMessageCommand= function(self)
			update_steps_types_to_show()
			self:playcommand("Set")
		end,
		current_group_changedMessageCommand= function(self, param)
			curr_group_name= param[1] or ""
		end,
	},
	player_actors(PLAYER_1, lpane_x, 0),
	player_actors(PLAYER_2, rpane_x, 0),
	music_wheel:create_actors(wheel_x, wheel_width, wheel_move_time),
	focus_element_info:create_actors(_screen.cx, _screen.cy),
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
				self:xy(_screen.cx, 16):setsize(_screen.w, 32)
					:diffuse({0, 0, 0, 1})
			end
		},
		normal_text("sort_text", "NO SORT",
								fetch_color("music_select.music_wheel.sort_type"),
								nil, 8, 16, 1, left),
		normal_text("sort_prop", "",
								fetch_color("music_select.music_wheel.sort_value"), nil,
								_screen.cx, 16, 1, center, {
									InitCommand= function(self)
										sort_prop= self
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
								_screen.w - 8, 16, 1, right, {
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
			self:xy(_screen.cx, _screen.h - 16)
		end,
		Def.Quad{
			InitCommand= function(self)
				self:xy(0, 0):setsize(_screen.w, 32)
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
