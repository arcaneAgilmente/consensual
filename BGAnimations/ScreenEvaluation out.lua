return Def.ActorFrame{
	dofile(THEME:GetPathG("", "general_out.lua")),
	normal_text(
		"going", "", fetch_color("text"), fetch_color("bg"), _screen.cx,
		_screen.cy, 2, nil, {
			InitCommand= function(self)
				if get_time_remaining() < misc_config:get_data().min_remaining_time
				or #bucket_man.filtered_songs < 1 then
					self:settext("Your turn ends here.")
				else
					self:settext("Keep playing!")
				end
			end
	})
}
