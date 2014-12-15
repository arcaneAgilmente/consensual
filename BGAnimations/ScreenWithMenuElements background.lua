local common_bg= false
function update_common_bg_colors()
	common_bg:diffuse(fetch_color("bg"))
end

return Def.Quad{
	InitCommand= function(self)
		common_bg= self
		self:FullScreen():diffuse(fetch_color("bg"))
	end
}
