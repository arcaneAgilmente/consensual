local shimon= setmetatable({}, frame_helper_mt)
local kotai= setmetatable({}, frame_helper_mt)
return Def.ActorFrame{
	shimon:create_actors(
		"shimon", 1, 608, 80, fetch_color("rev_bg"), fetch_color("bg", .875),
		_screen.cx, THEME:GetMetric("ScreenTextEntry", "QuestionY")),
	kotai:create_actors(
		"kotai", 1, 608, 32, fetch_color("rev_bg"), fetch_color("bg", .875),
		_screen.cx, THEME:GetMetric("ScreenTextEntry", "AnswerY")),
}
