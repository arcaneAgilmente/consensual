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
									 self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
									 self:scaletofit(0, 0, SCREEN_RIGHT, SCREEN_BOTTOM)
									 self:diffusealpha(.25)
								 end
	}
}
