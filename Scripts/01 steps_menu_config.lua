local default_config= {
	center_text_zoom= .5,
	item_text_zoom= .5,
	center_radius= 28,
	item_radius= 8,
	item_pad= 8,
	item_focus_zoom= 1.5,
	xoff= 0,
	yoff= 0,
}
steps_menu_config= create_setting(
	"steps menu config", "steps_menu_config.lua", default_config, -1)
steps_menu_config:load()
