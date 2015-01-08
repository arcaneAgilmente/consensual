local version_failed= false
local show_message= false
local message= ""
local next_screen= "ScreenInitialMenu"
if not NoteField or not NoteField.SetStepCallback then
	version_failed= true
	show_message= true
	message= "Your version of Stepmania is too old for this version of Consensual.\nUpgrade to a nightly build made on or after 2014/12/14.\nhttp://smnightly.katzepower.com/  (build #864 should work)\nSwitching to a different theme."
end

if not CubicSplineN then
	show_message= true
	message= "Gameplay transitions use splines for smooth edges now.\nEdges will be spiky in builds without splines."
end

if not PREFSMAN:GetPreference("SmoothLines") then
	show_message= true
	next_screen= "ScreenOptionsGraphicsSound"
	message= "You have the Smooth Lines preference set to false.  Consensual uses linestrips in many places, and having Smooth Lines set to false will ruin your frame rate.\nGoing to Graphics options screen so you can set it to true."
end

if PREFSMAN:GetPreference("IgnoredDialogs") ~= ""
and GAMESTATE:GetCurrentGame():GetName():lower() ~= "kickbox" then
	show_message= true
	message= "... I hate you."
	hate= true
end

dofile(THEME:GetPathO("", "art_helpers.lua"))
local unfold_time= 4

local function input(event)
	if event.DeviceInput.button == "DeviceButton_f" then
		PREFSMAN:SetPreference("IgnoredDialogs", "")
		next_screen= "ScreenExit"
	end
end

return Def.ActorFrame{
	Def.BitmapText{
		Font= "Common Normal", Text= message, InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy)
			self:wrapwidthpixels(_screen.w-32)
			self:diffuse(fetch_color("text"))
			self:strokecolor(fetch_color("stroke"))
			self:diffusealpha(0)
			self:sleep(unfold_time+1)
			if show_message then
				self:linear(.5)
				self:diffusealpha(1)
				self:linear(5)
			end
			self:queuecommand("Continue")
		end,
		OnCommand= function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(input)
		end,
		ContinueCommand= function(self)
			if version_failed then
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
				trans_new_screen(next_screen)
			end
		end
	},
	unfolding_text(
		"logo", _screen.cx, _screen.cy, "Consensual", fetch_color("text"),
		unfold_time, nil, nil, .5)
}
