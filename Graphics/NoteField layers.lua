local this_pn= false
local layers= {
	Def.Quad{
		Name= "Filter", InitCommand= function(self)
			self:hibernate(math.huge):draworder(newfield_draw_order.board)
		end,
		PlayerStateSetCommand= function(self, param)
			this_pn= param.PlayerNumber
			local filk= cons_players[this_pn].gameplay_element_colors.filter
			self:SetHeight(4096)
			self:diffuse(filk):hibernate(0)
			if filk[4] < .001 then self:hibernate(math.huge) end
		end,
		WidthSetCommand= function(self, param)
			local width= param.width + 8
			self:SetWidth(width)
		end,
		color_changedMessageCommand= function(self, param)
			if param.pn ~= this_pn then return end
			local filk= cons_players[this_pn].gameplay_element_colors.filter
			self:diffuse(filk):hibernate(0)
			if filk[4] < .001 then self:hibernate(math.huge) end
		end,
	},
}

return layers
