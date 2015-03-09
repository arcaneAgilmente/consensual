return Def.ActorFrame{
	InitCommand= cmd(xy,_screen.cx,_screen.cy),
	Def.Quad{
		Name= "bg", InitCommand= cmd(
			setsize,_screen.w,_screen.h;diffuse,fetch_color("bg", .875);),
		OnCommand= function(self)
			self:queuecommand("Recenter")
		end,
		RecenterCommand= function(self)
			-- ScreenMiniMenuContext is forced off center by the engine.
			-- I want it centered to make row and bg placement easy.
			SCREENMAN:GetTopScreen():xy(0, 0)
		end
	},
}
