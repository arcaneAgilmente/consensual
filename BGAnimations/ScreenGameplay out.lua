dofile(THEME:GetPathO("", "art_helpers.lua"))
local feedback_judgements= {
	"TapNoteScore_W1", "TapNoteScore_W2", "TapNoteScore_W3",
	"TapNoteScore_W4", "TapNoteScore_W5", "TapNoteScore_Miss"
}
local function player_combo_color(pn, luma)
	return function()
		local firsts= cons_players[pn].stage_stats.firsts
		local ret_color= judge_to_color("TapNoteScore_W1")
		for i, j in ipairs(feedback_judgements) do
			if firsts[j] then
				ret_color= judge_to_color(j)
			end
		end
		return Color.Alpha(adjust_luma(ret_color, luma), .75)
	end
end

local function player_score_color(pn, luma)
	return function()
		local pss= STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
		return Color.Alpha(adjust_luma(color_for_score(
			pss:GetActualDancePoints() / pss:GetPossibleDancePoints()), .75), luma)
	end
end

local earned_combo_splash= {}
local earned_score_splash= {}

local function player_combo_height(pn)
	return function()
		if earned_score_splash[pn] then
			return -.5 * _screen.h
		end
		return -_screen.h
	end
end

local function player_score_height(pn)
	return function()
		if earned_combo_splash[pn] then
			return .5 * _screen.h
		end
		return _screen.h
	end
end

local holding_start= {}
local function input(event)
	if not event.PlayerNumber then return end
	if event.GameButton == "Start" then
		if event.type == "InputEventType_Release" then
			holding_start[event.PlayerNumber]= false
		else
			holding_start[event.PlayerNumber]= true
		end
	end
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	StartTransitioningCommand= function(self)
		-- Deliberately ignore the fake_score for the player to give them a
		-- slight feeling that something doesn't fit.
		local nobody_earned_splash= true
		local somebody_holding_start= false
		for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			if holding_start[pn] then
				somebody_holding_start= true
			end
		end
		if not somebody_holding_start then
			update_player_stats_after_song()
		end
		for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
			local pss= STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
			if not pss:GetFailed() and not somebody_holding_start then
				local worst_judge= "TapNoteScore_W1"
				local firsts= cons_players[pn].stage_stats.firsts
				local threshold= cons_players[pn].combo_splash_threshold
				for i, j in ipairs(feedback_judgements) do
					if firsts[j] and TapNoteScore:Compare(worst_judge, j) > 0 then
						worst_judge= j
					end
				end
				if TapNoteScore:Compare(threshold, worst_judge) <= 0 then
					earned_combo_splash[pn]= true
				end
				local score= pss:GetActualDancePoints()/pss:GetPossibleDancePoints()
				if score >= .995 and
				cons_players[pn].flags.gameplay.score_confetti then
					activate_confetti("earned", true)
				end
				if score > score_color_threshold and
				cons_players[pn].flags.gameplay.score_splash then
					earned_score_splash[pn]= true
					self:GetChild(pn.."score"):playcommand("splash")
					nobody_earned_splash= false
				end
				if earned_combo_splash[pn] then
					self:GetChild(pn.."combo"):playcommand("splash")
					nobody_earned_splash= false
				end
			end
		end
		if nobody_earned_splash then
			self:GetChild("normal_exit"):playcommand("splash")
		end
	end,
}
local enabled= GAMESTATE:GetEnabledPlayers()
local xs= {
	[PLAYER_1]= (#enabled > 1 and _screen.w*.25) or _screen.w*.5,
	[PLAYER_2]= (#enabled > 1 and _screen.w*.75) or _screen.w*.5}
local width= (#enabled > 1 and _screen.w/2) or _screen.w
for i, pn in ipairs(enabled) do
	args[#args+1]= random_grow_column(
		pn.."combo", xs[pn], _screen.h, player_combo_color(pn, .5),
		player_combo_color(pn, .5), width, .125, player_combo_height(pn),
		"splash")
	args[#args+1]= random_grow_column(
		pn.."score", xs[pn], 0, player_score_color(pn, .5),
		player_score_color(pn, .5), width, .125, player_score_height(pn),
		"splash")
end
args[#args+1]= random_grow_circle(
	"normal_exit", _screen.cx, _screen.cy,
	adjust_luma(Alpha(fetch_color("gameplay.failed"), .75), .25),
	adjust_luma(Alpha(fetch_color("gameplay.failed"), .75), .015625),
		.125, _screen.w, "splash")

return Def.ActorFrame(args)
