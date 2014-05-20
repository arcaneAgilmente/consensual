ops_level_none, ops_level_simple, ops_level_all, ops_level_excessive= 1, 2, 3, 4

input_mode_pad, input_mode_cabinet= 1, 2
local curr_input_mode= input_mode_pad
function get_input_mode()
	return curr_input_mode
end

mine_effects= {
	{ name= "stealth",
		apply=
			function(pn)
				cons_players[pn].song_options:Stealth(.75, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Stealth(0, .75)
			end,
		time= .0625
	},
	{ name= "boomerang",
		apply=
			function(pn)
				cons_players[pn].song_options:Boomerang(1, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Boomerang(0, 1)
			end,
		time= .0625
	},
	{ name= "brake",
		apply=
			function(pn)
				cons_players[pn].song_options:Brake(1, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Brake(0, 1)
			end,
		time= .0625
	},
	{ name= "tiny",
		apply=
			function(pn)
				cons_players[pn].song_options:Tiny(1, 8)
			end,
		unapply=
			function(pn)
				cons_players[pn].song_options:Tiny(0, 1)
			end,
		time= .0625
	},
	{ name= "none",
		apply= noop_nil,
		unapply= noop_nil,
		time= .0625
	},
}

local things_to_put_in_user_table= {
	"flags", "options_level", "speed_info", "sigil_data", "dspeed"
}

local dspeed_default_min= 0
local dspeed_default_max= 2
do
	local receptor_min= THEME:GetMetric("Player", "ReceptorArrowsYStandard")
	local receptor_max= THEME:GetMetric("Player", "ReceptorArrowsYReverse")
	local arrow_height= THEME:GetMetric("ArrowEffects", "ArrowSpacing")
	local field_height= receptor_max - receptor_min
	local center_effect_size= field_height / 2
	dspeed_default_min= (SCREEN_CENTER_Y + receptor_min) / -center_effect_size
	dspeed_default_max= (SCREEN_CENTER_Y + receptor_max) / center_effect_size
end

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
	self.rating_cap= 4
	self.options_level= ops_level_none
	-- Temporarily make simple the default until this theme is used somewhere that the options menu should be hidden from normal players.
	self.rating_cap= -1
	self.options_level= ops_level_simple
	self.judge_totals= {}
	self:set_speed_info_from_poptions()
	self.dspeed= {min= dspeed_default_min, max= dspeed_default_max, alternate= false}
	self:flags_reset()
	self:combo_qual_reset()
	self:stage_stats_reset()
	self.mine_effect= mine_effects[1]
	self.sigil_data= {detail= 16, size= 150}
	self.play_history= {}
end

function cons_player:noob_mode()
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

function cons_player:simple_options_mode()
	self.options_level= ops_level_simple
	self.rating_cap= -1
	self.flags.pct_column= true
	self.flags.best_scores= true
end

function cons_player:all_options_mode()
	self.options_level= ops_level_all
	self.rating_cap= -1
	self.flags.judge= true
	self.flags.pct_column= true
	self.flags.sum_column= true
	self.flags.best_scores= true
end

function cons_player:excessive_options_mode()
	self.options_level= ops_level_excessive
	self.rating_cap= -1
	self.flags.judge= true
	self.flags.pct_column= true
	self.flags.offset= true
	self.flags.session_column= true
	self.flags.sum_column= true
	self.flags.best_scores= true
end

function cons_player:kyzentun_mode()
	self.options_level= ops_level_excessive
	self.rating_cap= -1
	self.kyzentun= true
	local styletype= GAMESTATE:GetCurrentStyle():GetStyleType()
	local new_speed= false
	if styletype == "StyleType_OnePlayerTwoSides" then
		new_speed= { speed= 500, mode= "m" }
	else
		new_speed= { speed= 900, mode= "m" }
	end
	if self.speed_info then
		self.speed_info.speed= new_speed.speed
		self.speed_info.mode= new_speed.mode
	else
		self.speed_info= new_speed
	end
	self.preferred_options:Distant(1.4)
	self.flags.sigil= true
	self.flags.judge= true
	self.flags.offset= true
	self.flags.pct_column= true
	self.flags.session_column= true
	self.flags.sum_column= true
	self.flags.best_scores= true
	self.flags.straight_floats= true
end

-- If the rating cap is less than or equal to 0, it has the special meaning of "no cap".
function cons_player:rating_is_over_cap(rating)
	if not rating then return true end
	if type(rating) ~= "number" then return true end
	if self.rating_cap <= 0 then return false end
	return rating > self.rating_cap
end

function cons_player:get_options_level()
	return self.options_level
end

function cons_player:combo_qual_reset()
	self.combo_quality= {}
end

function cons_player:stage_stats_reset()
	self.stage_stats= { firsts= {}}
	self.fake_score= {
		firsts= {}, combo= 0, life= 50, dp= 0,
		TapNoteScore_W1= 0, TapNoteScore_W2= 0, TapNoteScore_W3= 0,
		TapNoteScore_W4= 0, TapNoteScore_W5= 0, TapNoteScore_Miss= 0,
	}
	local cur_style= GAMESTATE:GetCurrentStyle()
	if cur_style then
		local columns= cur_style:ColumnsPerPlayer()
		--Trace("Making column score slots for " .. tostring(columns) .. " columns.")
		self.column_scores= {}
		-- Track indices from the engine are 0-indexed.
		for c= 0, columns-1 do
			self.column_scores[c]= {
				dp= 0, mdp= 0,
				judge_counts= {
					TapNoteScore_W1= 0,
					TapNoteScore_W2= 0,
					TapNoteScore_W3= 0,
					TapNoteScore_W4= 0,
					TapNoteScore_W5= 0,
					TapNoteScore_Miss= 0,
					TapNoteScore_HitMine= 0,
					TapNoteScore_AvoidMine= 0,
					HoldNoteScore_Held= 0,
					HoldNoteScore_LetGo= 0,
					HoldNoteScore_MissedHold= 0,
				}
			}
		end
	end
end

function cons_player:flags_reset()
	self.flags= {}
	self.flags.score_meter= true
	self.flags.dance_points= true
	self.flags.chart_info= true
	self.flags.bpm_meter= true
	self.flags.song_column= true
	self.flags.allow_toasty= PREFSMAN:GetPreference("EasterEggs")
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

function cons_player:set_ops_from_profile(profile)
	-- Fun fact:  Changing the tables that are set from the user_table will also
	-- modify the user_table.
	local ut= profile:GetUserTable()
	self.user_table= ut
	self.proguid= profile:GetGUID()
	--Trace("Setting options from user table for " .. profile:GetDisplayName())
	if ut then
		--rec_print_table(ut)
		-- Thanks for converting the numbers I stored into strings, stepmania.
		-- TODO:  Fix this stupid mistake in the engine.
		rec_convert_strings_to_numbers(ut)
		for k, v in pairs(ut) do
			self[k]= v
		end
		for i, eff in ipairs(mine_effects) do
			if ut.mine_effect == eff.name then
				self.mine_effect= eff
				break
			end
		end
	else
		--Trace("Is nil.")
	end
end

local cons_player_mt= { __index= cons_player}

cons_players= {}
for k, v in pairs(all_player_indices) do
	cons_players[v]= {}
	setmetatable(cons_players[v], cons_player_mt)
	cons_players[v]:clear_init(v)
	if v == PLAYER_1 then
		cons_players[v].id= "P1"
	else
		cons_players[v].id= "P2"
	end
end

function get_highest_options_level()
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local prev_max= 0
	for k, v in pairs(enabled_players) do
		--Trace(v .. " player is joined, options level: " .. cons_players[v]:get_options_level())
		prev_max= math.max(prev_max, cons_players[v]:get_options_level())
	end
	--Trace("Highest options level: " .. prev_max)
	return prev_max
end

function options_allowed()
	return get_highest_options_level() > ops_level_none
end

function generic_gsu_flag(flag_name)
	return
	function(player_number)
		return cons_players[player_number].flags[flag_name]
	end,
	function(player_number)
		cons_players[player_number].flags[flag_name]= true
	end,
	function(player_number)
		cons_players[player_number].flags[flag_name]= false
	end
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
	cons_players[player_number].mine_effect= nil
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
	time_remaining= 60 * 6
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
		if s.GetLastSecond then
			local len= s:GetLastSecond() - s:GetFirstSecond()
			return len <= time_remaining and len > 0
		else
			return s:GetTotalSeconds() <= time_remaining
		end
	end
end

function time_short_enough(t)
	if GAMESTATE:IsEventMode() then
		return true
	else
		return t <= time_remaining
	end
end

function filter_bucket_songs_by_time()
	bucket_man:filter_and_resort_songs(song_short_enough)
end

local last_song_time= 0
function set_last_song_time(t)
	last_song_time= t
end
function get_last_song_time()
	return last_song_time
end

function convert_score_to_time(score)
	-- A quad on a 2 minute song is worth 30 seconds.
	if not score then return 0 end
	return math.max(0, score - .75) * 120 * (last_song_time / 120)
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

-- Suspiciously similar design to CodeDetectorCodes in _fallback/Scripts/03 Gameplay.lua
local cons_codes= {
	left= {
		default= "Left",
		dance= "Left",
		pump= "DownLeft"
	},
	right= {
		default= "Right",
		dance= "Right",
		pump= "DownRight"
	},
	up= {
		default= "Up",
		dance= "Up",
		pump= "UpLeft"
	},
	down= {
		default= "Down",
		dance= "Down",
		pump= "UpRight"
	},
	left_release= {
		default= "~Left",
		dance= "~Left",
		pump= "~DownLeft"
	},
	right_release= {
		default= "~Right",
		dance= "~Right",
		pump= "~DownRight"
	},
	up_release= {
		default= "~Up",
		dance= "~Up",
		pump= "~UpLeft"
	},
	down_release= {
		default= "~Down",
		dance= "~Down",
		pump= "~UpRight"
	},
}

function cons_get_code(name)
	local code= cons_codes[name]
	return code[lowered_game_name()] or code.default
end

-- second index is number of players enabled.
local steps_types_by_game= {
	dance= {
		{
			"StepsType_Dance_Single",
			"StepsType_Dance_Double",
		},
		{
			"StepsType_Dance_Single",
		}
	},
	pump= {
		{
			"StepsType_Pump_Single",
			"StepsType_Pump_Halfdouble",
			"StepsType_Pump_Double",
		},
		{
			"StepsType_Pump_Single",
		}
	}
}

style_command_for_steps_type= {
	StepsType_Dance_Single= "style,single",
	StepsType_Dance_Double= "style,double",
	StepsType_Pump_Single= "style,single",
	StepsType_Pump_Halfdouble= "style,halfdouble",
	StepsType_Pump_Double= "style,double",
}

function cons_get_steps_types_to_show()
	local gname= lowered_game_name()
	local type_group= steps_types_by_game[lowered_game_name()]
	local num_players= GAMESTATE:GetNumPlayersEnabled()
	return (type_group and type_group[num_players]) or
	{}
end

function cons_set_current_steps(pn, steps)
	if GAMESTATE:GetNumPlayersEnabled() == 1 then
		local curr_st= GAMESTATE:GetCurrentStyle():GetStepsType()
		local to_st= steps:GetStepsType()
		if curr_st ~= to_st then
			local style_com= style_command_for_steps_type[to_st]
			if style_com then
				-- If the current style is double, and we try to set the style to
				-- single, then GameCommand::IsPlayable returns this error:
				-- Exception: Can't apply mode "style,single": too many players
				-- joined for ONE_PLAYER_ONE_CREDIT
				-- Unjoining the other side prevents that crash.
				if GAMESTATE:GetNumSidesJoined() > 1 then
					GAMESTATE:UnjoinPlayer(other_player[pn])
				end
				GAMESTATE:ApplyGameCommand(style_com, pn)
			end
		end
	end
	local curr_st= GAMESTATE:GetCurrentStyle():GetStepsType()
	if curr_st ~= steps:GetStepsType() then
		Trace("Attempted to set steps with invalid stepstype: " .. curr_st ..
					" ~= " .. steps:GetStepsType())
		return
	end
	GAMESTATE:SetPreferredDifficulty(pn, steps:GetDifficulty())
	gamestate_set_curr_steps(pn, steps)
end

function JudgmentTransformCommand( self, params )
	local y = -30
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
	local user_table= profile:GetUserTable()
--	Trace("User table for " .. profile:GetDisplayName())
--	if user_table then
--		rec_print_table(user_table)
--	else
--		Trace("Is nil.")
--	end
	local cp= false
	for i, pn in pairs(cons_players) do
		if pn.proguid == profile:GetGUID() then
			cp= pn
			break
		end
	end
	if cp and user_table then
		--Trace("Putting theme stuff in user table.")
		for i, k in ipairs(things_to_put_in_user_table) do
			--Trace(k)
			if not user_table[k] then
				user_table[k]= cp[k]
			end
		end
		if cp.mine_effect then
			user_table.mine_effect= cp.mine_effect.name
		end
	end
end
