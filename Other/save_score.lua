--[[
	ExportScoreForIRC is something that AJ made for fun. It requires an
	understanding of how StepMania views your filesystem, as well as knowledge
	on how to make your IRC client play from a script file.
	Since this was made for a limited purpose, it assumes you play as a single player
	in non-course modes.
	It spits out a string like this:
	$PLAYERNUMBER last played: $SONG by $ARTIST ($SONGGROUP) [$MODE $DIFFICULTY] $PERCENT | $W1 / $W2 / $W3 / $W4 / $W5 / $MISS | Holds: ($HELD/DROPPED) Max Combo: $MAXCOMBO
	If there are two players, there will be a line for each player.
	Usage:
	1. Place this file in Graphics/save_score.lua
	1.5. Learn how to add an actor to the frame that a screen returns.
	2. Add this line to whatever screen you want to write the current song:
	LoadActor(THEME:GetPathG("", "save_score.lua")),
	This is Version 0.3.
	The latest version can be found at http://kki.ajworld.net/misc/ExportScoreForIRC.lua
	Changelog:
	v0.3
	* File writing code updated to StepMania 5 recent, should work in anything after beta 2?
	v0.2
	* added song group
	v0.1
	* initial "release"
	setting up IRC
	this is going to be different for each client. I only have mIRC on hand to test
	this with.
	[mIRC]
	Open the Scripts Editor, go to the Aliases tab and paste this on its own line:
	/smlastplayed /me $read("%APPDATA%\StepMania 5.0\Save\_freezone\LastPlayed.txt") $$1-
	where "%APPDATA%\StepMania 5.0\Save\_freezone\LastPlayed.txt" is the path to the LastPlayed.txt
	file. Please also edit local path below if changing the folder from "_freezone".
	SM5 note: Stepmania 5 stores user data in a special user folder, inside APPDATA on windows. See http://www.stepmania.com/wiki/ for paths on other systems.
	[General]
	Since StepMania/sm-ssc can only read and write files from within its ecosystem,
	it's important that you make the location of LastPlayed.txt as simple as possible
	(and not likely to get removed by the uninstaller when upgrading).
--]]
-- path is where the file lives relative to StepMania's root.
local path = "Save/_freezone/LastPlayed.txt"

local function player_last_played_stats(pn)
	local outStr = pn .. " last played: "
	local song = GAMESTATE:GetCurrentSong();
	if song then
		-- attach song title/artist
		local mainTitle = song:GetDisplayFullTitle()
		local artist = song:GetDisplayArtist()
		outStr = outStr .. mainTitle .." by "..artist
		-- attach song group
		local songGroup = song:GetGroupName()
		outStr = outStr .. " ("..songGroup..")"
		-- attach stepstype and difficulty
		local steps = GAMESTATE:GetCurrentSteps(pn)
		if steps then
			local st = string.gsub(ToEnumShortString(steps:GetStepsType()),"_","-")
			local diff = ToEnumShortString(steps:GetDifficulty())
			outStr = outStr .." [".. st .." ".. diff .."] "
		end;
		local sStats = STATSMAN:GetCurStageStats()
		local pStats = sStats:GetPlayerStageStats(pn)
		-- attach percent score
		local pScore = pStats:GetPercentDancePoints()*100
		outStr = outStr ..string.format("%.02f%%",pScore)
		-- attach judge counts
		local w1 = pStats:GetTapNoteScores('TapNoteScore_W1')
		local w2 = pStats:GetTapNoteScores('TapNoteScore_W2')
		local w3 = pStats:GetTapNoteScores('TapNoteScore_W3')
		local w4 = pStats:GetTapNoteScores('TapNoteScore_W4')
		local w5 = pStats:GetTapNoteScores('TapNoteScore_W5')
		local miss = pStats:GetTapNoteScores('TapNoteScore_Miss')
		outStr = outStr .." | "..w1.." / "..w2.." / "..w3.." / "..w4.." / "..w5.." / "..miss
		-- attach OK/NG counts
		local held = pStats:GetHoldNoteScores('HoldNoteScore_Held')
		local dropped = pStats:GetHoldNoteScores('HoldNoteScore_LetGo')
		outStr = outStr .." / Holds: ("..held .." / ".. dropped ..")"
		-- attach max combo
		local maxCombo = pStats:MaxCombo();
		local comboThreshold = THEME:GetMetric("Gameplay","MinScoreToContinueCombo")
		local gotFullCombo = pStats:FullComboOfScore(comboThreshold);
		local comboLabel = gotFullCombo and "Full" or "Max"
		outStr = outStr .." ".. comboLabel .." Combo: ".. maxCombo
		return outStr
	end
end

function write_last_played_stats()
	if GAMESTATE:IsCourseMode() then return end
	local str= ""
	for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
		str= str .. player_last_played_stats(pn)
	end
	-- write string
	local file= RageFileUtil.CreateRageFile()
	if not file:Open(path, 2) then
		Warn("Could not open '" .. path .. "' to write current playing info.")
	else
		file:Write(str)
		file:Close()
		file:destroy()
	end
end

-- this code is in the public domain because I don't really care about
-- copyrighting something like this.
