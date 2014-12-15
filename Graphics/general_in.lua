return Def.Quad{
	StartTransitioningCommand= function(self)
		self:xy(_screen.cx, _screen.cy):setsize(_screen.w, _screen.h)
			:diffuse(fetch_color("bg")):linear(.5):diffusealpha(0)
	end
}
