local cursor= setmetatable({}, cursor_mt)
return Def.ActorFrame{
	cursor:create_actors(
		"cursor", 0, 0, 2, fetch_color("player.both"),
		fetch_color("player.hilight"), {{"top", "MenuUp"}, {"bottom", "MenuDown"}}),
	Def.Actor{
		OnCommand= function(self)
			self:GetParent():draworder(2):GetParent():SortByDrawOrder()
			cursor:refit(nil, nil, mini_menu_width+8, 20)
		end,
		ChangeCommand= function(self)
			self:GetParent():stoptweening():linear(.1)
		end
	},
}
