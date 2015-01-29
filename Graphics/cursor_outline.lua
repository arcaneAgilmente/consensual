local args= {...}
local self= args[1].self
return Def.ActorMultiVertex{
	Name= "outline", InitCommand= function(subself)
		self.parts[#self.parts+1]= {"none", subself}
		self:add_approaches(7)
		subself:SetDrawState{Mode= "DrawMode_LineStrip"}
			:SetNumVertices(7)
	end,
	RefitCommand= function(subself, param)
		self:set_verts_for_part(
			param[1], {
				0, -self.hh, self.hw, -self.hh, self.hw, self.hh,
				0, self.hh, -self.hw, self.hh, -self.hw, -self.hh,
				0, -self.hh,
		})
	end,
	LeftCommand= function(subself)
		subself:SetDrawState{First= 4}
	end,
	RightCommand= function(subself)
		subself:SetDrawState{First= 1, Num= 4}
	end,
	FullCommand= function(subself)
		subself:SetDrawState{First= 1, Num= -1}
	end
}
