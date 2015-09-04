return Def.ActorFrame{Def.Quad{
	InitCommand= function(self)
		self:hibernate(math.huge)
	end,
	PlayerStateSetCommand= function(self, param)
		local pn= param.PlayerNumber
		local filter_color= cons_players[pn].gameplay_element_colors.filter
		-- The NewField will send WidthSetCommand if it exists.  But the old one
		-- won't, so fetch the width from the style anyway.
		local style= GAMESTATE:GetCurrentStyle(pn)
		local alf= .2
		local width= style:GetWidth(pn) + 8
		self:setsize(width, _screen.h*4096)
		self:diffuse(filter_color):hibernate(0)
		if filter_color[4] < .001 then self:hibernate(math.huge) end
	end,
	WidthSetCommand= function(self, param)
		local width= param.Width + 8
		self:setsize(width, _screen.h*4096)
	end
}}
