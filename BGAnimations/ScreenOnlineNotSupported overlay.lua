return Def.ActorFrame{
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy):diffuse(fetch_color("text"))
				:stroke(fetch_color("stroke")):wrapwidthpixels(_screen.w-32)
				:settext(
					"Online mode is not supported.\n" ..
						"Choose a different theme to play online mode.\n" ..
						"Porting my music wheel to work in online mode would probably " ..
						"require a ton of work and I never play online mode.")
				:sleep(10):queuecommand("ChangeScreen")
		end,
		ChangeScreenCommand= function(self)
			trans_new_screen("ScreenAppearanceOptions")
		end
	}
}
