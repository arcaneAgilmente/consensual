local function rand_color()
	return {math.random(), math.random(), math.random(), math.random()}
end
local function maybe_rand_color(c)
	if c == "random" then return rand_color() end
	return c
end

local args= {...}
local pn= args[1].pn
local life= -1
local cp= cons_players[pn]
local life_use_width= cons_players[pn].life_use_width
local full_width= 24
local x= args[1].x
local surround_mode= cp.flags.gameplay.surround_life
local edge_align= left
local edge_width= 0
local xs= false
local function calc_edge_width()
	edge_width= full_width * ((1 - cp.life_blank_percent) * .5)
	if edge_width < 0 then edge_align= right end
	xs= {full_width * -.5, full_width * .5}
end
calc_edge_width()
local gec= cp.gameplay_element_colors
local full_outer= maybe_rand_color(gec.life_full_outer)
local full_inner= maybe_rand_color(gec.life_full_inner)
local empty_outer= maybe_rand_color(gec.life_empty_outer)
local empty_inner= maybe_rand_color(gec.life_empty_inner)

local parts= {}
local zooms= {1, -1}
local container= false
local frame_args= {
	InitCommand= function(self)
		container= self
		self:xy(x, _screen.h)
	end,
	OnCommand= function(self)
		if not surround_mode then return end
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
	end,
	LifeChangedMessageCommand= function(self, param)
		if param.Player == pn then
			local goal_life= param.LifeMeter:GetLife()
			if goal_life == life then return end
			life= goal_life
			local curr_inner= lerp_color(life, empty_inner, full_inner)
			local curr_outer= lerp_color(life, empty_outer, full_outer)
			for i, part in ipairs(parts) do
				part:stoptweening():linear(.1):zoomy(life)
					:diffuseleftedge(curr_outer):diffuserightedge(curr_inner)
			end
		end
	end
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
