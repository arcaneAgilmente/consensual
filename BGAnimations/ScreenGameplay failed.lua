dofile(THEME:GetPathO("", "art_helpers.lua"))
return random_grow_circle(
	"", _screen.cx, _screen.cy, adjust_luma(solar_colors.violet(.75), .25),
	adjust_luma(solar_colors.violet(.75), .015625), .125, _screen.w, "StartTransitioning")
