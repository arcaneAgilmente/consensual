local player= Var("Player")

local function recalc_verts(self, life_meter)
	local life_limit= life_meter:GetTotalLives()
	local life_remain= life_meter:GetLivesLeft()
	local lh= SCREEN_HEIGHT / life_limit
	local lx= -12
	local rx= 12
	local verts= {}
	local life_colors= fetch_color("gameplay.lifemeter.battery")
	for l= 1, life_limit do
		local col= color_in_set(life_colors, l, true)
		if l > life_remain then
			col= life_colors.lost_life
		end
		local highy= -(l * lh)
		local lowy= lh-(l * lh)
		verts[#verts+1]= {{rx, lowy, 0}, col}
		verts[#verts+1]= {{lx, lowy, 0}, col}
		verts[#verts+1]= {{lx, highy, 0}, col}
		verts[#verts+1]= {{rx, highy, 0}, col}
	end
	self:SetVertices(verts)
end

return Def.ActorFrame{
	Def.ActorMultiVertex{
		Name= "_lives", InitCommand= cmd(xy, 0, 0), BeginCommand= function(self)
			local life_meter= SCREENMAN:GetTopScreen():GetLifeMeter(player)
			recalc_verts(self, life_meter)
			self:SetDrawState{Mode= "DrawMode_Quads"}:visible(true)
		end,
		LifeChangedMessageCommand= function(self, param)
			if param.Player == player then
				recalc_verts(self, param.LifeMeter)
			end
		end,
	}
}
