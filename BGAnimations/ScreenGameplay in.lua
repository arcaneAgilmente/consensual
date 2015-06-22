return Def.Actor{
	StartTransitioningCommand= function(self)
		local trans_time= .5
		SCREENMAN:GetTopScreen():diffusealpha(0)
			:april_linear(trans_time):diffusealpha(1)
		self:sleep(trans_time)
	end
}
