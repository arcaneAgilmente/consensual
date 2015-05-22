dofile(THEME:GetPathO("", "art_helpers.lua"))

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= event.DeviceInput.button
	if button == "DeviceButton_n" then
	end
end

local black= {0, 0, 0, 1}
local tlc= black
local tcc= fetch_color("accent.orange")
local trc= black
local clc= fetch_color("accent.yellow")
local ccc= fetch_color("accent.orange")
local crc= fetch_color("accent.red")
local blc= black
local bcc= fetch_color("accent.orange")
local brc= black
--[[
local tlc= fetch_color("accent.red")
local tcc= fetch_color("accent.orange")
local trc= fetch_color("accent.yellow")
local clc= fetch_color("accent.magenta")
local ccc= color("#7f7f7f")
local crc= fetch_color("accent.green")
local blc= fetch_color("accent.violet")
local bcc= fetch_color("accent.blue")
local brc= fetch_color("accent.cyan")
]]

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.ActorFrame{
		InitCommand= function(self)
			self:diffuse(color("#7f7f7f"))
		end,
		Def.Quad{
			InitCommand= function(self)
				self:xy(0, 0):setsize(_screen.cx, _screen.cy)
					:horizalign(left):vertalign(top)
					:diffuseupperleft(tlc):diffuseupperright(tcc)
					:diffuselowerleft(clc):diffuselowerright(ccc)
			end
		},
		Def.Quad{
			InitCommand= function(self)
				self:xy(_screen.w, 0):setsize(_screen.cx, _screen.cy)
					:zoomx(-1)
					:horizalign(left):vertalign(top)
					:diffuseupperleft(trc):diffuseupperright(tcc)
					:diffuselowerleft(crc):diffuselowerright(ccc)
			end
		},
		Def.Quad{
			InitCommand= function(self)
				self:xy(0, _screen.h):setsize(_screen.cx, _screen.cy)
					:zoomy(-1)
					:horizalign(left):vertalign(top)
					:diffuseupperleft(blc):diffuseupperright(bcc)
					:diffuselowerleft(clc):diffuselowerright(ccc)
			end
		},
		Def.Quad{
			InitCommand= function(self)
				self:xy(_screen.cx, _screen.cy):setsize(_screen.cx, _screen.cy)
					:horizalign(left):vertalign(top)
					:diffuseupperleft(ccc):diffuseupperright(crc)
					:diffuselowerleft(bcc):diffuselowerright(brc)
			end
		},
	},
	--[[
	Def.Sprite{
		Texture= "big_circle", InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy):diffuse(color("#7f7f7f"))
		end
	},
	]]
	Def.Sprite{
		Texture= "big_spotlight", InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy):diffuse(color("#3f3f3f"))
				:blend("BlendMode_Add"):visible(true)
				:zoomx(_screen.w / 512):zoomy(_screen.h / 512)
		end
	},
}

return Def.ActorFrame(args)
