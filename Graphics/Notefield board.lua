local flash_quads= {}
local flash_wraps= {}
local columns= {}
local this_pn= false
local judge_flashes_enabled= false
local pstate= false
local poptions= false

local pos_feedback_frame= false
local pos_feedback_text= false
local pos_feedback_pos= 0
local pos_moves= {
	DeviceButton_e= -10,
	DeviceButton_r= -1,
	DeviceButton_t= 1,
	DeviceButton_y= 10,
}
local function pos_feedback_input(event)
	if event.type == "InputEventType_Release" then return end
	local move= pos_moves[event.DeviceInput.button]
	if move then
		pos_feedback_pos= pos_feedback_pos + move
		pos_feedback_frame:y(pos_feedback_pos)
		pos_feedback_text:settext(pos_feedback_pos)
	end
end

local judge_colors= fetch_color("judgment")
local function handle_rev_flip(act, rev_per)
	if rev_per > .5 then
		act:zoomy(-1)
	else
		act:zoomy(1)
	end
end
local args= {
	JudgmentMessageCommand= function(self, param)
		if param.Player ~= this_pn or not judge_flashes_enabled then return end
		local taps= param.Notes
		if taps then
			for track, tapnote in pairs(taps) do
				local tns= tapnote:GetTapNoteResult():GetTapNoteScore()
				if judge_colors[tns] and flash_quads[track] then
					if newskin_available() then
						local col= columns[track]
						if col then
							local beat= col:get_curr_beat()
							local second= col:get_curr_second()
							local rev_per= col:get_reverse_percent():evaluate(
								beat, second, beat, second, 0)
							handle_rev_flip(flash_quads[track], rev_per)
							col:apply_column_mods_to_actor(flash_wraps[track])
								:apply_note_mods_to_actor(flash_quads[track])
							-- Don't cancel out the zoomx from the mods becuase the flash
							-- should have the same width as the column.
							flash_quads[track]:zoomy(1):zoomz(1)
								:rotationx(0):rotationy(0):rotationz(0)
						end
					else
						local rev_per= poptions:GetReversePercentForColumn(track)
						handle_rev_flip(flash_quads[track], rev_per)
						local ypos= ArrowEffects.GetYPos(pstate, track, 0)
						flash_quads[track]:y(ypos)
					end
					flash_quads[track]:playcommand("flash", {color= judge_colors[tns]})
				end
			end
		end
	end,
	PlayerStateSetCommand= function(self, param)
		this_pn= param.PlayerNumber
		if newskin_available() then
			-- The old notefield sets itself as the parent of the board.
			if self:GetParent() then
				self:hibernate(math.huge)
				return
			end
		end
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
	WidthSetCommand= function(self, param)
		local newfield= param.newfield
		if newfield then
			columns= newfield:get_columns()
		end
		for i, col in ipairs(param.columns) do
			if flash_quads[i] then
				flash_quads[i]:SetWidth(col.width + col.padding)
			end
		end
	end,
	Def.Quad{
		InitCommand= function(self)
			self:hibernate(math.huge)
		end,
		PlayerStateSetCommand= function(self, param)
			this_pn= param.PlayerNumber
			local filk= cons_players[this_pn].gameplay_element_colors.filter
			if not newskin_available() then
				-- The NewField will send WidthSetCommand if it exists.  But the old
				-- NoteField won't, so fetch the width from the style.
				local style= GAMESTATE:GetCurrentStyle(this_pn)
				local width= style:GetWidth(this_pn) + 8
				self:SetWidth(width)
			end
			self:SetHeight(_screen.h*4096)
			self:diffuse(filk):hibernate(0)
			if filk[4] < .001 then self:hibernate(math.huge) end
		end,
		WidthSetCommand= function(self, param)
			local width= param.width + 8
			self:SetWidth(width)
		end
	},
}

if false then
	args[#args+1]= Def.ActorFrame{
		OnCommand= function(self)
			pos_feedback_frame= self
			self:queuecommand("set_input")
		end,
		set_inputCommand= function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(pos_feedback_input)
		end,
		Def.Quad{
			InitCommand= function(self)
				self:setsize(280, 1):diffuse{1, 1, 1, 1}
			end,
		},
		Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				pos_feedback_text= self:x(-140):horizalign(right)
			end,
		}
	}
end

for i= 1, 16 do
	args[#args+1]= Def.Quad{
		InitCommand= function(self)
			flash_quads[i]= self
			if newskin_available() then
				flash_wraps[i]= self:AddWrapperState()
			end
			self:hibernate(math.huge):setsize(64, 256):diffuse{1, 1, 1, 0}
				:vertalign(top)
		end,
		flashCommand= function(self, param)
			self:stoptweening():diffusetopedge(Alpha(param.color, .75))
				:linear(.2):diffusetopedge(Alpha(param.color, 0))
		end
	}
end

return Def.ActorFrame(args)
