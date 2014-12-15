if in_edit_mode then
	return Def.ActorFrame{
		Def.Actor{
			Name= "cover", StartTransitioningCommand= function(self)
				SCREENMAN:GetTopScreen():linear(.5):diffusealpha(0)
				self:sleep(.5)
			end
		}
	}
else
	return dofile(THEME:GetPathG("", "general_out.lua"))
end
