local version_failed= false
local show_message= false
local message= ""
local next_screen= "ScreenInitialMenu"

if not Actor.AddWrapperState then
	show_message= true
	message= "You should upgrade to Stepmania 5.0.5.  Some special effects require functions added in Stepmania 5.0.5."
end

if not NoteField or not NoteField.SetStepCallback then
	version_failed= true
	show_message= true
	message= "Your version of Stepmania is too old for this version of Consensual.\nUpgrade to Stepmania 5.0.5.\nSwitching to a different theme."
end

if not PREFSMAN:GetPreference("SmoothLines") then
	show_message= true
	next_screen= "ScreenOptionsGraphicsSound"
	message= "You have the Smooth Lines preference set to false.  Consensual uses linestrips in many places, and having Smooth Lines set to false will ruin your frame rate.\nGoing to Graphics options screen so you can set it to true."
end

if PREFSMAN:GetPreference("IgnoredDialogs") ~= ""
and GAMESTATE:GetCurrentGame():GetName():lower() ~= "kickbox" then
	PREFSMAN:SetPreference("IgnoredDialogs", "")
	show_message= true
	message= "If you see errors, report them with any information you have so they can be fixed."
end

dofile(THEME:GetPathO("", "art_helpers.lua"))
local unfold_time= 4

local function input(event)
	if event.DeviceInput.button == "DeviceButton_f" then
		PREFSMAN:SetPreference("IgnoredDialogs", "")
		hate= false
		next_screen= "ScreenInitialMenu"
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
			if version_failed or hate then
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
		unfold_time, nil, nil, .5),
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			if misc_config:get_data().show_startup_time then
				if not startup_time then
					startup_time= GetTimeSinceStart()
				end
				Warn("Startup time: " .. startup_time)
				self:zoom(.5):xy(_screen.cx, SCREEN_BOTTOM-48)
					:settext("Startup time: " .. startup_time)
					:diffuse(fetch_color("text")):strokecolor(fetch_color("stroke"))
			end
		end
	},
}
