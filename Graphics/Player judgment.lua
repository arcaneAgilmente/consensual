-- Some parts copy pasted from _fallback.
local player= Var "Player"

local el_pos= cons_players[player].gameplay_element_positions

local Judgment
local tani= setmetatable({upper= true}, text_and_number_interface_mt)
local tani_params= {
	sx= el_pos.combo_xoffset or 0, sy= el_pos.combo_yoffset or 30,
	tx= 8, nx= -8, ta= left, na= right, text_section= "Combo"
}

local ShowComboAt = THEME:GetMetric("Combo", "ShowComboAt");
local Pulse = THEME:GetMetric("Combo", "PulseCommand");
local PulseLabel = THEME:GetMetric("Combo", "PulseLabelCommand");

local JudgeCmds = {}
local function set_judge_commands()
	if cons_players[player].flags.gameplay.still_judge then
		local function judge_general_effect(self)
			self:diffusealpha(1):sleep(.8):april_linear(.1):diffusealpha(0)
		end
		for i, w in ipairs{"W2", "W3", "W4", "W5", "Miss"} do
			JudgeCmds["TapNoteScore_"..w]= judge_general_effect
		end
		JudgeCmds.TapNoteScore_W1= function(self)
			self:glowblink():effectperiod(.05):effectcolor1(color("1,1,1,0"))
				:effectcolor2(color("1,1,1,0.25"))
			judge_general_effect(self)
		end
		Pulse= noop_nil
		PulseLabel= noop_nil
	else
		local function judge_general_effect(self, i)
			local jscale= el_pos.judgment_scale
			self:diffusealpha(1):zoom((1 + (.1 * (6 - i))) * jscale)
				:april_linear(.05):zoom(jscale):sleep(.8)
				:april_linear(.1):zoomy(.5 * jscale):zoomx(2 * jscale):diffusealpha(0)
		end
		for i, w in ipairs{"W2", "W3", "W4"} do
			JudgeCmds["TapNoteScore_"..w]= function(self)
				judge_general_effect(self, i + 1)
			end
		end
		JudgeCmds.TapNoteScore_W1= function(self)
			self:glowblink():effectperiod(.05):effectcolor1(color("1,1,1,0"))
				:effectcolor2(color("1,1,1,0.25"))
			judge_general_effect(self, 1)
		end
		JudgeCmds.TapNoteScore_W5= function(self)
			self:vibrate():effectmagnitude(4, 8, 8)
			judge_general_effect(self, 5)
		end
		JudgeCmds.TapNoteScore_Miss= function(self)
			local jscale= el_pos.judgment_scale
			self:diffusealpha(1):zoom(jscale):y(-20 * jscale)
				:april_linear(.8):y(20 * jscale):sleep(.8)
				:april_linear(.1):zoomy(.5 * jscale):zoomx(2 * jscale):diffusealpha(0)
		end
	end
end
set_judge_commands()

local NumberMinZoom = THEME:GetMetric("Combo", "NumberMinZoom");
local NumberMaxZoom = THEME:GetMetric("Combo", "NumberMaxZoom");
local NumberMaxZoomAt = THEME:GetMetric("Combo", "NumberMaxZoomAt");

local LabelMinZoom = THEME:GetMetric("Combo", "LabelMinZoom");
local LabelMaxZoom = THEME:GetMetric("Combo", "LabelMaxZoom");

local tns_reverse= TapNoteScore:Reverse()
local tns_opposition= {
	[tns_reverse["TapNoteScore_W1"]]= "TapNoteScore_Miss",
	[tns_reverse["TapNoteScore_W2"]]= "TapNoteScore_W5",
	[tns_reverse["TapNoteScore_W3"]]= "TapNoteScore_W4",
	[tns_reverse["TapNoteScore_W4"]]= "TapNoteScore_W3",
	[tns_reverse["TapNoteScore_W5"]]= "TapNoteScore_W2",
	[tns_reverse["TapNoteScore_Miss"]]= "TapNoteScore_W1",
	TapNoteScore_W1= "TapNoteScore_Miss",
	TapNoteScore_W2= "TapNoteScore_W5",
	TapNoteScore_W3= "TapNoteScore_W4",
	TapNoteScore_W4= "TapNoteScore_W3",
	TapNoteScore_W5= "TapNoteScore_W2",
	TapNoteScore_Miss= "TapNoteScore_W1"
}

local tns_texts= {
	TapNoteScore_W1= "Ridiculous",
	TapNoteScore_W2= "Fantastic",
	TapNoteScore_W3= "Excellent",
	TapNoteScore_W4= "Great",
	TapNoteScore_W5= "Decent",
	TapNoteScore_Miss= "Miss"
}

local tns_windows= {}
local err_tex_width= 512
local err_tex_height= 16
local herr_tex_width= err_tex_width * .5
local herr_tex_height= err_tex_height * .5
local error_width= _screen.w * .4
local herror_width= error_width * .5
local min_offset= 0
local max_offset= 0
do
	local window_scale= PREFSMAN:GetPreference("TimingWindowScale")
	local windows= {
		PREFSMAN:GetPreference("TimingWindowSecondsW1") * window_scale,
		PREFSMAN:GetPreference("TimingWindowSecondsW2") * window_scale,
		PREFSMAN:GetPreference("TimingWindowSecondsW3") * window_scale,
		PREFSMAN:GetPreference("TimingWindowSecondsW4") * window_scale,
		PREFSMAN:GetPreference("TimingWindowSecondsW5") * window_scale,
		PREFSMAN:GetPreference("TimingWindowSecondsW5") * window_scale*1.25,
	}
	local tns_to_window= {}
	for i= 1, 5 do
		local tns_name= "TapNoteScore_W"..i
		tns_to_window[tns_name]= windows[i]
		tns_windows[i]= {windows[i], tns_name}
	end
	local error_window_name= cons_players[player].error_history_threshold
	local error_window= windows[6]
	if tns_to_window[error_window_name] then
		error_window= tns_to_window[error_window_name]
	end
	min_offset= -error_window
	max_offset= error_window
	tns_windows.TapNoteScore_W1= {0, windows[1]}
	tns_windows.TapNoteScore_W2= {windows[1], windows[2]}
	tns_windows.TapNoteScore_W3= {windows[2], windows[3]}
	tns_windows.TapNoteScore_W4= {windows[3], windows[4]}
	tns_windows.TapNoteScore_W5= {windows[4], windows[5]}
	tns_windows.TapNoteScore_Miss= {windows[5], windows[6]}
end

local function offset_to_judge(offset)
	local aboff= math.abs(offset)
	for i= 1, #tns_windows do
		if aboff <= tns_windows[i][1] then return tns_windows[i][2] end
	end
	return "TapNoteScore_Miss"
end

local judge_colors= fetch_color("judgment")
local dark_judge_colors= {}
local bright_judge_colors= {}
for name, c in pairs(judge_colors) do
	dark_judge_colors[name]= adjust_luma(c, .5)
	bright_judge_colors[name]= adjust_luma(c, 2)
end
local def_col= fetch_color("text")

local function fjtc(j)
	return judge_colors[j] or def_col
end
local function offset_to_color(offset)
	return bright_judge_colors[offset_to_judge(offset)] or def_col
end
local function offset_to_dark_color(offset)
	return dark_judge_colors[offset_to_judge(offset)] or def_col
end

local function scale_off(offset, min, max)
	return scale(clamp(offset, min_offset, max_offset), min_offset, max_offset,
							 min, max)
end
local function offset_to_x(offset)
	return scale_off(offset, 0, err_tex_width)
end
local function offset_to_w(offset)
	return scale_off(offset, -herror_width, herror_width)
end

local error_history_size= cons_players[player].error_history_size
local history_alpha= 0
if error_history_size > 0 then
	history_alpha= .25^(1 / error_history_size)
end
local error_bar_mt= {
	__index= {
		create_actors= function(self)
			return Def.ActorFrame{
				InitCommand= function(subself)
					self.container= subself
				end,
				player_flags_changedMessageCommand= function(subself, param)
					if param.pn ~= player then return end
					if param.name ~= "error_bar" then return end
					if cons_players[player].flags.gameplay.error_bar then
						self.hidden= false
						self.container:hibernate(0)
					else
						self.hidden= true
						self.container:hibernate(math.huge)
					end
				end,
				Def.ActorFrame{
					InitCommand= function(subself)
						subself:hibernate(math.huge)
					end,
					Def.ActorFrameTexture{
						InitCommand= function(subself)
							self.prev_frame_aft= subself
							subself:setsize(err_tex_width, err_tex_height)
								:EnableAlphaBuffer(true):Create()
								:EnablePreserveTexture(false)
								:Draw()
							self.prev_frame_tex= subself:GetTexture()
							self.prev_frame_sprite:visible(true)
						end,
						Def.Sprite{
							InitCommand= function(subself)
								self.prev_frame_sprite= subself
								subself:xy(herr_tex_width, herr_tex_height):visible(false)
									:setsize(err_tex_width, err_tex_height)
							end
						}
					},
					Def.ActorFrameTexture{
						InitCommand= function(subself)
							self.aft= subself
							subself:setsize(err_tex_width, 16)
								:EnableAlphaBuffer(true):Create()
								:EnablePreserveTexture(false)
								:Draw()
							self.texture= subself:GetTexture()
							self.prev_frame_sprite:SetTexture(self.texture)
							self.past_error:visible(true)
							self.curr_error:visible(true)
						end,
						Def.Sprite{
							InitCommand= function(subself)
								self.past_error= subself
								subself:xy(herr_tex_width, herr_tex_height):visible(false)
									:setsize(err_tex_width, err_tex_height)
									:diffusealpha(history_alpha)
									:SetTexture(self.prev_frame_tex)
							end
						},
						Def.Quad{
							InitCommand= function(subself)
								self.curr_error= subself
								subself:xy(herr_tex_width, 8):setsize(1, 16):visible(false)
							end
						}
					},
				},
				Def.Sprite{
					InitCommand= function(subself)
						self.cum_error= subself
						subself:SetTexture(self.texture)
					end
				},
				Def.Quad{
					InitCommand= function(subself)
						self.recent_error= subself:horizalign(left)
					end
				},
			}
		end,
		add_error= function(self, offset)
			self.recent_error:SetWidth(offset_to_w(offset))
				:diffuse(offset_to_color(offset))
			self.curr_error:x(offset_to_x(offset))
				:diffuse(offset_to_dark_color(offset))
			self.prev_frame_aft:Draw()
			self.aft:Draw()
		end,
		set_pos_scale= function(self, x, y, s)
			self.container:xy(x, y)
			self.cum_error:xy(0, 8 * s):setsize(error_width, 16 * s)
			self.recent_error:xy(0, 8 * s):setsize(0, 8 * s)
		end,
}}
local errbar= setmetatable({}, error_bar_mt)

local non_mine_tnses= {
	TapNoteScore_W1= true,
	TapNoteScore_W2= true,
	TapNoteScore_W3= true,
	TapNoteScore_W4= true,
	TapNoteScore_W5= true,
	TapNoteScore_Miss= true,
	TapNoteScore_CheckpointHit= true,
	TapNoteScore_CheckpointMiss= true,
}

local tns_values= {}
local function add_value_set(enum_table)
	for i, tns in ipairs(enum_table) do
		local metric_name= "PercentScoreWeight" .. ToEnumShortString(tns)
		if metric_name ~= "PercentScoreWeightNone" then
			local value= THEME:GetMetric("ScoreKeeperNormal", metric_name)
			tns_values[tns]= value
		end
	end
end
add_value_set(TapNoteScore)
add_value_set(HoldNoteScore)

local tns_reverse= TapNoteScore:Reverse()
local tns_cont_combo= tns_cont_combo()
local tns_maint_combo= tns_maint_combo()
local tns_inc_miss_combo= tns_reverse[THEME:GetMetric("Gameplay", "MaxScoreToIncrementMissCombo")]

local prev_combo= -1

local function get_seconds()
	return STATSMAN:GetCurStageStats():GetStepsSeconds()
end

local function add_to_col(col_score, judge, max_value, offset)
	local step_value= tns_values[judge]
	if not step_value then return end
	col_score.dp= col_score.dp + step_value
	col_score.mdp= col_score.mdp + max_value
	col_score.judge_counts[judge]= col_score.judge_counts[judge] + 1
	col_score.step_timings[#col_score.step_timings+1]= {
		time= get_seconds(), judge= judge, offset= offset}
end

local function add_tn_to_col(col_score, tapnote, max_value)
	add_to_col(col_score, tapnote:GetTapNoteResult():GetTapNoteScore(),
						 max_value, tapnote:GetTapNoteResult():GetTapNoteOffset())
end

local function set_combo_stuff(param)
	local toast= cons_players[player].toasty
	if toast then
		toast.remaining= toast.remaining - 1
		toast.progress= toast.progress + 1
		if toast.remaining <= 0 then
			cons_players[player].toasty= nil
		end
	end
	local combo= param.Misses or param.Combo
	if not combo or combo < ShowComboAt then
		tani:hide()
		return
	end
	tani:unhide()
	local label_text= ""
	if param.Combo then
		label_text= "Combo"
	else
		label_text= "Misses"
	end
	local wombo= combo
	local combo_qual= cons_players[player].combo_quality
	if toast and toast.remaining > 0 then
		wombo= toast.progress
		label_text= "Misses"
	end
	tani:set_text(label_text)
	--tani:set_number(wordify_number(wombo))
	tani:set_number(("%i"):format(wombo))
	if combo_qual then
		if combo_qual.worst_tns then
			local color= fjtc(combo_qual.worst_tns)
			if toast and toast.remaining > 0 then
				color= fjtc(toast.judge)
			end
			if color then
				tani.text:diffuse(color)
				tani.number:diffuse(color)
			end
		end
	end
	param.Zoom= scale(combo, 0, NumberMaxZoomAt, NumberMinZoom, NumberMinZoom)
	param.Zoom= clamp(param.Zoom, NumberMinZoom, NumberMaxZoom)
	param.LabelZoom= scale(combo, 0, NumberMaxZoomAt, LabelMinZoom, LabelMaxZoom)
	Pulse(tani.number, param)
	PulseLabel(tani.text, param)
end

local function disp_offset_from_judge(judge)
	local width= tns_windows[judge][2] - tns_windows[judge][1]
	local offset= tns_windows[judge][1] + (width * MersenneTwister.Random())
	if MersenneTwister.Random() > .5 then
		offset= offset * -1
	end
	return offset
end

local judgment_conf_names= {
	judgment= true, combo= true, error_bar= true,
}

local function set_display_judgment(disp_judge, disp_offset)
	local text= tns_texts[disp_judge]
	if text then
		if cons_players[player].flags.gameplay.error_bar then
			errbar:add_error(disp_offset)
		end
		Judgment:playcommand("Reset")
			:settext(get_string_wrapper("JudgementNames", text):upper())
			:diffuse(fjtc(disp_judge))
			:visible(true)
		JudgeCmds[disp_judge](Judgment)
	end
end

local args= {
	Name= "Judgement",
	InitCommand= function(self)
		if newskin_available() then
			self:draworder(newfield_draw_order.under_field)
		end
	end,
	Def.ActorFrame{
	normal_text(
		"Judgment", "", nil, fetch_color("gameplay.text_stroke"), 0, 0, 1,
		center, {
			ResetCommand= cmd(xy,0,0;finishtweening;stopeffect;visible,false)}),
	tani:create_actors("tani", tani_params),
	errbar:create_actors(),
	InitCommand= function(self)
		Judgment= self:GetChild("Judgment")
		Judgment:visible(false):zoom(el_pos.judgment_scale)
		tani:hide()
		tani.container:zoom(el_pos.combo_scale)
		tani.text:strokecolor(fetch_color("gameplay.text_stroke"))
		tani.number:strokecolor(fetch_color("gameplay.text_stroke"))
		tani.number:wrapwidthpixels((_screen.cx / el_pos.combo_scale) - 16)
		self:playcommand("gameplay_conf_changed", {pn= player, thing= next(judgment_conf_names)})
	end,
	ToastyAchievedMessageCommand= function(self,params)
		if params.PlayerNumber == player then
			--Trace("ToastyAchievedMessageCommand params:")
			--rec_print_table(params)
			if cons_players[player].flags.gameplay.allow_toasty then
				cons_players[player].toasty= {
					judge= "TapNoteScore_Miss", remaining= 5, progress= 0 }
			end
		end
	end,
	player_flags_changedMessageCommand= function(self, param)
		if param.pn ~= player then return end
		if param.name ~= "still_judge" then return end
		set_judge_commands()
		Judgment:zoom(el_pos.judgment_scale)
		set_display_judgment("TapNoteScore_W1", .0215)
	end,
	gameplay_conf_changedMessageCommand= function(self, param)
		if param.pn ~= player then return end
		if not judgment_conf_names[param.thing] then return end
		self:xy(el_pos.judgment_xoffset, el_pos.judgment_yoffset)
		tani:move_to(el_pos.combo_xoffset, el_pos.combo_yoffset)
		tani.container:zoom(el_pos.combo_scale)
		Judgment:zoom(el_pos.judgment_scale)
		set_display_judgment("TapNoteScore_W1", .0215)
		errbar:set_pos_scale(el_pos.error_bar_xoffset, el_pos.error_bar_yoffset, el_pos.error_bar_scale)
	end,
	JudgmentMessageCommand=
		function(self, param)
			if param.Player ~= player then return end
			local fake_judge= cons_players[player].fake_judge
			local fake_score= cons_players[player].fake_score
			local stage_stats= cons_players[player].stage_stats
			if true_gameplay then
				local max_step_value= 0
				if param.HoldNoteScore then
					max_step_value= tns_values.HoldNoteScore_Held
				elseif param.TapNoteScore then
					if non_mine_tnses[param.TapNoteScore] then
						max_step_value= tns_values.TapNoteScore_W1
					end
				end
				local taps= param.Notes
				local holds= param.Holds
				local col_scores= cons_players[player].column_scores
				if taps and col_scores then
					add_to_col(col_scores[0], param.TapNoteScore, max_step_value, param.TapNoteOffset)
					local function add_set(set)
						for track, tapnote in pairs(set) do
							add_tn_to_col(col_scores[track], tapnote, max_step_value)
						end
					end
					if taps then add_set(taps) end
				end
				if param.HoldNoteScore and col_scores then
					add_to_col(col_scores[0], param.HoldNoteScore, max_step_value)
					add_to_col(col_scores[param.FirstTrack+1], param.HoldNoteScore, max_step_value)
				end
			end
			if param.HoldNoteScore then
				if not tns_values[param.HoldNoteScore] then
					Trace("tns_values for " .. param.HoldNoteScore .. " is nil.")
				end
				if fake_judge then
					if fake_judge()  ~= "TapNoteScore_Miss" then
						fake_score.dp= fake_score.dp + tns_values.HoldNoteScore_Held
						fake_score.HoldNoteScore_Held=
							(fake_score.HoldNoteScore_Held or 0) + 1
					else
						fake_score.dp= fake_score.dp + tns_values.HoldNoteScore_LetGo
						fake_score.HoldNoteScore_LetGo=
							(fake_score.HoldNoteScore_LetGo or 0) + 1
					end
				else
					fake_score[param.HoldNoteScore]=
						(fake_score[param.HoldNoteScore] or 0) + 1
					fake_score.dp= fake_score.dp + tns_values[param.HoldNoteScore]
				end
				return
			end
			local this_tns= param.TapNoteScore
			if this_tns == "TapNoteScore_CheckpointHit"
				or this_tns == "TapNoteScore_CheckpointMiss" then
				if fake_judge and fake_judge() ~= "TapNoteScore_Miss" then
					fake_score.dp= fake_score.dp + tns_values.TapNoteScore_CheckpointHit
				else
					fake_score.dp= fake_score.dp + tns_values.TapNoteScore_CheckpointMiss
				end
				return
			end
			if this_tns == "TapNoteScore_HitMine"
				or this_tns == "TapNoteScore_AvoidMine"
				or this_tns == "TapNoteScore_None" then return end
			local firsts= stage_stats.firsts
			if firsts then
				if not firsts[this_tns] then
					firsts[this_tns]= get_seconds()
				end
			end
			local disp_judge= this_tns
			local disp_offset= param.TapNoteOffset
			if fake_judge then
				disp_judge= fake_judge()
				disp_offset= disp_offset_from_judge(disp_judge)
				fake_score.judge_counts[disp_judge]=
					fake_score.judge_counts[disp_judge] + 1
				fake_score.dp= fake_score.dp + tns_values[disp_judge]
				fake_score.step_timings[#fake_score.step_timings+1]= {
					time= get_seconds(), judge= disp_judge, offset= disp_offset}
			end
			local rev_disp= tns_reverse[disp_judge]
			if fake_score.combo_is_misses then
				if rev_disp <= tns_inc_miss_combo then
					fake_score.combo= (fake_score.combo or 0) + 1
				elseif rev_disp >= tns_cont_combo then
					fake_score.combo= 1
					fake_score.combo_is_misses= false
				end
			else
				if rev_disp < tns_maint_combo then
					fake_score.combo= 0
					if rev_disp <= tns_inc_miss_combo then
						fake_score.combo= 1
						fake_score.combo_is_misses= true
					end
				elseif rev_disp >= tns_cont_combo then
					fake_score.combo= (fake_score.combo or 0) + 1
				end
			end
			if cons_players[player].toasty then
				disp_judge= cons_players[player].toasty.judge
				disp_offset= disp_offset_from_judge(disp_judge)
			end
			local combo_qual= cons_players[player].combo_quality
			if combo_qual then
				local prev_worst= combo_qual.worst_tns
				if prev_worst then
					combo_qual.worst_tns= math.min(rev_disp, prev_worst)
				else
					combo_qual.worst_tns= rev_disp
				end
				if not prev_worst or rev_disp < prev_worst or
					-- starting a new combo.
					(prev_worst < tns_maint_combo and rev_disp >= tns_cont_combo)
				then
					combo_qual.worst_tns= rev_disp
				end
			end
			set_display_judgment(disp_judge, disp_offset)
			if fake_judge then
				if fake_score.combo_is_misses then
					set_combo_stuff({Misses= fake_score.combo})
				else
					set_combo_stuff({Combo= fake_score.combo})
				end
			end
		end,
	ComboCommand= function(self, param)
		if prev_combo == -1 then
			prev_combo= math.floor((param.Combo or 0) / 1000) * 1000
		end
		if param.Combo then
			if param.Combo >= prev_combo + 1000 then
				prev_combo= math.floor(param.Combo / 1000) * 1000
				if cons_players[player].flags.gameplay.combo_confetti then
					activate_confetti("combo", true, player)
				end
			end
		else
			prev_combo= 0
		end
		if not cons_players[player].fake_judge then
			set_combo_stuff(param)
		end
	end,
	},
}
args[1].OnCommand= THEME:GetMetric("Judgment", "JudgmentOnCommand")

return Def.ActorFrame(args)
