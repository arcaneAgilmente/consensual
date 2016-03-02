-- This provides a few key shortcuts for common editing tasks like changing
-- the current speed mod, toggling assist clap, and toggling between normal
-- music rate and half music rate.

-- This is intended as ScreenEdit overlay.lua.  If the theme you are using
-- already has ScreenEdit overlay.lua, consult the theme author about adding
-- this functionality.
-- lua is easier for this stuff than C++, and doesn't require making a new
-- release, so I don't feel like putting this in the general edit mode.

-- Original author: Kyzentun

-- Editing notes:
-- toggle_clap_key, toggle_half_rate_key, speed_mod_inc_key,
-- speed_mod_dec_key, and speed_mod_change_scale_key are meant to be set by
-- the user to whatever keys they want.
-- But finding keys not already used by edit mode can be difficult.
-- Edit mode uses the up and down keys mapped for each player for scrolling.
-- This also includes the MenuUp and MenuDown keys.
-- The left button for each player seems to delete an arrow, I have no idea
-- why.
-- So if one of the up/down keys is used for one of the keys in this file,
-- then both things will happen, which is inconvenient.
-- The back button for each player is used to bring up the options menu.
-- Edit mode leaves the following keys unused: y, i, s, d, f, g, h, j, k, z,
--   x, c
-- The keys on the numpad appear to all be unused too.
-- Set show_cur_press to true to turn on an actor that will tell you the name
-- of a key that is pressed.
-- It may be tempting to use alt for speed_mod_change_scale_key because it is
-- a modifier key, but that will cause you problems when you use alt+tab to
-- switch to something else and stepmania doesn't see the key release.  So
-- don't use alt.
-- I am not responsible for any problems that arise from accidentally mapping
-- a key that turns out to do something unexpected in edit mode.  It's a
-- hairy beast, test your chosen keys carefully to make sure they don't do
-- anything.

-- If clap or half rate end up still on after you leave edit mode, whoops.
-- Didn't happen to me when I tried it, so I think the options get reset
-- correctly.

-- half_rate, speed_mod_inc, speed_mod_scale, and default_speed_mod can be
-- edited, but the default values seem reasonable to me.

-- Comments below this point are meant for explaining things to themers.

-- The actors inside main_frame should be edited by the themer adding this to
-- their theme.  The actors given are simple BitmapTexts with no animations.
-- Each actor must have a SetStatusCommand to respond to each type of change.
-- Note also that each actor sets a corresponding variable so that the input
-- handler can run the SetStatus command when something happens.

local toggle_clap_key= "y"
local toggle_half_rate_key= "h"
local speed_mod_inc_key= "g"
local speed_mod_dec_key= "f"
local speed_mod_change_scale_key= "k"
local mini_inc_key= "d"
local mini_dec_key= "s"
local mini_change_scale_key= "j"
local show_cur_press= false
-- Using variables to store the buttons that will be used makes it easy to
-- configure them because they are set aside in their own section that people
-- can safely edit with low risk of breaking something.  If a future design
-- change decides that the buttons should be loaded from some config file,
-- the loading code can easily set the variables without needing to find the
-- input processing logic.

local half_rate= .5
local speed_mod_inc= 10
local speed_mod_scale= 10
local default_speed_mod= 400
local mini_inc= .01
local mini_scale= 10
local default_mini= 0

local speed_mod_scale_active= false
local mini_scale_active= false

-- Setting variables to refer to the options objects makes them easier to use
-- later.  player_state will be needed when applying the speed changes.
local song_options= GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
local player_state= GAMESTATE:GetPlayerState(PLAYER_1)
local player_options= player_state:GetPlayerOptions("ModsLevel_Preferred")

-- I like to initialize variables to false when they are going to be used to
-- access actors.  The actor will do the real initialization in InitCommand.
local speed_status_actor= false
local speed_inc_status_actor= false
local mini_status_actor= false
local mini_inc_status_actor= false
local clap_status_actor= false
local rate_status_actor= false
local cur_press_status_actor= false

-- Multiple places need to get the current amount that the speed is
-- incremented by, so the logic of checking whether the scale key is held is
-- wrapped in get_speed_inc.  Then everything that needs the increment calls
-- get_speed_inc() instead of duplicating the logic.  If the logic ever needs
-- to change, there is only one place to change.
local function get_speed_inc()
	if speed_mod_scale_active then
		return speed_mod_scale * speed_mod_inc
	else
		return speed_mod_inc
	end
end

local function get_mini_inc()
	if mini_scale_active then
		return mini_scale * mini_inc
	else
		return mini_inc
	end
end

-- get_mmod exists for a similar reason, it contains a bit of logic that is
-- used in multiple places.
local function get_mmod()
	-- The PlayerOptions functions don't have separate get and set functions,
	-- both things are combined into a single function.  A PlayerOptions
	-- function always returns the previous value.  If the arg is nil, it does
	-- not set a new value.
	local mmod= player_options:MMod()
	-- MMod returns nil if the player is currently set to a C or X mod.  This
	-- code is written to only deal with M mods, so when MMod returns nil, the
	-- default is used.
	if not mmod then mmod= default_speed_mod end
	return mmod
end

-- Wrapping a bit of logic in a function to make it easier to change later is
-- a core part of programming.
local function set_mmod(mmod)
	player_options:MMod(mmod)
	-- ApplyPreferredOptionsToOtherLevels does what its name says.  It takes
	-- what is set at ModsLevel_Preferred and applies it to ModsLevel_Stage,
	-- ModsLevel_Song, and ModsLevel_Current.  Edit mode has some screwy
	-- handling of mods, so the simplest thing to do is just apply the mods to
	-- all levels.
	player_state:ApplyPreferredOptionsToOtherLevels()
	speed_status_actor:playcommand("SetStatus", {mmod= mmod})
end

local function get_mini()
	return player_options:Mini()
end

local function set_mini(mini)
	player_options:Mini(mini)
	player_state:ApplyPreferredOptionsToOtherLevels()
	mini_status_actor:playcommand("SetStatus", {mini= mini})
end

-- The apply functions are used by the input handler to apply a change, and
-- by the initialization code to set the initial status of the actors when
-- the screen starts up.  This ensures that the initial status of an actor
-- will always be the same as an actor that was set by some input, even when
-- changes occur later.
local function apply_scale_active(active)
	speed_mod_scale_active= active
	speed_inc_status_actor:playcommand("SetStatus", {scale_active= speed_mod_scale_active})
end

local function apply_mini_scale_active(active)
	mini_scale_active= active
	mini_inc_status_actor:playcommand("SetStatus", {scale_active= mini_scale_active})
end

local function apply_clap(clap)
	song_options:AssistClap(clap)
	GAMESTATE:ApplyPreferredSongOptionsToOtherLevels()
	clap_status_actor:playcommand("SetStatus", {clap= clap})
end

local function apply_rate(rate)
	song_options:MusicRate(rate)
	GAMESTATE:ApplyPreferredSongOptionsToOtherLevels()
	rate_status_actor:playcommand("SetStatus", {rate= rate})
end

local function input(event)
	local button= ToEnumShortString(event.DeviceInput.button)
	if event.type == "InputEventType_FirstPress" then
		if show_cur_press then
			cur_press_status_actor:playcommand("SetStatus", {button= button})
		end
		if button == speed_mod_change_scale_key then
			apply_scale_active(true)
		elseif button == mini_change_scale_key then
			apply_mini_scale_active(true)
		elseif button == toggle_clap_key then
			local clap_status= not song_options:AssistClap()
			apply_clap(clap_status)
		elseif button == toggle_half_rate_key then
			local rate= song_options:MusicRate()
			-- half_rate could be set to anything, and MusicRate might not return
			-- it with the same precision because it's a float value.  So the
			-- easiest way to tell if the rate is currently set to half_rate is to
			-- compare to 1.  If someone sets half_rate to something greater than
			-- 1, they'll break this toggling logic.
			if rate < 1 then
				rate= 1
			else
				rate= half_rate
			end
			apply_rate(rate)
		elseif button == speed_mod_inc_key then
			-- This is where we see the benefit of creating get_speed_inc,
			-- get_mmod, and set_mmod functions.  Without those functions, the
			-- logic in them would have to be duplicated, which would make later
			-- modifications more difficult.
			set_mmod(get_mmod() + get_speed_inc())
		elseif button == speed_mod_dec_key then
			set_mmod(get_mmod() - get_speed_inc())
		elseif button == mini_inc_key then
			set_mini(get_mini() + get_mini_inc())
		elseif button == mini_dec_key then
			set_mini(get_mini() - get_mini_inc())
		end
	elseif event.type == "InputEventType_Release" then
		if button == speed_mod_change_scale_key then
			apply_scale_active(false)
		elseif button == mini_change_scale_key then
			apply_mini_scale_active(false)
		end
	end
end

-- Making an init actor like this should make it less likely for another
-- themer to accidentally break some of the init logic.
local function init_actor()
	return Def.Actor{
		OnCommand= function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(input)
			set_mmod(get_mmod())
			set_mini(get_mini())
			apply_scale_active()
			apply_mini_scale_active()
			apply_clap(false)
			apply_rate(1)
		end
	}
end

local next_y= 4

local main_frame= Def.ActorFrame{
	init_actor(),
	OnCommand= function(self)
		self:zoom(.5):xy(_screen.cx*.4, 16)
	end,
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			-- Setting a variable like this allows other code to access this actor
			-- directly.  I prefer this method over broadcasting a message or
			-- traversing the actor tree because it's more direct.
			cur_press_status_actor= self
			self:xy(0, 104)
		end,
		SetStatusCommand= function(self, param)
			self:settextf('"%s"', param.button)
		end,
	},
	Def.ActorFrame{
		InitCommand= function(self)
			speed_inc_status_actor= self
			self:xy(0, next_y):vertalign(top)
			next_y= next_y + 12
		end,
		Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				self:y(-8):zoom(.5)
					:settextf("(*%d: %s)", speed_mod_scale, speed_mod_change_scale_key)
			end,
		},
		Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				self:x(25):horizalign(left)
			end,
			SetStatusCommand= function(self, param)
				local inc= get_speed_inc()
				self:settextf("+%d (%s)", inc, speed_mod_inc_key)
			end,
		},
		Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				self:x(-25):horizalign(right)
			end,
			SetStatusCommand= function(self, param)
				local inc= get_speed_inc()
				self:settextf("(%s) -%d", speed_mod_dec_key, inc)
			end,
		},
	},
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			speed_status_actor= self
			self:xy(0, next_y):vertalign(top)
			next_y= next_y + 36
		end,
		SetStatusCommand= function(self, param)
			self:settextf("Speed: m%d", param.mmod)
		end
	},
	Def.ActorFrame{
		InitCommand= function(self)
			mini_inc_status_actor= self
			self:xy(0, next_y):vertalign(top)
			next_y= next_y + 12
		end,
		Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				self:y(-8):zoom(.5)
					:settextf("(*%d: %s)", mini_scale, mini_change_scale_key)
			end,
		},
		Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				self:x(25):horizalign(left)
			end,
			SetStatusCommand= function(self, param)
				local inc= get_mini_inc() * 100
				self:settextf("+%d (%s)", inc, mini_inc_key)
			end,
		},
		Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				self:x(-25):horizalign(right)
			end,
			SetStatusCommand= function(self, param)
				local inc= get_mini_inc() * 100
				self:settextf("(%s) -%d", mini_dec_key, inc)
			end,
		},
	},
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			mini_status_actor= self
			self:xy(0, next_y):vertalign(top)
			next_y= next_y + 24
		end,
		SetStatusCommand= function(self, param)
			self:settextf("Mini: %d%%", param.mini*100)
		end
	},
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			clap_status_actor= self
			self:xy(0, next_y):vertalign(top)
			next_y= next_y + 24
		end,
		SetStatusCommand= function(self, param)
			if param.clap then
				self:settextf("(%s) Clap: On", toggle_clap_key)
			else
				self:settextf("(%s) Clap: Off", toggle_clap_key)
			end
		end,
	},
	Def.BitmapText{
		Font= "Common Normal", InitCommand= function(self)
			rate_status_actor= self
			self:xy(0, next_y):vertalign(top)
			next_y= next_y + 24
		end,
		SetStatusCommand= function(self, param)
			self:settextf("(%s) Rate: %.2f", toggle_half_rate_key, param.rate)
		end,
	},
}

return main_frame
