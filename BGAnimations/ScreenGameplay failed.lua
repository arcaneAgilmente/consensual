dofile(THEME:GetPathO("", "art_helpers.lua"))
return Def.ActorFrame{
	StartTransitioningCommand= function(self)
		update_player_stats_after_song()
	end,
	random_grow_circle(
		"", _screen.cx, _screen.cy,
		adjust_luma(Alpha(fetch_color("gameplay.failed"), .75), .25),
		adjust_luma(Alpha(fetch_color("gameplay.failed"), .75), .015625),
			.125, _screen.w, "StartTransitioning")
}
