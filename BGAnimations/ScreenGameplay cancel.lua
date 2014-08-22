dofile(THEME:GetPathO("", "art_helpers.lua"))
return random_grow_circle(
	"", _screen.cx, _screen.cy, adjust_luma(solar_colors.red(.75), .25),
	adjust_luma(solar_colors.red(.75), .015625), .25, _screen.w, "StartTransitioning")
