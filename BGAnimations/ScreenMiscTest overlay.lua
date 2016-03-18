local model= false
local secs_in= 0
local state= 0
local trans= 0

local function input(event)
	if event.type == "InputEventType_Release" then return end
	if event.DeviceInput.button == "DeviceButton_n" then
		secs_in= secs_in + .01
		model:position(secs_in)
	elseif event.DeviceInput.button == "DeviceButton_m" then
		trans= trans + .001
		model:texturetranslate(trans, 0)
	elseif event.DeviceInput.button == "DeviceButton_k" then
		PROFILEMAN:SetStatsPrefix("pantsu_")
	elseif event.DeviceInput.button == "DeviceButton_l" then
		PROFILEMAN:SetStatsPrefix("")
	end
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.Model{
		InitCommand= function(self)
			model= self:xy(_screen.cx, _screen.cy):animate(false)
		end,
		Meshes= THEME:GetPathG("", "test/_down tap note model"),
		Materials= THEME:GetPathG("", "test/_down tap note model"),
		Bones= THEME:GetPathG("", "test/_down tap note model"),
	},
}

return Def.ActorFrame(args)
