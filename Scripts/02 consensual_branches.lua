cons_branches= {
	after_evaluation=
		function()
			if get_time_remaining() > 50 and #bucket_man.filtered_songs > 0 then
				return "ScreenProfileSave"
			else
				return "ScreenProfileSaveSummary"
			end
		end
}

-- Note that if I set [ScreenEvaluation] NextScreen to this value, it does not work.  So instead I have to do this.
-- Why?  Well, I don't want the normal stage system, where one credit buys some number of songs.  Instead, one credit buys some amount of song time, and playing songs uses up that time.
Branch.AfterEvaluation= cons_branches.after_evaluation
--Branch.AfterProfileSave= function() return SelectMusicOrCourse() end
-- Because I had to name my ScreenSelectMusic something different to get away
--   from all the crap normal SSM does that I don't need, want, or use.
function SelectMusicOrCourse()
	if IsNetSMOnline() then
		return "ScreenNetSelectMusic"
	elseif GAMESTATE:IsCourseMode() then
		return "ScreenConsSelectMusic"
	else
		return "ScreenConsSelectMusic"
	end
end
