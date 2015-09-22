local flash_quads= {}
local this_pn= false
local judge_flashes_enabled= false
local pstate= false
local poptions= false

local judge_colors= fetch_color("judgment")
local args= {
	JudgmentMessageCommand= function(self, param)
		if param.Player ~= this_pn or not judge_flashes_enabled then return end
		local taps= param.Notes
		if taps then
			for track, tapnote in pairs(taps) do
				local tns= tapnote:GetTapNoteResult():GetTapNoteScore()
				if judge_colors[tns] and flash_quads[track] then
					local rev_per= poptions:GetReversePercentForColumn(track)
					if rev_per > .5 then
						flash_quads[track]:zoomy(-1)
					else
						flash_quads[track]:zoomy(1)
					end
					local ypos= ArrowEffects.GetYPos(pstate, track, 0)
					flash_quads[track]:y(ypos)
						:playcommand("flash", {color= judge_colors[tns]})
				end
			end
		end
	end,
	PlayerStateSetCommand= function(self, param)
		this_pn= param.PlayerNumber
		pstate= GAMESTATE:GetPlayerState(this_pn)
		poptions= pstate:GetPlayerOptions("ModsLevel_Current")
		judge_flashes_enabled= cons_players[this_pn].flags.gameplay.judge_flashes
		-- The NewField will send WidthSetCommand if it exists.  But the old one
		-- won't, so fetch the width from the style anyway.
		local style= GAMESTATE:GetCurrentStyle(this_pn)
		local num_columns= style:ColumnsPerPlayer()
		local usable_columns= math.min(num_columns, #flash_quads)
		for i= 1, usable_columns do
			local col_info= style:GetColumnInfo(this_pn, i)
			flash_quads[i]:x(col_info.XOffset):hibernate(0)
		end
	end,
	Def.Quad{
	InitCommand= function(self)
		self:hibernate(math.huge)
	end,
	PlayerStateSetCommand= function(self, param)
		this_pn= param.PlayerNumber
		local filter_color= cons_players[this_pn].gameplay_element_colors.filter
		-- The NewField will send WidthSetCommand if it exists.  But the old one
		-- won't, so fetch the width from the style anyway.
		local style= GAMESTATE:GetCurrentStyle(this_pn)
		local alf= .2
		local width= style:GetWidth(this_pn) + 8
		self:setsize(width, _screen.h*4096)
		self:diffuse(filter_color):hibernate(0)
		if filter_color[4] < .001 then self:hibernate(math.huge) end
	end,
	WidthSetCommand= function(self, param)
		local width= param.Width + 8
		self:setsize(width, _screen.h*4096)
	end
}}

for i= 1, 16 do
	args[#args+1]= Def.Quad{
		InitCommand= function(self)
			flash_quads[i]= self
			self:hibernate(math.huge):setsize(64, 256):diffuse{0, 0, 0, 0}
				:vertalign(top)
		end,
		flashCommand= function(self, param)
			self:stoptweening():diffusetopedge(Alpha(param.color, .75))
				:linear(.2):diffusetopedge{0, 0, 0, 0}
		end
	}
end

return Def.ActorFrame(args)
