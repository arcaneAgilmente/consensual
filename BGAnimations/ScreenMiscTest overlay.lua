dofile(THEME:GetPathO("", "art_helpers.lua"))

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
end
local loaded_guy= LoadActor(THEME:GetPathG("", "guy"))
loaded_guy.BaseRotationZ= 90

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.Sprite{
		Texture= THEME:GetPathG("", "guy"), InitCommand= function(self)
			self:xy(_screen.cx*.5, _screen.cy)
		end,
		BaseRotationZ= 180,
	},
	loaded_guy,
}

return Def.ActorFrame(args)
