local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.DeviceInput.button == "DeviceButton_w" then
	elseif event.DeviceInput.button == "DeviceButton_w" then
	end
end

local white= {1, 1, 1, 1}

local texpath= ""

local width= .1
local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.Quad{
		InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy):setsize(100, 20)
				:cropleft(-width):cropright(1)
				:queuecommand("Fade")
		end,
		FadeCommand= function(self)
			self:linear(1):cropleft(1):cropright(-width):linear(0):cropleft(-width):cropright(1)
				:queuecommand("Fade")
		end,
	},
}

return Def.ActorFrame(args)
