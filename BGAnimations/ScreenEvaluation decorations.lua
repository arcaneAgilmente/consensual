local cg_thickness= 24
local lg_thickness= 40
do
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
end

local function not_negzero(s)
	if s == "-0%" then return "0%" end
	return s
end

local function changing_text(name, first_text, second_text, color, tx, ty, z, align, commands)
	commands= commands or {}
	if type(second_text) == "table" then
		Trace("Bad second_text: " .. tostring(second_text))
		rec_print_table(second_text)
	end
	if commands.OnCommand then
		commands.OnCommand= function(self)
													commands.OnCommand(self)
													self:queuecommand("Wait")
												end
	else
		commands.OnCommand= cmd(queuecommand, "Wait")
	end
	commands.WaitCommand= cmd(sleep, 5; queuecommand, "Change")
	commands.ChangeCommand= cmd(settext, second_text)
	return normal_text(name, first_text, color, tx, ty, z, align, commands)
end

local number_set= {}
local number_set_mt= { __index= number_set }
function number_set:init()
	self.first_numbers= {}
	self.second_numbers= {}
	self.colors= {}
	self.zooms= {}
end

function number_set:add_number(n, nb, color, z)
	nb= nb or n
	local index= #self.first_numbers+1
	self.first_numbers[index]= n
	self.second_numbers[index]= nb
	self.colors[index]= color
	self.zooms[index]= z
end

function number_set:create_actors(name, x, y, sx, sy, dx, dy, elz, ela)
	x= x or 0
	y= y or 0
	sx= sx or 0
	sy= sy or 0
	dx= dx or 0
	dy= dy or 0
	elz= elz or 1
	ela= ela or center
	local args= { Name= name, InitCommand= cmd(xy, x, y) }
	for i= 1, #self.first_numbers do
		local n= self.first_numbers[i]
		local nb= self.second_numbers[i]
		local c= self.colors[i] or solar_colors.f_text()
		local z= self.zooms[i] or elz
		local im= i - 1
		args[#args+1]= changing_text(
			"n" .. i, n, nb, c, sx + (dx * im), sy + (dy * im), z, ela)
	end
	return Def.ActorFrame(args)
end

local function make_banner_actor()
	local cur_song= gamestate_get_curr_song()
	local song_name= ""
	if cur_song then song_name= cur_song:GetDisplayFullTitle()
		return Def.ActorFrame{
			Name= "song_stuff",
			InitCommand= function(self)
										 self:xy(SCREEN_CENTER_X, SCREEN_TOP + 48)
									 end,
			Def.Sprite{
				Name= "banner",
				InitCommand= function(self)
											 if cur_song then
												 self:LoadFromSongBanner(cur_song)
												 self:scaletofit(-128, -40, 128, 40)
											 else
												 self:visible(false)
											 end
										 end
			},
			normal_text(
				"song_name", song_name, solar_colors.f_text(), 0, 52, 1, center,
				{ OnCommand=
					function(self)
						local limit= SCREEN_WIDTH - ((cg_thickness+lg_thickness)*2) - 16
						width_limit_text(self, limit)
					end
			})
		}
	end
end

local feedback_judgements= {
	"TapNoteScore_W1", "TapNoteScore_W2", "TapNoteScore_W3",
	"TapNoteScore_W4", "TapNoteScore_W5", "TapNoteScore_Miss"
}

local holdnote_names= {
	"HoldNoteScore_Held", "HoldNoteScore_LetGo"
}

local life_graph_interface= {}
local life_graph_interface_mt= { __index= life_graph_interface }
function life_graph_interface:create_actors(pstats, firsts, gx, gy, gw, gh, reflect)
	--local length= song_get_length(gamestate_get_curr_song())
	local length= gameplay_end_time - gameplay_start_time
	local samples= 100
	local sample_resolution= gh / samples
	local seconds_per_sample= length / samples
	--Trace("Getting life record over length " .. tostring(length))
	local life_record= pstats:GetLifeRecord(length, samples)
	local actor_info= {}
	local args= { Name= "GraphDisplay", InitCommand= cmd(xy, gx - gw/2, gy - gh/2) }
	local verts= {}
	local first_color= judgement_colors["TapNoteScore_W1"]
	if reflect then
		verts[1]= {{gw, 0, 0}, first_color}
		verts[2]= {{gw * .5, 0, 0}, first_color}
	else
		verts[1]= {{gw * .5, 0, 0}, first_color}
		verts[2]= {{0, 0, 0}, first_color}
	end
	for i, v in ipairs(life_record) do
		local sy= i * sample_resolution
		local sv= life_record[i]
		local ss= i * seconds_per_sample
		local sample_color= judgement_colors["TapNoteScore_W1"]
		for i, v in ipairs(feedback_judgements) do
			if firsts[v] then
				if ss >= firsts[v] then
					sample_color= judgement_colors[v]
				end
			end
		end
		if reflect then
			verts[#verts+1]= {{gw, sy, 0}, sample_color}
			verts[#verts+1]= {{gw * (1 - sv), sy, 0}, sample_color}
		else
			verts[#verts+1]= {{gw * sv, sy, 0}, sample_color}
			verts[#verts+1]= {{0, sy, 0}, sample_color}
		end
	end
	args[#args+1]= Def.ActorMultiVertex{
		Name= "lgraph",
		InitCommand=
			function(self)
				self:SetVertices(verts)
				self:SetDrawState{Mode="DrawMode_QuadStrip"}
			end
	}
	return Def.ActorFrame(args)
end

local combo_graph_interface= {}
function combo_graph_interface:create_actors(combo_data, cx, cy, cw, ch,
                                             normal_color, max_color)
	--local length= song_get_length(gamestate_get_curr_song())
	local length= gameplay_end_time - gameplay_start_time
	local seconds_resolution= (length) / ch
	local combo_resolution= 4 -- chosen by fair dice roll
	-- Any combo smaller than seconds_resolution or combo_resolution will not
	-- be shown.
	local deshou= {}
	local max_combo= 0
	for n= 1, #combo_data do
		if combo_data[n].SizeSeconds > seconds_resolution
			and combo_data[n].Count > combo_resolution then
			max_combo= math.max(max_combo, combo_data[n].Count)
			deshou[#deshou+1]= combo_data[n]
		end
	end
	local args= { Name= "ComboGraph", InitCommand= cmd(x,cx;y,cy-ch/2)}
	local verts= {}
	local max_texts= {}
	for n= 1, #deshou do
		local info= deshou[n]
		local py= info.StartSecond / seconds_resolution
		local ph= info.SizeSeconds / seconds_resolution
		local is_max= info.Count >= max_combo
		local cc= normal_color
		if is_max then cc= max_color end
		verts[#verts+1]= {{cw, py, 0}, cc}
		verts[#verts+1]= {{0, py, 0}, cc}
		verts[#verts+1]= {{0, py+ph, 0}, cc}
		verts[#verts+1]= {{cw, py+ph, 0}, cc}
		if is_max then
			max_texts[#max_texts+1]= {num= info.Count, x= 0, y= py + (ph/2)}
		end
	end
	args[#args+1]= Def.ActorMultiVertex{
		Name= "cgraph",
		InitCommand=
			function(self)
				self:x(cw*-.5)
				self:SetVertices(verts)
				self:SetDrawState{Mode="DrawMode_Quads"}
			end
	}
	for i, mt in ipairs(max_texts) do
		args[#args+1]= normal_text("max_text" .. i, mt.num, solar_colors.red(),
															 mt.x, mt.y, .5)
	end
	return Def.ActorFrame(args)
end

function combo_graph_interface.reposition_max_texts(container, cx)
	local children= container:GetChildren()
	for k, v in pairs(children) do
		if k:find("max_text") then
			local halfw= v:GetZoomedWidth() / 2
			local left= cx - halfw - 1
			local right= cx + halfw + 1
			if left < SCREEN_LEFT then
				v:x(2 - left)
			end
			if right > SCREEN_RIGHT then
				v:x(SCREEN_RIGHT - 1 - right)
			end
		end
	end
end

local combo_graph_interface_mt= { __index= combo_graph_interface }

local score_report_interface= {}
function score_report_interface:create_actors(player_number)
	self.player_number= player_number
	local args= { Name= "judge_list", InitCommand=cmd(y,36) }
	local scale= .9
	local spacing= 24 * scale
	args[#args+1]= chart_info(
		gamestate_get_curr_steps(player_number), 0, -spacing, scale)
	local curstats= STATSMAN:GetCurStageStats()
	local pstats= curstats:GetPlayerStageStats(player_number)
	local fake_score= (cons_players[player_number].fake_judge and
										 cons_players[player_number].fake_score) or nil
	local adp= pstats:GetActualDancePoints()
	local fadp= adp
	if fake_score then
		fadp= fake_score.dp
	end
	local mdp= pstats:GetPossibleDancePoints()
	cons_players[player_number].prev_score= adp/mdp
	local min_precision= 2
	local precision= math.ceil(math.log(mdp) / math.log(10)) - 2
	--Trace("Seval: mdp: " .. mdp .. ", log: " .. math.log(mdp, 10) ..
	--   ", precision: " .. precision)
	precision= math.max(min_precision, precision)
	local fmat= "%." .. precision .. "f%%"
	--Trace("fmat: " .. fmat)
	local raise= 10^(precision+2)
	local lower= 10^-precision
	local percent_score= fmat:format(math.floor(adp/mdp * raise) * lower)
	local fpcts= fmat:format(math.floor(fadp/mdp * raise) * lower)
	local score_color= color_for_score(adp/mdp)
	args[#args+1]= changing_text("score", fpcts, percent_score, score_color, 0, 0, scale)
	args[#args+1]= changing_text("dp", fadp .. " / " .. mdp,
															 adp .. " / " .. mdp, score_color, 0,
															 spacing*.75, .5*scale)
	local next_y= spacing*1.5
	if cons_players[player_number].flags.offset then
		local function offround(off)
			return math.round(off * 1000)
		end
		local offs_judged= cons_players[player_number].stage_stats.offsets_judged
		local off_precision= math.ceil(math.log(offs_judged) / math.log(10))
		local function offavground(avg)
			return math.round(avg * 10^(3+off_precision)) / 10^(off_precision)
		end
		local real_offscore=
			offround(cons_players[player_number].stage_stats.offset_score)
		local real_offavg= offavground(cons_players[player_number].stage_stats.offset_score / offs_judged)
		local fake_offscore= real_offscore
		local fake_offavg= real_offavg
		if cons_players[player_number].fake_score then
			fake_offscore=
				offround(cons_players[player_number].fake_score.offset_score)
			fake_offavg= offavground(cons_players[player_number].fake_score.offset_score / cons_players[player_number].fake_score.offsets_judged)
		end
		local wa_window= PREFSMAN:GetPreference("TimingWindowSecondsW1") * 1000
		local offcolor= solar_colors.f_text()
		if real_offavg <= wa_window then
			local perfection_pct= 1 - (real_offavg / wa_window)
			offcolor= convert_percent_to_color(perfection_pct)
		end
		local ms_text= " "..get_string_wrapper("ScreenEvaluation", "ms")
		local avg_text= " "..get_string_wrapper("ScreenEvaluation", "avg")
		local tot_text= " "..get_string_wrapper("ScreenEvaluation", "tot")
		args[#args+1]= changing_text("offavgms", fake_offavg..ms_text..avg_text, real_offavg..ms_text..avg_text, offcolor, 0, next_y, scale)
		next_y= next_y + spacing*.75
		args[#args+1]= changing_text("offms", fake_offscore..ms_text..tot_text, real_offscore..ms_text..tot_text, offcolor, 0, next_y, .5*scale)
		next_y= next_y + spacing*.75
	end
	if cons_players[player_number].flags.best_scores then
		next_y= next_y - spacing*.75
		local best_text_y= next_y + spacing*.5
		local score_y= best_text_y + spacing*.5
		next_y= next_y + spacing*1.5
		local seperation= 50
		local sub_sep= 40
		local rank_sep= #percent_score * 8 + 15
		args[#args+1]= normal_text(
			"mbest", get_string_wrapper("ScreenEvaluation", "Machine Best"),
			solar_colors.f_text(), -seperation, best_text_y, .5*scale)
		args[#args+1]= normal_text(
			"pbest", get_string_wrapper("ScreenEvaluation", "Your Best"),
			solar_colors.f_text(), seperation, best_text_y, .5*scale)
		local mpro= PROFILEMAN:GetMachineProfile()
		local ppro= PROFILEMAN:GetProfile(player_number)
		local pro_score_tani_args= {
			sx= -seperation, sy= score_y, tx= -sub_sep, tz= .5*scale, tt="", ta= left,
			nx= sub_sep, nz= .5*scale, nt= "", na= right
		}
		self.mscore= setmetatable({}, text_and_number_interface_mt)
		self.pscore= setmetatable({}, text_and_number_interface_mt)
		function set_score_tani_from_profile(pro, tani_args)
			tani_args.tt= ""
			tani_args.nt= ""
			tani_args.tc= nil
			tani_args.nc= nil
			local rank_ret= 0
			if pro then
				local hs_list= pro:GetHighScoreList(
					gamestate_get_curr_song(), gamestate_get_curr_steps(player_number))
				if hs_list then
					hs_list= hs_list:GetHighScores()
					for i, hs in ipairs(hs_list) do
						if hs:GetName() == ppro:GetLastUsedHighScoreName() and
							hs:GetScore() == pstats:GetScore() then
							rank_ret= i
							break
						end
					end
					if rank_ret == 1 then
						tani_args.tc= convert_percent_to_color(1)
						tani_args.nc= convert_percent_to_color(1)
					end
					local highest_score= hs_list[1]
					if highest_score then
						tani_args.tt= highest_score:GetName():sub(1, 4)
						local pct= math.floor(highest_score:GetPercentDP() * 10000) * .01
						tani_args.nt= ("%.2f%%"):format(pct)
					end
				end
			end
			return rank_ret
		end
		local mrank= set_score_tani_from_profile(mpro, pro_score_tani_args)
		args[#args+1]= self.mscore:create_actors("mscore", pro_score_tani_args)
		pro_score_tani_args.sx= -pro_score_tani_args.sx
		local prank= set_score_tani_from_profile(ppro, pro_score_tani_args)
		args[#args+1]= self.pscore:create_actors("pscore", pro_score_tani_args)
		if mrank ~= 0 then
			args[#args+1]= normal_text("mrank", "#" .. mrank,
																 convert_percent_to_color((9 - mrank) / 8),
																 -rank_sep, 0, .5*scale)
		end
		if prank ~= 0 then
			args[#args+1]= normal_text("prank", "#" .. prank,
																 convert_percent_to_color((9 - prank) / 8),
																 rank_sep, 0, .5*scale)
		end
	end
	local total_taps= 0
	for n, j in ipairs(feedback_judgements) do
		total_taps= total_taps + pstats:GetTapNoteScores(j)
	end
	local total_holds= 0
	for n, h in ipairs(holdnote_names) do
		total_holds= total_holds + pstats:GetHoldNoteScores(h)
	end
	local judge_totals= cons_players[player_number].judge_totals
	local percent_set= setmetatable({}, number_set_mt)
	percent_set:init()
	percent_set:add_number("", nil, solar_colors.bg())
	local taps_set= setmetatable({}, number_set_mt)
	taps_set:init()
	taps_set:add_number(get_string_wrapper("ScreenEvaluation", "Song"), nil, solar_colors.uf_text(), .5)
	local totals_set= setmetatable({}, number_set_mt)
	totals_set:init()
	totals_set:add_number(get_string_wrapper("ScreenEvaluation", "Session"), nil, solar_colors.uf_text())
	local running_totals_set= setmetatable({}, number_set_mt)
	running_totals_set:init()
	running_totals_set:add_number(get_string_wrapper("ScreenEvaluation", "Sum"), nil, solar_colors.uf_text())
	local running_total= 0
	local frunning_total= 0
	for n, j in ipairs(feedback_judgements) do
		local num_taps= pstats:GetTapNoteScores(j)
		local ftaps= num_taps
		if fake_score then
			ftaps= fake_score[j] or 0
		end
		local pcent= tostring(math.round((num_taps / total_taps) * 100)) .. "%"
		local fpcent= tostring(math.round((ftaps / total_taps) * 100)) .. "%"
		pcent= not_negzero(pcent)
		fpcent= not_negzero(fpcent)
		if total_taps <= 0 then pcent= "0%" fpcent= "0%" end
		local jc= judgement_colors[j]
		percent_set:add_number(fpcent, pcent, solar_colors.f_text())
		taps_set:add_number(ftaps, num_taps, jc)
		if judge_totals then
			local jt= 0
			local fjt= 0
			if judge_totals[j] then
				jt= judge_totals[j] + num_taps
				fjt= judge_totals[j] + ftaps
			else
				jt= num_taps
				fjt= ftaps
			end
			judge_totals[j]= jt
			totals_set:add_number(fjt, jt, jc)
			running_total= running_total + jt
			frunning_total= frunning_total + fjt
			running_totals_set:add_number(frunning_total, running_total, jc)
		end
	end
	running_total= 0
	frunning_total= 0
	for n, h in ipairs(holdnote_names) do
		local num_holds= pstats:GetHoldNoteScores(h)
		local fnh= num_holds
		if fake_score then
			fnh= fake_score[h] or 0
		end
		local pcent= tostring(math.round((num_holds / total_holds) * 100)) .. "%"
		local fpcent= tostring(math.round((fnh / total_holds) * 100)) .. "%"
		pcent= not_negzero(pcent)
		fpcent= not_negzero(fpcent)
		if total_holds <= 0 then pcent= "0%" fpcent= "0%" end
		local hc= judgement_colors[h]
		percent_set:add_number(fpcent, pcent, solar_colors.f_text())
		taps_set:add_number(fnh, num_holds, hc)
		if judge_totals then
			local jt= 0
			local fjt= 0
			if judge_totals[h] then
				jt= judge_totals[h] + num_holds
				fjt= judge_totals[h] + fnh
			else
				jt= num_holds
				fjt= fnh
			end
			judge_totals[h]= jt
			totals_set:add_number(fjt, jt, hc)
			running_total= running_total + jt
			frunning_total= frunning_total + fjt
			running_totals_set:add_number(frunning_total, running_total, hc)
		end
	end
	do
		local max_combo= pstats:MaxCombo()
		local percent= max_combo / total_taps
		local pcent= tostring(math.round(percent * 100)) .. "%"
		if total_taps <= 0 then pcent= "0%" fpcent= "0%" end
		percent_set:add_number(pcent, nil, solar_colors.f_text())
		taps_set:add_number(max_combo, nil, convert_percent_to_color(percent, 1))
		if judge_totals then
			if judge_totals.max_combo then
				judge_totals.max_combo= math.max(judge_totals.max_combo, max_combo)
			else
				judge_totals.max_combo= max_combo
			end
			running_totals_set:add_number(judge_totals.max_combo, nil, solar_colors.f_text())
		end
	end
	if cons_players[player_number].flags.pct_column then
		args[#args+1]= percent_set:create_actors(
			"percents", 0, next_y, 0, 0, 0, spacing, .5*scale, center)
	end
	if cons_players[player_number].flags.song_column then
		args[#args+1]= taps_set:create_actors(
			"taps", 0, next_y, 0, 0, 0, spacing, 1*scale, center)
	end
	if cons_players[player_number].flags.session_column then
		args[#args+1]= totals_set:create_actors(
			"totals", 0, next_y, 0, 0, 0, spacing, .5*scale, center)
	end
	if cons_players[player_number].flags.sum_column then
		args[#args+1]= running_totals_set:create_actors(
			"running_totals", 0, next_y, 0, 0, 0, spacing, .5*scale, center)
	end
	return Def.ActorFrame(args)
end

function score_report_interface:find_actors(container, allowed_width)
	self.container= container
	if not container then
		Trace("score_report_interface for " .. self.player_number .. " passed nil container.")
		return
	end
	local chart_info= container:GetChild("chart_info")
	if chart_info then
		width_limit_text(chart_info, allowed_width)
	end
	local offavgms= container:GetChild("offavgms")
	if offavgms then
		width_limit_text(offavgms, allowed_width)
	end
	local cnames= { "percents", "taps", "totals", "running_totals" }
	local children= {}
	local widths= {}
	local total_width= 0
	for i, cn in ipairs(cnames) do
		local child= container:GetChild(cn)
		if child then
			children[#children+1]= child
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(child)
			widths[#widths+1]= (xmx - xmn)
			total_width= total_width + (xmx - xmn)
		end
	end
	if self.mscore then
		self.mscore:find_actors(container:GetChild(self.mscore.name))
		self.pscore:find_actors(container:GetChild(self.pscore.name))
	end
	local pad= 8
	total_width= total_width + (pad * (#cnames - 1))
	local scale= 1
	if total_width > allowed_width then
		scale= allowed_width / total_width
		total_width= allowed_width
	end
	local left_edge= total_width * -.5
	for i= 1, #children do
		local scaled_width= (widths[i] * scale)
		local x= left_edge + (scaled_width / 2)
		children[i]:x(x)
		children[i]:zoomx(scale * children[i]:GetZoomX())
		left_edge= left_edge + scaled_width + pad
	end
end

local score_report_interface_mt= { __index= score_report_interface }

local profile_report_interface= {}
local profile_report_interface_mt= { __index= profile_report_interface }
function profile_report_interface:create_actors(player_number)
	self.player_number= player_number
	self.name= "profile_report"
	local spacing= 12
	local difa= 0
	if #GAMESTATE:GetEnabledPlayers() == 1 then
		difa= 1
	end
	local args= { Name= self.name, InitCommand=cmd(y, 36; diffusealpha, difa) }
	local pro= PROFILEMAN:GetProfile(player_number)
	if pro then
		args[#args+1]= normal_text(
			"pname", pro:GetDisplayName(), nil, 0, -24)
		local things_in_list= {}
		do
			local goal_seconds= pro:GetGoalSeconds()
			local gameplay_seconds= pro:GetTotalGameplaySeconds()
			things_in_list[#things_in_list+1]= {
				name= "Played Time", number= seconds_to_time_string(gameplay_seconds)}
			if goal_seconds > 0 then
				things_in_list[#things_in_list+1]= {
					name= "Goal Time", number= seconds_to_time_string(goal_seconds)}
			end
		end
		do
			local percent= "%.2f%%"
			local num= "%.2f"
			local goal_calories= pro:GetGoalCalories()
			local today_calories= pro:GetCaloriesBurnedToday()
			local total_calories= pro:GetTotalCaloriesBurned()
			local goal_pct= (today_calories/goal_calories)*100
			local pstats= STATSMAN:GetCurStageStats():GetPlayerStageStats(player_number)
			things_in_list[#things_in_list+1]= {
				name= "Calories Today", number= num:format(today_calories)}
			things_in_list[#things_in_list+1]= {
				name= "Calories Song", number= num:format(pstats:GetCaloriesBurned())}
			if goal_calories > 0 then
				things_in_list[#things_in_list+1]= {
					name= "Goal Calories", number= num:format(goal_calories)}
				things_in_list[#things_in_list+1]= {
					name= "Goal Percent", number= percent:format(goal_pct),
					color= convert_percent_to_color(goal_pct/100)}
			end
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
		things_in_list[#things_in_list+1]= {
			name= "Toasties", number= pro:GetNumToasties() }
		things_in_list[#things_in_list+1]= {
			name= "Taps and holds", number= pro:GetTotalTapsAndHolds() }
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
			local y= spacing * (i - 1)
			args[#args+1]= normal_text(
				thing.name .. "t", get_string_wrapper("ScreenEvaluation", thing.name),
				nil, -sep, y, .5, left)
			args[#args+1]= normal_text(
				thing.name .. "n", thing.number, thing.color, sep, y, .5, right)
		end
	end
	return Def.ActorFrame(args)
end

function profile_report_interface:find_actors(container)
	self.container= container
end

local cg_centers= { [PLAYER_1]= { SCREEN_LEFT + cg_thickness/2,
                                  SCREEN_CENTER_Y },
                    [PLAYER_2]= { SCREEN_RIGHT - cg_thickness/2,
                                  SCREEN_CENTER_Y }}
local lg_centers= { [PLAYER_1]= { SCREEN_LEFT + lg_thickness/2 + cg_thickness,
                                  SCREEN_CENTER_Y },
                    [PLAYER_2]= { SCREEN_RIGHT - lg_thickness/2 - cg_thickness,
                                  SCREEN_CENTER_Y }}

local function make_graph_actors()
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local outer_args= { Name= "graphs" }
	local curstats= STATSMAN:GetCurStageStats()
	for k, player_number in pairs(enabled_players) do
		local pstats= curstats:GetPlayerStageStats(player_number)
		local args= { Name= player_number .. "_graphs" }
		local lg_pos= lg_centers[player_number]
		local life_graph= setmetatable({}, life_graph_interface_mt)
		args[#args+1]= life_graph:create_actors(
			pstats, cons_players[player_number].stage_stats.firsts,
			lg_pos[1], lg_pos[2], lg_thickness, SCREEN_HEIGHT,
			player_number == PLAYER_2)
		local cg_pos= cg_centers[player_number]
		local new_element= {}
		setmetatable(new_element, combo_graph_interface_mt)
		args[#args+1]= new_element:create_actors(
			pstats:GetComboList(), cg_pos[1], cg_pos[2], cg_thickness, SCREEN_HEIGHT,
			solar_colors.f_text(), solar_colors.cyan())
		outer_args[#outer_args+1]= Def.ActorFrame(args)
	end
	return Def.ActorFrame(outer_args)
end

local score_reports= { [PLAYER_1]= {}, [PLAYER_2]= {}}
setmetatable(score_reports[PLAYER_1], score_report_interface_mt)
setmetatable(score_reports[PLAYER_2], score_report_interface_mt)

local profile_reports= { [PLAYER_1]= {}, [PLAYER_2]= {}}
setmetatable(profile_reports[PLAYER_1], profile_report_interface_mt)
setmetatable(profile_reports[PLAYER_2], profile_report_interface_mt)

local frame_helpers= { [PLAYER_1]= {}, [PLAYER_2]= {}}
setmetatable(frame_helpers[PLAYER_1], frame_helper_mt)
setmetatable(frame_helpers[PLAYER_2], frame_helper_mt)

local player_xs= { [PLAYER_1]= SCREEN_RIGHT * .25,
                   [PLAYER_2]= SCREEN_RIGHT * .75 }

local function make_player_specific_actors()
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local all_actors= { Name= "players" }
	for k, v in pairs(enabled_players) do
		local args= { Name= v, InitCommand=cmd(x,player_xs[v];y,SCREEN_TOP+120;vertalign,top) }
		local info_height= (#feedback_judgements + #holdnote_names + 3) * 24 + 8
		args[#args+1]= frame_helpers[v]:create_actors(
			"frame", 2, 0, 0, solar_colors[v](), solar_colors.bg(), 0, 0)
		args[#args+1]= score_reports[v]:create_actors(v)
		if #enabled_players > 1 then
			args[#args+1]= profile_reports[v]:create_actors(v)
		end
		all_actors[#all_actors+1]= Def.ActorFrame(args)
	end
	if #enabled_players == 1 then
		local this= enabled_players[1]
		local other= other_player[this]
		local args= { Name= other, InitCommand=cmd(x,player_xs[other];y,SCREEN_TOP+120;vertalign,top) }
		args[#args+1]= frame_helpers[other]:create_actors(
			"frame", 2, 0, 0, solar_colors[this](), solar_colors.bg(), 0, 0)
		args[#args+1]= profile_reports[this]:create_actors(this)
		all_actors[#all_actors+1]= Def.ActorFrame(args)
	end
	return Def.ActorFrame(all_actors)
end

local judge_frame_helper= setmetatable({}, frame_helper_mt)
local function make_judge_name_actors()
	local args= {
		Name= "judge_names",
		InitCommand= cmd(xy, SCREEN_CENTER_X, SCREEN_TOP + 204) }
	local frame_pad= .5
	if SCREEN_WIDTH == 640 then
		frame_pad= 1
	end
	args[#args+1]= judge_frame_helper:create_actors("frame", frame_pad, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0)
	local name_set= setmetatable({}, number_set_mt)
	name_set:init()
	for i, v in ipairs(feedback_judgements) do
		name_set:add_number(get_string_wrapper("ShortJudgmentNames", v), nil, judgement_colors[v])
	end
	for i, v in ipairs(holdnote_names) do
		name_set:add_number(get_string_wrapper("ShortJudgmentNames", v), nil, judgement_colors[v])
	end
	name_set:add_number(get_string_wrapper("ShortJudgmentNames", "MaxCombo"), nil, solar_colors.f_text())
	args[#args+1]= name_set:create_actors("names", 0, 0, 0, 0, 0, 24, .5, center)
	return Def.ActorFrame(args)
end

local function find_actors(self)
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local players_container= self:GetChild("players")
	local judge_names= self:GetChild("judge_names")
	local judge_left= SCREEN_CENTER_X
	local judge_right= SCREEN_CENTER_X
	if judge_names then
		judge_frame_helper:find_actors(judge_names:GetChild(judge_frame_helper.name))
		local fxmn, fxmx, fymn, fymx= rec_calc_actor_extent(judge_names)
		local fw= fxmx - fxmn + 8
		local fh= fymx - fymn + 8
		local fx= fxmn + (fw / 2)
		local fy= fymn + (fh / 2)
		judge_left= fxmn + judge_names:GetX()
		judge_right= fxmx + judge_names:GetX()
		judge_frame_helper:move(fx-4, fy-4)
		judge_frame_helper:resize(fw, fh)
	end
	local graphs= self:GetChild("graphs")
	local left_graph_edge= SCREEN_LEFT
	local right_graph_edge= SCREEN_RIGHT
	if graphs then
		local lgraph= graphs:GetChild(PLAYER_1 .. "_graphs")
		local rgraph= graphs:GetChild(PLAYER_2 .. "_graphs")
		if lgraph then
			lgraph= lgraph:GetChild("GraphDisplay")
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(lgraph)
			left_graph_edge= xmx + lgraph:GetX()
		end
		if rgraph then
			rgraph= rgraph:GetChild("GraphDisplay")
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(rgraph)
			right_graph_edge= xmn + rgraph:GetX()
		end
	end
	for k, v in pairs(enabled_players) do
		local pcont= players_container:GetChild(v)
		local cpos= player_xs[v]
		local width= 1
		if v == PLAYER_1 then
			cpos= (left_graph_edge + judge_left) / 2
			width= judge_left - left_graph_edge
		else
			cpos= (right_graph_edge + judge_right) / 2
			width= right_graph_edge - judge_right
		end
		pcont:x(cpos)
		local pad= 16
		width= width - (pad * 2)
		local score_cont= pcont:GetChild("judge_list")
		score_reports[v]:find_actors(score_cont, width)
		if #GAMESTATE:GetEnabledPlayers() == 1 then
			local other= other_player[v]
			local opcont= players_container:GetChild(other)
			profile_reports[v]:find_actors(opcont:GetChild(profile_reports[v].name), width)
			frame_helpers[other]:find_actors(opcont:GetChild(frame_helpers[other].name))
			local fxmn, fxmx, fymn, fymx= rec_calc_actor_extent(opcont)
			local fw= fxmx - fxmn + pad
			local fh= fymx - fymn + pad
			local fx= fxmn + (fw / 2)
			local fy= fymn + (fh / 2)
			frame_helpers[other]:move(fx-pad/2, fy)
			frame_helpers[other]:resize(fw, fh)
		else
			profile_reports[v]:find_actors(pcont:GetChild(profile_reports[v].name), width)
		end
		frame_helpers[v]:find_actors(pcont:GetChild(frame_helpers[v].name))
		local fxmn, fxmx, fymn, fymx= rec_calc_actor_extent(pcont)
		local fw= fxmx - fxmn + pad
		local fh= fymx - fymn + pad
		local fx= fxmn + (fw / 2)
		local fy= fymn + (fh / 2)
		frame_helpers[v]:move(fx-pad/2, fy)
		frame_helpers[v]:resize(fw, fh)
		--Trace("Resizing frame to " .. frame_width .. " x " .. frame_height)
		--frame_helpers[v]:resize(frame_width, frame_height)
	end
	local graphs= self:GetChild("graphs")
	if graphs then
		local pa_graphs= graphs:GetChild(PLAYER_1 .. "_graphs")
		if pa_graphs then
			local pa_combo_graph= pa_graphs:GetChild("ComboGraph")
			combo_graph_interface.reposition_max_texts(pa_combo_graph, cg_centers[PLAYER_1][1])
		end
		local pb_graphs= graphs:GetChild(PLAYER_2 .. "_graphs")
		if pb_graphs then
			local pb_combo_graph= pb_graphs:GetChild("ComboGraph")
			combo_graph_interface.reposition_max_texts(pb_combo_graph, cg_centers[PLAYER_2][1])
		end
	end
end

do
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local highest_score= 0
	local curstats= STATSMAN:GetCurStageStats()
	for i, v in ipairs(enabled_players) do
		if not GAMESTATE:IsEventMode() then
			local play_history= cons_players[v].play_history
			play_history[#play_history+1]= {
				song= gamestate_get_curr_song(), steps= gamestate_get_curr_steps(v)}
		end
		local pstats= curstats:GetPlayerStageStats(v)
		highest_score= math.max(highest_score,
			pstats:GetActualDancePoints() / pstats:GetPossibleDancePoints())
		if not GAMESTATE:IsCourseMode() then
			local profile_dir= false
			if v == PLAYER_1 then
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
				cons_players[v].column_scores.timestamp= Year() .. "_" .. pad_num(MonthOfYear()) .. "_" .. pad_num(DayOfMonth()) .. "_" .. pad_num(Hour()) .. "_" .. pad_num(Minute()) .. "_" .. pad_num(Second())
				all_attempts[#all_attempts+1]= cons_players[v].column_scores
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
	local reward= convert_score_to_time(highest_score)
	reduce_time_remaining(-reward)
end

return Def.ActorFrame{
	Name= "SEd",
	InitCommand= function(self)
								 find_actors(self)
							 end,
	make_banner_actor(),
	make_player_specific_actors(),
	make_judge_name_actors(),
	make_graph_actors(),
	Def.Actor{
		Name= "Vacuum Cleaner D27",
		InitCommand= function(self)
									 self:effectperiod(2^16)
									 timer_actor= self
								 end,
		CodeMessageCommand=
			function(self, param)
				if self:GetSecsIntoEffect() < 0.25 then return end
				local code_name= param.Name
				local pn= param.PlayerNumber
				if not code_name:find("release") then
					if GAMESTATE:IsSideJoined(pn) and #GAMESTATE:GetEnabledPlayers() > 1 then
						if score_reports[pn].hidden then
							score_reports[pn].hidden= false
							score_reports[pn].container:diffusealpha(1)
							profile_reports[pn].container:diffusealpha(0)
						else
							score_reports[pn].hidden= true
							score_reports[pn].container:diffusealpha(0)
							profile_reports[pn].container:diffusealpha(1)
						end
					end
				end
			end,
		OffCommand=
			function(self)
				filter_bucket_songs_by_time()
			end
	}
}
