-- Values for max_press_age, semi_recent_age, and recent_age may need
-- twerking to excite users.
-- Any button press older than max_press_age will be from history.  This
-- controls the maximum possible resolution of the nps measurement.  With a
-- 10 second history, the nps cannot be measure more finely than two
-- significant figurines. (x.x)
local max_press_age= 10
-- recent_ages are used to detect sharp changes in the nps and average in
-- their effect, to make the reported value respond quickly to changes.
-- adding more entries to recent_ages will weight the final value more toward
-- the average age of the notes in the recent_ages ranges.  {1, 1, 1, 1}
-- would weight it heavily towards presses in the most recent second, and
-- make the precision given by max_press_age unreachable.
local recent_ages= {.25, .5, 1, 1, 2, 2, 3, 4, 5}
-- sharp_change is used to detect a sudden change in the press rate, and
-- switch from displaying max_press_age if it's too innaccurate.
local sharp_change= 1

local nps_format= "%.1f"

nps_counter_mt= {
	__index= {
		create_actors= function(self, pn, x, y)
			self.press_history= {}
			self.pn= pn
			local function update()
				local curr_time= GetTimeSinceStart()
				local oldest_age= curr_time - max_press_age
				local is_recent= {}
				local recent_counts= {}
				local recent_ends= {}
				-- This fills is_recent with ages that can be compared with, to avoid
				-- unnecessary additions and subtractions when comparing.
				for i= 1, #recent_ages do
					is_recent[i]= curr_time - recent_ages[i]
					recent_counts[i]= 0
				end
				local i= 1
				while i <= #self.press_history do
					if self.press_history[i] < oldest_age then
						table.remove(self.press_history, i)
					else
						for r= 1, #is_recent do
							if self.press_history[i] >= is_recent[r] then
								recent_counts[r]= recent_counts[r] + 1
								if not recent_ends[r] then
									recent_ends[r]= self.press_history[i]
								end
							end
						end
						i= i + 1
					end
				end
				local max_press_nps= #self.press_history / max_press_age
				local nps_total= 0
				local totals= 0
				for i= 1, #recent_counts do
					local span= 0
					if recent_ends[i] then
						span= (curr_time - recent_ends[i])
					end
					if span > .015625 and recent_counts[i] > 2 then
						local curr_recent_nps= (recent_counts[i] - 1) / span
						nps_total= nps_total + curr_recent_nps
						totals= totals + 1
					else
						local curr_recent_nps= (recent_counts[i]) / recent_ages[i]
						nps_total= nps_total + curr_recent_nps
						totals= totals + 1
					end
				end
				local averaged_nps= nps_total / (totals)
				--[[
				if math.abs(averaged_nps - max_press_nps) < sharp_change
				and nps_total > max_press_nps then
					averaged_nps= max_press_nps
				end
				]]
				self.display:settextf(nps_format, averaged_nps)
			end
			local function input(event)
				if event.type ~= "InputEventType_FirstPress" then return end
				if event.PlayerNumber ~= self.pn then return end
				self.press_history[#self.press_history+1]= GetTimeSinceStart()
			end
			return Def.ActorFrame{
				OnCommand= function(subself)
					self.container= subself
					subself:xy(x, y):SetUpdateFunction(update)
					SCREENMAN:GetTopScreen():AddInputCallback(input)
				end,
				Def.BitmapText{
					Font= "Common Normal", InitCommand= function(subself)
						self.display= subself
						subself:zoom(.5):diffuse(fetch_color("text")):x(32)
							:strokecolor(fetch_color("stroke")):horizalign(right)
					end
				},
				Def.BitmapText{
					Font= "Common Normal", Text= "NPS:", InitCommand= function(subself)
						subself:zoom(.5):diffuse(fetch_color("text")):x(-32)
							:strokecolor(fetch_color("stroke")):horizalign(left)
					end
				},
			}
		end
}}
