if in_edit_mode then
	return Def.ActorFrame{
		Def.Actor{
			Name= "cover", StartTransitioningCommand= function(self)
				SCREENMAN:GetTopScreen():diffusealpha(0):linear(.5):diffusealpha(1)
				self:sleep(.5)
			end
		}
	}
else
	return dofile(THEME:GetPathG("", "general_in.lua"))
end
