local judge_colors= fetch_color("judgment")
local bright_colors= {}
local dark_colors= {}
local judge_colored_verts= {}
for name, color in pairs(judge_colors) do
	bright_colors[name]= Alpha(adjust_luma(color, 4), .5)
	dark_colors[name]= Alpha(adjust_luma(color, 1/4), .5)
	local bright= {Alpha(adjust_luma(color, 4), .5)}
	local dark= {Alpha(adjust_luma(color, 1/4), .5)}
	judge_colored_verts[name]= {bright, dark, dark, dark, dark, dark, dark, dark}
end
local function flash_quad(zx)
	return Def.Quad{
		Name= "Flash", InitCommand= function(self)
			self:draworder(newfield_draw_order.mid_board)
		end,
		WidthSetCommand= function(self, param)
			self:setsize(param.width/2, 256):diffusealpha(0)
				:horizalign(right):zoomx(zx):vertalign(top)
			param.column:set_layer_transform_type(self, "FieldLayerTransformType_PosOnly")
		end,
		ColumnJudgmentCommand= function(self, param)
			if judge_colors[param.tap_note_score] then
				self:stoptweening()
					:diffuseupperright(bright_colors[param.tap_note_score])
					:diffuseupperleft(dark_colors[param.tap_note_score])
					:diffuselowerright(dark_colors[param.tap_note_score])
					:diffuselowerleft(Alpha(dark_colors[param.tap_note_score], 0))
					:linear(2):diffusealpha(0)
			end
		end,
	}
end
local function flash_amv()
	return Def.ActorMultiVertex{
		Name= "Flash", InitCommand= function(self)
			self:draworder(newfield_draw_order.mid_board)
				:SetDrawState{Mode="DrawMode_Fan"}
		end,
		WidthSetCommand= function(self, param)
			local hw= param.width/2
			self:SetVertices{
				{{0, 0, 0}}, {{-hw, 0, 0}}, {{0, 512, 0}}, {{hw, 0, 0}},
				{{hw, -hw, 0}}, {{0, -hw, 0}}, {{-hw, -hw, 0}}, {{-hw, 0, 0}},
			}
			param.column:set_layer_transform_type(self, "FieldLayerTransformType_PosOnly")
				:set_layer_fade_type(self, "FieldLayerFadeType_Explosion")
		end,
		ColumnJudgmentCommand= function(self, param)
			local tns= param.tap_note_score
			if judge_colors[tns] then
				self:stoptweening():diffusealpha(1)
					:SetVertices(judge_colored_verts[tns])
					:linear(.2):diffusealpha(0)
			end
		end,
		ReverseChangedCommand= function(self, param)
			self:zoomy(param.sign)
		end,
	}
end
local layers= {
	flash_amv()
	--flash_quad(1),
	--flash_quad(-1),
}
return layers
