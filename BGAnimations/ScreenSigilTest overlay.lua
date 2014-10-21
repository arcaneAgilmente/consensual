dofile(THEME:GetPathO("", "sigil.lua"))

local sigil= setmetatable({}, sigil_controller_mt)

local sigil_status= false

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	if event.PlayerNumber and event.GameButton then
		if event.GameButton == "MenuLeft" then
			sigil:redetail((sigil.detail or 1) - 1)
		elseif event.GameButton == "MenuRight" then
			sigil:redetail((sigil.detail or 1) + 1)
		end
	end
	if event.DeviceInput.button == "DeviceButton_n" then
		sigil:redetail(64)
		for i= 1, 32 do
			sigil:redetail(64-i)
		end
	end
	if event.DeviceInput.button == "DeviceButton_m" then
		sigil:redetail(1)
		for i= 1, 32 do
			sigil:redetail(1+i)
		end
	end
	local status_text= tostring(#sigil.detail_queue) .. ": " ..
		table.concat(sigil.detail_queue, ", ")
	sigil_status:settext(status_text)
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	sigil:create_actors("sigil", SCREEN_CENTER_X, SCREEN_CENTER_Y, fetch_color("accent.cyan"), 64, 300),
	Def.BitmapText{
		Name= "sigil_status",
		Font= "Common Normal",
		InitCommand= function(self)
			self:xy(SCREEN_CENTER_X, 16)
			sigil_status= self
			self:diffuse(fetch_color("text"))
		end
	},
	Def.BitmapText{
		Name= "game chars test",
		Font= "Common Normal",
		InitCommand= function(self)
			self:xy(SCREEN_CENTER_X, 40)
			self:settext("&left; &down; &up; &right; &downleft; &upleft; &upright; &downright; &center; &start; &select; &back; &menuleft; &menudown; &menuup; &menuright;")
		end
	},
	Def.BitmapText{
		Name= "game chars stroke test",
		Font= "Common Normal",
		InitCommand= function(self)
			self:xy(SCREEN_CENTER_X, 40)
			self:settext("&left; &down; &up; &right; &downleft; &upleft; &upright; &downright; &center; &start; &select; &back; &menuleft; &menudown; &menuup; &menuright;")
			self:strokecolor(fetch_color("accent.magenta"))
		end
	},
}

return Def.ActorFrame(args)
