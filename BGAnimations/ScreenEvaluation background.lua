local bg_color= fetch_color("evaluation.bg")
local args= {
	Name= "SEbg",
	Def.Quad{
		Name= "bgquad", InitCommand=
			cmd(FullScreen;diffuse,Alpha(bg_color, 1)) },
}

if scrambler_mode then
	args[#args+1]= swapping_amv(
		"swapper", _screen.cx, _screen.cy, _screen.w, _screen.h, 16, 10, nil,
		"_", false, true, true, {
			SubInitCommand= function(self)
				local song= gamestate_get_curr_song()
				if song and song:HasBackground() then
					self:playcommand("ChangeTexture", {song:GetBackgroundPath()})
				else
					self:visible(false)
				end
				self:diffusealpha(bg_color[4])
			end,
	})
else
	args[#args+1]= Def.Sprite{
		Name= "background", InitCommand= function(self)
			local song= gamestate_get_curr_song()
			if song and song:HasBackground() then
				self:LoadFromCurrentSongBackground()
			else
				self:visible(false)
			end
			self:scale_or_crop_background():diffusealpha(bg_color[4])
		end
	}
end

return Def.ActorFrame(args)
