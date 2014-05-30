local cg_thickness= 24
local lg_thickness= 40
local reward_time= 0
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

dofile(THEME:GetPathO("", "art_helpers.lua"))

local tns_reverse= TapNoteScore:Reverse()
local tnss_that_affect_combo= {
	TapNoteScore_W1= true,
	TapNoteScore_W2= true,
	TapNoteScore_W3= true,
	TapNoteScore_W4= true,
	TapNoteScore_W5= true,
	TapNoteScore_Miss= true,
}
local tns_cont_combo= tns_reverse[THEME:GetMetric("Gameplay", "MinScoreToContinueCombo")]
local tns_maint_combo= tns_reverse[THEME:GetMetric("Gameplay", "MinScoreToMaintainCombo")]
local tnss_that_can_be_early= {
	TapNoteScore_W1= true,
	TapNoteScore_W2= true,
	TapNoteScore_W3= true,
	TapNoteScore_W4= true,
	TapNoteScore_W5= true,
}

-- style compatibility issue:  Dance, Pump, and Techno are the only supported games.
local column_to_pad_arrow_map= {
	[PLAYER_1]= {
		StepsType_Dance_Single= {[0]= 4, 8, 2, 6},
		StepsType_Dance_Double= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Couple= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Solo= {[0]= 4, 1, 8, 2, 3, 6},
		StepsType_Dance_Threepanel= {[0]= 1, 8, 3},
		StepsType_Dance_Routine= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Pump_Single= {[0]= 7, 1, 5, 3, 9},
		StepsType_Pump_Halfdouble= {[0]= 5, 3, 9, 16, 10, 14},
		StepsType_Pump_Double= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Couple= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Routine= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Single4= {[0]= 4, 8, 2, 6},
		StepsType_Techno_Single5= {[0]= 7, 1, 5, 3, 9},
		StepsType_Techno_Single8= {[0]= 1, 2, 3, 4, 6, 7, 8, 9},
		StepsType_Techno_Double4= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Techno_Double5= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Double8= {[0]= 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18},
	},
	[PLAYER_2]= {
		StepsType_Dance_Single= {[0]= 13, 17, 11, 15},
		StepsType_Dance_Double= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Couple= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Dance_Solo= {[0]= 13, 10, 17, 11, 12, 15},
		StepsType_Dance_Threepanel= {[0]= 10, 17, 12},
		StepsType_Dance_Routine= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Pump_Single= {[0]= 16, 10, 14, 12, 18},
		StepsType_Pump_Halfdouble= {[0]= 5, 3, 9, 16, 10, 14},
		StepsType_Pump_Double= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Couple= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Pump_Routine= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Single4= {[0]= 13, 17, 11, 15},
		StepsType_Techno_Single5= {[0]= 16, 10, 14, 12, 18},
		StepsType_Techno_Single8= {[0]= 10, 11, 12, 13, 15, 16, 17, 18},
		StepsType_Techno_Double4= {[0]= 4, 8, 2, 6, 13, 17, 11, 15},
		StepsType_Techno_Double5= {[0]= 7, 1, 5, 3, 9, 16, 10, 14, 12, 18},
		StepsType_Techno_Double8= {[0]= 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18},
}}

local function get_pad_arrow_for_col(pn, col)
	-- -1 is the index for the combined stats of all panels
	if col == -1 then return -1 end
	local steps_type= gamestate_get_curr_steps(pn):GetStepsType()
	if column_to_pad_arrow_map[pn][steps_type] then
		return column_to_pad_arrow_map[pn][steps_type][col]
	end
end

local function color_dance_pad_by_score(pn, pad)
	local steps_type= gamestate_get_curr_steps(pn):GetStepsType()
	local col_score= cons_players[pn].column_scores
	if column_to_pad_arrow_map[pn][steps_type] then
		for c= 0, #col_score do
			local arrow_id= column_to_pad_arrow_map[pn][steps_type][c]
			if arrow_id then
				pad:color_arrow(arrow_id, color_for_score(col_score[c].dp/col_score[c].mdp))
				pad.arrows[arrow_id]:SetVertices(vert_colors)
			end
		end
	end
end

local function toggle_visible_indicator(pn, pad, col)
	if col < 0 then return end
	pad:toggle_indicator(get_pad_arrow_for_col(pn, col))
end

local number_set_mt= {
	__index= {
		create_actors= function(self, name, x, y, sx, sy, dx, dy, elz, ela, elc,
														elw)
			x= x or 0
			y= y or 0
			sx= sx or 0
			sy= sy or 0
			dx= dx or 0
			dy= dy or 0
			elz= elz or 1
			ela= ela or center
			elc= elc or 10
			elw= elw or 80
			self.name= name
			local args= {Name= name, InitCommand= cmd(xy, x, y)}
			self.els= {}
			self.elzooms= {}
			self.elz= elz
			self.elw= elw
			for i= 1, elc do
				local im= i-1
				self.els[i]= "n"..i
				args[#args+1]= normal_text(
					self.els[i], "", nil, sx + (dx * im), sy + (dy * im), elz, ela)
			end
			return Def.ActorFrame(args)
		end,
		find_actors= function(self, container)
			self.container= container
			for i= 1, #self.els do
				self.els[i]= container:GetChild(self.els[i])
			end
		end,
		set= function(self, number_data)
			-- Each entry in number_data is {number= n, color= c, zoom= z}
			for i, el in ipairs(self.els) do
				if number_data[i] then
					local number= number_data[i].number or ""
					local color= number_data[i].color or solar_colors.f_text()
					local zoom= (number_data[i].zoom or 1) * self.elz
					self.elzooms[i]= zoom
					el:settext(number)
					el:diffuse(color)
					el:zoom(zoom)
					width_limit_text(el, self.elw, zoom)
					el:visible(true)
				else
					el:visible(false)
				end
			end
		end,
		width_limit= function(self, width)
			for i, el in pairs(self.els) do
				width_limit_text(el, width, self.elzooms[i])
			end
		end
}}

local best_score_mt= {
	__index= {
		create_actors= function(self, name, x, y, z, score_name)
			self.name= name
			local args= {Name= name, InitCommand= cmd(xy, x, y)}
			self.fh= setmetatable({}, frame_helper_mt)
			args[#args+1]= self.fh:create_actors(
				"frame", .5, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0)
			local bt= get_string_wrapper("ScreenEvaluation", score_name)
			args[#args+1]= normal_text("best_text", bt, nil, 0, 0, z*.5)
			args[#args+1]= normal_text("rank", "", nil, 0, -24*.5*z, z*.5)
			self.score= setmetatable({}, text_and_number_interface_mt)
			args[#args+1]= self.score:create_actors(
				"score", {sy= 24*.5*z, tx= -40, nx= 40, tz= .5*z, nz= .5*z, ta= left,
									na= right, tt= "", nt= ""})
			return Def.ActorFrame(args)
		end,
		find_actors= function(self, container)
			self.container= container
			self.fh:find_actors(container:GetChild(self.fh.name))
			self.score:find_actors(container:GetChild(self.score.name))
			self.rank= container:GetChild("rank")
		end,
		set= function(self, profile_pn, rank_pn)
			local profile= false
			if profile_pn then
				profile= PROFILEMAN:GetProfile(profile_pn)
			else
				profile= PROFILEMAN:GetMachineProfile()
			end
			local rank_profile= PROFILEMAN:GetProfile(rank_pn)
			self.score:hide()
			if profile and rank_profile then
				local hs_list= profile:GetHighScoreListIfExists(
					gamestate_get_curr_song(), gamestate_get_curr_steps(rank_pn))
				if hs_list then
					hs_list= hs_list:GetHighScores()
					local highest_score= hs_list[1]
					if highest_score then
						local pn_to_filler= {[PLAYER_1]= "#P1#", [PLAYER_2]= "#P2#"}
						local rank= 0
						local pstats=
							STATSMAN:GetCurStageStats():GetPlayerStageStats(rank_pn)
						for i, hs in ipairs(hs_list) do
							if hs:GetName() == pn_to_filler[rank_pn] or
								(hs:GetName() == rank_profile:GetLastUsedHighScoreName() and
								 hs:GetScore() == pstats:GetScore()) then
									rank= i
									break
							end
						end
						if rank == 0 then
							self.rank:visible(false)
						else
							self.rank:settext("#"..rank)
							self.rank:diffuse(convert_percent_to_color((9 - rank) / 8))
							self.rank:visible(true)
						end
						self.score:set_text(highest_score:GetName())
						local pct= math.floor(highest_score:GetPercentDP() * 10000) * .01
						self.score:set_number(("%.2f%%"):format(pct))
						local name_width= 80 - self.score.number:GetZoomedWidth() - 4
						width_clip_text(self.score.text, name_width)
						self.score:unhide()
						local fxmn, fxmx, fymn, fymx=
							rec_calc_actor_extent(self.container)
						local fw= fxmx - fxmn + 2
						local fh= fymx - fymn + 4
						local fx= fxmn + (fw / 2)
						local fy= fymn + (fh / 2)
						self.fh:move(fx, fy-2)
						self.fh:resize(fw, fh)
					end
				end
			end
		end
}}

local function make_banner_actor()
	local cur_song= gamestate_get_curr_song()
	local song_name= ""
	if cur_song then song_name= cur_song:GetDisplayFullTitle()
		return Def.ActorFrame{
			Name= "song_stuff",
			InitCommand= function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_TOP + 12)
			end,
			Def.Sprite{
				Name= "banner",
				InitCommand= function(self)
					self:xy(0, 56)
					if cur_song then
						self:LoadFromSongBanner(cur_song)
						scale_to_fit(self, 256, 80)
					else
						self:visible(false)
					end
				end
			},
			normal_text(
				"song_name", song_name, solar_colors.f_text(), 0, 0, 1, center,
				{ OnCommand= function(self)
						local limit= SCREEN_WIDTH - ((cg_thickness+lg_thickness)*2) - 16
						width_limit_text(self, limit)
				end
			})
		}
	end
end

local reward_time_mt= {
	__index= {
		create_actors= function(self, name, x, y)
			self.name= name
			local args= {Name= name, InitCommand= cmd(xy, x, y)}
			self.frame= setmetatable({}, frame_helper_mt)
			args[#args+1]= self.frame:create_actors("frame", .5, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0)
			args[#args+1]= normal_text("reward_text", "", solar_colors.uf_text(), 0, 0, .5)
			args[#args+1]= normal_text("reward_amount", "", solar_colors.f_text(), 0, 0, 1)
			args[#args+1]= normal_text("remain_text", "", solar_colors.uf_text(), 0, 0, .5)
			args[#args+1]= normal_text("remain_time", "", solar_colors.f_text(), 0, 0, 1)
			return Def.ActorFrame(args)
		end,
		find_actors= function(self, container)
			self.container= container
			self.frame:find_actors(container:GetChild(self.frame.name))
			self.reward_text= container:GetChild("reward_text")
			self.reward_amount= container:GetChild("reward_amount")
			self.remain_text= container:GetChild("remain_text")
			self.remain_time= container:GetChild("remain_time")
		end,
		set= function(self, width, reward_time)
			local next_y= 0
			if reward_time ~= 0 then
				self.reward_text:settext(get_string_wrapper("ScreenEvaluation", "Reward"))
				width_limit_text(self.reward_text, width, .5)
				next_y= next_y + (24 * .75)
				local reward_str= ""
				local minutes= math.round_to_zero(reward_time / 60)
				local seconds= math.round_to_zero(reward_time % 60)
				if seconds < 10 and minutes > 0 and reward_time ~= 0 then
					seconds= "0" .. seconds
				end
				if reward_time > 0 then
					reward_str= "+" .. minutes .. ":" .. seconds
				elseif reward_time < 0 then
					reward_str= minutes .. ":" .. seconds
				end
				self.reward_amount:settext(reward_str)
				width_limit_text(self.reward_amount, width, 1)
				self.reward_amount:y(next_y)
				next_y= next_y + (24 * .75)
			end
			self.remain_text:settext(get_string_wrapper("ScreenEvaluation", "Remaining"))
			width_limit_text(self.remain_text, width, .5)
			self.remain_text:y(next_y)
			next_y= next_y + (24 * .75)
			local seconds= get_time_remaining()
			local minutes= math.floor(math.round(seconds) / 60)
			seconds= math.round(seconds) % 60
			if seconds < 10 then seconds= "0" .. seconds end
			self.remain_time:settext(minutes .. ":" .. seconds)
			width_limit_text(self.remain_time, width, 1)
			self.remain_time:y(next_y)
			local fxmn, fxmx, fymn, fymx= rec_calc_actor_extent(self.container)
			local fw= fxmx - fxmn + 2
			local fh= fymx - fymn + 4
			local fx= fxmn + (fw / 2)
			local fy= fymn + (fh / 2)
			self.frame:move(fx, fy-1)
			self.frame:resize(fw, fh)
		end
}}

local reward_indicator= setmetatable({}, reward_time_mt)

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

local combo_graph_mt= {
	__index= {
		create_actors= function(self, name, x, y, w, h)
			self.name= name
			self.w= w or 12
			self.h= h or SCREEN_HEIGHT
			return Def.ActorMultiVertex{
				Name= name,
				InitCommand= function(self)
					self:xy(x, y)
					self:SetDrawState{Mode="DrawMode_QuadStrip"}
				end
			}
		end,
		find_actors= function(self, container)
			self.container= container
		end,
		set= function(self, step_timings)
			local length= gameplay_end_time - gameplay_start_time
			local pix_per_sec= self.h / length
			local true_disp_height= DISPLAY:GetDisplayHeight()
			local min_sex= length / true_disp_height
			local verts= {}
			local prev_time= 0
			for i, tim in ipairs(step_timings) do
				if tnss_that_affect_combo[tim.judge] and
				(tim.time - prev_time > min_sex or prev_time == 0) then
					local color= judgement_colors[tim.judge]
					local y= tim.time * pix_per_sec
					prev_time= tim.time
					verts[#verts+1]= {{-self.w, y, 0}, color}
					verts[#verts+1]= {{self.w, y, 0}, color}
				end
			end
			if #verts > 2 and #verts % 2 == 0 then
				self.container:SetVertices(verts)
				self.container:SetDrawState{Num= #verts}
			end
		end
}}

local score_report_mt= {
	__index= {
		create_actors= function(self, name)
			self.scale= .9
			self.spacing= 24 * self.scale
			self.name= name
			self.pct_col= setmetatable({}, number_set_mt)
			self.song_col= setmetatable({}, number_set_mt)
			self.session_col= setmetatable({}, number_set_mt)
			self.sum_col= setmetatable({}, number_set_mt)
			local args= {
				Name= name,
				-- Create actors assuming all stats will be displayed.
				-- The set function will fill in/position the ones that are enabled.
				-- This will allow us to toggle the visibility flags on this screen.
				normal_text("chart_info", "", nil, 0, 0, self.scale),
				normal_text("score", "", nil, 0, 0, self.scale),
				normal_text("dp", "", nil, 0, 0, self.scale*.5),
				normal_text("offavgms", "", nil, 0, 0, self.scale),
				normal_text("offms", "", nil, 0, 0, self.scale*.5),
				self.pct_col:create_actors(
					"pct", 0, 0, 0, 0, 0, self.spacing, self.scale, center, 10),
				self.song_col:create_actors(
					"song", 0, 0, 0, 0, 0, self.spacing, self.scale, center, 10),
				self.session_col:create_actors(
					"session", 0, 0, 0, 0, 0, self.spacing, self.scale, center, 10),
				self.sum_col:create_actors(
					"sum", 0, 0, 0, 0, 0, self.spacing, self.scale, center, 10),
			}
			return Def.ActorFrame(args)
		end,
		find_actors= function(self, container)
			self.container= container
			self.chart_info= container:GetChild("chart_info")
			self.score= container:GetChild("score")
			self.dp= container:GetChild("dp")
			self.offavgms= container:GetChild("offavgms")
			self.offms= container:GetChild("offms")
			self.pct_col:find_actors(container:GetChild(self.pct_col.name))
			self.song_col:find_actors(container:GetChild(self.song_col.name))
			self.session_col:find_actors(container:GetChild(self.session_col.name))
			self.sum_col:find_actors(container:GetChild(self.sum_col.name))
		end,
		set= function(self, player_number, col_id, score_data, allowed_width)
			if allowed_width then
				self.allowed_width= allowed_width
			else
				allowed_width= self.allowed_width or 1
			end
			local flags= cons_players[player_number].flags
			local session_col= get_pad_arrow_for_col(player_number, col_id)
			local session_score= cons_players[player_number].session_stats[session_col]
			local next_y= 0
			self.chart_info:settext(
				chart_info_text(gamestate_get_curr_steps(player_number)))
			width_limit_text(self.chart_info, allowed_width, self.scale)
			next_y= next_y + self.spacing
			do -- score stuff
				-- TODO: session stats for score?  The data is calculated, but not displayed.
				local adp= score_data.dp
				local mdp= score_data.mdp
				local min_precision= 2
				local precision= math.ceil(math.log(mdp) / math.log(10)) - 2
				precision= math.max(min_precision, precision)
				local fmat= "%." .. precision .. "f%%"
				--Trace("fmat: " .. fmat)
				local raise= 10^(precision+2)
				local lower= 10^-precision
				local percent_score= fmat:format(math.floor(adp/mdp * raise) * lower)
				local score_color= color_for_score(adp/mdp)
				self.score:settext(percent_score)
				self.score:diffuse(score_color)
				self.score:y(next_y)
				next_y= next_y + (self.spacing * .75)
				self.dp:settext(adp .. " / " .. mdp)
				self.dp:diffuse(score_color)
				self.dp:y(next_y)
				next_y= next_y + (self.spacing * .25)
			end
			if flags.offset then
				-- TODO: session stats for offset?  The data is not calculated.
				local function offround(off)
					return math.round(off * 1000)
				end
				local offs_judged= 0
				local offset_total= 0
				-- Mines and others don't have a valid offset, don't count them.
				for i, tim in ipairs(score_data.step_timings) do
					-- Misses have an offset of 0.
					if tim.offset and tim.judge ~= "TapNoteScore_Miss" then
						offs_judged= offs_judged + 1
						offset_total= offset_total + math.abs(tim.offset)
					end
				end
				local off_precision= math.ceil(math.log(offs_judged) / math.log(10))
				local function offavground(avg)
					return math.round(avg * 10^(3+off_precision)) / 10^(off_precision)
				end
				local offscore= offround(offset_total)
				local offavg= offavground(offset_total / offs_judged)
				local offcolor= solar_colors.f_text()
				local wa_window= PREFSMAN:GetPreference("TimingWindowSecondsW1")*1000
				if offavg <= wa_window then
					local perfection_pct= 1 - (offavg / wa_window)
					offcolor= convert_percent_to_color(perfection_pct)
				end
				local ms_text= " "..get_string_wrapper("ScreenEvaluation", "ms")
				local avg_text= " "..get_string_wrapper("ScreenEvaluation", "avg")
				local tot_text= " "..get_string_wrapper("ScreenEvaluation", "tot")
				next_y= next_y + (self.spacing * .5)
				self.offavgms:settext(offavg..ms_text..avg_text)
				self.offavgms:y(next_y)
				self.offavgms:diffuse(offcolor)
				width_limit_text(self.offavgms, allowed_width, self.scale)
				self.offavgms:visible(true)
				next_y= next_y + (self.spacing * .75)
				self.offms:settext(offscore..ms_text..tot_text)
				self.offms:y(next_y)
				self.offms:diffuse(offcolor)
				self.offms:visible(true)
				next_y= next_y + (self.spacing * .25)
			else
				self.offavgms:visible(false)
				self.offms:visible(false)
			end
			do -- columns
				local pct_data= {{}}
				local song_data= {
					{number= "Song", color= solar_colors.uf_text(), zoom= .5}}
				local session_data= {
					{number= "Session", color= solar_colors.uf_text(), zoom= .5}}
				local sum_data= {
					{number= "Sum", color= solar_colors.uf_text(), zoom= .5}}
				local judge_totals= {}
				local early_counts= {}
				local late_counts= {}
				for i, tim in ipairs(score_data.step_timings) do
					-- Misses count as early because of this.
					if tnss_that_can_be_early[tim.judge] and tim.offset >= 0 then
						late_counts[tim.judge]= (late_counts[tim.judge] or 0) + 1
					else
						early_counts[tim.judge]= (early_counts[tim.judge] or 0) + 1
					end
				end
				local function add_judge_data(judge_names)
					local sum_ear_total= 0
					local sum_lat_total= 0
					local fj_ear_total= 0
					local fj_lat_total= 0
					for i, fj in ipairs(judge_names) do
						fj_ear_total= fj_ear_total + (early_counts[fj] or 0)
						fj_lat_total= fj_lat_total + (late_counts[fj] or 0)
					end
					judge_totals[#judge_totals+1]= fj_ear_total + fj_lat_total
					local function pct_to_str(num, den)
						if num == 0 or den == 0 then return "" end
						return math.round((num/den)*100) .. "%"
					end
					for i, fj in ipairs(judge_names) do
						local jcolor= judgement_colors[fj]
						local earnum= early_counts[fj] or 0
						local latnum= late_counts[fj] or 0
						local sessear= session_score.judge_counts.early[fj]
						local sesslat= session_score.judge_counts.late[fj]
						sum_ear_total= sum_ear_total + sessear
						sum_lat_total= sum_lat_total + sesslat

						local pctstr= ""
						local numstr= ""
						local sessstr= ""
						local sumstr= ""

						local numz= 1
						if flags.score_early_late and tnss_that_can_be_early[fj] then
							local earpstr= pct_to_str(earnum, fj_ear_total)
							local latpstr= pct_to_str(latnum, fj_lat_total)
							local divstr= "/"
							if earpstr == "" or latpstr == "" then divstr= "" end
							pctstr= earpstr .. divstr .. latpstr
							numstr= earnum .. "/" .. latnum
							numz= .5
							sessstr= sessear .. "/" .. sesslat
							sumstr= sum_ear_total .. "/" .. sum_lat_total
						else
							pctstr= pct_to_str(earnum+latnum, fj_ear_total+fj_lat_total)
							numstr= earnum + latnum
							sessstr= sessear + sesslat
							sumstr= sum_ear_total + sum_lat_total
						end

						pct_data[#pct_data+1]= {
							number= pctstr, color= solar_colors.f_text(), zoom= .5}
						song_data[#song_data+1]= {
							number= numstr, color= jcolor, zoom= numz}
						session_data[#session_data+1]= {
							number= sessstr, color= jcolor, zoom= .5}
						sum_data[#sum_data+1]= {
							number= sumstr, color= jcolor, zoom= .5}
					end
				end
				add_judge_data(feedback_judgements)
				add_judge_data(holdnote_names)
				local max_combo= score_data.max_combo
				if max_combo then
					local percent= max_combo / judge_totals[1]
					local pcent= tostring(math.round(percent * 100)) .. "%"
					if judge_totals[1] <= 0 or max_combo == 0 then pcent= "" end
					pct_data[#pct_data+1]= {
						number= pcent, color= solar_colors.f_text(), zoom= .5}
					song_data[#song_data+1]= {
						number= max_combo, color= convert_percent_to_color(percent),
						zoom= 1}
				end
				local column_slots= {}
				if flags.pct_column then
					column_slots[#column_slots+1]= self.pct_col
					self.pct_col:set(pct_data)
					self.pct_col.container:visible(true)
				else
					self.pct_col.container:visible(false)
				end
				if flags.song_column then
					column_slots[#column_slots+1]= self.song_col
					self.song_col:set(song_data)
					self.song_col.container:visible(true)
				else
					self.song_col.container:visible(false)
				end
				if flags.session_column then
					column_slots[#column_slots+1]= self.session_col
					self.session_col:set(session_data)
					self.session_col.container:visible(true)
				else
					self.session_col.container:visible(false)
				end
				if flags.sum_column then
					column_slots[#column_slots+1]= self.sum_col
					self.sum_col:set(sum_data)
					self.sum_col.container:visible(true)
				else
					self.sum_col.container:visible(false)
				end
				local column_width= allowed_width / #column_slots
				local left_edge= -(column_width * (#column_slots / 2)) +
					(column_width / 2)
				next_y= next_y + (self.spacing * .5)
				for i, col in ipairs(column_slots) do
					local x= left_edge + (column_width * (i - 1))
					col.container:xy(x, next_y)
					col:width_limit(column_width - 8)
				end
			end
		end
}}

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

local cg_centers= { [PLAYER_1]= {SCREEN_LEFT + cg_thickness/2, 0},
	[PLAYER_2]= {SCREEN_RIGHT - cg_thickness/2, 0}}
local lg_centers= { [PLAYER_1]= { SCREEN_LEFT + lg_thickness/2 + cg_thickness,
                                  SCREEN_CENTER_Y },
                    [PLAYER_2]= { SCREEN_RIGHT - lg_thickness/2 - cg_thickness,
                                  SCREEN_CENTER_Y }}

local combo_graphs= {
	[PLAYER_1]= setmetatable({}, combo_graph_mt),
	[PLAYER_2]= setmetatable({}, combo_graph_mt)
}

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
		args[#args+1]= combo_graphs[player_number]:create_actors(
			"cgraph", cg_pos[1], cg_pos[2], 12, SCREEN_HEIGHT)
		outer_args[#outer_args+1]= Def.ActorFrame(args)
	end
	return Def.ActorFrame(outer_args)
end

local score_reports= { [PLAYER_1]= {}, [PLAYER_2]= {}}
setmetatable(score_reports[PLAYER_1], score_report_mt)
setmetatable(score_reports[PLAYER_2], score_report_mt)

local profile_reports= { [PLAYER_1]= {}, [PLAYER_2]= {}}
setmetatable(profile_reports[PLAYER_1], profile_report_interface_mt)
setmetatable(profile_reports[PLAYER_2], profile_report_interface_mt)

local frame_helpers= { [PLAYER_1]= {}, [PLAYER_2]= {}}
setmetatable(frame_helpers[PLAYER_1], frame_helper_mt)
setmetatable(frame_helpers[PLAYER_2], frame_helper_mt)

local player_xs= { [PLAYER_1]= SCREEN_RIGHT * .25,
                   [PLAYER_2]= SCREEN_RIGHT * .75 }

local dance_pads= {[PLAYER_1]= setmetatable({}, dance_pad_mt),
	[PLAYER_2]= setmetatable({}, dance_pad_mt)}

local besties= {
	[PLAYER_1]= {machine= setmetatable({}, best_score_mt),
							 player= setmetatable({}, best_score_mt)},
	[PLAYER_2]= {machine= setmetatable({}, best_score_mt),
							 player= setmetatable({}, best_score_mt)}}

local function make_player_specific_actors()
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local all_actors= { Name= "players" }
	for k, v in pairs(enabled_players) do
		local args= { Name= v, InitCommand=cmd(x,player_xs[v];y,SCREEN_TOP+160;vertalign,top) }
		args[#args+1]= frame_helpers[v]:create_actors(
			"frame", 2, 0, 0, solar_colors[v](), solar_colors.bg(), 0, 0)
		args[#args+1]= score_reports[v]:create_actors(v)
		if #enabled_players > 1 then
			args[#args+1]= profile_reports[v]:create_actors(v)
		end
		args[#args+1]= dance_pads[v]:create_actors("dance_pad", 0, -34, 10)
		args[#args+1]= besties[v].machine:create_actors("mbest", 0, -114, 1,
																										"Machine Best")
		args[#args+1]= besties[v].player:create_actors("pbest", 0, -72, 1,
																										"Player Best")
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
local judge_name_set= setmetatable({}, number_set_mt)
local judge_name_data= {}
local function make_judge_name_actors()
	local args= {
		Name= "judge_names",
		InitCommand= cmd(xy, SCREEN_CENTER_X, SCREEN_TOP + 226) }
	local frame_pad= .5
	if SCREEN_WIDTH == 640 then
		frame_pad= 1
	end
	args[#args+1]= judge_frame_helper:create_actors("frame", frame_pad, 0, 0, solar_colors.rbg(), solar_colors.bg(), 0, 0)
	for i, v in ipairs(feedback_judgements) do
		judge_name_data[#judge_name_data+1]= {
			number= get_string_wrapper("ShortJudgmentNames", v),
			color= judgement_colors[v], zoom= .5}
	end
	for i, v in ipairs(holdnote_names) do
		judge_name_data[#judge_name_data+1]= {
			number= get_string_wrapper("ShortJudgmentNames", v),
			color= judgement_colors[v], zoom= .5}
	end
	judge_name_data[#judge_name_data+1]= {
		number= get_string_wrapper("ShortJudgmentNames", "MaxCombo"),
		color= solar_colors.f_text(), zoom= .5}
	args[#args+1]= judge_name_set:create_actors(
		"names", 0, 0, 0, 0, 0, 24, 1, center, #judge_name_data)
	return Def.ActorFrame(args)
end

local score_datas= {}
local score_data_viewing_indices= {}
local showing_profile_on_other_side= false

local function find_actors(self)
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local players_container= self:GetChild("players")
	local judge_names= self:GetChild("judge_names")
	local judge_left= SCREEN_CENTER_X
	local judge_right= SCREEN_CENTER_X
	if judge_names then
		judge_name_set:find_actors(judge_names:GetChild(judge_name_set.name))
		judge_name_set:set(judge_name_data)
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
	reward_indicator:find_actors(self:GetChild(reward_indicator.name))
	reward_indicator:set(judge_right - judge_left, reward_time)
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
		combo_graphs[v]:find_actors(self:GetChild("graphs"):GetChild(v.."_graphs"):GetChild(combo_graphs[v].name))
		score_reports[v]:find_actors(pcont:GetChild(score_reports[v].name))
		frame_helpers[v]:find_actors(pcont:GetChild(frame_helpers[v].name))
		score_reports[v].allowed_width= width
		dance_pads[v]:find_actors(pcont:GetChild(dance_pads[v].name))
		color_dance_pad_by_score(v, dance_pads[v])
		besties[v].machine:find_actors(pcont:GetChild(besties[v].machine.name))
		besties[v].machine:set(nil, v)
		besties[v].player:find_actors(pcont:GetChild(besties[v].player.name))
		besties[v].player:set(v, v)
		if #GAMESTATE:GetEnabledPlayers() == 1 then
			showing_profile_on_other_side= true
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
	end
end

local function add_column_score_to_session(pn, session_stats, col_id, col_score)
	local session_col_id= get_pad_arrow_for_col(pn, col_id)
	local sesscol= session_stats[session_col_id]
	sesscol.dp= sesscol.dp + col_score.dp
	sesscol.mdp= sesscol.mdp + col_score.mdp
	sesscol.max_combo= math.max(sesscol.max_combo, col_score.max_combo)
	for i, tim in ipairs(col_score.step_timings) do
		if sesscol.judge_counts.early[tim.judge] then
			if tnss_that_can_be_early[tim.judge] and tim.offset >= 0 then
				sesscol.judge_counts.late[tim.judge]=
					sesscol.judge_counts.late[tim.judge] + 1
			else
				sesscol.judge_counts.early[tim.judge]=
					sesscol.judge_counts.early[tim.judge] + 1
			end
		end
	end
end

local function crunch_combo_data_for_column(col)
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
			if revj >= tns_cont_combo then
				if curr_combo == 0 then
					curr_combo_start= tim.time
				end
				curr_combo= curr_combo + 1
			elseif revj < tns_maint_combo then
				end_combo(tim.time)
			end
		end
	end
	end_combo(step_timings[#step_timings].time)
	col.max_combo= max_combo
	col.combo_data= combo_data
end

local function save_column_scores(pn)
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

do
	local enabled_players= GAMESTATE:GetEnabledPlayers()
	local highest_score= 0
	local curstats= STATSMAN:GetCurStageStats()
	for i, v in ipairs(enabled_players) do
		if not GAMESTATE:IsEventMode() then
			local play_history= cons_players[v].play_history
--			Trace("Adding song to play_history with timestamp " ..
--							tostring(prev_song_start_timestamp) .. "-" ..
--							tostring(prev_song_end_timestamp))
			play_history[#play_history+1]= {
				song= gamestate_get_curr_song(), steps= gamestate_get_curr_steps(v),
				start= prev_song_start_timestamp, finish= prev_song_end_timestamp}
		end
		score_datas[v]= {}
		local pstats= curstats:GetPlayerStageStats(v)
		for i= -1, #cons_players[v].column_scores do
			score_datas[v][i]= cons_players[v].column_scores[i]
		end
		score_datas[v][-1].dp= pstats:GetActualDancePoints()
		score_datas[v][-1].mdp= pstats:GetPossibleDancePoints()
		score_datas[v][-1].max_combo= pstats:MaxCombo()
		for i, fj in ipairs(feedback_judgements) do
			score_datas[v][-1].judge_counts[fj]= pstats:GetTapNoteScores(fj)
		end
		for i, hj in ipairs(holdnote_names) do
			score_datas[v][-1].judge_counts[hj]= pstats:GetHoldNoteScores(hj)
		end
		cons_players[v].fake_score.mdp= score_datas[v][-1].mdp
		score_data_viewing_indices[v]= -1
		highest_score= math.max(highest_score,
			pstats:GetActualDancePoints() / pstats:GetPossibleDancePoints())
		--save_column_scores(v)
		add_column_score_to_session(v, cons_players[v].session_stats, -1, score_datas[v][-1])
		for ic= 0, #cons_players[v].column_scores do
			crunch_combo_data_for_column(cons_players[v].column_scores[ic])
			add_column_score_to_session(v, cons_players[v].session_stats, ic, cons_players[v].column_scores[ic])
		end
	end
	reward_time= convert_score_to_time(highest_score)
	reduce_time_remaining(-reward_time)
end

local function set_visible_score_data(pn, index)
	local function size_frame_to_report(report_container, is_profile)
		local pad= 16
		local fxmn, fxmx, fymn, fymx= rec_calc_actor_extent(report_container)
		local fw= fxmx - fxmn + pad
		local fh= fymx - fymn + pad
		local fx= fxmn + (fw / 2)
		local fy= fymn + (fh / 2)
		-- There's probably a bug in rec_calc_actor_extent....
		if is_profile then
			frame_helpers[pn]:move(fx-pad/2, fy+pad*1.75)
		else
			frame_helpers[pn]:move(fx-pad/2, fy-pad/2)
		end
		frame_helpers[pn]:resize(fw, fh)
	end
	if index == -3 then
		score_reports[pn]:set(pn, -1, cons_players[pn].fake_score)
		score_reports[pn].container:diffusealpha(1)
		size_frame_to_report(score_reports[pn].container)
		if not showing_profile_on_other_side then
			profile_reports[pn].container:diffusealpha(0)
		end
		combo_graphs[pn]:set(cons_players[pn].fake_score.step_timings)
	elseif index == -2 then
		score_reports[pn].container:diffusealpha(0)
		profile_reports[pn].container:diffusealpha(1)
		size_frame_to_report(profile_reports[pn].container, true)
	else
		score_reports[pn]:set(pn, index, score_datas[pn][index])
		score_reports[pn].container:diffusealpha(1)
		size_frame_to_report(score_reports[pn].container)
		if not showing_profile_on_other_side then
			profile_reports[pn].container:diffusealpha(0)
		end
		combo_graphs[pn]:set(score_datas[pn][index].step_timings)
	end
end

return Def.ActorFrame{
	Name= "SEd",
	InitCommand= function(self)
		find_actors(self)
	end,
	make_banner_actor(),
	make_player_specific_actors(),
	reward_indicator:create_actors("reward", SCREEN_CENTER_X, SCREEN_TOP+150),
	make_judge_name_actors(),
	make_graph_actors(),
	Def.Actor{
		Name= "Honmono dayo",
		OnCommand= function(self)
			for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
				if cons_players[pn].fake_judge then
					set_visible_score_data(pn, -3)
				else
					set_visible_score_data(pn, -1)
				end
			end
			self:sleep(5)
			self:queuecommand("ShowRealScore")
		end,
		ShowRealScoreCommand= function(self)
			for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
				if cons_players[pn].fake_judge then
					if score_data_viewing_indices[pn] == -1 then
						set_visible_score_data(pn, -1)
					end
				end
			end
		end,
	},
	Def.Actor{
		Name= "Vacuum Cleaner D27",
		InitCommand= function(self)
			self:effectperiod(2^16)
			timer_actor= self
		end,
		CodeMessageCommand= function(self, param)
			if self:GetSecsIntoEffect() < 0.25 then return end
			local code_name= param.Name
			local pn= param.PlayerNumber
			if not score_data_viewing_indices[pn] then return end
			local view_changers= { left= true, menu_left= true,
														 right= true, menu_right= true}
			if view_changers[code_name] then
				toggle_visible_indicator(pn, dance_pads[pn], score_data_viewing_indices[pn])
				if code_name == "left" or code_name == "menu_left" then
					score_data_viewing_indices[pn]= score_data_viewing_indices[pn] - 1
				elseif code_name == "right" or code_name == "menu_right" then
					score_data_viewing_indices[pn]= score_data_viewing_indices[pn] + 1
				end
				if score_data_viewing_indices[pn] < -2 then
					score_data_viewing_indices[pn]= #score_datas[pn]
				elseif (score_data_viewing_indices[pn] == -2 and
								showing_profile_on_other_side) then
					score_data_viewing_indices[pn]= #score_datas[pn]
				elseif score_data_viewing_indices[pn] > #score_datas[pn] then
					if showing_profile_on_other_side then
						score_data_viewing_indices[pn]= -1
					else
						score_data_viewing_indices[pn]= -2
					end
				end
				toggle_visible_indicator(pn, dance_pads[pn], score_data_viewing_indices[pn])
				set_visible_score_data(pn, score_data_viewing_indices[pn])
			end
		end,
		OffCommand= function(self)
			filter_bucket_songs_by_time()
		end
	}
}
