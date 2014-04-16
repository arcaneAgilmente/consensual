-- this file returns a single quad that represents the background of most screens in the theme.
return Def.Quad{
	-- FullScreen is defined in Themes/_fallback/Scripts/02 Actor.lua in sm-ssc.
	-- bg comes from Scripts/01 solar_colors.lua
	InitCommand=cmd(FullScreen;diffuse,solar_colors.bg())
}
