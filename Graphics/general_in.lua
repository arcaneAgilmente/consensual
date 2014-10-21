return Def.Quad{
	StartTransitioningCommand= function(self)
		self:xy(_screen.cx, _screen.cy)
		self:setsize(_screen.w, _screen.h)
		self:diffuse(fetch_color("bg"))
		self:linear(.5)
		self:diffusealpha(0)
	end
}
