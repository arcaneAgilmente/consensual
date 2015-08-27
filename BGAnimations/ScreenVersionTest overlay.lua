local version_failed= false
local show_message= false
local message= ""
local next_screen= "ScreenInitialMenu"

if not get_music_file_length then
	version_failed= true
	show_message= true
	message= "You must upgrade to Stepmania 5.0.9.  Some special effects require functions added in Stepmania 5.0.9.  If you believe you are on 5.0.9 and are using the SSE2 exe, that executable is outdated.  Non-SSE2 support was dropped and the exe without the sse2 suffix should be the only one."
end

if not PREFSMAN:GetPreference("SmoothLines") then
	show_message= true
	next_screen= "ScreenOptionsGraphicsSound"
	message= "You have the Smooth Lines preference set to false.  Consensual uses linestrips in many places, and having Smooth Lines set to false will ruin your frame rate.\nGoing to Graphics options screen so you can set it to true."
end

-- The banner cache slows down startup time by forcing stepmania to look in
-- every song folder.  It's not used by Consensual at all, and provides no
-- benefit to other themes.
PREFSMAN:SetPreference("BannerCache", "BannerCacheMode_Off")

if PREFSMAN:GetPreference("IgnoredDialogs") ~= "" then
	PREFSMAN:SetPreference("IgnoredDialogs", "")
	show_message= true
	message= "If you see errors, report them with any information you have so they can be fixed."
end

if PREFSMAN:GetPreference("VideoRenderers"):sub(1, 6) ~= "opengl" then
	version_failed= true
	show_message= true
	message= "d3d renderer not supported.  Edit your Preferences.ini to switch VideoRenderers to opengl."
end

dofile(THEME:GetPathO("", "strokes.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))
local unfold_time= 4
local fade_time= 1

local function continue()
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

local function input(event)
	if event.DeviceInput.button == "DeviceButton_f" then
		PREFSMAN:SetPreference("IgnoredDialogs", "")
		hate= false
		next_screen= "ScreenInitialMenu"
	elseif event.type == "InputEventType_FirstPress"
	and event.GameButton == "Start" then
		continue()
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
			self:sleep(unfold_time+fade_time)
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
			continue()
		end
	},
	animated_text("Consensual", _screen.cx, _screen.cy, 4, unfold_time, fade_time),
--	unfolding_text(
--		"logo", _screen.cx, _screen.cy, "Consensual", fetch_color("text"),
--		unfold_time, nil, nil, .5),
	Def.BitmapText{
		Font= "Common Normal", OnCommand= function(self)
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
