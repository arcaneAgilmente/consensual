-- Some parts copy pasted from _fallback.
local player= Var "Player"

local Judgment
local tani= setmetatable({upper= true}, text_and_number_interface_mt)
local tani_params= {
	sy= cons_players[player].combo_offset, tx= 8, nx= -8, ta= left, na= right, text_section= "Combo"
}
local OffsetQuad

local JudgeCmds = {
	TapNoteScore_W1 = THEME:GetMetric( "Judgment", "JudgmentW1Command" );
	TapNoteScore_W2 = THEME:GetMetric( "Judgment", "JudgmentW2Command" );
	TapNoteScore_W3 = THEME:GetMetric( "Judgment", "JudgmentW3Command" );
	TapNoteScore_W4 = THEME:GetMetric( "Judgment", "JudgmentW4Command" );
	TapNoteScore_W5 = THEME:GetMetric( "Judgment", "JudgmentW5Command" );
	TapNoteScore_Miss = THEME:GetMetric( "Judgment", "JudgmentMissCommand" );
};

local ShowComboAt = THEME:GetMetric("Combo", "ShowComboAt");
local Pulse = THEME:GetMetric("Combo", "PulseCommand");
local PulseLabel = THEME:GetMetric("Combo", "PulseLabelCommand");

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
	TapNoteScore_W1= "Fantastic",
	TapNoteScore_W2= "Excellent",
	TapNoteScore_W3= "Great",
	TapNoteScore_W4= "Decent",
	TapNoteScore_W5= "Wayoff",
	TapNoteScore_Miss= "Miss"
}

local tns_windows= {}
local offset_scaler= 0
do
	local windows= {
		PREFSMAN:GetPreference("TimingWindowSecondsW1"),
		PREFSMAN:GetPreference("TimingWindowSecondsW2"),
		PREFSMAN:GetPreference("TimingWindowSecondsW3"),
		PREFSMAN:GetPreference("TimingWindowSecondsW4"),
		PREFSMAN:GetPreference("TimingWindowSecondsW5"),
		PREFSMAN:GetPreference("TimingWindowSecondsW5")*1.25,
	}
	offset_scaler= (SCREEN_WIDTH / 4) / windows[5]
	tns_windows.TapNoteScore_W1= {0, windows[1]}
	tns_windows.TapNoteScore_W2= {windows[1], windows[2]}
	tns_windows.TapNoteScore_W3= {windows[2], windows[3]}
	tns_windows.TapNoteScore_W4= {windows[3], windows[4]}
	tns_windows.TapNoteScore_W5= {windows[4], windows[5]}
	tns_windows.TapNoteScore_Miss= {windows[5], windows[6]}
end

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
local tns_cont_combo= tns_reverse[THEME:GetMetric("Gameplay", "MinScoreToContinueCombo")]
local tns_maint_combo= tns_reverse[THEME:GetMetric("Gameplay", "MinScoreToMaintainCombo")]
local tns_inc_miss_combo= tns_reverse[THEME:GetMetric("Gameplay", "MaxScoreToIncrementMissCombo")]

local prev_combo= -1

local get_seconds= function() return 0 end
-- GetStepsSeconds is recently added, in an attempt to make life and combo
-- graphs match better.
if StageStats.GetStepsSeconds then
	get_seconds= function()
		return STATSMAN:GetCurStageStats():GetStepsSeconds()
	end
else
	get_seconds= function()
		return GAMESTATE:GetCurMusicSeconds()
	end
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
	tani:set_number(("%i"):format(wombo))
	if combo_qual then
		if combo_qual.worst_tns then
			local color= judge_to_color(combo_qual.worst_tns)
			if toast and toast.remaining > 0 then
				color= judge_to_color(toast.judge)
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

local args= {
	Name= "Judgement",
	normal_text(
		"Judgment", "", nil, fetch_color("gameplay.text_stroke"), 0, 0, 1,
		center, {
			ResetCommand= cmd(xy,0,0;finishtweening;stopeffect;visible,false)}),
	tani:create_actors("tani", tani_params),
	Def.Quad{
		Name= "offset",
		InitCommand= function(self)
									 self:y(30)
									 self:SetWidth(0)
									 self:SetHeight(8)
									 self:visible(false)
									 self:horizalign(left)
								 end
	},
	InitCommand= function(self)
								 Judgment= self:GetChild("Judgment")
								 OffsetQuad= self:GetChild("offset")
								 Judgment:visible(false)
								 tani:hide()
								 tani.text:strokecolor(fetch_color("gameplay.text_stroke"))
								 tani.number:strokecolor(fetch_color("gameplay.text_stroke"))
							 end,
	ToastyAchievedMessageCommand=
		function(self,params)
			if params.PlayerNumber == player then
				--Trace("ToastyAchievedMessageCommand params:")
				--rec_print_table(params)
				if cons_players[player].flags.gameplay.allow_toasty then
					cons_players[player].toasty= {
						judge= "TapNoteScore_Miss", remaining= 5, progress= 0 }
				end
			end
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
					if holds then add_set(holds) end
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
				local width= tns_windows[disp_judge][2] - tns_windows[disp_judge][1]
				disp_offset= tns_windows[disp_judge][1] + (width * MersenneTwister.Random())
				if MersenneTwister.Random() > .5 then
					disp_offset= disp_offset * -1
				end
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
			end
			local text= tns_texts[disp_judge]
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
			if text then
				if cons_players[player].flags.gameplay.offset then
					OffsetQuad:finishtweening()
					OffsetQuad:SetWidth(disp_offset * offset_scaler)
					OffsetQuad:diffuse(judge_to_color(disp_judge))
					OffsetQuad:visible(true)
					OffsetQuad:linear(1)
					OffsetQuad:diffusealpha(0)
				end
				Judgment:playcommand("Reset")
				Judgment:settext(get_string_wrapper("JudgementNames", text):upper())
				Judgment:diffuse(judge_to_color(disp_judge))
				Judgment:visible(true)
				JudgeCmds[disp_judge](Judgment)
			end
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
	end
}
args[1].OnCommand= THEME:GetMetric("Judgment", "JudgmentOnCommand")

return Def.ActorFrame(args)
