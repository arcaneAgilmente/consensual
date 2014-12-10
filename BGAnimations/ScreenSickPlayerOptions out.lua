if in_edit_mode then
	return Def.ActorFrame{
		Def.Actor{
			Name= "cover", StartTransitioningCommand= function(self)
				local screen= SCREENMAN:GetTopScreen()
				screen:linear(1)
				screen:diffusealpha(0)
				self:sleep(1)
			end
		}
	}
else
	return dofile(THEME:GetPathG("", "general_out.lua"))
end
