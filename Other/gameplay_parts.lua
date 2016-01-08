line_spacing= 24
h_line_spacing= line_spacing / 2

game_text= fetch_color("text")
game_stroke= fetch_color("gameplay.text_stroke")

dofile(THEME:GetPathO("", "sigil.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))
dofile(THEME:GetPathO("", "nps_counter.lua"))

local function is_gameplay_screen(screen)
	if screen.PauseGame then return true end
end

local function feedback_general_init(self, name, decor_center, pn)
	self.name= name
	self.pn= pn
	self.decor_center= decor_center
end

local function add_conf_messages(self, frame, name)
	frame.gameplay_conf_changedMessageCommand= function(subself, param)
		if param.pn == self.pn and param.thing == name then
			self:update_config(true)
		end
	end
	frame.player_flags_changedMessageCommand= function(subself, param)
		if param.pn == self.pn and param.name == name then
			self:update_flag()
		end
	end
end

local function over_confident(pn)
	return cons_players[pn].confidence and cons_players[pn].confidence >= 50
end

local function general_flag_check(self, flag)
	if flag then
		self.hidden= false
		self.container:hibernate(0)
		self:update_config()
	else
		self.hidden= true
		self.container:hibernate(math.huge)
	end
end

sigil_feedback_mt= {
	__index= {
		create_actors= function(self, name, decor_center, pn)
			if not name then return nil end
			feedback_general_init(self, name, decor_center, pn)
			local player_data= cons_players[pn].sigil_data
			-- Initial data should ensure that all actors get updated the first frame.
			self.prev_state= { detail= player_data.detail, fill_amount= 1}
			self.sigil= setmetatable({}, sigil_controller_mt)
			local frame= Def.ActorFrame{
				InitCommand= function(subself)
					self.container= subself
					self:update_flag()
					self:update_config()
				end,
				self.sigil:create_actors(name, 0, 0, pn_to_color(pn), 4, 150),
			}
			add_conf_messages(self, frame, "sigil")
			return frame
		end,
		demo_update= function(self)
			self:score_update(1)
		end,
		score_update= function(self, score)
			local new_detail= math.max(1, math.round(self.sigil.max_detail * ((score - .5) * 2)))
			self.sigil:set_goal_detail(new_detail)
			self.prev_state.detail= new_detail
			self.prev_state.fill_amount= life
		end,
		update= function(self, player_stage_stats)
			if self.hidden then return end
			local pstats= player_stage_stats
			local life= pstats:GetCurrentLife()
			local adp= pstats:GetActualDancePoints()
			if cons_players[self.pn].fake_judge then
				adp= cons_players[self.pn].fake_score.dp
			end
			local pdp= pstats:GetCurrentPossibleDancePoints()
			local score= adp / pdp
			if pdp == 0 then
				score= 1
			end
			score_update(score)
		end,
		update_flag= function(self)
			general_flag_check(self, cons_players[self.pn].flags.gameplay.sigil)
		end,
		update_config= function(self, force)
			local pn= self.pn
			local flags= cons_players[pn].flags.gameplay
			if flags.sigil then
				local el_pos= cons_players[pn].gameplay_element_positions
				local dec_cen= self.decor_center
				self.container:xy(dec_cen[1] + el_pos.sigil_xoffset, dec_cen[2] + el_pos.sigil_yoffset)
				self.sigil:recalc_size_and_max_detail(
					150 * el_pos.sigil_scale, cons_players[pn].sigil_data.detail, force)
			end
		end,
}}

judge_feedback_mt= {
	__index= {
		create_actors= function(self, name, decor_center, pn)
			if not name then return nil end
			feedback_general_init(self, name, decor_center, pn)
			self.elements= {}
			local args= {
				Name= name,
				InitCommand= function(subself)
					self.container= subself
					for i, tani in ipairs(self.elements) do
						tani.text:strokecolor(game_stroke)
						tani.number:strokecolor(game_stroke)
					end
					self:update_flag()
					self:update_config()
				end
			}
			for n= 1, #feedback_judgements do
				local new_element= {}
				setmetatable(new_element, text_and_number_interface_mt)
				args[#args+1]= new_element:create_actors(
					feedback_judgements[n], {
						tc= judge_to_color(feedback_judgements[n]),
						nc= judge_to_color(feedback_judgements[n]),
						text_section= "JudgementNames",
						tt= feedback_judgements[n]})
				self.elements[#self.elements+1]= new_element
			end
			add_conf_messages(self, args, "judge_list")
			return Def.ActorFrame(args)
		end,
		demo_update= function(self)
			for i, ele in ipairs(self.elements) do
				ele:set_number(1000)
			end
		end,
		update= function(self, player_stage_stats)
			if self.hidden then return end
			if cons_players[self.pn].fake_judge then
				local fake_score= cons_players[self.pn].fake_score
				for n= 1, #self.elements do
					local ele= self.elements[n]
					ele:set_number(fake_score.judge_counts[ele.name])
				end
			else
				for n= 1, #self.elements do
					local ele= self.elements[n]
					ele:set_number(player_stage_stats:GetTapNoteScores(ele.name))
				end
			end
		end,
		update_flag= function(self)
			general_flag_check(self, cons_players[self.pn].flags.gameplay.judge_list and not over_confident(self.pn))
		end,
		update_config= function(self, force)
			if not self.hidden then
				local el_pos= cons_players[self.pn].gameplay_element_positions
				self.container:xy(self.decor_center[1] + el_pos.judge_list_xoffset, self.decor_center[2] + el_pos.judge_list_yoffset)
				local scale= el_pos.judge_list_scale
				local judge_spacing= scale * line_spacing
				local start_y= 0
				local tx= -10 * scale
				local nx= 10 * scale
				for n, ele in ipairs(self.elements) do
					ele:move_to(0, start_y + judge_spacing * n)
					ele.text:x(tx):zoom(scale)
					ele.number:x(nx):zoom(scale)
				end
			end
		end,
}}

bpm_feedback_mt= {
	__index= {
		create_actors= function(self, name, decor_center, pn)
			feedback_general_init(self, name, decor_center, pn)
			self.tani= setmetatable({}, text_and_number_interface_mt)
			local scale= cons_players[pn].gameplay_element_positions.bpm_scale
			local tanarg= {tx=-4,nx=4,tt="BPM: ",text_section="ScreenGameplay"}
			local frame= Def.ActorFrame{
				Name= self.name, InitCommand= function(subself)
					self.container= subself
					self.tani.text:strokecolor(game_stroke)
					self.tani.number:strokecolor(game_stroke)
					self:update_flag()
					self:update_config()
				end,
				self.tani:create_actors("tani", tanarg),
			}
			add_conf_messages(self, frame, "bpm")
			return frame
		end,
		demo_update= function(self)
			self.tani:set_number(999)
		end,
		update= function(self)
			if self.hidden then return end
			local bpm= SCREENMAN:GetTopScreen():GetTrueBPS(self.pn) * 60
			self.tani:set_number(("%.0f"):format(bpm))
		end,
		update_flag= function(self)
			general_flag_check(self, cons_players[self.pn].flags.gameplay.bpm)
		end,
		update_config= function(self, force)
			if not self.hidden then
				local el_pos= cons_players[self.pn].gameplay_element_positions
				self.container:xy(self.decor_center[1] + el_pos.bpm_xoffset, self.decor_center[2] + el_pos.bpm_yoffset)
				self.tani.text:zoom(el_pos.bpm_scale)
				self.tani.number:zoom(el_pos.bpm_scale)
			end
		end,
}}

local score_meter_centers= {
	[PLAYER_1]= { SCREEN_LEFT + 32, SCREEN_BOTTOM },
	[PLAYER_2]= { SCREEN_RIGHT - 32, SCREEN_BOTTOM }
}
score_meter_mt= {
	__index= {
		create_actors= function(self, name, decor_center, pn)
			if not name then return nil end
			self.name= name
			self.pn= pn
			self.parts= {}
			local frame_args= {
				Name= name, InitCommand= function(subself)
					subself:xy(score_meter_centers[pn][1], score_meter_centers[pn][2])
					self.container= subself
					self:update_flag()
					self:update_config(true)
				end,
			}
			add_conf_messages(self, frame_args, "score_meter")
			local zooms= {1, -1}
			for i= 1, 2 do
				frame_args[#frame_args+1]= Def.Quad{
					InitCommand= function(subself)
						self.parts[i]= subself
						subself:setsize(8, SCREEN_BOTTOM):vertalign(bottom)
							:horizalign(right):zoomx(zooms[i])
					end
				}
			end
			local grades= grade_config:get_data()
			for i, g in ipairs(grades) do
				frame_args[#frame_args+1]= Def.Quad{
					InitCommand= function(subself)
						local y= -_screen.h * self:pct_to_zoom(g)
						local c= percent_to_color(g)
						subself:setsize(16, 1):xy(0, y):diffuse(c)
					end
				}
			end
			return Def.ActorFrame(frame_args)
		end,
		pct_to_zoom= function(self, p)
			return math.min(1, p^((p+1)^((p*2.718281828459045))))
		end,
		demo_update= function(self)
			self:set_color{1, 1, 1, 1}
			self:score_update(1)
		end,
		score_update= function(self, score)
			if score < 0 then
				score= -score
				self.container:y(0)
				self:align_parts(top)
			else
				self.container:y(_screen.h)
				self:align_parts(bottom)
			end
			self:zoom_parts(self:pct_to_zoom(score))
		end,
		update= function(self, player_stage_stats)
			if self.hidden then return end
			local adp= player_stage_stats:GetActualDancePoints()
			local mdp= player_stage_stats:GetPossibleDancePoints()
			local fake_score
			if cons_players[self.pn].fake_judge then
				fake_score= cons_players[self.pn].fake_score
				adp= fake_score.dp
			end
			local score= adp / mdp
			if fake_score then
				for i= #feedback_judgements, 1, -1 do
					local fj= feedback_judgements[i]
					if fake_score.judge_counts[fj] > 0 then
						self:set_color(judge_to_color(fj))
						break
					end
				end
			else
				for i= #feedback_judgements, 1, -1 do
					local fj= feedback_judgements[i]
					if player_stage_stats:GetTapNoteScores(fj) > 0 then
						self:set_color(judge_to_color(fj))
						break
					end
				end
			end
			self:score_update(score)
		end,
		update_flag= function(self)
			general_flag_check(self, cons_players[self.pn].flags.gameplay.score_meter and not over_confident(self.pn))
		end,
		update_config= function(self, force)
		end,
		set_color= function(self, c)
			local calpha= Alpha(c, 0)
			for i, part in ipairs(self.parts) do
				part:diffuseleftedge(c):diffuserightedge(calpha)
			end
		end,
		align_parts= function(self, align)
			for i, part in ipairs(self.parts) do
				part:vertalign(align)
			end
		end,
		zoom_parts= function(self, z)
			for i, part in ipairs(self.parts) do
				part:zoomy(z)
			end
		end
}}

local numerical_score_flags= {
	dance_points= true, pct_score= true, subtractive_score= true,
}

numerical_score_feedback_mt= {
	__index= {
		create_actors= function(self, name, decor_center, pn)
			feedback_general_init(self, name, decor_center, pn)
			local flags= cons_players[pn].flags.gameplay
			local scale= cons_players[pn].gameplay_element_positions.score_scale
			local dp_parts_pad= 10
			local dp_parts_pad_dub= dp_parts_pad * 2
			self.fmat= "%.2f%%"
			local args= {
				Name= name, InitCommand= function(subself)
					self.container= subself
					self:update_flag()
					self:update_config(true)
				end,
				gameplay_conf_changedMessageCommand= function(subself, param)
					if param.pn == self.pn and param.thing == "score" then
						self:update_config(true)
					end
				end,
				player_flags_changedMessageCommand= function(subself, param)
					if param.pn == self.pn and numerical_score_flags[param.name] then
						self:update_flag()
					end
				end,
				OnCommand= function(subself)
					local mdp= 10000
					if is_gameplay_screen(SCREENMAN:GetTopScreen():GetName()) then
						mdp= STATSMAN:GetCurStageStats():GetPlayerStageStats(self.pn):GetPossibleDancePoints()
					end
					self.precision= math.max(
						2, math.ceil(math.log(mdp) / math.log(10))-2)
					self.fmat= "%." .. self.precision .. "f%%"
					-- maximum width for the pct will be -222%
					self.pct:settext(self.fmat:format(-222))
					self.max_dp:settext(mdp)
					local pad= 16
					-- add the width the scored dp will have.
					local dp_width= (self.max_dp:GetWidth() * 2) + dp_parts_pad_dub
					-- maximum width for the pct will be -222%
					self.pct:settext(self.fmat:format(-222))
					local pct_width= self.pct:GetWidth()
					local total_width= dp_width + pct_width + pad
					local pct_x= total_width / 2
					self.pct_container:x(pct_x)
					self.dp_container:x(pct_x - pct_width - pad - (dp_width/2))
					self.pct:settext(self.fmat:format(0))
					self.sub_pct:settext(self.fmat:format(0))
				end
			}
			local dp_args= {
				Name= "dp", InitCommand= function(subself)
					self.dp_container= subself
					self.curr_dp= subself:GetChild("curr_dp")
					self.slash_dp= subself:GetChild("slash_dp")
					self.max_dp= subself:GetChild("max_dp")
					self.sub_dp= subself:GetChild("sub_dp")
				end,
				normal_text(
					"curr_dp", "0", game_text, game_stroke, -dp_parts_pad, 0, 1, right),
				normal_text(
					"slash_dp", "/", game_text, game_stroke, 0, 0, 1),
				normal_text(
					"max_dp", "0", game_text, game_stroke, dp_parts_pad, 0, 1, left),
			}
			dp_args[#dp_args+1]= normal_text(
					"sub_dp", "0", game_text, game_stroke, dp_parts_pad, 24, 1, left)
			args[#args+1]= Def.ActorFrame(dp_args)
			local pct_args= {
				Name= "pct", InitCommand= function(subself)
					self.pct_container= subself
					self.pct= subself:GetChild("pct")
					self.sub_pct= subself:GetChild("sub_pct")
				end,
				normal_text("pct", "", game_text, game_stroke, 0, 0, 1, right),
			}
			pct_args[#pct_args+1]= normal_text("sub_pct", "", game_text, game_stroke, 0, 24, 1, right)
			args[#args+1]= Def.ActorFrame(pct_args)
			return Def.ActorFrame(args)
		end,
		pct_round= function(self, pct)
			return math.floor(pct * (10^(self.precision+2))) * (10^-self.precision)
		end,
		update= function(self, pss)
			if self.hidden then return end
			local adp= pss:GetActualDancePoints()
			local mdp= pss:GetPossibleDancePoints()
			local cdp= pss:GetCurrentPossibleDancePoints()
			local fake_score
			if cons_players[self.pn].fake_judge then
				fake_score= cons_players[self.pn].fake_score
				adp= fake_score.dp
			end
			local missed_points= cdp - adp
			local text_color= game_text
			if fake_score then
				for i= #feedback_judgements, 1, -1 do
					local fj= feedback_judgements[i]
					if fake_score.judge_counts[fj] > 0 then
						text_color= judge_to_color(fj)
						break
					end
				end
			else
				for i= #feedback_judgements, 1, -1 do
					local fj= feedback_judgements[i]
					if pss:GetTapNoteScores(fj) > 0 then
						text_color= judge_to_color(fj)
						break
					end
				end
			end
			local pct= self:pct_round(adp/mdp)
			local sub_pct= self:pct_round((mdp - missed_points) / mdp)
			self.pct:settext(self.fmat:format(pct)):diffuse(text_color)
			self.sub_pct:settext(self.fmat:format(sub_pct)):diffuse(text_color)
			self.curr_dp:settext(adp):diffuse(text_color)
			self.max_dp:settext(mdp):diffuse(text_color)
			self.sub_dp:settext(mdp-missed_points):diffuse(text_color)
		end,
		update_flag= function(self)
			local something_showing= false
			local flags= cons_players[self.pn].flags.gameplay
			self.dp_container:visible(flags.dance_points)
			self.pct_container:visible(flags.pct_score)
			self.sub_dp:visible(flags.subtractive_score)
			self.sub_pct:visible(flags.subtractive_score)
			if flags.dance_points or flags.pct_score or flags.subtractive_score then
				self.hidden= false
				self.container:hibernate(0)
			else
				self.hidden= true
				self.container:hibernate(math.huge)
			end
		end,
		update_config= function(self)
			if not self.hidden then
				local el_pos= cons_players[self.pn].gameplay_element_positions
				self.container:xy(self.decor_center[1] + el_pos.score_xoffset, self.decor_center[2] + el_pos.score_yoffset):zoom(el_pos.score_scale)
			end
		end,
}}
