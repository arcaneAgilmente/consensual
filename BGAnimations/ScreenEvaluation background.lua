return Def.ActorFrame {
	Name= "SEbg",
	Def.Quad{ Name= "bgquad", InitCommand=cmd(FullScreen;diffuse,solar_colors.bg()) },
	Def.Sprite{
		Name= "background",
		InitCommand= function(self)
									 local song= gamestate_get_curr_song()
									 if song and song:HasBackground() then
										 self:LoadFromCurrentSongBackground()
									 else
										 self:visible(false)
									 end
									 self:FullScreen()
									 self:diffusealpha(.25)
								 end
	}
}
