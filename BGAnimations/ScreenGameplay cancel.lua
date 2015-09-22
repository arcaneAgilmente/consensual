dofile(THEME:GetPathO("", "art_helpers.lua"))
local circle_rad= math.sqrt(((_screen.w/2)^2) + ((_screen.h/2)^2))
return Def.ActorFrame{
	StartTransitioningCommand= function(self)
		update_player_stats_after_song()
	end,
	random_grow_circle(
	"", _screen.cx, _screen.cy,
	adjust_luma(Alpha(fetch_color("gameplay.cancel"), .75), .25),
	adjust_luma(Alpha(fetch_color("gameplay.cancel"), .75), .015625),
		.125, circle_rad, "StartTransitioning")
}
