return Def.ActorFrame{Def.Quad{
	InitCommand= function(self)
		self:hibernate(math.huge)
	end,
	PlayerStateSetCommand= function(self, param)
		local pn= param.PlayerNumber
		local style= GAMESTATE:GetCurrentStyle(pn)
		local alf= .2
		local width= style:GetWidth(pn) + 8
		local filter_color= cons_players[pn].gameplay_element_colors.filter
		self:setsize(width, _screen.h*4096):diffuse(filter_color):hibernate(0)
		if filter_color[4] < .001 then self:hibernate(math.huge) end
	end,
}}
