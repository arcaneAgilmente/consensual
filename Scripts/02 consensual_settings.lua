local cons_player= {}

function cons_player:clear_init(player_number)
	for k, v in pairs(self) do
		if k ~= "id" then
			self[k]= nil
		end
	end
	self.player_number= player_number
	self.current_options= GAMESTATE:GetPlayerState(player_number):GetPlayerOptions("ModsLevel_Current")
	self.song_options= GAMESTATE:GetPlayerState(player_number):GetPlayerOptions("ModsLevel_Song")
	self.stage_options= GAMESTATE:GetPlayerState(player_number):GetPlayerOptions("ModsLevel_Stage")
	self.preferred_options= GAMESTATE:GetPlayerState(player_number):GetPlayerOptions("ModsLevel_Preferred")
	self.judge_totals= {}
	self:set_speed_info_from_poptions()
	self.dspeed= {min= dspeed_default_min, max= dspeed_default_max, alternate= false}
	self:flags_reset()
	self:pain_config_reset()
	self:combo_qual_reset()
	self:unacceptable_score_reset()
	self:stage_stats_reset()
	self:session_stats_reset()
	self.mine_effect= sorted_mine_effect_names[1]
	self.sigil_data= {detail= 16, size= 150}
	self.play_history= {}
end

function cons_player:clear_mods()
	self:clear_init(self.player_number)
	GAMESTATE:ApplyGameCommand("mod,clearall", self.player_number)
	-- SM5 will crash if a noteskin is not applied after clearing all mods.
	-- Apply the default noteskin first in case Cel doesn't exist.
	local default_noteskin= THEME:GetMetric("Common", "DefaultNoteSkinName")
	local prev_note, succeeded= self.song_options:NoteSkin("uswcelsm5")
	if not succeeded then
		prev_note, succeeded= self.song_options:NoteSkin(default_noteskin)
		if not succeeded then
			Warn("Failed to set default noteskin when clearing player options.  Please do not delete the default noteskin.")
		end
	end
end

function cons_player:noob_mode()
	-- TODO:  Test whether this accidentally overrides player_config.
	-- Move rating_cap and options_level to somethign similar to
	-- profile_flag_setting so the machine owner can configure what each level
	-- sets.
	self.rating_cap= 5
	self.options_level= 1
	self.flags= set_player_flag_to_level(self.player_number, 1)
	self.pain_config= set_player_pain_to_level(self.player_number, 1)
end

function cons_player:simple_options_mode()
	self.rating_cap= 10
	self.options_level= 2
	self.flags= set_player_flag_to_level(self.player_number, 2)
	self.pain_config= set_player_pain_to_level(self.player_number, 2)
end

function cons_player:all_options_mode()
	self.rating_cap= 15
	self.options_level= 3
	self.flags= set_player_flag_to_level(self.player_number, 3)
	self.pain_config= set_player_pain_to_level(self.player_number, 3)
end

function cons_player:excessive_options_mode()
	self.rating_cap= -1
	self.options_level= 4
	self.flags= set_player_flag_to_level(self.player_number, 4)
	self.pain_config= set_player_pain_to_level(self.player_number, 4)
end

function cons_player:kyzentun_mode()
	self.rating_cap= -1
	self.options_level= 5
	self.kyzentun= true
	local styletype= GAMESTATE:GetCurrentStyle(self.player_number):GetStyleType()
	local new_speed= {speed= 1000, mode= "m"}
	self.preferred_options:Distant(1.5)
	if styletype == "StyleType_OnePlayerTwoSides" then
		self.preferred_options:Distant(1.2)
		new_speed= {speed= 500, mode= "m"}
	end
	if self.speed_info then
		self.speed_info.speed= new_speed.speed
		self.speed_info.mode= new_speed.mode
	else
		self.speed_info= new_speed
	end
	self.preferred_options:NoteSkin("uswshadow3dsm5")
	self.flags= set_player_flag_to_level(self.player_number, 4)
	self.pain_config= set_player_pain_to_level(self.player_number, 4)
	self.combo_splash_threshold= "TapNoteScore_Miss"
	self.combo_graph_threshold= "TapNoteScore_Miss"
	self.sigil_data.detail= 32
	activate_confetti("perm", true)
end

function cons_player:combo_qual_reset()
	self.combo_quality= {}
end

local function empty_judge_count_set()
	local ret= {}
	for i, tns in ipairs(TapNoteScore) do
		ret[tns]= 0
	end
	for i, tns in ipairs(HoldNoteScore) do
		ret[tns]= 0
	end
	return ret
end

function cons_player:unacceptable_score_reset()
	self.unacceptable_score= {
		enabled= false, condition= "dance_points", value= 0}
end

function cons_player:stage_stats_reset()
	self.stage_stats= {firsts= {}}
	local function empty_col_score()
		return {
			dp= 0, mdp= 0, max_combo= 0, step_timings= {},
			judge_counts= empty_judge_count_set(),
		}
	end
	self.fake_score= empty_col_score()
	local cur_style= GAMESTATE:GetCurrentStyle(self.player_number)
	if cur_style then
		local columns= cur_style:ColumnsPerPlayer()
		--Trace("Making column score slots for " .. tostring(columns) .. " columns.")
		self.column_scores= {}
		-- Track indices from the engine are 1-indexed.
		-- Column 0 is for all columns combined.
		for c= 0, columns do
			self.column_scores[c]= empty_col_score()
		end
	end
end

function cons_player:session_stats_reset()
	self.session_stats= {}
	-- Columns in the session stats are for every panel on the pad, to handle
	-- mixed sessions.  Otherwise, a session where P2 played one song on single,
	-- and one song on double would put the data for the single song in the
	-- wrong columns.
	-- style compatibility issue:  Dance, Pump, and Techno are the only supported games.
	for i= -1, 18 do
		self.session_stats[i]= {
			dp= 0, mdp= 0, max_combo= 0, judge_counts= {
				early= empty_judge_count_set(), late= empty_judge_count_set()}
		}
	end
end

function cons_player:flags_reset()
	self.flags= set_player_flag_to_level(self.player_number, 1)
	-- allow_toasty is set here so it will be affected if the preference is changed while the game is running.
	self.flags.gameplay.allow_toasty= PREFSMAN:GetPreference("EasterEggs")
end

function cons_player:pain_config_reset()
	self.pain_config= set_player_pain_to_level(self.player_number, 1)
end

function cons_player:set_speed_info_from_poptions()
	local speed= nil
	local mode= nil
	if self.preferred_options:MaxScrollBPM() > 0 then
		mode= "m"
		speed= self.preferred_options:MaxScrollBPM()
	elseif self.preferred_options:TimeSpacing() > 0 then
		mode= "C"
		speed= self.preferred_options:ScrollBPM()
	else
		mode= "x"
		speed= self.preferred_options:ScrollSpeed()
	end
	self.speed_info= { speed= speed, mode= mode }
	return self.speed_info
end

function cons_player:get_speed_info()
	return self.speed_info or self:set_speed_info_from_poptions()
end

local function find_read_bpm_for_player_steps(player_number)
	local bpms= get_display_bpms(GAMESTATE:GetCurrentSteps(player_number),
															 GAMESTATE:GetCurrentSong())
	return bpms[2]
end

function set_speed_from_speed_info(player)
	-- mmods are just a poor mask over xmods, so if you set an mmod in
	-- the middle of the song, it'll null out.  This means that if you
	-- use PlayerState:SetPlayerOptions, it'll ruin whatever mmod the
	-- player has set.  So this code is here to remove that mask.
	if not player.player_number or not GAMESTATE:IsPlayerEnabled(player.player_number) then return end
	local speed_info= player:get_speed_info()
	speed_info.prev_bps= nil
	local mode_functions= {
		x= function(speed)
				 player.preferred_options:XMod(speed)
				 player.stage_options:XMod(speed)
				 player.song_options:XMod(speed)
				 player.current_options:XMod(speed)
			 end,
		C= function(speed)
				 player.preferred_options:CMod(speed)
				 player.stage_options:CMod(speed)
				 player.song_options:CMod(speed)
				 player.current_options:CMod(speed)
			 end,
		m= function(speed)
				 local read_bpm= find_read_bpm_for_player_steps(player.player_number)
				 local real_speed= (speed / read_bpm) / get_rate_from_songopts()
				 player.preferred_options:XMod(real_speed)
				 player.stage_options:XMod(real_speed)
				 player.song_options:XMod(real_speed)
				 player.current_options:XMod(real_speed)
				 --player.song_options:MMod(speed)
				 --player.current_options:MMod(speed)
			 end,
		D= function(speed)
				 local read_bpm= find_read_bpm_for_player_steps(player.player_number)
				 local real_speed= (speed / read_bpm) / get_rate_from_songopts()
				 player.dspeed_mult= real_speed
				 player.preferred_options:XMod(real_speed)
				 player.stage_options:XMod(real_speed)
				 player.song_options:XMod(real_speed)
				 player.current_options:XMod(real_speed)
				 if math.abs(player.dspeed.max - player.dspeed.min) < .01 then
					 player.dspeed.special= true
					 if player.dspeed.alternate then
						 player.current_options:Sudden(1)
						 player.song_options:Sudden(1)
						 player.song_options:SuddenOffset(suddmin)
						 player.dspeed_phase= 1
						 dspeed_special_phase_starts[player.dspeed_phase](player)
					 else
						 player.song_options:Centered(dspeed_default_max)
					 end
				 else
					 player.dspeed.special= false
					 player.song_options:Centered(player.dspeed.max)
				 end
			 end
	}
	if mode_functions[speed_info.mode] then
		mode_functions[speed_info.mode](speed_info.speed)
	end
end

function cons_player:set_ops_from_profile(profile)
	if profile then
		self.proguid= profile:GetGUID()
	end
	local prof_slot= pn_to_profile_slot(self.player_number)
	self.pain_config= profile_pain_setting:load(prof_slot)
	self.flags= profile_flag_setting:load(prof_slot)
	self.style_config= style_config:load(prof_slot)
	local config= player_config:load(prof_slot)
	for k, v in pairs(config) do
		self[k]= v
	end
end

local cons_player_mt= { __index= cons_player}

if cons_players then
	for k, v in pairs(all_player_indices) do
		setmetatable(cons_players[v], cons_player_mt)
	end
else
	cons_players= {}
	for k, v in pairs(all_player_indices) do
		cons_players[v]= {}
		setmetatable(cons_players[v], cons_player_mt)
	end
end

function options_allowed()
	return true
end

function generic_gsu_flag(flag_field, flag_name)
	return
	function(player_number)
		return cons_players[player_number].flags[flag_field][flag_name]
	end,
	function(player_number)
		cons_players[player_number].flags[flag_field][flag_name]= true
	end,
	function(player_number)
		cons_players[player_number].flags[flag_field][flag_name]= false
	end
end

function generic_flag_control_element(flag_field, flag_name)
	local funcs= {generic_gsu_flag(flag_field, flag_name)}
	return {name= flag_name, init= funcs[1], set= funcs[2], unset= funcs[3]}
end

local tn_judges= {
	"TapNoteScore_Miss", "TapNoteScore_W5", "TapNoteScore_W4", "TapNoteScore_W3", "TapNoteScore_W2", "TapNoteScore_W1"
}

local tn_hold_judges= {
	"HoldNoteScore_LetGo", "HoldNoteScore_Held", "HoldNoteScore_Missed"
}

local generic_fake_judge= {
	__index= {
		initialize=
			function(self, pn, tn_settings)
				self.settings= DeepCopy(tn_settings)
				self.used= {}
				for i= 1, #tn_judges do
					self.used[i]= 0
				end
				local steps= GAMESTATE:GetCurrentSteps(pn)
				local taps= steps:GetRadarValues(pn):GetValue("RadarCategory_TapsAndHolds")
				local holds= steps:GetRadarValues(pn):GetValue("RadarCategory_Holds")
			end,
		
}}

local fake_judges= {
	TapNoteScore_Miss= function() return "TapNoteScore_Miss" end,
	TapNoteScore_W5= function() return "TapNoteScore_W5" end,
	TapNoteScore_W4= function() return "TapNoteScore_W4" end,
	TapNoteScore_W3= function() return "TapNoteScore_W3" end,
	TapNoteScore_W2= function() return "TapNoteScore_W2" end,
	TapNoteScore_W1= function() return "TapNoteScore_W1" end,
	Random=
		function()
			return tn_judges[MersenneTwister.Random(1, #tn_judges)]
		end
}

function set_fake_judge(tns)
	return
	function(player_number)
		cons_players[player_number].fake_judge= fake_judges[tns]
	end
end

function unset_fake_judge(player_number)
	cons_players[player_number].fake_judge= nil
end

function check_fake_judge(tns)
	return
	function(player_number)
		return cons_players[player_number].fake_judge == fake_judges[tns]
	end
end

function check_mine_effect(eff)
	return
	function(player_number)
		return cons_players[player_number].mine_effect == eff
	end
end

function set_mine_effect(eff)
	return
	function(player_number)
		cons_players[player_number].mine_effect= eff
	end
end

function unset_mine_effect(player_number)
	cons_players[player_number].mine_effect= "none"
end

function GetPreviousPlayerSteps(player_number)
	return cons_players[player_number].prev_steps
end

function GetPreviousPlayerScore(player_number)
	return cons_players[player_number].prev_score or 0
end

function ConvertScoreToFootRateChange(meter, score)
	local diff= (math.max(0, score - .625) * (8 / .375)) - 4
	if meter > 13 then
		diff= diff * .25
	elseif meter > 10 then
		diff= diff * .5
	elseif meter > 8 then
		diff= diff * .75
	end
	if diff > 0 then
		diff= math.floor(diff + .5)
	else
		diff= math.ceil(diff - .5)
	end
	return diff
	--score= score^4
	--local max_diff= scale(meter, 8, 16, 4, 1)
	--max_diff= force_to_range(1, max_diff, 4)
	--local change= scale(score, 0, 1, -max_diff, max_diff)
	--if change < 0 then
	--	change= math.floor(change + .75)
	--else
	--	change= math.floor(change + .25)
	--end
	--return change
end

local time_remaining= 0
function set_time_remaining_to_default()
	time_remaining= misc_config:get_data().default_credit_time
end

function reduce_time_remaining(amount)
	if not GAMESTATE:IsEventMode() then
		time_remaining= time_remaining - amount
	end
end

function get_time_remaining()
	return time_remaining
end

function song_short_enough(s)
	if GAMESTATE:IsEventMode() then
		return true
	else
		local maxlen= time_remaining + misc_config:get_data().song_length_grace
		if s.GetLastSecond then
			local len= s:GetLastSecond() - s:GetFirstSecond()
			return len <= maxlen and len > 0
		else
			local steps_type= GAMESTATE:GetCurrentStyle():GetStepsType()
			return (s:GetTotalSeconds(steps_type) or 0) <= maxlen
		end
	end
end

local censoring_on= true
function toggle_censoring()
	censoring_on= not censoring_on
end

local chart_rating_cap= -1
function update_rating_cap()
	local old_cap= chart_rating_cap
	chart_rating_cap= 0
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if cons_players[pn].rating_cap < 0 then
			chart_rating_cap= -1
		else
			chart_rating_cap= math.max(cons_players[pn].rating_cap, chart_rating_cap)
		end
	end
	return old_cap ~= chart_rating_cap
end

function disable_rating_cap()
	chart_rating_cap= -1
end

function song_short_and_uncensored(song)
	local show= song_short_enough(song)
	if censoring_on and check_censor_list(song) then
		show= false
	end
	if show and chart_rating_cap > 0 then
		local steps_list= get_filtered_sorted_steps_list(song)
		local playable_steps= false
		local i= 1
		while not playable_steps and i <= #steps_list do
			if steps_list[i]:GetMeter() <= chart_rating_cap then
				playable_steps= true
			end
			i= i+1
		end
		show= playable_steps
	end
	return show
end

function time_short_enough(t)
	if GAMESTATE:IsEventMode() then
		return true
	else
		return t <= time_remaining
	end
end

local last_song_time= 0
function set_last_song_time(t)
	last_song_time= t
end
function get_last_song_time()
	return last_song_time
end

function convert_score_to_time(score)
	if not score then return 0 end
	local conf_data= misc_config:get_data()
	local min_score_for_reward= conf_data.min_score_for_reward
	if score < min_score_for_reward then return 0 end
	local score_factor= score - min_score_for_reward
	local reward_factor_high= 1-min_score_for_reward
	local min_reward= conf_data.min_reward_pct
	local max_reward= conf_data.max_reward_pct
	local time_mult= last_song_time
	if not conf_data.reward_time_by_pct then
		min_reward= conf_data.min_reward_time
		max_reward= conf_data.max_reward_time
		time_mult= 1
	end
	return scale(score_factor, 0, reward_factor_high, min_reward, max_reward) * time_mult
end

function cons_can_join()
	return GAMESTATE:GetCoinMode() == "CoinMode_Home" or
		GAMESTATE:GetCoinMode() == "CoinMode_Free" or
		GAMESTATE:GetCoins() >= GAMESTATE:GetCoinsNeededToJoin()
end

function cons_join_player(pn)
	local ret= GAMESTATE:JoinInput(pn)
	if ret then
		cons_players[pn]:clear_init(pn)
		if april_fools then
			cons_players[pn].fake_judge= fake_judges.Random
		end
	end
	return ret
end

function get_coin_info()
--	Trace("CoinMode: " .. GAMESTATE:GetCoinMode())
--	Trace("Coins: " .. GAMESTATE:GetCoins())
--	Trace("Needed: " .. GAMESTATE:GetCoinsNeededToJoin())
	local coins= GAMESTATE:GetCoins()
	local needed= GAMESTATE:GetCoinsNeededToJoin()
	local credits= math.floor(coins / needed)
	coins= coins % needed
	if needed == 0 then
		credits= 0
		coins= 0
	end
	return credits, coins, needed
end

function cons_get_steps_types_to_show()
	local types= {}
	for i, data in ipairs(combined_visible_styles()) do
		types[#types+1]= data.stepstype
	end
	return types
end

function cons_set_current_steps(pn, steps)
	local num_players= GAMESTATE:GetNumPlayersEnabled()
	local curr_st= GAMESTATE:GetCurrentStyle(pn):GetStepsType()
	local to_st= steps:GetStepsType()
	if curr_st ~= to_st then
		local curr_style_info= stepstype_to_style[curr_st][num_players]
		if not curr_style_info then
			lua.ReportScriptError("Error when trying to fetch style info.  Dumping stepstype_to_style.")
			rec_print_table(stepstype_to_style)
		end
		local to_style= stepstype_to_style[to_st][num_players]
		if to_style then
			if curr_style_info.for_sides > to_style.for_sides then
				-- If the current style is double, and we try to set the style to
				-- single, then we run into the error of having too many sides
				-- joined to change styles.
				-- Unjoining the other side prevents that error.
				GAMESTATE:UnjoinPlayer(other_player[pn])
			elseif curr_style_info.for_sides < to_style.for_sides then
				-- No action necessary.
			end
			set_current_style(to_style.name, pn)
		else
			lua.ReportScriptError("Need to change the style, but no to_style found.")
			return
		end
	end
	local curr_st= GAMESTATE:GetCurrentStyle(pn):GetStepsType()
	if curr_st ~= steps:GetStepsType() then
		lua.ReportScriptError("Attempted to set steps with invalid stepstype: "
														.. curr_st .. " ~= " .. steps:GetStepsType())
		return
	end
	gamestate_set_curr_steps(pn, steps)
end

function JudgmentTransformCommand( self, params )
	local y = cons_players[params.Player].judgment_offset
	if params.bReverse then
		y = y * -1
		self:rotationx(180)
	else
		self:rotationx(0)
	end
	if params.bCentered then
		if params.Player == PLAYER_1 then
			self:rotationz(90)
		else
			self:rotationz(-90)
		end
	else
		self:rotationz(0)
	end
	self:x( 0 )
	self:y( y )
end

function SaveProfileCustom(profile, dir)
	if profile == PROFILEMAN:GetMachineProfile() then return end
	local cp= false
	for i, pn in pairs(cons_players) do
		if pn.proguid == profile:GetGUID() then
			cp= pn
			break
		end
	end
	if cp then
		local pn= cp.player_number
		local prof_slot= pn_to_profile_slot(pn)
		profile_pain_setting:save(prof_slot)
		profile_flag_setting:set_dirty(prof_slot)
		profile_flag_setting:save(prof_slot)
		local config_data= player_config:get_data(prof_slot)
		for k, v in pairs(config_data) do
			if type(v) ~= "table" then
				config_data[k]= cp[k]
			end
		end
		player_config:set_dirty(prof_slot)
		player_config:save(prof_slot)
		style_config:save(prof_slot)
	end
end

function player_using_profile(pn)
	return PROFILEMAN:IsPersistentProfile(pn)
end

function ops_level(pn)
	return cons_players[pn].options_level
end
