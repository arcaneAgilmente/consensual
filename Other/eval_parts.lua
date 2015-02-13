local conversions= {
	{1, 60, ""}, {60, 60, ":"}, {3600, 24, ":"}, {86400, 365, "/"},
	{31557600, 0, "/"}
}
function seconds_to_time_string(seconds)
	local ret= ""
	for i, v in ipairs(conversions) do
		local part= math.floor(seconds / v[1])
		if v[2] > 0 then part= part % v[2] end
		if seconds >= v[1] then
			if part < 10 then
				part= "0" .. part
			end
			ret= part .. v[3] .. ret
		end
	end
	return ret
end

profile_report_mt= {
	__index= {
		create_actors= function(self, pn, hide)
			self.pn= pn
			self.name= "profile_report"
			local spacing= 12
			local difa= 1
			if hide then difa= 0 end
			local args= {
				Name= self.name, InitCommand= function(subself)
					subself:diffusealpha(difa)
					self.container= subself
				end
			}
			local pro= PROFILEMAN:GetProfile(pn)
			if pro then
				args[#args+1]= normal_text(
					"pname", pro:GetDisplayName(), nil, eval_stroke, 0, 0)
				local things_in_list= {}
				do
					local gameplay_seconds= pro:GetTotalGameplaySeconds()
					things_in_list[#things_in_list+1]= {
						name= "Played Time",
						number= seconds_to_time_string(gameplay_seconds)}
					local percent= "%.2f%%"
					local num= "%.2f"
					local today_calories= pro:GetCaloriesBurnedToday()
					local total_calories= pro:GetTotalCaloriesBurned()
					local pstats= STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
					local song_calories= pstats:GetCaloriesBurned()
					things_in_list[#things_in_list+1]= {
						name= "Weight", number= num:format(pro:GetWeightPounds())}
					if pro.GetIgnoreStepCountCalories
					and pro:GetIgnoreStepCountCalories() then
						song_calories= cons_players[pn].last_song_calories
						things_in_list[#things_in_list+1]= {
							name= "Heart Rate",
							number= cons_players[pn].last_song_heart_rate}
					end
					things_in_list[#things_in_list+1]= {
						name= "Calories Song", number= num:format(song_calories)}
					things_in_list[#things_in_list+1]= {
						name= "Calories Today", number= num:format(today_calories)}
					things_in_list[#things_in_list+1]= {
						name= "Total Calories", number= num:format(total_calories)}
				end
				things_in_list[#things_in_list+1]= {
					name= "Sessions", number= pro:GetTotalSessions() }
				things_in_list[#things_in_list+1]= {
					name= "Session time",
					number= seconds_to_time_string(pro:GetTotalSessionSeconds()) }
				things_in_list[#things_in_list+1]= {
					name= "Songs played", number= pro:GetNumTotalSongsPlayed() }
				if not GAMESTATE:IsCourseMode() then
					things_in_list[#things_in_list+1]= {
						name= "This song played",
						number= pro:GetSongNumTimesPlayed(GAMESTATE:GetCurrentSong()) }
				end
				do
					local toasts= pro:GetNumToasties()
					local songs= pro:GetNumTotalSongsPlayed()
					local toast_pct= toasts / songs
					local color= percent_to_color((toast_pct-.75)*4)
					things_in_list[#things_in_list+1]= {
						name= "Toasties", number= pro:GetNumToasties(), color= color}
				end
				if pro.GetTotalDancePoints then
					things_in_list[#things_in_list+1]= {
						name= "Dance Points", number= pro:GetTotalDancePoints() }
				end
				do
					local taps= pro:GetTotalTapsAndHolds() + pro:GetTotalJumps() +
						pro:GetTotalHands()
					local level= 0
					local calc_taps= 0
					local prev_calc_taps= 0
					local level_diff= 0
					repeat
						level= level + 1
						-- This formula is from milistisia, I have no idea how he came
						-- up with it, but it seems good enough.
						calc_taps= math.round(((400*level)^(1+level/140)+(level*(level+1)*(level+2)*100)/10)^(1+(100-level)/1000))
						level_diff= calc_taps - prev_calc_taps
						prev_calc_taps= calc_taps
					until calc_taps > taps
					if level > cons_players[pn].experience_level
					and player_using_profile(pn) then
						activate_confetti("earned", true)
						cons_players[pn].experience_level= level
					end
					things_in_list[#things_in_list+1]= {
						name= "Experience Level", number= level }
					things_in_list[#things_in_list+1]= {
						name= "Experience", number= taps }
					things_in_list[#things_in_list+1]= {
						name= "Taps to next level", number= calc_taps - taps,
						color= color_percent_above(1-((calc_taps-taps)/level_diff), .5)}
				end
				things_in_list[#things_in_list+1]= {
					name= "Taps", number= pro:GetTotalTapsAndHolds() }
				things_in_list[#things_in_list+1]= {
					name= "Hands", number= pro:GetTotalHands() }
				things_in_list[#things_in_list+1]= {
					name= "Holds", number= pro:GetTotalHolds() }
				things_in_list[#things_in_list+1]= {
					name= "Jumps", number= pro:GetTotalJumps() }
				things_in_list[#things_in_list+1]= {
					name= "Mines", number= pro:GetTotalMines() }
				things_in_list[#things_in_list+1]= {
					name= "Lifts", number= pro:GetTotalLifts() }
				local sep= 90
				for i, thing in ipairs(things_in_list) do
					local y= spacing * (i) + 12
					args[#args+1]= normal_text(
						thing.name .. "t", get_string_wrapper("ProfileData", thing.name),
						nil, eval_stroke, -sep, y, .5, left)
					args[#args+1]= normal_text(
						thing.name .. "n", thing.number, thing.color, eval_stroke,
						sep, y, .5, right)
				end
			end
			return Def.ActorFrame(args)
		end
}}
