local cursor= setmetatable({}, cursor_mt)
return Def.ActorFrame{
	Def.Quad{
		Name= "bg", InitCommand= cmd(setsize,100,32;diffuse,fetch_color("bg", .875))
	},
	cursor:create_actors(
		"cursor", 0, 0, 2, fetch_color("player.both"),
		fetch_color("player.hilight"), true, false),
	Def.Actor{ InitCommand= function(self) cursor:refit(0, 0, 100, 32) end,},
}
