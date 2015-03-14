dofile(THEME:GetPathO("", "eval_parts.lua"))

local player_xs= { [PLAYER_1]= SCREEN_RIGHT * .25,
                   [PLAYER_2]= SCREEN_RIGHT * .75 }

local function input(event)
	if not event.PlayerNumber then return end
	if event.type == "InputEventType_Release" then return end
	if event.GameButton == "Start" then
		SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
		trans_new_screen("ScreenConsNameEntry")
	end
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end
}
local profile_reports= {}
for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	profile_reports[pn]= setmetatable({}, profile_report_mt)
	args[#args+1]= Def.ActorFrame{
		InitCommand= function(self)
			self:xy(player_xs[pn], 120)
		end,
		profile_reports[pn]:create_actors(pn, false)
	}
end

return Def.ActorFrame(args)
