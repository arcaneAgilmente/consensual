finish_song_sort_worker()

local meter_range= .5

local num_players= 0
local nps_player= PLAYER_1
local enabled_players= GAMESTATE:GetEnabledPlayers()
for i, pn in ipairs(enabled_players) do
	nps_player= pn
	num_players= num_players + 1
	-- I should really add a lua binding for disabling the stage tokens.
	GAMESTATE:AddStageToPlayer(pn)
	GAMESTATE:AddStageToPlayer(pn)
	GAMESTATE:AddStageToPlayer(pn)
end

local function try_song(song)
	if not song then return false end
	local steps_list= get_filtered_steps_list(song)
	local matching_steps= {}
	for p, pn in ipairs(enabled_players) do
		matching_steps[pn]= {}
	end
	local len= song_get_length(song)
	local num_matched= 0
	local matched_by_pn= {}
	for i, steps in ipairs(steps_list) do
		local nps= calc_nps(nps_player, len, steps)
		local meter= steps:GetMeter()
		for p, pn in ipairs(enabled_players) do
			local use_meter= meter
			if workout_mode[pn].use_nps_to_rate then
				use_meter= nps
			else
				use_meter= meter
			end
			if use_meter >= workout_mode[pn].current_meter - meter_range
			and use_meter <= workout_mode[pn].current_meter + meter_range then
				if not matched_by_pn[pn] then
					num_matched= num_matched + 1
					matched_by_pn[pn]= true
				end
				table.insert(matching_steps[pn], {steps, use_meter})
			end
		end
	end
	if num_matched == num_players then
		GAMESTATE:SetCurrentSong(song)
		for pn, steps_set in pairs(matching_steps) do
			local best_match= false
			local match_dist= 1000
			local curr_meter= workout_mode[pn].current_meter
			for i, steps_info in ipairs(steps_set) do
				local this_dist= math.abs(curr_meter - steps_info[2])
				if this_dist < match_dist or not best_match then
					best_match= steps_info[1]
					match_dist= this_dist
				end
			end
			if not best_match then
				lua.ReportScriptError("Something went wrong and matching steps weren't actually found for " .. pn ..".  Song:  '" .. song:GetSongDir() .. "'")
				GAMESTATE:SetCurrentSteps(pn, steps_list[1])
			else
				GAMESTATE:SetCurrentSteps(pn, best_match)
			end
		end
		return true
	elseif num_matched > num_players then
		lua.ReportScriptError("Something went wrong and more players than exist were matched.  Song:  '" .. song:GetSongDir() .. "'")
	end
	return false
end

local can_start_picking= false
local function input(event)
	if event.type == "InputEventType_Release" then return end
	if event.DeviceInput.button == "DeviceButton_g" then
		can_start_picking= true
	end
end

local tries= 0
local tries_text= false
local matched= false
local num_songs= #bucket_man.filtered_songs
local next_range_inc_at= 100
local function update(self)
	if not can_start_picking then return end
	local tick_start= GetTimeSinceStart()
	while not matched and GetTimeSinceStart() - tick_start < .02 do
		local song= bucket_man.filtered_songs[math.random(1, num_songs)]
		if try_song(song) then
			matched= true
			if GAMESTATE:CanSafelyEnterGameplay() then
				trans_new_screen("ScreenStageInformation")
			else
				lua.ReportScriptError("Something went wrong and it's not actually safe to enter gameplay.")
			end
		end
		tries= tries + 1
		if tries > next_range_inc_at then
			meter_range= meter_range + .5
			next_range_inc_at= next_range_inc_at + 100
		end
	end
	tries_text:settext(tries)
	if tries > num_songs then
		local cant= "Can't find a song within the allowed difficulty range."
		lua.ReportScriptError(cant)
		tries_text:settext(cant)
		trans_new_screen("ScreenWorkoutEval")
	end
end

local positions= {
	[PLAYER_1]= _screen.w * .25, [PLAYER_2]= _screen.w * .75}
local function progress_data()
	local menu_y= 120
	local args= {}
	for i, pn in ipairs(enabled_players) do
		local progress, goal= get_workout_progress(pn)
		local work_data= workout_mode[pn]
		args[#args+1]= normal_text("pn", pn, nil, nil, positions[pn], menu_y)
		args[#args+1]= normal_text("progress", tostring(progress), nil, nil, positions[pn], menu_y+24)
		args[#args+1]= normal_text("goal", tostring(goal), nil, nil, positions[pn], menu_y+48)
	end
	return Def.ActorFrame(args)
end

return Def.ActorFrame{
	Def.ActorFrame{
		OnCommand= function(self)
			self:SetUpdateFunction(update)
			SCREENMAN:GetTopScreen():AddInputCallback(input)
		end,
		normal_text("tries", "", fetch_color("text"), fetch_color("stroke"),
								_screen.cx, _screen.cy, 1, nil, {
									InitCommand= function(self) tries_text= self end})
	},
	progress_data()
}
