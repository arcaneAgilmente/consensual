dofile(THEME:GetPathO("", "strokes.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))

local all_songs= SONGMAN:GetAllSongs()
local field= false
local curr_song= 1
local curr_steps= 1

local function set_steps()
	if not field then return end
	if curr_song < 1 then curr_song= 1 end
	if curr_steps < 1 then curr_steps= 1 end
	local steps_list= all_songs[curr_song]:GetAllSteps()
	if curr_steps > #steps_list then
		curr_steps= 1
	end
	lua.ReportScriptError("Song: " .. curr_song .. " " .. all_songs[curr_song]:GetDisplayMainTitle() .. " Steps: " .. steps_list[curr_steps]:GetStepsType() .. " " .. steps_list[curr_steps]:GetDifficulty())
	field:set_steps(steps_list[curr_steps])
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
	if button == "n" then
		curr_steps= curr_steps + 1
	elseif button == "m" then
		curr_steps= curr_steps - 1
	elseif button == "j" then
		curr_song= curr_song + 1
	elseif button == "k" then
		curr_song= curr_song - 1
	end
	set_steps()
end

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	--[[
	Def.NewField{
		InitCommand= function(self)
			field= self
			self:xy(_screen.cx, _screen.cy)
		end,
	},
	]]
	animated_text("Consensual", _screen.cx, _screen.cy, 4, 4, 10)
}

return Def.ActorFrame(args)
