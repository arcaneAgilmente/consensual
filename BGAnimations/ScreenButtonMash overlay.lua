-- A simple screen for showing the player how fast they're mashing a button.

-- press_history will store the times that the button was pressed.
local press_history= {}
-- Values for max_press_age, semi_recent_age, and recent_age may need twerking
-- to excite users.
-- Any button press older than max_press_age will be from history.  This
-- controls the maximum possible resolution of the nps measurement.  With a 10
-- second history, the nps cannot be measure more finely than two significant
-- figurines. (x.x)
local max_press_age= 10
-- recent_ages are used to detect sharp changes in the nps and average in
-- their effect, to make the reported value respond quickly to changes.
-- adding more entries to recent_ages will weight the final value more towards
-- the average age of the notes in the recent_ages ranges.  {1, 1, 1, 1} would
-- weight it heavily towards presses in the most recent second, and make the
-- precision given by max_press_age unreachable.
local recent_ages= {1, 2, 3, 4}
-- sharp_change is used to detect a sudden change in the press rate, and
-- switch from displaying max_press_age if it's too innaccurate.
local sharp_change= 1

local peak= 0
local peak_display= false
local nps_format= "%.3f"

-- averaged_nps_display will display what would actually be seen by the user.
local averaged_nps_display= false
-- debug_max_press_nps_display and debug_recent_nps_display are for debug
-- purposes, feedback to the programmer for tuning the algorithm.
local debug_max_press_nps_display= false
local debug_recent_nps_display= {}

local function update_nps()
	local curr_time= GetTimeSinceStart()
	local oldest_age= curr_time - max_press_age
	local is_recent= {}
	local recent_counts= {}
	-- This fills is_recent with ages that can be compared with, to avoid
	-- unnecessary additions and subtractions when comparing.
	for i= 1, #recent_ages do
		is_recent[i]= curr_time - recent_ages[i]
		recent_counts[i]= 0
	end
	local i= 1
	while i <= #press_history do
		if press_history[i] < oldest_age then
			table.remove(press_history, i)
		else
			for r= 1, #is_recent do
				if press_history[i] >= is_recent[r] then
					recent_counts[r]= recent_counts[r] + 1
				end
			end
			i= i + 1
		end
	end
	local max_press_nps= #press_history / max_press_age
	-- It might make more sense to the user not include max_press_nps in the
	-- averaged value.  Twerk as needed.
	local nps_total= max_press_nps
	for i= 1, #recent_counts do
		local curr_recent_nps= recent_counts[i] / recent_ages[i]
		nps_total= nps_total + curr_recent_nps
		debug_recent_nps_display[i]:settextf(nps_format, curr_recent_nps)
	end
	debug_max_press_nps_display:settextf(nps_format, max_press_nps)
	-- If you decide to take max_press_nps out of the averaged value, remove
	-- the +1 from the divisor.
	local averaged_nps= nps_total / (#recent_counts + 1)
	if math.abs(averaged_nps - max_press_nps) < sharp_change and nps_total > max_press_nps then
		averaged_nps= max_press_nps
	end
	averaged_nps_display:settextf(nps_format, averaged_nps)
	peak= math.max(peak, averaged_nps)
	peak_display:settextf(nps_format, peak)
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.type ~= "InputEventType_FirstPress" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
	if button == "f" or event.button == "Left" or event.button == "Right" then
		press_history[#press_history+1]= GetTimeSinceStart()
	end
	if event.button == "Back" then
		trans_new_screen("ScreenInitialMenu")
	end
end

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
		self:SetUpdateFunction(update_nps)
	end,
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			averaged_nps_display= self
			self:diffuse(fetch_color("text")):strokecolor(fetch_color("stroke"))
				:xy(_screen.cx, _screen.cy+8)
		end
	},
	normal_text("avg", "Averaged", fetch_color("text"), fetch_color("stroke"),
							_screen.cx-48, _screen.cy+8, 1, right),
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			debug_max_press_nps_display= self
			self:diffuse(fetch_color("text")):strokecolor(fetch_color("stroke"))
				:xy(_screen.cx, _screen.cy-12):zoom(.5)
		end
	},
	normal_text("10s", "10 second count", fetch_color("text"), fetch_color("stroke"),
							_screen.cx-32, _screen.cy-12, .5, right),
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy-32):settext("Mash 'f'!")
		end
	},
	normal_text("peak", "Peak", fetch_color("text"), fetch_color("stroke"),
							_screen.cx-48, _screen.cy-64, 1, right),
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			peak_display= self
			self:diffuse(fetch_color("text")):strokecolor(fetch_color("stroke"))
				:xy(_screen.cx, _screen.cy-64)
		end
	},
}

for i= 1, #recent_ages do
	local y= _screen.cy+12+(20*i)
	args[#args+1]= Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			debug_recent_nps_display[i]= self
			self:diffuse(fetch_color("text")):strokecolor(fetch_color("stroke"))
				:xy(_screen.cx, y):zoom(.5)
		end
	}
	args[#args+1]= normal_text("ra"..i, i.." second count", fetch_color("text"), fetch_color("stroke"), _screen.cx-32, y, .5, right)
end

return Def.ActorFrame(args)
