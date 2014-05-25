function calc_circle_verts(radius, chords, start_angle, end_angle)
	if start_angle == end_angle then
		end_angle= start_angle + (math.pi*2)
	end
	local chord_angle= (end_angle - start_angle) / chords
	local verts= {}
	for c= 0, chords do
		local angle= start_angle + (chord_angle * c)
		verts[c+1]= {{radius * math.cos(angle), radius * math.sin(angle), 0}}
	end
	return verts
end

function arrow_amv(name, x, y, width, height, detail, color)
	x= x or 0
	y= y or 0
	width= width or 4
	height= height or 8
	detail= detail or 4
	color= color or solar_colors.f_text()
	local radius= height / 2
	local ratio= width / radius
	return Def.ActorMultiVertex{
		Name= name,
		InitCommand=
			function(self)
				self:xy(x, y)
				local verts= {{{0, 0, 0}, color}}
				local top_curve_verts= calc_circle_verts(radius, detail, 0, math.pi/2)
				for i, vert in ipairs(top_curve_verts) do
					verts[#verts+1]= {
						{(vert[1][1] - radius) * ratio, vert[1][2] - radius, 0}, color}
				end
				local bot_curve_verts= calc_circle_verts(radius, detail, -math.pi/2, 0)
				for i, vert in ipairs(bot_curve_verts) do
					verts[#verts+1]= {
						{(vert[1][1] - radius) * ratio, vert[1][2] + radius, 0}, color}
				end
				self:SetDrawState{Mode="DrawMode_Fan"}
				self:SetVertices(verts)
			end
	}
end

function circle_amv(name, x, y, r, chords, color)
	x= x or 0
	y= y or 0
	r= r or 4
	chords= chords or 6
	return Def.ActorMultiVertex{
		Name= name,
		InitCommand= function(self)
			self:xy(x, y)
			local verts= calc_circle_verts(r, chords, 0, 0)
			table.insert(verts, 1, {{0, 0, 0}, color})
			for i, v in ipairs(verts) do
				v[2]= color
			end
			self:SetDrawState{Mode="DrawMode_Fan"}
			self:SetVertices(verts)
	end}
end

function dance_arrow_amv(name, x, y, r, size, color)
	x= x or 0
	y= y or 0
	r= r or 0
	size= size or 8
	local norm_size= math.sqrt(size*2)
	local leg_width= size/8
	local tip_size= leg_width / math.sqrt(2)
	local point_vert= {0, -size/2, 0}
	return Def.ActorMultiVertex{
		Name= name,
		InitCommand= function(self)
			self:xy(x, y)
			local verts= {
				{point_vert, color},
				{{point_vert[1]-norm_size, point_vert[2]+norm_size, 0}, color},
				{{point_vert[1]-norm_size, point_vert[2]+norm_size+tip_size, 0}, color},
				{{point_vert[1]-norm_size+tip_size, point_vert[2]+norm_size+tip_size, 0}, color},
				{{point_vert[1]-(leg_width/2), point_vert[2]+(leg_width*2), 0}, color},
				{{point_vert[1]-(leg_width/2), point_vert[2]+size-tip_size, 0}, color},
				{{point_vert[1], point_vert[2]+size, 0}, color},
				{{point_vert[1]+(leg_width/2), point_vert[2]+size-tip_size, 0}, color},
				{{point_vert[1]+(leg_width/2), point_vert[2]+(leg_width*2), 0}, color},
				{{point_vert[1]+norm_size-tip_size, point_vert[2]+norm_size+tip_size, 0}, color},
				{{point_vert[1]+norm_size, point_vert[2]+norm_size+tip_size, 0}, color},
				{{point_vert[1]+norm_size, point_vert[2]+norm_size, 0}, color},
			}
			self:rotationz(r)
			self:SetDrawState{Mode="DrawMode_Fan"}
			self:SetVertices(verts)
		end
	}
end

dance_pad_mt= {
	__index= {
		create_actors= function(self, name, x, y, panel_width)
			self.name= name
			local sepw= .5
			local function sep(name, x, y, w, h)
				return Def.Quad{
					Name= name,
					InitCommand= function(self)
						self:xy(x, y)
						self:SetWidth(w)
						self:SetHeight(h)
						self:diffuse(solar_colors.rbg())
				end}
			end
			local function pad_half(name, x, y)
				local args= {
					Name= name,
					InitCommand= cmd(xy, x, y),
					Def.Quad{
						Name= "bg",
						InitCommand= function(self)
							self:SetWidth(panel_width * 3 + sepw)
							self:SetHeight(panel_width * 3 + sepw)
							self:diffuse(solar_colors.bg())
					end},
					sep("sep1", 0, panel_width * -1.5, panel_width * 3, sepw),
					sep("sep2", 0, panel_width * -.5, panel_width * 3, sepw),
					sep("sep3", 0, panel_width * .5, panel_width * 3, sepw),
					sep("sep4", 0, panel_width * 1.5, panel_width * 3, sepw),
					sep("sep5", panel_width * -1.5, 0, sepw, panel_width * 3),
					sep("sep6", panel_width * -.5, 0, sepw, panel_width * 3),
					sep("sep7", panel_width * .5, 0, sepw, panel_width * 3),
					sep("sep8", panel_width * 1.5, 0, sepw, panel_width * 3),
				}
				local panel_poses= {
					{-1, -1, -45}, {0, -1, 0}, {1, -1, 45},
					{-1, 0, -90}, {0, 0, 0}, {1, 0, 90},
					{-1, 1, -135}, {0, 1, 180}, {1, 1, 135}}
				for p= 1, 9 do
					local px= panel_width * panel_poses[p][1]
					local py= panel_width * panel_poses[p][2]
					args[#args+1]= Def.Quad{
						Name= "dai"..p,
						InitCommand= function(self)
							self:xy(px, py)
							self:SetWidth(panel_width)
							self:SetHeight(panel_width)
							self:diffuse(solar_colors.rbg_shadow(0))
					end}
					if p == 5 then
						args[#args+1]= circle_amv(
							"daa"..p, px, py, (panel_width-3)/2, 12)
					else
						args[#args+1]= dance_arrow_amv(
							"daa"..p, px, py, panel_poses[p][3], panel_width-3)
					end
				end
				return Def.ActorFrame(args)
			end
			return Def.ActorFrame{
				Name= name,
				InitCommand= cmd(xy, x, y),
				pad_half("halfa", panel_width * -1.5, 0),
				pad_half("halfb", panel_width * 1.5, 0)
			}
		end,
		find_actors= function(self, container)
			self.container= container
			self.indicators= {}
			self.arrows= {}
			local function load_half(frame)
				for p= 1, 9 do
					self.indicators[#self.indicators+1]= frame:GetChild("dai"..p)
					self.arrows[#self.arrows+1]= frame:GetChild("daa"..p)
				end
			end
			load_half(container:GetChild("halfa"))
			load_half(container:GetChild("halfb"))
		end,
		color_arrow= function(self, aid, color)
			if self.arrows[aid] then
				local num_verts= self.arrows[aid]:GetNumVertices()
				local vert_colors= {}
				for vc= 1, num_verts do
					vert_colors[vc]= {color}
				end
				self.arrows[aid]:SetVertices(vert_colors)
			end
		end,
		toggle_indicator= function(self, aid)
			if not aid or aid < 1 then return end
			if self.indicators[aid] then
				if self.indicators[aid]:GetDiffuseAlpha() > .5 then
					self.indicators[aid]:diffusealpha(0)
				else
					self.indicators[aid]:diffusealpha(1)
				end
			end
		end
}}
