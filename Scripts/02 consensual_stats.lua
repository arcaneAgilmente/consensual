local tns_reverse= TapNoteScore:Reverse()
tnss_that_affect_combo= {
	TapNoteScore_W1= true,
	TapNoteScore_W2= true,
	TapNoteScore_W3= true,
	TapNoteScore_W4= true,
	TapNoteScore_W5= true,
	TapNoteScore_Miss= true,
}
tnss_that_can_be_early= {
	TapNoteScore_W1= true,
	TapNoteScore_W2= true,
	TapNoteScore_W3= true,
	TapNoteScore_W4= true,
	TapNoteScore_W5= true,
}

function tns_cont_combo()
	return tns_reverse[THEME:GetMetric("Gameplay", "MinScoreToContinueCombo")]
end
function tns_maint_combo()
	return tns_reverse[THEME:GetMetric("Gameplay", "MinScoreToMaintainCombo")]
end
feedback_judgements= {
	"TapNoteScore_W1", "TapNoteScore_W2", "TapNoteScore_W3",
	"TapNoteScore_W4", "TapNoteScore_W5", "TapNoteScore_Miss"
}
holdnote_names= {
	"HoldNoteScore_Held", "HoldNoteScore_LetGo", "HoldNoteScore_MissedHold"
}

-- style compatibility issue:  Dance, Kickbox, Pump, and Techno are the only supported games.
local column_to_pad_arrow_map= {
	[PLAYER_1]= {
		StepsType_Dance_Single= {4, 8, 2, 6},
		StepsType_Dance_Double= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Couple= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Solo= {4, 1, 8, 2, 3, 6},
		StepsType_Dance_Threepanel= {1, 8, 3},
		StepsType_Dance_Routine= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Pump_Single= {7, 1, 5, 3, 9},
		StepsType_Pump_Halfdouble= {5, 3, 9, 16, 10, 14},
		StepsType_Pump_Double= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Couple= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Routine= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Single4= {4, 8, 2, 6},
		StepsType_Techno_Single5= {7, 1, 5, 3, 9},
		StepsType_Techno_Single8= {1, 2, 3, 4, 6, 7, 8, 9},
		StepsType_Techno_Double4= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Techno_Double5= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Double8= {1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18},
		StepsType_Kickbox_Human= {1, 4, 5, 8},
		StepsType_Kickbox_Quadarm= {3, 4, 5, 6},
		StepsType_Kickbox_Insect= {1, 3, 4, 5, 6, 8},
		StepsType_Kickbox_Arachnid= {1, 2, 3, 4, 5, 6, 7, 8},
	},
	[PLAYER_2]= {
		StepsType_Dance_Single= {13, 17, 11, 15},
		StepsType_Dance_Double= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Couple= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Solo= {13, 10, 17, 11, 12, 15},
		StepsType_Dance_Threepanel= {10, 17, 12},
		StepsType_Dance_Routine= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Pump_Single= {16, 10, 14, 12, 18},
		StepsType_Pump_Halfdouble= {5, 3, 9, 16, 10, 14},
		StepsType_Pump_Double= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Couple= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Routine= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Single4= {13, 17, 11, 15},
		StepsType_Techno_Single5= {16, 10, 14, 12, 18},
		StepsType_Techno_Single8= {10, 11, 12, 13, 15, 16, 17, 18},
		StepsType_Techno_Double4= {4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Techno_Double5= {7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Double8= {1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18},
		StepsType_Kickbox_Human= {1, 4, 5, 8},
		StepsType_Kickbox_Quadarm= {3, 4, 5, 6},
		StepsType_Kickbox_Insect= {1, 3, 4, 5, 6, 8},
		StepsType_Kickbox_Arachnid= {1, 2, 3, 4, 5, 6, 7, 8},
}}

function get_controller_stepstype_map(pn, steps_type)
	return column_to_pad_arrow_map[pn][steps_type]
end

function get_pad_arrow_for_col(pn, col)
	-- 0 is the index for the combined stats of all panels
	if col == 0 then return 0 end
	local steps_type= gamestate_get_curr_steps(pn):GetStepsType()
	if column_to_pad_arrow_map[pn][steps_type] then
		return column_to_pad_arrow_map[pn][steps_type][col]
	else
		return col
	end
end

function add_column_score_to_session(pn, session_stats, col_id, col_score)
	local session_col_id= get_pad_arrow_for_col(pn, col_id)
	local sesscol= session_stats[session_col_id]
	-- Prevent reloading the screen from increasing session stats.
	local stage_seed= GAMESTATE:GetStageSeed()
	if stage_seed == sesscol.stage_seed then return end
	sesscol.stage_seed= stage_seed
	sesscol.dp= sesscol.dp + col_score.dp
	sesscol.mdp= sesscol.mdp + col_score.mdp
	sesscol.max_combo= math.max(sesscol.max_combo, col_score.max_combo)
	for i, tim in ipairs(col_score.step_timings) do
		if sesscol.judge_counts.early[tim.judge] then
			if tnss_that_can_be_early[tim.judge] and (tim.offset or 0) >= 0 then
				sesscol.judge_counts.late[tim.judge]=
					sesscol.judge_counts.late[tim.judge] + 1
			else
				sesscol.judge_counts.early[tim.judge]=
					sesscol.judge_counts.early[tim.judge] + 1
			end
		end
	end
end

local function trace_if_nil(n, name)
	if not n then lua.ReportScriptError(name .. " is nil.") end
end

function crunch_combo_data_for_column(col)
	local cont_combo= tns_cont_combo()
	local maint_combo= tns_maint_combo()
	local step_timings= col.step_timings
	local max_combo= 0
	local curr_combo= 0
	local combo_data= {}
	local curr_combo_start= 0
	local function end_combo(time)
		if curr_combo > 0 then
			max_combo= math.max(curr_combo, max_combo)
			combo_data[#combo_data+1]= {
				StartSecond= curr_combo_start,
				SizeSeconds= time - curr_combo_start,
				Count= curr_combo}
		end
		curr_combo= 0
	end
	for i, tim in ipairs(step_timings) do
		if tnss_that_affect_combo[tim.judge] then
			local revj= tns_reverse[tim.judge]
			if revj >= cont_combo then
				if curr_combo == 0 then
					curr_combo_start= tim.time
				end
				curr_combo= curr_combo + 1
			elseif revj < maint_combo then
				end_combo(tim.time)
			end
		end
	end
	if #step_timings > 0 then
		end_combo(step_timings[#step_timings].time)
	end
	col.max_combo= max_combo
	col.combo_data= combo_data
end

function save_column_scores(pn)
	if not GAMESTATE:IsCourseMode() then
		local profile_dir= false
		if pn == PLAYER_1 then
			profile_dir= PROFILEMAN:GetProfileDir("ProfileSlot_Player1")
		else
			profile_dir= PROFILEMAN:GetProfileDir("ProfileSlot_Player2")
		end
		local cur_song= gamestate_get_curr_song()
		local song_name= "unknown_song"
		if cur_song then song_name= cur_song:GetDisplayFullTitle() end
		if profile_dir then
			local file_handle= RageFileUtil.CreateRageFile()
			local file_name= profile_dir .. "/song_scores/" .. song_name .. "_column_scores.lua"
			local all_attempts= {}
			if FILEMAN:DoesFileExist(file_name) then
				all_attempts= dofile(file_name)
			end
			local function pad_num(num)
				if num < 10 then return "0" .. num
				else return num end
			end
			cons_players[pn].column_scores.timestamp= Year() .. "_" .. pad_num(MonthOfYear()) .. "_" .. pad_num(DayOfMonth()) .. "_" .. pad_num(Hour()) .. "_" .. pad_num(Minute()) .. "_" .. pad_num(Second())
			all_attempts[#all_attempts+1]= cons_players[pn].column_scores
			if not file_handle:Open(file_name, 2) then
				Trace("Could not open '" .. file_name .. "' to write column scores.")
			else
				local output= "return " .. lua_table_to_string(all_attempts) .. "\n"
				file_handle:Write(output)
				file_handle:Close()
				file_handle:destroy()
				Trace("column scores written to '" .. file_name .. "'")
			end
		else
			Trace("Nil profile dir, unable to write column scores.")
		end
	end
end

function update_player_stats_after_song()
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local highest_score= 0
	local curstats= STATSMAN:GetCurStageStats()
	local stage_seed= 0
	for i, pn in ipairs(enabled_players) do
		if not GAMESTATE:IsEventMode() then
			local play_history= cons_players[pn].play_history
--			Trace("Adding song to play_history with timestamp " ..
--							tostring(prev_song_start_timestamp) .. "-" ..
--							tostring(prev_song_end_timestamp))
			play_history[#play_history+1]= {
				song= gamestate_get_curr_song(), steps= gamestate_get_curr_steps(pn),
				start= prev_song_start_timestamp, finish= prev_song_end_timestamp}
		end
		local score_data= {}
		local pstats= curstats:GetPlayerStageStats(pn)
		for i= 0, #cons_players[pn].column_scores do
			score_data[i]= cons_players[pn].column_scores[i]
		end
		score_data[0].dp= pstats:GetActualDancePoints()
		score_data[0].mdp= pstats:GetPossibleDancePoints()
		score_data[0].max_combo= pstats:MaxCombo()
		for i, fj in ipairs(feedback_judgements) do
			score_data[0].judge_counts[fj]= pstats:GetTapNoteScores(fj)
		end
		for i, hj in ipairs(holdnote_names) do
			score_data[0].judge_counts[hj]= pstats:GetHoldNoteScores(hj)
		end
		cons_players[pn].fake_score.mdp= score_data[0].mdp
		highest_score= math.max(highest_score,
			pstats:GetActualDancePoints() / pstats:GetPossibleDancePoints())
		--save_column_scores(pn)
		stage_seed= cons_players[pn].session_stats[0].stage_seed
		add_column_score_to_session(pn, cons_players[pn].session_stats, 0, score_data[0])
		for ic= 1, #cons_players[pn].column_scores do
			crunch_combo_data_for_column(cons_players[pn].column_scores[ic])
			add_column_score_to_session(pn, cons_players[pn].session_stats, ic, cons_players[pn].column_scores[ic])
		end
		cons_players[pn].unacceptable_score.enabled= nil
		cons_players[pn].score_data= score_data
	end
	last_song_reward_time= convert_score_to_time(highest_score)
	if GAMESTATE:GetStageSeed() ~= stage_seed then
		reduce_time_remaining(-last_song_reward_time)
	end
	unacc_reset_count= nil
end

function get_workout_progress(pn)
	local work_data= workout_mode[pn]
	local progress= 0
	local goal= 0
	if work_data.goal_type == "calories" then
		local profile= PROFILEMAN:GetProfile(pn)
		if profile then
			progress= profile:GetTotalCaloriesBurned()
			goal= work_data.end_calories
		end
	elseif work_data.goal_type == "step_count" then
		local stats= cons_players[pn].session_stats[0]
		local total= 0
		for i, tns in ipairs(workout_counted_steps) do
			local early= stats.judge_counts.early[tns] or 0
			local late= stats.judge_counts.late[tns] or 0
			total= total + early + late
		end
		progress= total
		goal= work_data.goal_target * workout_step_or_calorie_multiplier
	elseif work_data.goal_type == "time" then
		progress= cons_players[pn].credit_time
		goal= work_data.goal_target * 60
	else
		lua.ReportScriptError(
			"Player " .. pn .. " has unknown goal type '"
				.. work_data.goal_type .. "', marking them as complete.")
	end
	return progress, goal
end
