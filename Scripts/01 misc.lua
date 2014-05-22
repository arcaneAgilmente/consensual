-- For when you need a noop function to pass to something that requires a callback.
function noop_false() return false end
function noop_true() return true end
function noop_blank() return "" end
function noop_nil() end
function noop_retarg(...) return ... end

function gte_nil(value, min)
	if min then
		return value >= min
	else
		return true
	end
end

function lte_nil(value, max)
	if max then
		return value <= max
	else
		return true
	end
end

function min_nil(a, b)
	return (lte_nil(a, b) and a) or b
end

function max_nil(a, b)
	return (gte_nil(a, b) and a) or b
end

all_player_indices= {PLAYER_1, PLAYER_2}
other_player= { [PLAYER_1]= PLAYER_2, [PLAYER_2]= PLAYER_1}

difficulty_labels= {
	Difficulty_Beginner= "Difficulty_Beginner",
	Difficulty_Easy= "Difficulty_Easy",
	Difficulty_Medium= "Difficulty_Medium",
	Difficulty_Hard= "Difficulty_Hard",
	Difficulty_Challenge= "Difficulty_Challenge",
	Difficulty_Edit= "Difficulty_Edit"
}

-- this has to be a function instead of a constant because the game can change.
function lowered_game_name()
	return GAMESTATE:GetCurrentGame():GetName():lower()
end

-- Lua:  Battery contacts not included.
-- Round to nearest integer.
function math.round(n)
	if n > 0 then
		return math.floor(n+0.5)
	else
		return math.ceil(n-0.5)
	end
end

function force_to_range(min, number, max)
	return math.min(max, math.max(min, number))
end

function pow_ten_force(val)
	return 10^math.round(math.log10(val))
end

-- Usage:  Pass in an ActorFrame to print all the children of.
function print_children(a)
	local aname= a:GetName()
	Trace("Printing child list for " .. aname)
	if a.GetChildren then
		local children= a:GetChildren()
		for k, v in pairs(children) do
			Trace("  " .. v:GetName())
		end
	else
		Trace("Not an ActorFrame or other thing with children.")
	end
	Trace("Done.")
end

-- Usage:  Pass in an ActorFrame and a string to put in front of every line.
-- indent will be appended to at each level of the recursion, to indent each
-- generation further.

function rec_print_children(parent, indent)
	if not indent then indent= "" end
	if #parent > 0 and type(parent) == "table" then
		for i, c in ipairs(parent) do
			rec_print_children(c, indent .. i .. "->")
		end
	elseif parent.GetChildren then
		local pname= (parent.GetName and parent:GetName()) or ""
		local children= parent:GetChildren()
		Trace(indent .. pname .. " children:")
		for k, v in pairs(children) do
			if #v > 0 then
				Trace(indent .. pname .. "->" .. k .. " shared name:")
				rec_print_children(v, indent .. pname .. "->")
				Trace(indent .. pname .. "->" .. k .. " shared name over.")
			else
				rec_print_children(v, indent .. pname .. "->")
			end
		end
		Trace(indent .. pname .. " children over.")
	else
		local pname= (parent.GetName and parent:GetName()) or ""
		Trace(indent .. pname .. "(" .. tostring(parent) .. ")")
	end
end

function rec_find_child(parent, name)
	if parent:GetName() == name then
		--Trace("Found matching child: " .. parent:GetName())
		return parent
	end
	if parent.GetChildren then
		for k, v in pairs(parent:GetChildren()) do
			local res= rec_find_child(v, name)
			if res then
				--Trace("Recursively returning match: " .. res:GetName())
				return res
			end
		end
	end
	return nil
end

function rec_convert_strings_to_numbers(t)
	for k, v in pairs(t) do
		if tonumber(v) then
			t[k]= tonumber(v)
		elseif type(v) == "table" then
			rec_convert_strings_to_numbers(v)
		end
	end
end

-- Usage:  Pass in a table and a string to indent each line with.
function print_table(t, indent)
	if not indent then indent= "" end
	for k, v in pairs(t) do
		Trace(indent .. k .. ": " .. tostring(v))
	end
	Trace(indent .. "end")
end

-- Usage:  Pass in a table and a string to indent each line with.
-- indent will be appended to at each level of the recursion, to indent each
-- generation further.
-- DO NOT pass in a table that contains a reference loop.
-- A reference loop is a case where a table contains a member that is a
-- reference to itself, or contains a table that contains a reference to
-- itself.
-- Short reference loop example:  a= {}   a[1]= a
-- Longer reference loop example:  a= {b= {c= {}}}   a.b.c[1]= a
function rec_print_table(t, indent, depth_remaining)
	if not indent then indent= "" end
	if type(t) ~= "table" then
		Trace(indent .. "rec_print_table passed a " .. type(t))
		return
	end
	depth_remaining= depth_remaining or -1
	if depth_remaining == 0 then return end
	for k, v in pairs(t) do
		if type(v) == "table" then
			Trace(indent .. k .. ": table")
			rec_print_table(v, indent .. "  ", depth_remaining - 1)
		else
			Trace(indent .. k .. ": " .. tostring(v))
		end
	end
	Trace(indent .. "end")
end

function lua_table_to_string(t, indent)
	indent= indent or ""
	local ret= "{\n"
	local internal_indent= indent .. "  "
	local function do_value_for_key(k, v)
		local k_str= k
		if type(k) == "number" then
			k_str= "[" .. k .. "]"
		else
			k_str= "[" .. ("%q"):format(k) .. "]"
		end
		local v_str= ""
		if type(v) == "table" then
			v_str= lua_table_to_string(v, internal_indent)
		elseif type(v) == "string" then
			v_str= ("%q"):format(v)
		elseif type(v) == "number" then
			if v ~= math.floor(v) then
				v_str= ("%.3f"):format(v)
			else
				v_str= tostring(v)
			end
		else
			v_str= tostring(v)
		end
		ret= ret .. internal_indent .. k_str .. "= " .. v_str .. ",\n"
	end
	-- do the integer indices from 0 to n first, in order.
	for n= 0, #t do
		if t[n] then
			do_value_for_key(n, t[n])
		end
	end
	for k, v in pairs(t) do
		local is_integer_key= (type(k) == "number") and (k == math.floor(k)) and k >= 0 and k < #t
		if not is_integer_key then
			do_value_for_key(k, v)
		end
	end
	ret= ret .. indent .. "}"
	return ret
end

function generate_song_sort_test_data()
	local song_table= {}
	for i, song in ipairs(SONGMAN:GetAllSongs()) do
		song_table[#song_table+1]=
			{group= song:GetGroupName(), song= song:GetDisplayMainTitle()}
	end
	local file_handle= RageFileUtil.CreateRageFile()
	local file_name= "test_song_sort_data.lua"
	if not file_handle:Open(file_name, 2) then
		Trace("Could not open '" .. file_name .. "' to write test song sort data.")
	else
		local output= "return " .. lua_table_to_string(song_table) .. "\n"
		file_handle:Write(output)
		file_handle:Close()
		file_handle:destroy()
		Trace("test song sort data written to '" .. file_name .. "'")
	end
end

function get_string_wrapper(section, string)
	--Trace("get_string_wrapper:  Searching section \"" .. tostring(section)
	--   .. "\" for string \"" .. tostring(string) .. "\"")
	if not string then return "" end
	if section then
		if string ~= "" and section ~= "" and
			THEME:HasString(section, string) then
			return THEME:GetString(section, string)
		else
			--Trace("Emptry string, empty section, or string not found.")
			return string
		end
	else
		--Trace("Empty section.")
		return string
	end
end

function wrapped_index(start, offset, set_size)
	return ((start - 1 + offset) % set_size) + 1
end

do
	local zoomed_width= SCREEN_BOTTOM / 32
	local zoomed_height= 24
	local spacing_y= zoomed_width
	local start_y= 0
	function life_pill_transform(self,offsetFromCenter,itemIndex,numItems)
		--Trace("life_pill_transform: " .. self:GetName() .. ": " .. offsetFromCenter .. ", " .. itemIndex .. ", " .. numItems)
		--local parent= self:GetParent()
		--if parent then
		--   Trace("Parent: " .. parent:GetName())
		--end
		self:zoomtoheight(zoomed_height)
		self:zoomtowidth(zoomed_width)
		self:rotationz(-90)
		self:y(start_y - (itemIndex * spacing_y))
	end
end

if MonthOfYear() == 3 and DayOfMonth() == 1 then
	april_fools= true
end

global_distortion_mode= april_fools
function maybe_distort_text(text_actor)
	if global_distortion_mode and text_actor.distort then
		if april_fools then
			if GetTimeSinceStart() > 2048 then
				-- This should cause the distortion to start appearing 2048 seconds
				-- after sm starts.  Then the distortion will take 612 seconds to go
				-- through a full cycle.
				local dist= 2 * math.sin((GetTimeSinceStart() - 2048) / 100)
				if math.abs(dist) > 1 then
					if dist > 0 then
						dist= dist - 1
					else
						dist= dist + 1
					end
					text_actor:distort(dist)
				end
			end
		else
			text_actor:distort(.75)
		end
	end
end

local get_all_steps= "GetAllSteps"
local get_main_title= "GetDisplayMainTitle"
local set_curr_song= noop_nil
local get_curr_song= noop_nil
local get_curr_steps= noop_nil
local set_curr_steps= noop_nil
local does_group_exist= noop_false
local get_group_banner_path= noop_blank
function song_get_length() return 0 end

function set_course_mode()
	get_all_steps= "GetAllTrails"
	get_main_title= "GetDisplayFullTitle"
	set_curr_song= GAMESTATE.SetCurrentCourse
	get_curr_song= GAMESTATE.GetCurrentCourse
	get_curr_steps= GAMESTATE.GetCurrentTrail
	set_curr_steps= GAMESTATE.SetCurrentTrail
	does_group_exist= SONGMAN.DoesCourseGroupExist
	get_group_banner_path= SONGMAN.GetCourseGroupBannerPath
	song_get_length=
		function(song)
			local steps_type= GAMESTATE:GetCurrentStyle():GetStepsType()
			return (song.GetTotalSeconds and song:GetTotalSeconds(steps_type)) or 0
		end
end

function  set_song_mode()
	get_all_steps= "GetAllSteps"
	get_main_title= "GetDisplayMainTitle"
	set_curr_song= GAMESTATE.SetCurrentSong
	get_curr_song= GAMESTATE.GetCurrentSong
	get_curr_steps= GAMESTATE.GetCurrentSteps
	set_curr_steps= GAMESTATE.SetCurrentSteps
	does_group_exist= SONGMAN.DoesSongGroupExist
	get_group_banner_path= SONGMAN.GetSongGroupBannerPath
	song_get_length=
		function(song)
			return (song.GetFirstSecond and
							math.round(song:GetLastSecond() - song:GetFirstSecond())) or 0
		end
end

function song_get_all_steps(song)
	return song[get_all_steps](song)
end

function song_get_main_title(song)
	return song[get_main_title](song)
end

function steps_get_bpms(strail)
	local bpms= {}
	if GAMESTATE:IsCourseMode() then
		for i, entry in ipairs(strail:GetTrailEntries()) do
			local ebpms= entry:GetSteps():GetDisplayBpms()
			bpms[#bpms+1]= ebpms[1]
			if ebpms[1] ~= ebpms[2] then
				bpms[#bpms+1]= ebpms[2]
			end
		end
	else
		bpms= strail:GetDisplayBpms()
	end
	table.sort(bpms)
	local ib= 2
	while bpms[ib] do
		if bpms[ib] == bpms[ib-1] then
			table.remove(bpms, ib)
		else
			ib= ib+1
		end
	end
	return bpms
end

function steps_get_bpms_as_text(strail)
	local bpms= steps_get_bpms(strail)
	local bpm_text= ""
	local low, high= false, false
	for i, v in ipairs(bpms) do
		if not low or v < low then
			low= v
		end
		if not high or v > high then
			high= v
		end
		if i > 1 then
			bpm_text= bpm_text .. "-"
		end
		bpm_text= bpm_text .. ("%.0f"):format(v)
	end
	local short_text= ("%.0f"):format(low)
	if low ~= high then
		short_text= short_text .. "-" .. ("%.0f"):format(high)
	end
	return short_text
end

function steps_get_author(steps)
	if steps.GetAuthorCredit then
		-- All three of these are plausible places for the author name.
		-- The correct place.
		local author= steps:GetAuthorCredit()
		if not author or author == "" then
			-- The wrong place.
			author= steps:GetChartName()
		end
		if not author or author == "" then
			-- The place that exists in .sm files.
			author= steps:GetDescription()
		end
		return author
	else
		return ""
	end
end

function gamestate_get_curr_song()
	return get_curr_song(GAMESTATE)
end

function gamestate_set_curr_song(song)
	return set_curr_song(GAMESTATE, song)
end

function gamestate_get_curr_steps(pn)
	return get_curr_steps(GAMESTATE, pn)
end

function gamestate_set_curr_steps(pn, steps)
	return set_curr_steps(GAMESTATE, pn, steps)
end

function songman_does_group_exist(name)
	return does_group_exist(SONGMAN, name)
end

function songman_get_group_banner_path(name)
	return get_group_banner_path(SONGMAN, name)
end

playmode_to_command= {
	PlayMode_Regular= "regular",
	PlayMode_Nonstop= "nonstop",
	PlayMode_Oni= "oni",
	PlayMode_Endless= "endless",
	PlayMode_Battle= "battle",
	PlayMode_Rave= "rave"
}

function get_current_song_length()
	local song= gamestate_get_curr_song()
	if song then
		return song_get_length(song)
	else
		return 0
	end
end

function get_rate_from_songopts()
	return GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate()
end

-- An object to handle coordination of rate changes between things on a screen.
local rate_coordinator_interface= {}
rate_coordinator_interface_mt= { __index= rate_coordinator_interface }
function rate_coordinator_interface:initialize()
	self.notify_list= {}
	self.current_rate= get_rate_from_songopts()
end

function rate_coordinator_interface:add_to_notify(sub)
	self.notify_list[#self.notify_list+1]= sub
end

function rate_coordinator_interface:remove_from_notify(sub)
	local index= 0
	for i, s in ipairs(self.notify_list) do
		if s == sub then
			index= i
		end
	end
	if index ~= 0 then
		table.remove(self.notify_list, index)
	end
end

function rate_coordinator_interface:notify(new_rate, play_new_sample)
	if tonumber(new_rate) then
		self.current_rate= new_rate
		for v in ivalues(self.notify_list) do
			v:notify_of_rate_change()
		end
		if play_new_sample then
			play_sample_music()
		end
	else
		error("Someone notified of a bad new rate: \"" .. tostring(new_rate)
				.. '"')
	end
end

function rate_coordinator_interface:get_current_rate()
	return self.current_rate
end

function steps_to_string(steps)
	return get_string_wrapper("DifficultyNames", steps:GetStepsType()) .. "-"
	.. get_string_wrapper("DifficultyNames", steps:GetDifficulty())
end

local cached_steps_list= false
local cached_steps_song= false
local cached_steps_players= false
function get_filtered_sorted_steps_list(song)
	song= song or gamestate_get_curr_song()
	local num_players= GAMESTATE:GetNumPlayersEnabled()
	if song == cached_steps_song and num_players == cached_steps_players then
		return cached_steps_list
	end
	local ret= {}
	local filter_types= cons_get_steps_types_to_show()
	if song and #filter_types >= 1 then
		local all_steps= song_get_all_steps(song)
		for i, v in ipairs(all_steps) do
			local st= v:GetStepsType() 
			for fi, fv in ipairs(filter_types) do
				if st == fv then
					ret[#ret+1]= v
					break
				end
			end
		end
		local function compare(ela, elb)
			if not ela then return true end
			if not elb then return false end
			local type_diff= StepsType:Compare(ela:GetStepsType(), elb:GetStepsType())
			if type_diff == 0 then
				return Difficulty:Compare(ela:GetDifficulty(), elb:GetDifficulty()) < 0
			else
				return type_diff < 0
			end
		end
		table.sort(ret, compare)
	end
	cached_steps_players= num_players
	cached_steps_song= song
	cached_steps_list= ret
	return ret
end

convert_code_name_to_display_text= {
	noob_mode="noob",
	simple_options_mode="simple options",
	all_options_mode="all options",
	excessive_options_mode="excessive options",
	kyzentun_mode="Kyzentun",
	unjoin="Unjoin Other",
}

function play_sample_music()
	if GAMESTATE:IsCourseMode() then return end
	local song= GAMESTATE:GetCurrentSong()
	if song then
		local songpath= song:GetMusicPath()
		local sample_start= song:GetSampleStart()
		local sample_len= song:GetSampleLength()
--		Trace("Playing sample: " .. tostring(songpath) .. " " ..
--				sample_start .. " - " .. sample_len)
		if songpath and sample_start and sample_len then
			SOUND:PlayMusicPart(songpath, sample_start,
													sample_len, 0, 0, true, true)
		else
			SOUND:PlayMusicPart("", 0, 0)
--			Trace("Something was invalid.")
		end
	else
		SOUND:PlayMusicPart("", 0, 0)
--		Trace("No current song to play sample.")
	end
end

function stop_music()
	SOUND:PlayMusicPart("", 0, 0)
end

music_wheel_width= SCREEN_WIDTH*.3125

local poptions_queries= {
	{ n= "Alternate", f= PlayerOptions.GetAlternate },
	{ n= "AttackMines", f= PlayerOptions.GetAttackMines },
	{ n= "Backwards", f= PlayerOptions.GetBackwards },
	{ n= "Beat", f= PlayerOptions.GetBeat },
	{ n= "Big", f= PlayerOptions.GetBig },
	{ n= "Blind", f= PlayerOptions.GetBlind },
	{ n= "Blink", f= PlayerOptions.GetBlink },
	{ n= "BMRize", f= PlayerOptions.GetBMRize },
	{ n= "Boomerang", f= PlayerOptions.GetBoomerang },
	{ n= "Boost", f= PlayerOptions.GetBoost },
	{ n= "Brake", f= PlayerOptions.GetBrake },
	{ n= "Bumpy", f= PlayerOptions.GetBumpy },
	{ n= "Centered", f= PlayerOptions.GetCentered },
	{ n= "CMod", f= PlayerOptions.GetCMod },
	{ n= "Confusion", f= PlayerOptions.GetConfusion },
	{ n= "Cover", f= PlayerOptions.GetCover },
	{ n= "Cross", f= PlayerOptions.GetCross },
	{ n= "Dark", f= PlayerOptions.GetDark },
	{ n= "Dizzy", f= PlayerOptions.GetDizzy },
	{ n= "Drunk", f= PlayerOptions.GetDrunk },
	{ n= "Echo", f= PlayerOptions.GetEcho },
	{ n= "Expand", f= PlayerOptions.GetExpand },
	{ n= "Flip", f= PlayerOptions.GetFlip },
	{ n= "Floored", f= PlayerOptions.GetFloored },
	{ n= "Hidden", f= PlayerOptions.GetHidden },
	{ n= "HiddenOffset", f= PlayerOptions.GetHiddenOffset },
	{ n= "HoldRolls", f= PlayerOptions.GetHoldRolls },
	{ n= "Invert", f= PlayerOptions.GetInvert },
	{ n= "Left", f= PlayerOptions.GetLeft },
	{ n= "Little", f= PlayerOptions.GetLittle },
	{ n= "Mines", f= PlayerOptions.GetMines },
	{ n= "Mini", f= PlayerOptions.GetMini },
	{ n= "Mirror", f= PlayerOptions.GetMirror },
	{ n= "MMod", f= PlayerOptions.GetMMod },
	{ n= "MuteOnError", f= PlayerOptions.GetMuteOnError },
	{ n= "NoAttacks", f= PlayerOptions.GetNoAttacks },
	{ n= "NoFakes", f= PlayerOptions.GetNoFakes },
	{ n= "NoHands", f= PlayerOptions.GetNoHands },
	{ n= "NoHolds", f= PlayerOptions.GetNoHolds },
	{ n= "NoJumps", f= PlayerOptions.GetNoJumps },
	{ n= "NoLifts", f= PlayerOptions.GetNoLifts },
	{ n= "NoMines", f= PlayerOptions.GetNoMines },
	{ n= "NoQuads", f= PlayerOptions.GetNoQuads },
	{ n= "NoRolls", f= PlayerOptions.GetNoRolls },
	{ n= "NoStretch", f= PlayerOptions.GetNoStretch },
	{ n= "NoteSkin", f= PlayerOptions.GetNoteSkin },
	{ n= "Passmark", f= PlayerOptions.GetPassmark },
	{ n= "Planted", f= PlayerOptions.GetPlanted },
	{ n= "Quick", f= PlayerOptions.GetQuick },
	{ n= "RandomAttacks", f= PlayerOptions.GetRandomAttacks },
	{ n= "RandomSpeed", f= PlayerOptions.GetRandomSpeed },
	{ n= "RandomVanish", f= PlayerOptions.GetRandomVanish },
	{ n= "Reverse", f= PlayerOptions.GetReverse },
	{ n= "Right", f= PlayerOptions.GetRight },
	{ n= "Roll", f= PlayerOptions.GetRoll },
	{ n= "Shuffle", f= PlayerOptions.GetShuffle },
	{ n= "Skew", f= PlayerOptions.GetSkew },
	{ n= "Skippy", f= PlayerOptions.GetSkippy },
	{ n= "SoftShuffle", f= PlayerOptions.GetSoftShuffle },
	{ n= "SongAttacks", f= PlayerOptions.GetSongAttacks },
	{ n= "Split", f= PlayerOptions.GetSplit },
	{ n= "Stealth", f= PlayerOptions.GetStealth },
	{ n= "StepAttacks", f= PlayerOptions.GetStepAttacks },
	{ n= "Stomp", f= PlayerOptions.GetStomp },
	{ n= "Sudden", f= PlayerOptions.GetSudden },
	{ n= "SuddenOffset", f= PlayerOptions.GetSuddenOffset },
	{ n= "SuperShuffle", f= PlayerOptions.GetSuperShuffle },
	{ n= "Tiny", f= PlayerOptions.GetTiny },
	{ n= "Tipsy", f= PlayerOptions.GetTipsy },
	{ n= "Tornado", f= PlayerOptions.GetTornado },
	{ n= "Twirl", f= PlayerOptions.GetTwirl },
	{ n= "Twister", f= PlayerOptions.GetTwister },
	{ n= "Wave", f= PlayerOptions.GetWave },
	{ n= "Wide", f= PlayerOptions.GetWide },
	{ n= "XMod", f= PlayerOptions.GetXMod },
	{ n= "XMode", f= PlayerOptions.GetXMode },
}

function spew_player_options(poptions)
	Trace("Spewing player options.")
	for e= 1, #poptions_queries do
		local el= poptions_queries[e]
		Trace(el.n .. ": " .. tostring(el.f(poptions)))
	end
	Trace("Done.")
end
