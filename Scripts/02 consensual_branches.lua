local function workout_goal_reached()
	local num_reached_goal= 0
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local progress, goal= get_workout_progress(pn)
		if progress >= goal then
			num_reached_goal= num_reached_goal + 1
		end
	end
	return num_reached_goal
end

local function workout_pick_or_eval()
	--lua.ReportScriptError("workout_pick_or_eval called.")
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		local work_data= workout_mode[pn]
		local score_data= cons_players[pn].score_data
		local score= score_data[0].dp / score_data[0].mdp
		if score < work_data.easier_threshold then
			work_data.current_meter= work_data.current_meter - 1
		elseif score > work_data.harder_threshold then
			work_data.current_meter= work_data.current_meter + 1
		end
	end
	if workout_goal_reached() >= #GAMESTATE:GetEnabledPlayers() then
		return "ScreenWorkoutEval"
	else
		return "ScreenWorkoutPick"
	end
end

cons_branches= {
	after_gameplay= function()
		local go_to_heart= false
		for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			local profile= PROFILEMAN:GetProfile(pn)
			if profile and profile.GetIgnoreStepCountCalories and
			profile:GetIgnoreStepCountCalories() then
				go_to_heart= true
			end
		end
		if go_to_heart then
			return "ScreenHeartEntry"
		end
		if workout_mode then
			return workout_pick_or_eval()
		end
		return "ScreenEvaluationNormal"
	end,
	after_heart= function()
		if workout_mode then
			return workout_pick_or_eval()
		else
			return "ScreenEvaluationNormal"
		end
	end,
	after_evaluation= function()
		if GAMESTATE:IsEventMode() then
			return "ScreenProfileSave"
		elseif get_time_remaining() < misc_config:get_data().min_remaining_time
		or #bucket_man.filtered_songs < 1 or GAMESTATE:IsCourseMode() then
			return "ScreenConsNameEntry"
		else
			return SelectMusicOrCourse()
		end
	end,
	after_profile_save = function()
		if GAMESTATE:IsEventMode() then
			return SelectMusicOrCourse()
		else
			return "ScreenInitialMenu"
		end
	end,
}

Branch.AfterProfileSave= cons_branches.after_profile_save
-- Because I had to name my ScreenSelectMusic something different to get away
--   from all the crap normal SSM does that I don't need, want, or use.
function SelectMusicOrCourse()
	if IsNetSMOnline() then
		return "ScreenOnlineNotSupported" -- I don't support online mode yet.
		--return "ScreenNetSelectMusic"
	end
	return "ScreenConsSelectMusic"
end
