local default_config= {
	bg_tex_size= 256,
	bg_zoomx= 1.25,
	bg_zoomy= 1.25,
	square_bg= false,
	amount= 64,
	pos_min_speed= 1,
	pos_max_speed= 2,
	min_size= 4,
	max_size= 128,
	size_min_speed= 2^-9,
	size_max_speed= 2^-8,
	min_color= .5,
	max_color= .875,
	color_min_speed= 2^-5,
	color_max_speed= 2^-4,
}
bubble_config= create_setting(
	"bubble config", "bubble_config.lua", default_config, -1)
bubble_config:load()
