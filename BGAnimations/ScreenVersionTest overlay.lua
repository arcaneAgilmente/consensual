local test_failed= false
local test_text= ""
if not NoteField or not NoteField.SetStepCallback then
	test_failed= true
	test_text= "Your version of Stepmania is too old for this version of Consensual.\nUpgrade to a nightly build made on or after 2014/12/14.\nhttp://smnightly.katzepower.com/  (build #864 should work)\nSwitching to a different theme."
end

dofile(THEME:GetPathO("", "art_helpers.lua"))
local unfold_time= 4

return Def.ActorFrame{
	Def.BitmapText{
		Font= "Common Normal", Text= test_text, InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy)
			self:wrapwidthpixels(_screen.w-32)
			self:diffuse(fetch_color("text"))
			self:strokecolor(fetch_color("stroke"))
			self:diffusealpha(0)
			self:sleep(unfold_time+1)
			if test_failed then
				self:linear(.5)
				self:diffusealpha(1)
				self:linear(5)
			end
			self:queuecommand("Continue")
		end,
		ContinueCommand= function(self)
			if test_failed then
				local theme_names= THEME:GetSelectableThemeNames()
				local simply_love= false
				local ultralight= false
				for i, name in ipairs(theme_names) do
					if name == "Simply Love" or name == "Simply-Love-SM5" then
						simply_love= name
					elseif name == "ultralight" then
						ultralight= name
					end
				end
				if simply_love then
					THEME:SetTheme(simply_love)
				elseif ultralight then
					THEME:SetTheme(ultralight)
				else
					THEME:SetTheme("default")
				end
			else
				trans_new_screen("ScreenInitialMenu")
			end
		end
	},
	unfolding_text(
		"logo", _screen.cx, _screen.cy, "Consensual", fetch_color("text"),
		unfold_time, nil, nil, .5)
}
