local pi= math.pi
local rate_coordinator= setmetatable({}, rate_coordinator_interface_mt)
rate_coordinator:initialize()

local function can_have_special_actors()
	local screen_name= Var("LoadingScreen")
	return screen_name == "ScreenGameplay" or
		screen_name == "ScreenGameplayShared" or
		screen_name == "ScreenDemonstration"
end

local wrapper_layers= 3 -- x, y, z rotation
local screen_gameplay= false
local gameplay_wrappers= {}
local song_opts= GAMESTATE:GetSongOptionsObject("ModsLevel_Current")
local disable_extra_processing= misc_config:get_data().disable_extra_processing

local receptor_min= THEME:GetMetric("Player", "ReceptorArrowsYStandard")
local receptor_max= THEME:GetMetric("Player", "ReceptorArrowsYReverse")
local arrow_height= THEME:GetMetric("ArrowEffects", "ArrowSpacing")
local field_height= receptor_max - receptor_min

local line_spacing= 24
local h_line_spacing= line_spacing / 2

-- SCREEN_WIDTH - life_bar_width - score_feedback_width
-- spb_width is also used as the width of the title.
local spb_width= SCREEN_WIDTH - 48 - 32
local spb_height= 16
local spb_x= SCREEN_CENTER_X
local spb_y= SCREEN_BOTTOM - (spb_height / 2) - 1
local spb_time_off= spb_height + 4
local spb_time_y= spb_y - spb_time_off

local player_dec_centers= {
	[PLAYER_1]= {_screen.cx * .5, _screen.cy},
	[PLAYER_2]= {_screen.cx * 1.5, _screen.cy},
}

local note_drift_minx= _screen.w * .15
local note_drift_maxx= _screen.w * .85
local note_drift_miny= _screen.h * .25
local note_drift_maxy= _screen.h * .5
local note_drift_minzx= .5
local note_drift_maxzx= 2
local zx_diff= note_drift_maxzx - note_drift_minzx
local function rand_note_drift(min, max)
	return math.random(min, max)
end
local function rand_xnote_drift()
	return rand_note_drift(note_drift_minx, note_drift_maxx)
end
local function rand_ynote_drift()
	return rand_note_drift(note_drift_miny, note_drift_maxy)
end
local function rand_zoomx_drift()
	return (math.random() * zx_diff) + note_drift_minzx
end
local note_drift_indices= {[PLAYER_1]= {1, 2, 3}, [PLAYER_2]= {4, 5, 6}}
local note_drift_speeds= {}
local note_drift_currents= {}
local note_drift_goals= {}
for i= 1, 4, 3 do
	note_drift_speeds[i]= 512
	note_drift_speeds[i+1]= 128
	note_drift_speeds[i+2]= .75
	note_drift_currents[i]= rand_xnote_drift()
	note_drift_currents[i+1]= rand_ynote_drift()
	note_drift_currents[i+2]= rand_zoomx_drift()
	note_drift_goals[i]= rand_xnote_drift()
	note_drift_goals[i+1]= rand_ynote_drift()
	note_drift_goals[i+2]= rand_zoomx_drift()
end

local player_sides= {
	[PLAYER_1]=
		THEME:GetMetric("ScreenGameplay", "PlayerP1OnePlayerOneSideX"),
	[PLAYER_2]=
		THEME:GetMetric("ScreenGameplay", "PlayerP2OnePlayerOneSideX")}
local side_diffs= {
	[PLAYER_1]= player_sides[PLAYER_2] - player_sides[PLAYER_1],
	[PLAYER_2]= player_sides[PLAYER_1] - player_sides[PLAYER_2]}
local side_swap_vals= {}
local swap_on_xs= {}
local side_toggles= {}
local side_actors= {}
local notefields= {}
local notefield_wrappers= {}
local notecolumns= {}
local next_chuunibyou= {[PLAYER_1]= 0, [PLAYER_2]= 0}
local chuunibyou_state= {[PLAYER_1]= true, [PLAYER_2]= true}
local chuunibyou_sides= {}
if true_gameplay and (cons_players[PLAYER_1].chuunibyou or
											cons_players[PLAYER_2].chuunibyou) then
	local enabled= GAMESTATE:GetEnabledPlayers()
	if #enabled == 1 then
		chuunibyou_sides= {
			[true]= player_sides[enabled[1]],
			[false]= player_sides[other_player[enabled[1]]]
		}
	else
		chuunibyou_sides= {
			[true]= player_sides[PLAYER_1],
			[false]= player_sides[PLAYER_2]
		}
		if gamestate_get_curr_steps(enabled[1]) ==
		gamestate_get_curr_steps(enabled[2]) then
			local opsa= cons_players[enabled[1]].preferred_options
			local opsb= cons_players[enabled[2]].preferred_options
			local checklist= {
				"Boost", "Brake", "Wave", "Expand", "Boomerang", "Hidden",
				"HiddenOffset", "Sudden", "SuddenOffset", "Skew", "Tilt", "Beat",
				"Bumpy","Drunk", "Tipsy", "Tornado", "Mini", "Tiny", "Reverse",
				"Alternate", "Centered", "Cross", "Flip", "Invert", "Split",
				"Xmode", "Blind", "Dark", "Blink", "RandomVanish", "Stealth",
				"Mirror", "Backwards", "Left", "Right", "Shuffle", "SoftShuffle",
				"SuperShuffle", "Big", "BMRize", "Echo", "Floored", "Little",
				"Planted", "AttackMines", "Quick", "Skippy", "Stomp", "Twister",
				"Wide", "HoldRolls", "NoJumps","NoHands","NoQuads", "NoStretch",
				"NoLifts", "NoFakes", "NoMines",
			}
			local same_mods= true
			local speeda= cons_players[enabled[1]].speed_info
			local speedb= cons_players[enabled[2]].speed_info
			if speeda.speed ~= speedb.speed or speeda.mode ~= speedb.mode then
				same_mods= false
			end
			if same_mods then
				for i= 1, #checklist do
					if opsa[checklist[1]](opsa) ~= opsb[checklist[1]](opsb) then
						same_mods= false
						break
					end
				end
			end
			if not same_mods then
				chuunibyou_state[enabled[2]]= not chuunibyou_state[enabled[2]]
			end
		else
			chuunibyou_state[enabled[2]]= not chuunibyou_state[enabled[2]]
		end
	end
end

local judge_feedback_interface= {}
function judge_feedback_interface:create_actors(name, fx, fy, pn)
	if not name then return nil end
	self.name= name
	self.pn= pn
	if not fx then fx= 0 end
	if not fy then fy= 0 end
	self.elements= {}
	local args= {
		Name= name,
		InitCommand= function(subself)
			self.container= subself
			subself:xy(fx, fy)
			for i, tani in ipairs(self.elements) do
				tani.text:strokecolor(fetch_color("gameplay.text_stroke"))
				tani.number:strokecolor(fetch_color("gameplay.text_stroke"))
			end
		end
	}
	local start_y= 0
	local scale= cons_players[pn].gameplay_element_positions.judge_list_scale
	local judge_spacing= scale * line_spacing
	local tx= -10 * scale
	local nx= 10 * scale
	for n= 1, #feedback_judgements do
		local new_element= {}
		setmetatable(new_element, text_and_number_interface_mt)
		args[#args+1]= new_element:create_actors(
			feedback_judgements[n], {
				sy= start_y + judge_spacing * n, tx= tx, nx= nx,
				tz= scale, nz= scale,
				tc= judge_to_color(feedback_judgements[n]),
				nc= judge_to_color(feedback_judgements[n]),
				text_section= "JudgementNames",
				tt= feedback_judgements[n]})
		self.elements[#self.elements+1]= new_element
	end
	return Def.ActorFrame(args)
end

function judge_feedback_interface:update(player_stage_stats)
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
end

local judge_feedback_interface_mt= { __index= judge_feedback_interface }

dofile(THEME:GetPathO("", "sigil.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))

local sigil_feedback_interface= {}
function sigil_feedback_interface:create_actors(name, fx, fy, player_number)
	if not name then return nil end
	self.name= name
	self.player_number= player_number
	local player_data= cons_players[player_number].sigil_data
	-- Initial data should ensure that all actors get updated the first frame.
	self.prev_state= { detail= player_data.detail, fill_amount= 1}
	if not fx then fx= 0 end
	if not fy then fy= 0 end
	self.sigil= setmetatable({}, sigil_controller_mt)
	return self.sigil:create_actors(name, fx, fy, pn_to_color(player_number), player_data.detail, 150 * cons_players[player_number].gameplay_element_positions.sigil_scale)
end

function sigil_feedback_interface:update(player_stage_stats)
	local pstats= player_stage_stats
	local life= pstats:GetCurrentLife()
	local adp= pstats:GetActualDancePoints()
	if cons_players[self.player_number].fake_judge then
		adp= cons_players[self.player_number].fake_score.dp
	end
	local pdp= pstats:GetCurrentPossibleDancePoints()
	local score= adp / pdp
	if pdp == 0 then
		score= 1
	end
	--Trace("SGBG.Update:  Current life:  " .. life .. "\n  ADP:  " .. adp ..
	--   "\n  pdp:  " .. pdp .. "\n  score:  " .. score)
	local new_detail= math.max(1, math.round(self.sigil.max_detail * ((score - .5) * 2)))
	self.sigil:set_goal_detail(new_detail)
	self.prev_state.detail= new_detail
	self.prev_state.fill_amount= life
end

local sigil_feedback_interface_mt= { __index= sigil_feedback_interface }

local score_meter_centers= {
	[PLAYER_1]= { SCREEN_LEFT + 32, SCREEN_BOTTOM },
	[PLAYER_2]= { SCREEN_RIGHT - 32, SCREEN_BOTTOM }
}
local score_meter_mt= {
	__index= {
		create_actors= function(self, name, fx, fy, player_number)
			if not name then return nil end
			self.name= name
			self.player_number= player_number
			if not fx then fx= 0 end
			if not fy then fy= 0 end
			self.parts= {}
			local frame_args= {
				Name= name, InitCommand= function(subself)
					subself:xy(fx, fy)
					self.container= subself
				end,
			}
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
		update= function(self, player_stage_stats)
			local adp= player_stage_stats:GetActualDancePoints()
			local mdp= player_stage_stats:GetPossibleDancePoints()
			local fake_score
			if cons_players[self.player_number].fake_judge then
				fake_score= cons_players[self.player_number].fake_score
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

local numerical_score_feedback_mt= {
	__index= {
		create_actors= function(self, name, x, y, pn)
			self.name= name
			self.player_number= pn
			x= x or 0
			y= y or 0
			local flags= cons_players[pn].flags.gameplay
			local scale= cons_players[pn].gameplay_element_positions.score_scale
			local dp_parts_pad= 10
			local dp_parts_pad_dub= dp_parts_pad * 2
			self.fmat= "%.2f%%"
			local args= {
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.pct= subself:GetChild("pct")
					subself:zoom(scale)
				end,
				OnCommand= function(subself)
					local mdp= STATSMAN:GetCurStageStats():GetPlayerStageStats(self.player_number):GetPossibleDancePoints()
					if self.pct then
						self.pct:strokecolor(fetch_color("gameplay.text_stroke"))
						self.precision= math.max(
							2, math.ceil(math.log(mdp) / math.log(10))-2)
						self.fmat= "%." .. self.precision .. "f%%"
						-- maximum width for the pct will be -222%
						self.pct:settext(self.fmat:format(-222))
						local pct_width= self.pct:GetWidth()
						self.pct:x(pct_width / 2):settext(self.fmat:format(0))
					end
					if self.max_dp then
						self.max_dp:settext(mdp)
					end
					if self.dual_mode then
						local pad= 16
						-- add the width the scored dp will have.
						local dp_width= (self.max_dp:GetWidth() * 2) + dp_parts_pad_dub
						-- maximum width for the pct will be -222%
						self.pct:settext(self.fmat:format(-222))
						local pct_width= self.pct:GetWidth()
						local total_width= dp_width + pct_width + pad
						local pct_x= total_width / 2
						self.pct:x(pct_x)
						self.dp_container:x(pct_x - pct_width - pad - (dp_width/2))
						self.pct:settext(self.fmat:format(0))
					end
				end
			}
			if flags.dance_points then
				if flags.pct_score then
					self.dual_mode= true
				end
				args[#args+1]= Def.ActorFrame{
					Name= "dp", InitCommand= function(subself)
						self.dp_container= subself
						self.curr_dp= subself:GetChild("curr_dp")
						self.slash_dp= subself:GetChild("slash_dp")
						self.max_dp= subself:GetChild("max_dp")
						self.curr_dp:strokecolor(fetch_color("gameplay.text_stroke"))
						self.slash_dp:strokecolor(fetch_color("gameplay.text_stroke"))
						self.max_dp:strokecolor(fetch_color("gameplay.text_stroke"))
					end,
					normal_text(
						"curr_dp", "0", fetch_color("text"), nil, -dp_parts_pad, 0, 1, right),
					normal_text(
						"slash_dp", "/", fetch_color("text"), nil, 0, 0, 1),
					normal_text(
						"max_dp", "0", fetch_color("text"), nil, dp_parts_pad, 0, 1, left),
				}
			end
			if flags.pct_score then
				args[#args+1]= normal_text(
					"pct", "", fetch_color("text"), nil, 0, 0, 1, right)
			end
			return Def.ActorFrame(args)
		end,
		update= function(self, pss)
			local adp= pss:GetActualDancePoints()
			local mdp= pss:GetPossibleDancePoints()
			local fake_score
			if cons_players[self.player_number].fake_judge then
				fake_score= cons_players[self.player_number].fake_score
				adp= fake_score.dp
			end
			local text_color= fetch_color("text")
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
			if self.pct then
				local pct= math.floor(adp/mdp*(10^(self.precision+2))) *
					(10^-self.precision)
				self.pct:settext(self.fmat:format(pct)):diffuse(text_color)
			end
			if self.dp_container then
				self.curr_dp:settext(adp):diffuse(text_color)
				self.max_dp:settext(mdp):diffuse(text_color)
			end
		end
}}

local bpm_feedback_interface= {}
local bpm_feedback_interface_mt= { __index= bpm_feedback_interface }
function bpm_feedback_interface:create_actors(name, fx, fy, pn)
	self.name= name
	self.tani= setmetatable({}, text_and_number_interface_mt)
	self.pn= pn
	local scale= cons_players[pn].gameplay_element_positions.bpm_scale
	return Def.ActorFrame{
		Name= self.name, InitCommand= function(subself)
			subself:xy(fx, fy)
			self.container= subself
			self.tani.text:strokecolor(fetch_color("gameplay.text_stroke"))
			self.tani.number:strokecolor(fetch_color("gameplay.text_stroke"))
		end,
		self.tani:create_actors(
			"tani", { tx= -4, nx= 4, tt= "BPM: ", text_section= "ScreenGameplay",
								tz= scale, nz= scale
							})
	}
end

function bpm_feedback_interface:update()
	local bpm= screen_gameplay:GetTrueBPS(self.pn) * 60
	self.tani:set_number(("%.0f"):format(bpm))
end

local feedback_things= { [PLAYER_1]= {}, [PLAYER_2]= {}}

local song_progress_bar_interface= {}
local song_progress_bar_interface_mt= { __index= song_progress_bar_interface }
function song_progress_bar_interface:create_actors()
	self.name= "song_progress"
	self.frame= setmetatable({}, frame_helper_mt)
	self.text_color= fetch_color("gameplay.song_progress_bar.text")
	self.stroke_color= fetch_color("gameplay.song_progress_bar.stroke")
	self.progress_colors= fetch_color("gameplay.song_progress_bar.progression")
	self.length_colors= fetch_color("gameplay.song_progress_bar.length")
	local args= {
		Name= self.name, InitCommand= function(subself)
			subself:xy(spb_x, spb_y)
			self.container= subself
			self.filler= subself:GetChild("filler")
			self.time= subself:GetChild("time")
			self.song_first_second= 0
			self.song_len= 1
		end,
		normal_text(
			"time", "", fetch_color("text"), fetch_color("gameplay.song_progress_bar.stroke"),
			0, -spb_time_off)
	}
	if not disable_extra_processing then
		args[#args+1]= self.frame:create_actors(
			"frame", .5, spb_width, spb_height,
			fetch_color("gameplay.song_progress_bar.frame"),
			fetch_color("gameplay.song_progress_bar.bg"),
			0, 0)
		args[#args+1]= Def.Quad{
			Name= "filler", InitCommand=
				function(self)
					self:diffuse(
						fetch_color("gameplay.song_progress_bar.progression.too_low"))
						:x(spb_width * -.5):horizalign(left)
						:setsize(spb_width, spb_height-1):zoomx(0)
				end
		}
	end
	return Def.ActorFrame(args)
end

function song_progress_bar_interface:set_from_song()
	local song= GAMESTATE:GetCurrentSong()
	if song then
		self.song_first_second= song:GetFirstSecond()
		self.song_len= (song:GetLastSecond() - self.song_first_second) /
			song_opts:MusicRate()
	else
		Trace("Current song is nil on ScreenGameplay")
	end
end

function song_progress_bar_interface:update()
	local cur_seconds= (GAMESTATE:GetCurMusicSeconds() -self.song_first_second)
		/ (song_opts:MusicRate() * screen_gameplay:GetHasteRate())
	local cur_color= false
	if not disable_extra_processing then
		local zoom= cur_seconds / self.song_len
		cur_color= color_in_set(self.progress_colors, math.ceil(zoom * #self.progress_colors), false, false, false)
		self.filler:diffuse(cur_color):zoomx(zoom)
	end
	cur_seconds= math.floor(cur_seconds)
	if cur_seconds ~= self.prev_second then
		self.prev_second= cur_seconds
		if disable_extra_processing then
			self.time:settext(
					table.concat({secs_to_str(cur_seconds), " / ",
												secs_to_str(self.song_len)}))
		else
			local parts= {
				{secs_to_str(cur_seconds), Alpha(cur_color, 1)},
				{" / ", self.text_color},
				{secs_to_str(self.song_len), self.text_color},
			}
			if self.song_len > 120 then
				parts[3][2]= color_in_set(
					self.length_colors, math.ceil((self.song_len-120)/15), false, false, false)
			end
			set_text_from_parts(self.time, parts)
		end
	end
end
local song_progress_bar= setmetatable({}, song_progress_bar_interface_mt)

local song_rate_mt= {
	__index= {
		create_actors= function(self)
			self.name= "rate"
			self.tani= setmetatable({}, text_and_number_interface_mt)
			return Def.ActorFrame{
				InitCommand= function(subself)
					subself:xy(_screen.cx, spb_time_y - (line_spacing * 2))
					self.container= subself
					self.tani.text:strokecolor(fetch_color("gameplay.text_stroke"))
					self.tani.number:strokecolor(fetch_color("gameplay.text_stroke"))
				end,
				self.tani:create_actors(
					"tani", { tx= -4, nx= 4, tt= "Rate: " ,
										text_section= "ScreenGameplay"})
			}
		end,
		update= function(self)
			local rate= song_opts:MusicRate() * screen_gameplay:GetHasteRate()
			if math.abs(rate - 1) < .01 then
				self.container:hibernate(math.huge)
			else
				self.container:hibernate(0)
				self.tani:set_number(("%.2f"):format(rate))
			end
		end
}}
local song_rate= setmetatable({}, song_rate_mt)

local half_scrw= (SCREEN_WIDTH / 2)
local half_scrh= (SCREEN_HEIGHT / 2)
local to_radians= math.pi / 180
local base_len= math.sqrt((half_scrw * half_scrw) + (half_scrh * half_scrh))
local base_x= -half_scrw
local base_y= -half_scrh
local base_z= 0
local curr_x= base_x
local curr_y= base_y
local curr_z= base_z
local base_angle_x= 0
local base_angle_y= 0
local base_angle_z= 0
base_angle_z= math.atan2(base_y, base_x)

local function reposition_screen(screen)
	local rx= (screen:GetRotationX() * to_radians) + base_angle_x
	local ry= (screen:GetRotationY() * to_radians) + base_angle_y
	local rz= (screen:GetRotationZ() * to_radians) + base_angle_z
	local tx= math.cos(rz)
	local ty= math.sin(rz)
	local nx= math.cos(ry) * tx * base_len
	local tz= math.sin(ry) * tx
	local yz_mag= math.sqrt(ty * ty + tz * tz)
	local ny= math.sin(rx) * yz_mag * base_len
	local nz= math.cos(rx) * yz_mag * base_len
	--   Trace(("Angles: %f.3, %f.3  Pos: %f.3, %f.3, %f.3"):format(try, trz, nx, ny, nz))
	screen:x(nx):y(ny):z(nz)
end
local function rotate_screen_z(screen, rot)
	-- The screen is rotated around its top left corner, but we want to
	-- rotate around its center.
	--   base_angle_z= math.atan2(curr_y, curr_x)
	--   local total_angle= (rot * to_radians) + base_angle_z
	--   local angle_x= math.cos(total_angle) * base_len
	--   local angle_y= math.sin(total_angle) * base_len
	--   local new_x= half_scrw + (angle_x)
	--   local new_y= half_scrh + (angle_y)
	--   screen:xy(new_x, new_y)
	screen:rotationz(rot)
	reposition_screen(screen)
end

local function rotate_screen_y(screen, rot)
	screen:rotationy(rot)
end

local function rotate_screen_x(screen, rot)
	screen:rotationx(rot)
end

gameplay_start_time= -20
gameplay_end_time= 0
local timer_actor

local function get_screen_time()
	return timer_actor:GetSecsIntoEffect()
end

local dspeed_default_min= 0
local dspeed_default_max= 2
do
	local receptor_min= THEME:GetMetric("Player", "ReceptorArrowsYStandard")
	local receptor_max= THEME:GetMetric("Player", "ReceptorArrowsYReverse")
	local arrow_height= THEME:GetMetric("ArrowEffects", "ArrowSpacing")
	local field_height= receptor_max - receptor_min
	local center_effect_size= field_height / 2
	dspeed_default_min= (SCREEN_CENTER_Y + receptor_min) / -center_effect_size
	dspeed_default_max= (SCREEN_CENTER_Y + receptor_max) / center_effect_size
end
local dspeed_default_range= dspeed_default_max - dspeed_default_min

local suddmin= -1
local suddmax= .5

local function dspeed_start(player)
	local pdspeed= player.dspeed
	local center_range= pdspeed.max - pdspeed.min
	local field_hahs= (field_height / arrow_height)
	local field_ahs= field_hahs * (center_range * .5)
	local ahs_per_second= screen_gameplay:GetTrueBPS(player.player_number) * player.dspeed_mult
	local fields_per_second= ahs_per_second / field_ahs
	if pdspeed.special then
		field_ahs= field_hahs * dspeed_default_range * .5
		fields_per_second= ahs_per_second / field_ahs
		local cen_dst_val, cen_dst_app= player.song_options:Centered(nil, dspeed_default_range * fields_per_second)
		if pdspeed.alternate then
			local suddoff_app= (suddmax - suddmin) / ((dspeed_default_max - dspeed_default_min) / cen_dst_app) * 3
			player.song_options:SuddenOffset(nil, suddoff_app)
		end
	else
		player.song_options:Centered(nil, center_range * fields_per_second)
	end
end

local function dspeed_halt(player)
	player.song_options:Centered(nil, 0)
	if player.dspeed.special and player.dspeed.alternate then
		player.song_options:SuddenOffset(nil, 0)
	end
end

local function dspeed_alternate(player)
	if player.current_options:Reverse() == 1 then
		player.song_options:Reverse(0)
		player.current_options:Reverse(0)
		local rev_tilt= -player.song_options:Tilt()
		player.song_options:Tilt(rev_tilt)
		player.current_options:Tilt(rev_tilt)
	else
		player.song_options:Reverse(1)
		player.current_options:Reverse(1)
		local rev_tilt= -player.song_options:Tilt()
		player.song_options:Tilt(rev_tilt)
		player.current_options:Tilt(rev_tilt)
	end
end

local function dspeed_reset(player)
	if player.dspeed.alternate then
		dspeed_alternate(player)
	end
	if player.dspeed.special then
		if player.dspeed.alternate then
			local cen= player.current_options:Centered()
			if cen < 1 then
				player.current_options:Centered(1)
			else
				player.current_options:Centered(dspeed_default_max)
			end
		else
			player.current_options:Centered(1)
		end
	else
		player.current_options:Centered(player.dspeed.min)
	end
end

local dspeed_special_phase_starts= {
	function(player)
		player.song_options:Reverse(1)
		player.current_options:Reverse(1)
		player.song_options:Centered(dspeed_default_max)
		player.current_options:Centered(dspeed_default_min)
		player.current_options:SuddenOffset(suddmax)
	end,
	function(player)
		player.song_options:Reverse(0)
		player.current_options:Reverse(0)
		player.current_options:SuddenOffset(.5)
	end,
}

local dspeed_special_phase_updates= {
	function(player)
		local cen= player.current_options:Centered()
		if cen >= 1 then
			player.dspeed_phase= 2
			dspeed_special_phase_starts[player.dspeed_phase](player)
		else
			dspeed_alternate(player)
		end
	end,
	function(player)
		local cen= player.current_options:Centered()
		if cen >= dspeed_default_max then
			player.dspeed_phase= 1
			dspeed_special_phase_starts[player.dspeed_phase](player)
		else
			dspeed_alternate(player)
		end
	end
}

local already_spewed= true
local function spew_children()
	if not already_spewed then
		local top_screen= SCREENMAN:GetTopScreen()
		Trace("Top screen children.")
		if top_screen then
			local top_parent= top_screen:GetParent()
			local prev_top_parent= top_parent
			Trace("Climbing tree to find parents.")
			while top_parent do
				Trace(top_parent:GetName())
				prev_top_parent= top_parent
				top_parent= top_parent:GetParent()
			end
			top_parent= prev_top_parent
			if top_parent then
				rec_print_children(top_parent, "")
			else
				rec_print_children(top_screen, "")
			end
			already_spewed= true
		end
	end
end

-- for use inside the enabled players loop in Update.
local player= nil
local curstats= STATSMAN:GetCurStageStats()
local pstats= {}
local enabled_players= GAMESTATE:GetEnabledPlayers()
for i, pn in ipairs(enabled_players) do
	pstats[pn]= curstats:GetPlayerStageStats(pn)
end

local next_spline_change_time= 0
local function rand_pos()
	return math.random(-32, 32)
end
local function rand_angle()
	return (math.random(0, 16) * .03125) * pi
end
local function rand_zoom()
	return scale(math.random(), 0, 1, .25, 2)
end

local function Update(self, delta)
	if gameplay_start_time == -20 then
		if GAMESTATE:GetCurMusicSeconds() >= 0 then
			gameplay_start_time= get_screen_time()
		end
	else
		gameplay_end_time= get_screen_time()
	end
	if not curstats then
		Trace("SGbg.Update:  curstats is nil.")
	end
	song_progress_bar:update()
	song_rate:update()
	if get_music_file_length then
		multiapproach(note_drift_currents, note_drift_goals, note_drift_speeds, delta)
	else
		multiapproach(note_drift_currents, note_drift_goals, note_drift_speeds)
	end
	for i, pn in pairs(enabled_players) do
		player= cons_players[pn]
		if player.man_lets_have_fun and notefields[pn] then
			local xin= note_drift_indices[pn][1]
			local yin= note_drift_indices[pn][2]
			local zin= note_drift_indices[pn][3]
			side_actors[pn]:xy(note_drift_currents[xin], note_drift_currents[yin])
				:zoomx(note_drift_currents[zin])
			for i, info in ipairs{{xin, rand_xnote_drift},
				{yin, rand_ynote_drift}, {zin, rand_zoomx_drift}} do
				local index= info[1]
				if math.abs(note_drift_currents[index] - note_drift_goals[index])
				< .001 then
					note_drift_goals[index]= info[2]()
				end
			end
		end
		local unmine_time= player.unmine_time
		if unmine_time and unmine_time <= get_screen_time() then
			player.mine_data.unapply(pn)
			player.mine_data= nil
			player.unmine_time= nil
		end
		local speed_info= player:get_speed_info()
		if speed_info.mode == "CX" and screen_gameplay.GetTrueBPS then
			local this_bps= screen_gameplay:GetTrueBPS(pn)
			if speed_info.prev_bps ~= this_bps and this_bps > 0 then
				speed_info.prev_bps= this_bps
				local xmod= (speed_info.speed) / (this_bps * 60)
				player.song_options:XMod(xmod)
				player.current_options:XMod(xmod)
			end
		end
		local song_pos= GAMESTATE:GetPlayerState(pn):GetSongPosition()
		if speed_info.mode == "D" then
			local this_bps= screen_gameplay:GetTrueBPS(pn)
			local discard, approach= player.song_options:Centered()
			if approach == 0 then
				if not song_pos:GetFreeze() and not song_pos:GetDelay() then
					dspeed_start(player)
				end
			else
				if song_pos:GetFreeze() or song_pos:GetDelay() then
					dspeed_halt(player)
				end
			end
			if speed_info.prev_bps ~= this_bps and this_bps > 0 then
				speed_info.prev_bps= this_bps
				dspeed_start(player)
			end
			if player.dspeed.special then
				if player.dspeed.alternate then
					dspeed_special_phase_updates[player.dspeed_phase](player)
				else
					dspeed_alternate(player)
					if player.current_options:Centered() >= dspeed_default_max then
						dspeed_reset(player)
					end
				end
			else
				if player.current_options:Centered() >= player.dspeed.max then
					dspeed_reset(player)
				end
			end
		end
		if player.chuunibyou and player.chuunibyou > 0 then
			if song_pos:GetSongBeat() > next_chuunibyou[pn] then
				chuunibyou_state[pn]= not chuunibyou_state[pn]
				side_actors[pn]:x(chuunibyou_sides[chuunibyou_state[pn]])
				next_chuunibyou[pn]= next_chuunibyou[pn] + player.chuunibyou
			end
		end
		if notecolumns[pn] and get_screen_time() > next_spline_change_time then
			next_spline_change_time= next_spline_change_time + 20
			if cons_players[pn].pos_splines_demo or cons_players[pn].rot_splines_demo
			or cons_players[pn].zoom_splines_demo then
				for i= 1, #notecolumns[pn] do
					if hate then
						local spread= math.random(-120, 120)
						local per= spread / (#notecolumns[pn] - 1)
						local start= (spread * -.5) - per
						notecolumns[pn][i]:rotationz(start + (i * per))
					end
					if cons_players[pn].pos_splines_demo
					and not cons_players[pn].spatial_arrows then
						local handler= notecolumns[pn][i]:get_pos_handler()
						handler:set_beats_per_t(64/math.random(1, 32))
							:set_spline_mode("NoteColumnSplineMode_Offset")
							:set_subtract_song_beat(false)
						local spline= handler:get_spline()
						local num_points= math.random(1, 8)
						spline:set_loop(true):set_size(num_points)
						for p= 1, num_points do
							spline:set_point(p, {rand_pos(), rand_pos(), rand_pos()})
						end
						spline:solve()
					end
					if cons_players[pn].rot_splines_demo then
						local handler= notecolumns[pn][i]:get_rot_handler()
						handler:set_beats_per_t(64/math.random(1, 32))
							:set_spline_mode("NoteColumnSplineMode_Position")
							:set_subtract_song_beat(false)
						local spline= handler:get_spline()
						local num_points= math.random(1, 8)
						spline:set_loop(true):set_size(num_points)
						local prevx= rand_angle() * 4
						local prevy= rand_angle() * 4
						local prevz= rand_angle() * 4
						for p= 1, num_points do
							spline:set_point(p, {prevx, prevy, prevz})
							prevx= prevx + rand_angle()
							prevy= prevy + rand_angle()
							prevz= prevz + rand_angle()
						end
						spline:solve()
					end
					if cons_players[pn].zoom_splines_demo then
						local handler= notecolumns[pn][i]:get_zoom_handler()
						handler:set_beats_per_t(64/math.random(1, 32))
							:set_spline_mode("NoteColumnSplineMode_Position")
							:set_subtract_song_beat(false)
						local spline= handler:get_spline()
						local num_points= math.random(1, 8)
						spline:set_loop(true):set_size(num_points)
						for p= 1, num_points do
							spline:set_point(p, {rand_zoom(), rand_zoom(), rand_zoom()})
						end
						spline:solve()
					end
					notecolumns[pn][i]:linear(20)
				end
			end
		end
		if (side_swap_vals[pn] or 0) > 1 then
			if side_toggles[pn] then
				side_actors[pn]:x(player_sides[pn])
			else
				side_actors[pn]:x(swap_on_xs[pn])
			end
			side_toggles[pn]= not side_toggles[pn]
		end
	end
end

local tilt_scale= 1
local tilters= {
	addrotationx= {
		screen_layer= 1,
		note_layer= 3,
		{
			tilt_scale,
			Down= true, DownLeft= true,
		},
		{
			-tilt_scale,
			Up= true, DownRight= true,
		},
	},
	addrotationy= {
		screen_layer= 2,
		note_layer= 2,
		{
			tilt_scale,
			Right= true, UpRight= true,
		},
		{
			-tilt_scale,
			Left= true, UpLeft= true,
		},
	},
}

local function tilt_input(event)
	if event.type == "InputEventType_Release" then return end
	local pn= event.PlayerNumber
	if not pn then return end
	local button= event.button
	if not button then return end
	for tilt_name, parts in pairs(tilters) do
		for i, part in ipairs(parts) do
			if part[button] then
				local screen_layer= parts.screen_layer
				local note_layer= parts.note_layer
				if gameplay_wrappers[screen_layer][tilt_name] then
					gameplay_wrappers[screen_layer][tilt_name](
						gameplay_wrappers[screen_layer], part[1])
					for sub_pn, wrapper in pairs(notefield_wrappers) do
						wrapper[note_layer][tilt_name](wrapper[note_layer], -part[1])
					end
				else
					lua.ReportScriptError("Bad tilt name: " .. tilt_name)
				end
			end
		end
	end
end

local function facing_input(event)
	if event.type == "InputEventType_Release" then return end
	local pn= event.PlayerNumber
	local player= cons_players[pn]
--	if event.DeviceInput.button == "DeviceButton_j" and event.type == "InputEventType_FirstPress" then
--		screen_gameplay:PauseGame(not screen_gameplay:IsPaused())
--	end
	if not player or not player.spatial_turning or not notefields[pn] then
		return end
	local button= event.button
	local position= player.panel_positions[button]
	if not position then return end
	cons_players[pn].facing_angle= cons_players[pn].facing_angle + (.02 * position[1])
	cons_players[pn].facing_angle= approach(cons_players[pn].facing_angle, 0, .02 * math.abs(position[2]))
	local angle= cons_players[pn].facing_angle - math.pi*.5
	local anti= (-angle) - math.pi*.5
	notefields[pn]:rotationz(angle/math.pi*180 + 90)
	for i, actor in ipairs(notefields[pn]:get_column_actors()) do
		actor:get_rot_handler():get_spline():set_point(1, {0, 0, anti})
		:set_point(2, {0, 0, ani})
	end
end

local function chart_info_text(pn)
	local cur_steps= gamestate_get_curr_steps(pn)
	if not cur_steps then return "" end
	local author= steps_get_author(cur_steps, gamestate_get_curr_song())
	local difficulty= steps_to_string(cur_steps)
	local rating= cur_steps:GetMeter()
	return author .. ": " .. difficulty .. ": " .. rating
end

local lifex = {
	[PLAYER_1]= 12,
	[PLAYER_2]= _screen.w-12,
}

local function make_special_actors_for_players()
	if not can_have_special_actors() then
		return Def.Actor{}
	end
	local args= { Name= "special_actors",
								OnCommand= cmd(SetUpdateFunction,Update)
              }
	local function add_feedback(add_to_feedback, pn, el_pos, name, meat)
		add_to_feedback[#add_to_feedback+1]= {
			name= name, meattable= meat, center= {
				player_dec_centers[pn][1] + el_pos[name .. "_xoffset"],
				player_dec_centers[pn][2] + el_pos[name .. "_yoffset"]}}
	end
	for k, pn in pairs(enabled_players) do
		local add_to_feedback= {}
		local over_confident= cons_players[pn].confidence and cons_players[pn].confidence >= 50
		local flags= cons_players[pn].flags.gameplay
		local el_pos= cons_players[pn].gameplay_element_positions
		if flags.sigil then
			add_feedback(add_to_feedback, pn, el_pos, "sigil",
									 sigil_feedback_interface_mt)
		end
		if flags.judge and not over_confident then
			add_feedback(add_to_feedback, pn, el_pos, "judge_list",
									 judge_feedback_interface_mt)
		end
		if flags.score_meter and not over_confident then
			add_to_feedback[#add_to_feedback+1]= {
				name= "scoremeter", meattable= score_meter_mt,
				center= {score_meter_centers[pn][1], score_meter_centers[pn][2]}}
		end
		if (flags.dance_points or flags.pct_score) and not over_confident then
			add_feedback(add_to_feedback, pn, el_pos, "score",
									 numerical_score_feedback_mt)
		end
		if flags.bpm_meter then
			add_feedback(add_to_feedback, pn, el_pos, "bpm",
									 bpm_feedback_interface_mt)
		end
		local a= {Name= pn}
		a[#a+1]= LoadActor(THEME:GetPathG("", "special_lifebar.lua"), {pn= pn, x= lifex[pn]})
		for fk, fv in pairs(add_to_feedback) do
			local new_feedback= {}
			setmetatable(new_feedback, fv.meattable)
			a[#a+1]= new_feedback:create_actors(fv.name, fv.center[1], fv.center[2], pn)
			feedback_things[pn][#feedback_things[pn]+1]= new_feedback
		end
		if flags.chart_info then
			a[#a+1]= normal_text(
				"author", chart_info_text(pn), fetch_color("gameplay.chart_info"),
				fetch_color("gameplay.text_stroke"),
				player_dec_centers[pn][1] + el_pos.chart_info_xoffset,
				player_dec_centers[pn][2] + el_pos.chart_info_yoffset,
				el_pos.chart_info_scale, center,
				{ OnCommand= function(self)
						width_limit_text(self, spb_width/2 - 48, el_pos.chart_info_scale)
				end,
					["CurrentSteps"..ToEnumShortString(pn).."ChangedMessageCommand"]=
						function(self)
							if GAMESTATE:IsCourseMode() then return end
							self:settext(chart_info_text(pn))
							width_limit_text(self, spb_width/2 - 48, el_pos.chart_info_scale)
						end
			})
		end
		--[[
		a[#a+1]= Def.BitmapText{
			Font= THEME:GetPathF("Common", "Normal"), InitCommand= function(self)
				self:diffuse(Color.White)
				self:xy(author_centers[pn][1], author_centers[pn][2]+24)
			end,
			["CurrentSteps"..ToEnumShortString(pn).."ChangedMessageCommand"]=
				function(self)
					local steps= GAMESTATE:GetCurrentSteps(pn)
					local song= GAMESTATE:GetCurrentSong()
					if not steps or not song then self:settext("NPS: N/A") return end
					local song_len= song:GetLastSecond() - song:GetFirstSecond()
					local radar= steps:GetRadarValues(pn)
					local notes= radar:GetValue("RadarCategory_TapsAndHolds") +
						radar:GetValue("RadarCategory_Jumps") +
						radar:GetValue("RadarCategory_Hands")
					self:settext(("NPS: %.2f"):format(notes / song_len))
				end
		}
		a[#a+1]= normal_text(
			"toasties", "", nil, fetch_color("gameplay.text_stroke"),
				author_centers[pn][1], author_centers[pn][2]+24, 1, center,
				{ OnCommand= cmd(queuecommand, "Update"),
					ToastyAchievedMessageCommand= function(self, param)
						self:queuecommand("Update")
					end,
					UpdateCommand= function(self)
						local pro= PROFILEMAN:GetProfile(pn)
						local toasts= pro:GetNumToasties()
						local songs= pro:GetNumTotalSongsPlayed()
						local toast_pct= toasts / songs
						local color= percent_to_color((toast_pct-.75)*4)
						self:diffuse(color)
						self:settext(toasts .. "/" .. songs)
					end
		})
		]]
		args[#args+1]= Def.ActorFrame(a)
	end
	args[#args+1]= normal_text(
		"songtitle", "", fetch_color("gameplay.song_name"), nil, SCREEN_CENTER_X,
		spb_time_y - line_spacing, 1, center, {
			OnCommand= cmd(playcommand, "Set"),
			CurrentSongChangedMessageCommand= cmd(playcommand, "Set"),
			SetCommand= function(self)
				local cur_song= GAMESTATE:GetCurrentSong()
				if cur_song then
					local title= cur_song:GetDisplayFullTitle()
					self:settext(title)
						:strokecolor(fetch_color("gameplay.text_stroke"))
					width_limit_text(self, spb_width)
				end
			end
	})
	args[#args+1]= song_progress_bar:create_actors()
	args[#args+1]= song_rate:create_actors()
	return Def.ActorFrame(args)
end

local function apply_time_spent()
	local time_spent= gameplay_end_time - gameplay_start_time
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		cons_players[pn].credit_time= (cons_players[pn].credit_time or 0) + time_spent
	end
	reduce_time_remaining(time_spent)
	return time_spent
end

local confidence_data= {}
local function step_callback(pn)
	return function(col, score)
		if confidence_data[pn].active then
			return col, "TapNoteScore_Miss"
		else
			return col, score
		end
	end
end

local function setpressed_callback(pn)
	return function(col)
		if confidence_data[pn].active then
			return col, false
		else
			return col, true
		end
	end
end

local function didtapnote_callback(pn)
	return function(col, score, bright)
		if confidence_data[pn].active then
			return col, "TapNoteScore_Miss", bright
		else
			return col, score, bright
		end
	end
end

local function didholdnote_callback(pn)
	return function(col, score, bright)
		if confidence_data[pn].active then
			return col, "HoldNoteScore_MissedHold", bright
		else
			return col, score, bright
		end
	end
end

local side_names= {
	["Player" .. ToEnumShortString(PLAYER_1)]= true,
	["Player" .. ToEnumShortString(PLAYER_2)]= true,
}
local trans_names= {
	In= true, Out= true, Cancel= true
}

-- Don't feel like adding an arg to all the functions.
local inversion_toasty_level= 0

local function invert_not_notefield(child, invert)
	local name= child:GetName()
	local function sub_invert(sub_child)
		invert_not_notefield(sub_child, invert, true)
	end
	if side_names[name] then
		for_all_children(child, sub_invert)
	elseif name ~= "NoteField" then
		invert(child)
	end
end

local function wrap_invert(invert)
	return function(child) invert_not_notefield(child, invert) end
end

local function tween_not_trans(child, tween)
	if tween and not trans_names[child:GetName()] then
		child:finishtweening()
		rand_tween(child, inversion_toasty_level)
	end
end

local next_x_zoom= -1
local function horiz_invert_gameplay(tween)
	MESSAGEMAN:Broadcast("gameplay_xversion", {inversion_toasty_level, tween})
	local function invert_child(child, in_player)
		tween_not_trans(child, tween)
		if not in_player then
			child:x(_screen.w - child:GetDestX())
		end
		child:zoomx(next_x_zoom)
	end
	for_all_children(screen_gameplay, wrap_invert(invert_child))
	next_x_zoom= next_x_zoom * -1
end

local next_y_zoom= -1
local function vert_invert_gameplay(tween)
	MESSAGEMAN:Broadcast("gameplay_yversion", {inversion_toasty_level, tween})
	local function invert_child(child, in_player)
		tween_not_trans(child, tween)
		if not in_player then
			child:y(_screen.h - child:GetDestY())
		end
		child:zoomy(next_y_zoom)
	end
	for_all_children(screen_gameplay, wrap_invert(invert_child))
	next_y_zoom= next_y_zoom * -1
end

local function invert_both()
	horiz_invert_gameplay(true)
	vert_invert_gameplay(false)
end

local function wrap_inv(inv, tween)
	return function() inv(tween) end
end

local inversion_choices= {
	noop_nil,
	wrap_inv(horiz_invert_gameplay, true),
	wrap_inv(vert_invert_gameplay, true),
	invert_both,
}

local inversion_sets= {
	[0]= {1, 1},
	{1, 1}, {2, 2}, {3, 3}, {2, 2}, {3, 3}, {2, 3}, {2, 4}
}

local function cleanup(self)
	MESSAGEMAN:Broadcast("gameplay_unversion")
	prev_song_end_timestamp= hms_timestamp()
	local time_spent= apply_time_spent()
	set_last_song_time(time_spent)
	for i, pn in ipairs(enabled_players) do
		cons_players[pn].toasty= nil
	end
end

local do_unacceptable_check= false
local unacc_dp_limits= {}
local unacc_voted= {}
local unacc_reset_votes= 0

local mircol= {4, 3, 2, 1}
local function miss_all(col, tns, bright)
	return mircol[col], "TapNoteScore_W5", bright
end

local swap_start_beat= false
local swapper= false
local function swapper_starter(self)
	if not swap_start_beat or not swapper then return end
	local song_pos= GAMESTATE:GetSongPosition()
	if song_pos:GetSongBeat() > swap_start_beat then
		swapper:SetSecondsIntoAnimation(0):SetDecodeMovie(false)
		swap_start_beat= false
	end
end

local movie_exts= {
	avi= true, f4v= true, flv= true, mkv= true, mp4= true, mpeg= true,
	mpg= true, mov= true, ogv= true, webm= true, wmv= true,
}

local function bg_swap()
	if scrambler_mode then
		return swapping_amv(
			"swapper", _screen.cx, _screen.cy, _screen.w, _screen.h, 16, 10, nil,
			"_", false, true, true, {
				Def.ActorFrame{
					InitCommand= function(self)
						self:SetUpdateFunction(swapper_starter)
					end,
				},
				CurrentSongChangedMessageCommand= function(self, param)
					local song= GAMESTATE:GetCurrentSong()
					local path= false
					swapper= self:GetChild("amv")
					self:visible(false)
					if song:HasBGChanges() then
						local changes= song:GetBGChanges()
						if changes[1] then
							local ext= changes[1].file1:match("[^.]+$") or ""
							if movie_exts[ext:lower()] then
								path= song:GetSongDir() .. changes[1].file1
								swap_start_beat= changes[1].start_beat
							else
							end
						else
						end
					elseif song:HasBackground() then
						path= song:GetBackgroundPath()
					end
					if path then
						self:playcommand("ChangeTexture", {path}):visible(true)
							:queuecommand("HideBG")
					else
						self:visible(false)
					end
				end,
				HideBGCommand= function(self)
					SCREENMAN:GetTopScreen():GetChild("SongBackground"):visible(false)
				end,
				Def.Quad{
					InitCommand= function(self) self:FullScreen()
							:diffuse{0, 0, 0, 1-PREFSMAN:GetPreference("BGBrightness")}
					end
				}
		})
	else
		return Def.Actor{}
	end
end

return Def.ActorFrame {
	Name= "SGPbgf",
	bg_swap(),
	make_special_actors_for_players(),
	Def.Actor{
		Name= "timer actor",
		InitCommand= function(self)
									 self:effectperiod(2^16)
									 timer_actor= self
								 end,
	},
	Def.Actor{
		Name= "Cleaner S22", OnCommand= function(self)
			screen_gameplay= SCREENMAN:GetTopScreen()
			if tilt_mode then
				screen_gameplay:AddInputCallback(tilt_input)
			end
			screen_gameplay:AddInputCallback(facing_input)
			screen_gameplay:xy(-_screen.cx, -_screen.cy)
			for i= 1, wrapper_layers do
				gameplay_wrappers[i]= screen_gameplay:AddWrapperState()
			end
			gameplay_wrappers[wrapper_layers]:xy(_screen.cx, _screen.cy)
			screen_gameplay:HasteLifeSwitchPoint(.5, true)
				:HasteTimeBetweenUpdates(4, true)
				:HasteAddAmounts({-.25, 0, .25}, true)
				:HasteTurningPoints({-1, 0, 1})
			song_progress_bar:set_from_song()
			if song_opts:MusicRate() < 1 or song_opts:Haste() < 0 then
				song_opts:SaveScore(false)
			else
				song_opts:SaveScore(true)
			end
			prev_song_start_timestamp= hms_timestamp()
			local force_swap= (cons_players[PLAYER_1].side_swap or 0) > 1 or
				(cons_players[PLAYER_2].side_swap or 0) > 1
			local unacc_enable_votes= 0
			local unacc_reset_limit= misc_config:get_data().gameplay_reset_limit
			local curstats= STATSMAN:GetCurStageStats()
			for i, pn in ipairs(enabled_players) do
				for fk, fv in pairs(feedback_things[pn]) do
					if fv.update then fv:update(pstats[pn]) end
				end
				cons_players[pn].prev_steps= gamestate_get_curr_steps(pn)
				cons_players[pn]:stage_stats_reset()
				cons_players[pn]:combo_qual_reset()
				cons_players[pn].unmine_time= nil
				cons_players[pn].mine_data= nil
				local punacc= cons_players[pn].unacceptable_score
				if punacc.enabled then
					unacc_enable_votes= unacc_enable_votes + 1
					unacc_reset_limit= math.min(
						unacc_reset_limit, cons_players[pn].unacceptable_score.limit)
					local mdp= curstats:GetPlayerStageStats(pn):GetPossibleDancePoints()
					local tdp= mdp
					if punacc.condition == "dance_points" then
						tdp= math.max(0, math.round(punacc.value))
					elseif punacc.condition == "score_pct" then
						tdp= math.max(0, math.round(mdp - mdp * punacc.value))
					else
						unacc_enable_votes= unacc_enable_votes - 1
					end
					unacc_dp_limits[pn]= tdp
				end
				local speed_info= cons_players[pn].speed_info
				if speed_info then
					speed_info.prev_bps= nil
				end
				set_speed_from_speed_info(cons_players[pn])
				side_actors[pn]=
					screen_gameplay:GetChild("Player" .. ToEnumShortString(pn))
				side_actors[pn]:addy(cons_players[pn].gameplay_element_positions.notefield_yoffset)
				side_actors[pn]:addx(cons_players[pn].gameplay_element_positions.notefield_xoffset)
				notefields[pn]= side_actors[pn]:GetChild("NoteField")
				if notefields[pn] then
					local nx= side_actors[pn]:GetX()
					local ny= side_actors[pn]:GetY()
					local tocx= nx - (_screen.w*.5)
					local tocy= (ny - (_screen.h*.5)) * 0
					notefields[pn]:xy(tocx, -tocy)
					notefield_wrappers[pn]= {}
					for i= 1, wrapper_layers do
						notefield_wrappers[pn][i]= notefields[pn]:AddWrapperState()
					end
					notefield_wrappers[pn][wrapper_layers]:xy(-tocx, tocy)
					if notefields[pn].get_column_actors then
						notecolumns[pn]= notefields[pn]:get_column_actors()
						if cons_players[pn].man_lets_have_fun then
							local style_width= GAMESTATE:GetCurrentStyle(pn):GetWidth(pn)
							local column_width= style_width / #notecolumns[pn]
							note_drift_minx= column_width * 2
							note_drift_maxx= _screen.w - note_drift_minx
							for i, actor in ipairs(notecolumns[pn]) do
								actor:rainbow()
									:effecttiming(math.random(), math.random(),
										math.random(), math.random(), math.random())
							end
						end
						if cons_players[pn].spatial_turning then
							cons_players[pn].panel_positions= get_spatial_panel_positions(
								cons_players[pn].prev_steps:GetStepsType(), #notecolumns[pn])
							cons_players[pn].facing_angle= 0
							for i, actor in ipairs(notefields[pn]:get_column_actors()) do
								actor:get_rot_handler():set_spline_mode("NoteColumnSplineMode_Position")
									:set_beats_per_t(8)
									:get_spline():set_size(2)
									:set_point(1, {0, 0, 0})
									:set_point(2, {0, 0, 0}):solve()
							end
						end
						if cons_players[pn].spatial_arrows then
							notefields[pn]:addy(tocy)
							notefields[pn]:addx(-tocx)
							local positions= get_spatial_receptor_positions(
								cons_players[pn].prev_steps:GetStepsType(), #notecolumns[pn])
							for i, pos in ipairs(positions) do
								local sx= pos[1] * 64
								local sy= pos[2] * 64
								local ex= pos[1] * 10 * 64
								local ey= pos[2] * 10 * 64
								local handler= notecolumns[pn][i]:get_pos_handler()
								handler:set_spline_mode("NoteColumnSplineMode_Position")
									:set_beats_per_t(8)
									:get_spline():set_size(2):set_point(1, {sx, sy})
									:set_point(2, {ex, ey}):solve()
							end
						else
							local spread= cons_players[pn].column_angle or 0
							if hate then spread= math.random(-120, 120) end
							local per= spread / (#notecolumns[pn] - 1)
							local start= (spread * -.5) - per
							for i= 1, #notecolumns[pn] do
								notecolumns[pn][i]:rotationz(start + (i * per))
							end
						end
					end
					if cons_players[pn].side_swap or force_swap then
						side_swap_vals[pn]= cons_players[pn].side_swap or
							cons_players[other_player[pn]].side_swap
						local mod_res= side_swap_vals[pn] % 1
						if mod_res == 0 then mod_res= 1 end
						swap_on_xs[pn]= player_sides[pn] + (side_diffs[pn] * mod_res)
						side_actors[pn]:x(swap_on_xs[pn])
						side_toggles[pn]= true
					end
					if cons_players[pn].confidence
					and cons_players[pn].confidence > 0 then
						confidence_data[pn]= {
							active= false, chance= cons_players[pn].confidence
						}
						notefields[pn]:SetStepCallback(step_callback(pn))
						notefields[pn]:SetSetPressedCallback(setpressed_callback(pn))
						notefields[pn]:SetDidTapNoteCallback(didtapnote_callback(pn))
						notefields[pn]:SetDidHoldNoteCallback(didholdnote_callback(pn))
					end
				end
			end
			if unacc_enable_votes == #enabled_players and
				(GAMESTATE:IsEventMode() or get_current_song_length() /
				 song_ops:MusicRate() < get_time_remaining()) then
					unacc_reset_count= unacc_reset_count or 0
					if unacc_reset_count < unacc_reset_limit then
						do_unacceptable_check= true
					end
			end
		end,
		OffCommand= cleanup,
		CancelCommand= cleanup,
		CurrentSongChangedMessageCommand= function(self, param)
			song_progress_bar:set_from_song()
		end,
		CurrentStepsP1ChangedMessageCommand= function(self, param)
			set_speed_from_speed_info(cons_players[PLAYER_1])
		end,
		CurrentStepsP2ChangedMessageCommand= function(self, param)
			set_speed_from_speed_info(cons_players[PLAYER_2])
		end,
		ToastyAchievedMessageCommand= function(self, param)
			if cons_players[param.PlayerNumber].flags.gameplay.allow_toasty then
				inversion_toasty_level= cons_players[param.PlayerNumber].toasty_level
				local choice= rand_choice(inversion_toasty_level, inversion_sets)
				inversion_choices[choice]()
			end
		end,
		JudgmentMessageCommand= function(self, param)
			local pn= param.Player
			local confidence= confidence_data[pn]
			for fk, fv in pairs(feedback_things[pn]) do
				if fv.update then fv:update(pstats[pn]) end
			end
			if confidence then
				if confidence.active then
					if confidence.chance < 100 then
						confidence.active= confidence.active - 1
					elseif cons_players[pn].toasty then
						cons_players[pn].toasty.remaining= 100
					end
					if confidence.active < 1 then
						confidence.active = false
						cons_players[pn].song_options:MinTNSToHideNotes(confidence.min_tns)
					end
				else
					if math.random(0, 99) < confidence.chance then
						confidence.active= math.random(1, confidence.chance+1)
						confidence.min_tns= cons_players[pn].song_options:
							MinTNSToHideNotes("TapNoteScore_CheckpointHit")
						confidence.fake_judge= cons_players[pn].fake_judge
						cons_players[pn].toasty= {
							judge= "TapNoteScore_Miss", remaining= confidence.active,
							progress= 0}
					end
				end
			end
			if param.TapNoteScore == "TapNoteScore_HitMine" then
				local cp= cons_players[pn]
				if cp.mine_effect then
					local mine_data= mine_effects[cp.mine_effect]
					mine_data.apply(pn)
					cp.mine_data= mine_data
					if not cp.unmine_time then
						cp.unmine_time= get_screen_time()
					end
					cp.unmine_time= cp.unmine_time + mine_data.time
				end
			end
			if do_unacceptable_check and not unacc_voted[pn] then
				local pdp= pstats[pn]:GetCurrentPossibleDancePoints()
				local adp= pstats[pn]:GetActualDancePoints()
				if pdp - adp > unacc_dp_limits[pn] then
					unacc_voted[pn]= true
					unacc_reset_votes= unacc_reset_votes + 1
					if unacc_reset_votes >= #enabled_players then
						unacc_reset_count= unacc_reset_count + 1
						apply_time_spent()
						for i, pn in ipairs(enabled_players) do
							while GAMESTATE:GetNumStagesLeft(pn) < 3 do
								GAMESTATE:AddStageToPlayer(pn)
							end
						end
						SCREENMAN:SetNewScreen("ScreenStageInformation")
					end
				end
			end
		end,
	},
}
