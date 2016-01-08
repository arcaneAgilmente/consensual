local args= {...}
local pn= args[1].pn
local life= -1
local cp= cons_players[pn]
local life_use_width= cp.life_use_width
local life_stages= cp.life_stages or 1
if life_stages < 1 then return Def.Actor{} end
local full_width= 24
local x= args[1].x
local surround_mode= cp.flags.gameplay.surround_life
local edge_align= left
local edge_width= 0
local xs= false
local parts= {}
local zooms= {1, -1}
local container= false
local function calc_edge_width()
	edge_width= full_width * ((1 - cp.life_blank_percent) * .5)
	if edge_width < 0 then edge_align= right end
	xs= {full_width * -.5, full_width * .5}
end
calc_edge_width()
local gec= cp.gameplay_element_colors
local color_sets= {
	{gec.life_empty_inner, gec.life_full_inner},
	{gec.life_empty_outer, gec.life_full_outer},
}

local function enable_surround()
	local plactor= SCREENMAN:GetTopScreen():GetChild(
		"Player"..ToEnumShortString(pn))
	local plax= plactor:GetX()
	container:x(plax)
	local left_dist= plax
	local right_dist= _screen.w - plax
	local use_dist= math.min(left_dist, right_dist)
	full_width= use_dist * 2 * life_use_width
	calc_edge_width()
	for i, part in ipairs(parts) do
		part:x(xs[i]):playcommand("RealignWidth")
	end
end

local function disable_surround()
	full_width= 24
	x= args[1].x
	container:x(x)
	calc_edge_width()
	for i, part in ipairs(parts) do
		part:x(xs[i]):playcommand("RealignWidth")
	end
end

local frame_args= {
	InitCommand= function(self)
		container= self
		self:xy(x, _screen.h)
	end,
	OnCommand= function(self)
		if not surround_mode then return end
		enable_surround()
	end,
	LifeChangedMessageCommand= function(self, param)
		if param.Player == pn then
			local goal_life= param.LifeMeter:GetLife()
			if goal_life == life then return end
			self:playcommand("life_update", {life= goal_life})
		end
	end,
	life_updateCommand= function(self, param)
		life= param.life
		local colors= {}
		local floor_stage= math.floor(life * life_stages)
		local lower_floor= floor_stage / life_stages
		local upper_floor= (floor_stage+1) / life_stages
		local staged_life= scale(life, lower_floor, upper_floor, 0, 1)
		local color_life= staged_life^2
		if life >= 1 then
			colors[1]= color_sets[1][2]
			colors[2]= color_sets[2][2]
			staged_life= 1
		else
			for i, color_set in ipairs(color_sets) do
				local lower_color= lerp_color(
					lower_floor, color_set[1], color_set[2])
				local upper_color= lerp_color(
					upper_floor, color_set[1], color_set[2])
				colors[i]= lerp_color(color_life, lower_color, upper_color)
			end
		end
		local curr_inner= lerp_color(life, empty_inner, full_inner)
		local curr_outer= lerp_color(life, empty_outer, full_outer)
		for i, part in ipairs(parts) do
			part:stoptweening():april_linear(.1):zoomy(staged_life)
				:diffuseleftedge(colors[2]):diffuserightedge(colors[1])
		end
	end,
	color_changedMessageCommand= function(self, param)
		if param.pn ~= pn then return end
		color_sets= {
			{gec.life_empty_inner, gec.life_full_inner},
			{gec.life_empty_outer, gec.life_full_outer},
		}
		self:playcommand("life_update", {life= life})
		self:finishtweening()
	end,
	player_flags_changedMessageCommand= function(self, param)
		if param.pn ~= pn then return end
		if param.name ~= "surround_life" then return end
		if cp.flags.gameplay.surround_life then
			enable_surround()
		else
			disable_surround()
		end
	end,
	gameplay_conf_changedMessageCommand= function(self, param)
		if param.pn ~= pn then return end
		if param.thing ~= "lifebar" then return end
		life_use_width= cp.life_use_width
		life_stages= cp.life_stages
		if cp.flags.gameplay.surround_life then
			enable_surround()
		else
			disable_surround()
		end
		self:playcommand("life_update", {life= life})
		self:finishtweening()
	end,
}
for i, qx in ipairs(xs) do
	frame_args[#frame_args+1]= Def.Quad{
		InitCommand= function(self)
			parts[#parts+1]= self
			self:xy(qx, 0):vertalign(bottom)
				:zoomx(zooms[i]):zoomy(0):playcommand("RealignWidth")
		end,
		RealignWidthCommand= function(self)
			self:horizalign(edge_align):setsize(edge_width, _screen.h)
		end
	}
end
return Def.ActorFrame(frame_args)
