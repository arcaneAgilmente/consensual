cons_branches= {
	after_evaluation=
		function()
			if GAMESTATE:IsEventMode() then
				return "ScreenProfileSave"
			elseif get_time_remaining() < min_remaining_time or #bucket_man.filtered_songs < 1 then
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

-- Note that if I set [ScreenEvaluation] NextScreen to this value, it does not work.  So instead I have to do this.
-- Why?  Well, I don't want the normal stage system, where one credit buys some number of songs.  Instead, one credit buys some amount of song time, and playing songs uses up that time.
Branch.AfterEvaluation= cons_branches.after_evaluation
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
