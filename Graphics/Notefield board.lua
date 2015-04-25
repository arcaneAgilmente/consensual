local filter_color= fetch_color("accent.violet")
--color("0.135,0.135,0.135,1")

return Def.ActorFrame{Def.Quad{
	InitCommand= function(self)
		self:hibernate(math.huge):diffuse(filter_color)
	end,
	PlayerStateSetCommand= function(self, param)
		local pn= param.PlayerNumber
		local style= GAMESTATE:GetCurrentStyle(pn)
		local alf= .2
		local width= style:GetWidth(pn) + 8
		self:setsize(width, _screen.h*4096):diffusealpha(alf):hibernate(0)
	end,
}}
