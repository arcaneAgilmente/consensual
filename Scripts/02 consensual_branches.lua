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
		return Branch.AfterGameplay()
	end,
	after_evaluation=
		function()
			if GAMESTATE:IsEventMode() then
				return "ScreenProfileSave"
			elseif get_time_remaining() < misc_config:get_data().min_remaining_time or #bucket_man.filtered_songs < 1 then
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
		return "ScreenExit" -- I don't support online mode yet.
		--return "ScreenNetSelectMusic"
	end
	return "ScreenConsSelectMusic"
end
