local rate_coordinator= setmetatable({}, rate_coordinator_interface_mt)
rate_coordinator:initialize()

local function can_have_special_actors()
	local screen_name= Var("LoadingScreen")
	return screen_name == "ScreenGameplay" or
		screen_name == "ScreenDemonstration"
end

-- The order of these elements also affects the coloring of the score meter.
local feedback_judgements= {
	"TapNoteScore_Miss", "TapNoteScore_W5", "TapNoteScore_W4",
	"TapNoteScore_W3", "TapNoteScore_W2", "TapNoteScore_W1"
}

local screen_gameplay= false
local song_opts= GAMESTATE:GetSongOptionsObject("ModsLevel_Current")

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

local judge_spacing= line_spacing * .75
local judge_y= spb_time_y - (line_spacing * 2) - (judge_spacing * #feedback_judgements)
local judge_centers= {
	[PLAYER_1]= { SCREEN_CENTER_X - (SCREEN_CENTER_X / 2), judge_y},
	[PLAYER_2]= { SCREEN_CENTER_X + (SCREEN_CENTER_X / 2), judge_y}
}

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
function judge_feedback_interface:create_actors(name, fx, fy, player_number)
	if not name then return nil end
	self.name= name
	self.player_number= player_number
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
	local tx= -10
	local nx= 10
	local start_y= 0
	for n= 1, #feedback_judgements do
		local new_element= {}
		setmetatable(new_element, text_and_number_interface_mt)
		args[#args+1]= new_element:create_actors(
			feedback_judgements[n], {
				sy= start_y + judge_spacing * n, tx= tx, nx= nx, tz= .75, nz= .75,
				tc= judge_to_color(feedback_judgements[n]),
				nc= judge_to_color(feedback_judgements[n]),
				text_section= "JudgementNames",
				tt= feedback_judgements[n]})
		self.elements[#self.elements+1]= new_element
	end
	return Def.ActorFrame(args)
end

function judge_feedback_interface:update(player_stage_stats)
	if cons_players[self.player_number].fake_judge then
		local fake_score= cons_players[self.player_number].fake_score
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

local sigil_centers= {
	[PLAYER_1]= { SCREEN_CENTER_X - (SCREEN_CENTER_X / 2), SCREEN_BOTTOM*.375},
	[PLAYER_2]= { SCREEN_CENTER_X + (SCREEN_CENTER_X / 2), SCREEN_BOTTOM*.375}
}

dofile(THEME:GetPathO("", "sigil.lua"))

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
	return self.sigil:create_actors(name, fx, fy, pn_to_color(player_number), player_data.detail, player_data.size)
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

local score_feedback_interface= {}
local score_feedback_centers= {
	[PLAYER_1]= { SCREEN_LEFT + 32, SCREEN_BOTTOM },
	[PLAYER_2]= { SCREEN_RIGHT - 32, SCREEN_BOTTOM }
}
function score_feedback_interface:create_actors(name, fx, fy, player_number)
	if not name then return nil end
	self.name= name
	self.player_number= player_number
	if not fx then fx= 0 end
	if not fy then fy= 0 end
	return Def.ActorFrame{
		Name= name, InitCommand= function(subself)
			subself:xy(fx, fy)
			self.container= subself
			self.meter= subself:GetChild("meter")
		end,
		Def.Quad{ Name= "meter", InitCommand= function(self)
								self:setsize(16, SCREEN_BOTTOM):vertalign(bottom)
							end
		}
	}
end

function score_feedback_interface:update(player_stage_stats)
	local adp= player_stage_stats:GetActualDancePoints()
	local mdp= player_stage_stats:GetPossibleDancePoints()
	local fake_score
	if cons_players[self.player_number].fake_judge then
		fake_score= cons_players[self.player_number].fake_score
		adp= fake_score.dp
	end
	local score= adp / mdp
	local function set_color(c)
		self.meter:diffuse(c)
	end
	if fake_score then
		for i, fj in ipairs(feedback_judgements) do
			if fake_score.judge_counts[fj] > 0 then
				set_color(judge_to_color(fj))
				break
			end
		end
	else
		for i, fj in ipairs(feedback_judgements) do
			if player_stage_stats:GetTapNoteScores(fj) > 0 then
				set_color(judge_to_color(fj))
				break
			end
		end
	end
	if score < 0 then
		score= -score
		self.container:y(0)
		self.meter:vertalign(top)
	else
		self.container:y(_screen.h)
		self.meter:vertalign(bottom)
	end
	self.meter:zoomy(score^((score+1)^((score*2.718281828459045))))
end

local score_feedback_interface_mt= { __index= score_feedback_interface }

local dp_feedback_centers= {
	[PLAYER_1]= { SCREEN_RIGHT * .25, SCREEN_TOP + h_line_spacing },
	[PLAYER_2]= { SCREEN_RIGHT * .75, SCREEN_TOP + h_line_spacing }
}

local numerical_score_feedback_mt= {
	__index= {
		create_actors= function(self, name, x, y, pn)
			self.name= name
			self.player_number= pn
			x= x or 0
			y= y or 0
			local flags= cons_players[pn].flags.gameplay
			self.fmat= "%.2f%%"
			local args= {
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.pct= subself:GetChild("pct")
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
						local dp_width= (self.max_dp:GetWidth() * 2) + 20
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
						"curr_dp", "0", fetch_color("text"), nil, -10, 0, 1, right),
					normal_text(
						"slash_dp", "/", fetch_color("text"), nil, 0, 0, 1),
					normal_text(
						"max_dp", "0", fetch_color("text"), nil, 10, 0, 1, left),
				}
			end
			if flags.pct_score then
				args[#args+1]= normal_text(
					"pct", "", fetch_color("text"), nil, 0, 0, 1, right)
			end
			return Def.ActorFrame(args)
		end,
		init= function(self, pss)
			self.inited= true
		end,
		update= function(self, pss)
			if not self.inited then
				self:init(pss)
			end
			local adp= pss:GetActualDancePoints()
			local mdp= pss:GetPossibleDancePoints()
			local fake_score
			if cons_players[self.player_number].fake_judge then
				fake_score= cons_players[self.player_number].fake_score
				adp= fake_score.dp
			end
			local text_color= fetch_color("text")
			if fake_score then
				for i, fj in ipairs(feedback_judgements) do
					if fake_score.judge_counts[fj] > 0 then
						text_color= judge_to_color(fj)
						break
					end
				end
			else
				for i, fj in ipairs(feedback_judgements) do
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
local bpm_y= spb_time_y
local bpm_centers= {
	[PLAYER_1]= { SCREEN_CENTER_X - (SCREEN_CENTER_X / 2), bpm_y},
	[PLAYER_2]= { SCREEN_CENTER_X + (SCREEN_CENTER_X / 2), bpm_y}
}
local bpm_feedback_interface_mt= { __index= bpm_feedback_interface }
function bpm_feedback_interface:create_actors(name, fx, fy, player_number)
	self.name= name
	self.tani= setmetatable({}, text_and_number_interface_mt)
	self.player_number= player_number
	return Def.ActorFrame{
		Name= self.name, InitCommand= function(subself)
			subself:xy(fx, fy)
			self.container= subself
			self.tani.text:strokecolor(fetch_color("gameplay.text_stroke"))
			self.tani.number:strokecolor(fetch_color("gameplay.text_stroke"))
		end,
		self.tani:create_actors(
			"tani", { tx= -4, nx= 4, tt= "BPM: ", text_section= "ScreenGameplay"
							})
	}
end

function bpm_feedback_interface:update()
	local bpm= screen_gameplay:GetTrueBPS(self.player_number) * 60
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
	return Def.ActorFrame{
		Name= self.name, InitCommand= function(subself)
			subself:xy(spb_x, spb_y)
			self.container= subself
			self.filler= subself:GetChild("filler")
			self.time= subself:GetChild("time")
			self.song_first_second= 0
			self.song_len= 1
		end,
		self.frame:create_actors(
			"frame", .5, spb_width, spb_height,
			fetch_color("gameplay.song_progress_bar.frame"),
			fetch_color("gameplay.song_progress_bar.bg"),
			0, 0),
		Def.Quad{
			Name= "filler", InitCommand=
				function(self)
					self:diffuse(
						fetch_color("gameplay.song_progress_bar.progression.too_low"))
						:x(spb_width * -.5):horizalign(left)
						:setsize(spb_width, spb_height-1):zoomx(0)
				end
		},
		normal_text("time", "", nil, fetch_color("gameplay.song_progress_bar.stroke"),
		0, -spb_time_off)
	}
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
	local zoom= cur_seconds / self.song_len
	local cur_color= color_in_set(self.progress_colors, math.ceil(zoom * #self.progress_colors), false, false, false)
	self.filler:diffuse(cur_color):zoomx(zoom)
	cur_seconds= math.floor(cur_seconds)
	if cur_seconds ~= self.prev_second then
		self.prev_second= cur_seconds
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
local song_progress_bar= setmetatable({}, song_progress_bar_interface_mt)

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

local function Update(self)
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
	for k, v in pairs(enabled_players) do
		player= cons_players[v]
		local unmine_time= player.unmine_time
		if unmine_time and unmine_time <= get_screen_time() then
			player.mine_data.unapply(v)
			player.mine_data= nil
			player.unmine_time= nil
		end
		local speed_info= player:get_speed_info()
		if speed_info.mode == "CX" and screen_gameplay.GetTrueBPS then
			local this_bps= screen_gameplay:GetTrueBPS(v)
			if speed_info.prev_bps ~= this_bps and this_bps > 0 then
				speed_info.prev_bps= this_bps
				local xmod= (speed_info.speed) / (this_bps * 60)
				player.song_options:XMod(xmod)
				player.current_options:XMod(xmod)
			end
		end
		local song_pos= GAMESTATE:GetPlayerState(v):GetSongPosition()
		if speed_info.mode == "D" then
			local this_bps= screen_gameplay:GetTrueBPS(v)
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
			if song_pos:GetSongBeat() > next_chuunibyou[v] then
				chuunibyou_state[v]= not chuunibyou_state[v]
				side_actors[v]:x(chuunibyou_sides[chuunibyou_state[v]])
				next_chuunibyou[v]= next_chuunibyou[v] + player.chuunibyou
			end
		end
		if (side_swap_vals[v] or 0) > 1 then
			if side_toggles[v] then
				side_actors[v]:x(player_sides[v])
			else
				side_actors[v]:x(swap_on_xs[v])
			end
			side_toggles[v]= not side_toggles[v]
		end
		for fk, fv in pairs(feedback_things[v]) do
			if fv.update then fv:update(pstats[v]) end
		end
	end
end

local author_centers= {
	[PLAYER_1]= { SCREEN_RIGHT * .25, SCREEN_TOP + (line_spacing*1.5) },
	[PLAYER_2]= { SCREEN_RIGHT * .75, SCREEN_TOP + (line_spacing*1.5) }
}

local function chart_info_text(pn)
	local cur_steps= gamestate_get_curr_steps(pn)
	if not cur_steps then return "" end
	local author= steps_get_author(cur_steps, gamestate_get_curr_song())
	local difficulty= steps_to_string(cur_steps)
	local rating= cur_steps:GetMeter()
	return author .. ": " .. difficulty .. ": " .. rating
end

local function make_special_actors_for_players()
	if not can_have_special_actors() then
		return Def.Actor{}
	end
	local args= { Name= "special_actors",
								OnCommand= cmd(SetUpdateFunction,Update)
              }
	for k, v in pairs(enabled_players) do
		local add_to_feedback= {}
		local flags= cons_players[v].flags.gameplay
		if flags.sigil then
			add_to_feedback[#add_to_feedback+1]= {
				name= "sigil", meattable= sigil_feedback_interface_mt,
				center= {sigil_centers[v][1], sigil_centers[v][2]}}
		end
		if flags.judge then
			add_to_feedback[#add_to_feedback+1]= {
				name= "judge_list", meattable= judge_feedback_interface_mt,
				center= {judge_centers[v][1], judge_centers[v][2]}}
		end
		if flags.score_meter then
			add_to_feedback[#add_to_feedback+1]= {
				name= "scoremeter", meattable= score_feedback_interface_mt,
				center= {score_feedback_centers[v][1], score_feedback_centers[v][2]}}
		end
		if flags.dance_points or flags.pct_score then
			add_to_feedback[#add_to_feedback+1]= {
				name= "scorenumber", meattable= numerical_score_feedback_mt,
				center= {dp_feedback_centers[v][1], dp_feedback_centers[v][2]}}
		end
		if flags.bpm_meter then
			add_to_feedback[#add_to_feedback+1]= {
				name= "bpm", meattable= bpm_feedback_interface_mt,
				center= {bpm_centers[v][1], bpm_centers[v][2]}}
		end
		local a= {Name= v}
		for fk, fv in pairs(add_to_feedback) do
			local new_feedback= {}
			setmetatable(new_feedback, fv.meattable)
			a[#a+1]= new_feedback:create_actors(fv.name, fv.center[1], fv.center[2], v)
			feedback_things[v][#feedback_things[v]+1]= new_feedback
		end
		if flags.chart_info then
			a[#a+1]= normal_text(
				"author", chart_info_text(v), fetch_color("gameplay.chart_info"),
				fetch_color("gameplay.text_stroke"),
				author_centers[v][1], author_centers[v][2], 1, center,
				{ OnCommand= function(self)
						width_limit_text(self, spb_width/2 - 48)
				end,
					["CurrentSteps"..ToEnumShortString(v).."ChangedMessageCommand"]=
						function(self)
							if GAMESTATE:IsCourseMode() then return end
							self:settext(chart_info_text(v))
							width_limit_text(self, spb_width/2 - 48)
						end
			})
		end
		--[[
		a[#a+1]= normal_text(
			"toasties", "", nil, fetch_color("gameplay.text_stroke"),
				author_centers[v][1], author_centers[v][2]+24, 1, center,
				{ OnCommand= cmd(queuecommand, "Update"),
					ToastyAchievedMessageCommand= cmd(queuecommand, "Update"),
					UpdateCommand= function(self)
						local pro= PROFILEMAN:GetProfile(v)
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

local function cleanup(self)
	prev_song_end_timestamp= hms_timestamp()
	local time_spent= apply_time_spent()
	set_last_song_time(time_spent)
end

local do_unacceptable_check= false
local unacc_dp_limits= {}
local unacc_voted= {}
local unacc_reset_votes= 0

local mircol= {4, 3, 2, 1}
local function miss_all(col, tns, bright)
	return mircol[col], "TapNoteScore_W5", bright
end

return Def.ActorFrame {
	Name= "SGPbgf",
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
			screen_gameplay:HasteLifeSwitchPoint(.5, true)
				:HasteTimeBetweenUpdates(4, true)
				:HasteAddAmounts({-.25, 0, .25}, true)
				:HasteTurningPoints({-1, 0, 1})
			song_progress_bar:set_from_song()
			local song_ops= GAMESTATE:GetSongOptionsObject("ModsLevel_Current")
			if song_ops:MusicRate() < 1 or song_ops:Haste() < 0 then
				song_ops:SaveScore(false)
			else
				song_ops:SaveScore(true)
			end
			prev_song_start_timestamp= hms_timestamp()
			local force_swap= (cons_players[PLAYER_1].side_swap or 0) > 1 or
				(cons_players[PLAYER_2].side_swap or 0) > 1
			local unacc_enable_votes= 0
			local unacc_reset_limit= misc_config:get_data().gameplay_reset_limit
			local curstats= STATSMAN:GetCurStageStats()
			for k, v in pairs(enabled_players) do
				cons_players[v].prev_steps= gamestate_get_curr_steps(v)
				cons_players[v]:stage_stats_reset()
				cons_players[v]:combo_qual_reset()
				cons_players[v].unmine_time= nil
				cons_players[v].mine_data= nil
				local punacc= cons_players[v].unacceptable_score
				if punacc.enabled then
					unacc_enable_votes= unacc_enable_votes + 1
					unacc_reset_limit= math.min(
						unacc_reset_limit, cons_players[v].unacceptable_score.limit)
					local mdp= curstats:GetPlayerStageStats(v):GetPossibleDancePoints()
					local tdp= mdp
					if punacc.condition == "dance_points" then
						tdp= math.max(0, math.round(punacc.value))
					elseif punacc.condition == "score_pct" then
						tdp= math.max(0, math.round(mdp - mdp * punacc.value))
					else
						unacc_enable_votes= unacc_enable_votes - 1
					end
					unacc_dp_limits[v]= tdp
				end
				local speed_info= cons_players[v].speed_info
				if speed_info then
					speed_info.prev_bps= nil
				end
				set_speed_from_speed_info(cons_players[v])
				side_actors[v]=
					screen_gameplay:GetChild("Player" .. ToEnumShortString(v))
				notefields[v]= side_actors[v]:GetChild("NoteField")
				if notefields[v] then
					--notefields[v]:SetDidTapNoteCallback(miss_all)
				end
				if cons_players[v].side_swap or force_swap then
					side_swap_vals[v]= cons_players[v].side_swap or
						cons_players[other_player[v]].side_swap
					local mod_res= side_swap_vals[v] % 1
					if mod_res == 0 then mod_res= 1 end
					swap_on_xs[v]= player_sides[v] + (side_diffs[v] * mod_res)
					side_actors[v]:x(swap_on_xs[v])
					side_toggles[v]= true
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
		JudgmentMessageCommand= function(self, param)
			local pn= param.Player
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
