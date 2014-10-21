local bg_color= fetch_color("evaluation.bg")
return Def.ActorFrame {
	Name= "SEbg",
	Def.Quad{
		Name= "bgquad", InitCommand=
			cmd(FullScreen;diffuse,Alpha(bg_color, 1)) },
	Def.Sprite{
		Name= "background", InitCommand= function(self)
			local song= gamestate_get_curr_song()
			if song and song:HasBackground() then
				self:LoadFromCurrentSongBackground()
			else
				self:visible(false)
			end
			self:scale_or_crop_background()
			self:diffusealpha(bg_color[4])
		end
	}
}
