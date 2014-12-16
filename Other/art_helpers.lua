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
	color= color or fetch_color("text")
	local radius= height / 2
	local ratio= width / radius
	return Def.ActorMultiVertex{
		Name= name, InitCommand= function(self)
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
			self:xy(x, y):SetDrawState{Mode="DrawMode_Fan"}:SetVertices(verts)
		end
	}
end

function circle_amv(name, x, y, r, chords, color)
	x= x or 0
	y= y or 0
	r= r or 4
	chords= chords or 6
	return Def.ActorMultiVertex{
		Name= name, InitCommand= function(self)
			local verts= calc_circle_verts(r, chords, 0, 0)
			table.insert(verts, 1, {{0, 0, 0}, color})
			for i, v in ipairs(verts) do
				v[2]= color
			end
			self:xy(x, y):SetDrawState{Mode="DrawMode_Fan"}:SetVertices(verts)
	end}
end

star_amv_mt= {
	__index= {
		create_actors= function(self, name, x, y, r, a, points, color, time, rot_step)
			self.name= name
			self.x= x or 0
			self.y= y or 0
			self.r= r or 24
			self.a= a or 0
			self.points= points or 5
			self.color= color or fetch_color("accent.magenta")
			self.shift_time= time or 8
			self.rot= 0
			self.rot_step= rot_step or 90
			self:repoint(self.points, self.r)
			return Def.ActorMultiVertex{
				Name= name, InitCommand= function(subself)
					self.container= subself
					subself:xy(x, y):queuecommand("change")
				end,
				changeCommand= function(subself)
					local step= self.step_set[self.curr_step]
					local curr_point= 1
					local verts= {}
					repeat
						local curr_pos= self.point_poses[curr_point]
						verts[#verts+1]= {curr_pos[1], self.color}
						curr_point= wrapped_index(curr_point, step, self.points)
					until curr_point == 1
					verts[#verts+1]= verts[1]
					subself:SetDrawState{Mode="DrawMode_LineStrip"}
						:SetVertices(verts):SetNumVertices(#verts):SetLineWidth(.125)
						:rotationz(self.rot)
						:queuecommand("change"):linear(self.shift_time)
					self.curr_step= wrapped_index(self.curr_step, 1, #self.step_set)
					self.rot= self.rot + self.rot_step
				end
			}
		end,
		move= function(self, x, y)
			self.x= x or self.x
			self.y= y or self.y
			self.container:xy(self.x, self.y)
		end,
		repoint= function(self, new_points, new_radius)
			self.points= new_points or self.points
			self.r= new_radius or self.r
			self.point_poses= calc_circle_verts(self.r, self.points, self.a, self.a)
			self.step_set= {}
			local factors= {}
			self.step_set[1]= 1
			for i= 2, self.points do
				if self.points % i == 0 then
					factors[#factors+1]= i
				else
					local passed_factors= true
					for f, fact in ipairs(factors) do
						if i % fact == 0 then
							passed_factors= false
							break
						end
					end
					if passed_factors then
						self.step_set[#self.step_set+1]= i
					end
				end
			end
			self.curr_step= wrapped_index(1, math.round(GetTimeSinceStart()/self.shift_time), #self.step_set)
		end
}}

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
		Name= name, InitCommand= function(self)
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
			self:xy(x, y):rotationz(r):SetDrawState{Mode="DrawMode_Fan"}
				:SetVertices(verts)
		end
	}
end

local function gen_arrow_verts(size, point_vert, leg_width, leg_len, stem_width)
	return {
		point_vert,
		{point_vert[1]-leg_len, point_vert[2]+leg_len, 0},
		{point_vert[1]+leg_width, point_vert[2]+leg_width, 0},

		{point_vert[1]-leg_len, point_vert[2]+leg_len, 0},
		{point_vert[1]-leg_len+leg_width, point_vert[2]+leg_len+leg_width, 0},
		{point_vert[1]+leg_width, point_vert[2]+leg_width, 0},

		{point_vert[1]-leg_len, point_vert[2]+leg_len, 0},
		{point_vert[1]-leg_len, point_vert[2]+leg_len+leg_width, 0},
		{point_vert[1]-leg_len+leg_width, point_vert[2]+leg_len+leg_width, 0},

		point_vert,
		{point_vert[1]+leg_len, point_vert[2]+leg_len, 0},
		{point_vert[1]-leg_width, point_vert[2]+leg_width, 0},

		{point_vert[1]+leg_len, point_vert[2]+leg_len, 0},
		{point_vert[1]+leg_len-leg_width, point_vert[2]+leg_len+leg_width, 0},
		{point_vert[1]-leg_width, point_vert[2]+leg_width, 0},

		{point_vert[1]+leg_len, point_vert[2]+leg_len, 0},
		{point_vert[1]+leg_len, point_vert[2]+leg_len+leg_width, 0},
		{point_vert[1]+leg_len-leg_width, point_vert[2]+leg_len+leg_width, 0},

		{point_vert[1]-stem_width, point_vert[2]+stem_width, 0},
		{point_vert[1]+stem_width, point_vert[2]+stem_width, 0},
		{point_vert[1]-stem_width, point_vert[2]+size-stem_width, 0},

		{point_vert[1]+stem_width, point_vert[2]+stem_width, 0},
		{point_vert[1]+stem_width, point_vert[2]+size-stem_width, 0},
		{point_vert[1]-stem_width, point_vert[2]+size-stem_width, 0},

		{point_vert[1]-stem_width, point_vert[2]+size-stem_width, 0},
		{point_vert[1]+stem_width, point_vert[2]+size-stem_width, 0},
		{point_vert[1], point_vert[2]+size, 0},
	}
end

function noteskin_arrow_amv(name, x, y, r, size, out_color, in_color)
	x= x or 0
	y= y or 0
	r= r or 0
	size= size or 8
	local point_vert= {0, -size/2, 0}
	local leg_width= 8
	local leg_len= size/2 - leg_width^.5
	local stem_width= 4 * 2^.5
	local insize= size-8
	local in_point_vert= {0, -insize/2, 0}
	local inlw= leg_width-4
	local inll= leg_len-2
	local insw= stem_width-2
	return Def.ActorMultiVertex{
		Name= name,
		InitCommand= function(self)
			local out_verts= gen_arrow_verts(size, point_vert, leg_width, leg_len, stem_width)
			local in_verts= gen_arrow_verts(insize, in_point_vert, inlw, inll, insw)
			local verts= {}
			for i, v in ipairs(out_verts) do
				verts[#verts+1]= {v, out_color}
			end
			for i, v in ipairs(in_verts) do
				verts[#verts+1]= {v, in_color}
			end
			self:xy(x, y):rotationz(r):SetDrawState{Mode="DrawMode_Triangles"}
				:SetVertices(verts)
		end
	}
end

function random_grow_circle(name, x, y, center_color, edge_color, step_time, end_radius, activate_command)
	return Def.ActorMultiVertex{
		Name= name,
		[activate_command.."Command"]= function(self)
			if type(center_color) == "function" then center_color= center_color() end
			if type(edge_color) == "function" then edge_color= edge_color() end
			local verts= {{{0, 0, 0}, center_color}}
			local points= 128
			for i= 1, points+1 do
				verts[#verts+1]= {{0, 0, 0}, edge_color}
			end
			local expansion_vectors= calc_circle_verts(end_radius * .05, points, 0, 0)
			self:xy(x, y):SetVertices(verts):SetDrawState{Mode= "DrawMode_Fan"}
			for i= 1, 20 do
				for v, vert in ipairs(verts) do
					if v > 1 then
						local scale= i + ((MersenneTwister.Random(1, 11) - 6) * .05)
						vert[1][1]= expansion_vectors[v-1][1][1] * scale
						vert[1][2]= expansion_vectors[v-1][1][2] * scale
					end
				end
				-- Make the join point of the circle match.
				verts[#verts][1][1]= verts[2][1][1]
				verts[#verts][1][2]= verts[2][1][2]
				self:linear(step_time):SetVertices(verts)
			end
		end
	}
end

function random_grow_column(name, x, y, bottom_color, top_color, w, step_time, end_h, activate_command)
	return Def.ActorMultiVertex{
		Name= name,
		[activate_command.."Command"]= function(self)
			if type(bottom_color) == "function" then bottom_color= bottom_color() end
			if type(top_color) == "function" then top_color= top_color() end
			if type(end_h) == "function" then end_h= end_h() end
			local sx= w*-.5
			local cols= 64
			local xdiff= w / cols
			local verts= {}
			for i= 1, cols+1 do
				local vx= sx + ((i-1) * xdiff)
				verts[#verts+1]= {{vx, 0, 0}, bottom_color}
				verts[#verts+1]= {{vx, 0, 0}, top_color}
			end
			local grow_amount= end_h / 20
			self:xy(x, y):SetVertices(verts):SetDrawState{Mode= "DrawMode_Strip"}
			for i= 1, 20 do
				for v, vert in ipairs(verts) do
					if v % 2 == 0 then
						local scale= i
						if i < 20 then
							scale= i + ((MersenneTwister.Random(1, 11) - 6) * .2)
						end
						vert[1][2]= grow_amount * scale
					end
				end
				self:linear(step_time):SetVertices(verts)
			end
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
					Name= name, InitCommand= function(self)
						self:xy(x, y):setsize(w, h):diffuse(fetch_color("rev_bg"))
				end}
			end
			local function pad_half(name, x, y)
				local args= {
					Name= name, InitCommand= cmd(xy, x, y),
					Def.Quad{
						Name= "bg", InitCommand= function(self)
							self:setsize(panel_width * 3 + sepw, panel_width * 3 + sepw)
								:diffuse(fetch_color("bg"))
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
						Name= "dai"..p, InitCommand= function(self)
							self:xy(px, py):setsize(panel_width, panel_width)
								:diffuse(Alpha(fetch_color("rev_bg_shadow"), 0))
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
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.indicators= {}
					self.arrows= {}
					local function load_half(frame)
						for p= 1, 9 do
							self.indicators[#self.indicators+1]= frame:GetChild("dai"..p)
							self.arrows[#self.arrows+1]= frame:GetChild("daa"..p)
						end
					end
					load_half(subself:GetChild("halfa"))
					load_half(subself:GetChild("halfb"))
				end,
				pad_half("halfa", panel_width * -1.5, 0),
				pad_half("halfb", panel_width * 1.5, 0)
			}
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
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end,
}}

local letter_vert_positions= {
	a= {{1, -5}, {4, -5}, {5, -4}, {5, 0}, {5, -3}, {1, -3}, {0, -2}, {0, -1},
		{1, 0}, {3, 0}, {5, -2}},
	b= {{0, -8}, {0, 0}, {0, -4}, {2, -5}, {4, -5}, {5, -4}, {5, -1}, {4, 0},
		{2, 0}, {0, -1}},
	c= {{5, -4}, {4, -5}, {1, -5}, {0, -4}, {0, -1}, {1, 0}, {4, 0}, {5, -1}},
	d= {{5, -8}, {5, 0}, {5, -4}, {3, -5}, {1, -5}, {0, -4}, {0, -1}, {1, 0},
		{3, 0}, {5, -1}},
	e= {{5, -1}, {4, 0}, {1, 0}, {0, -1}, {0, -4}, {1, -5}, {4, -5}, {5, -4},
		{5, -3}, {0, -3}},
	f= {{5, -7}, {4, -8}, {2, -8}, {1, -7}, {1, 0}, {1, -4}, {0, -4}, {4, -4}},
	l= {{1, -8}, {2, -8}, {2, 0}, {0, 0}, {4, 0}},
	n= {{0, -5}, {0, 0}, {0, -3}, {2, -5}, {4, -5}, {5, -4}, {5, 0}},
	o= {{0, -4}, {0, -1}, {1, 0}, {4, 0}, {5, -1}, {5, -4}, {4, -5}, {1, -5},
		{0, -4}},
	s= {{0, -1}, {1, 0}, {4, 0}, {5, -1}, {0, -4}, {1, -5}, {4, -5}, {5, -4}},
	u= {{0, -5}, {0, -1}, {1, 0}, {3, 0}, {4, -1}, {4, -5}, {4, -1}, {5, 0}},
	C= {{5, -7}, {4, -8}, {1, -8}, {0, -7}, {0, -1}, {1, 0}, {4, 0}, {5, -1}},
}
local letter_w= 8

function unfolding_letter(name, x, y, letter, color, unfold_time, scale, thick, steps)
	if not letter_vert_positions[letter] then return Def.Actor{} end
	local function add_shuffle_step(self, source_verts, time)
		local ordering= {}
		for i= 1, #source_verts do ordering[i]= i end
		shuffle(ordering)
		local shuffled_verts= {}
		for i= 1, #source_verts do
			local sv= source_verts[ordering[i]]
			shuffled_verts[i]= {{sv[1]*scale, sv[2]*scale, 0}, color}
		end
		self:SetVertices(shuffled_verts)
		self:linear(unfold_time)
	end
	return Def.ActorMultiVertex{
		Name= name, InitCommand= function(self)
			local source_verts= letter_vert_positions[letter]
			local final_verts= {}
			steps= steps or 1
			for i= 1, #source_verts do
				local sv= source_verts[i]
				final_verts[i]= {{sv[1]*scale, sv[2]*scale, 0}, color}
			end
			self:xy(x, y)
			self:SetDrawState{Mode= "DrawMode_LineStrip"}
			self:SetLineWidth(thick)
			for i= 1, steps do
				add_shuffle_step(self, source_verts, unfold_time)
			end
			self:SetVertices(final_verts)
		end
	}
end

function unfolding_text(name, x, y, text, color, unfold_time, scale, thick,
											 fade_time)
	local args= {Name= name, InitCommand= function(self)
								 self:xy(x, y)
								 self:linear(unfold_time)
								 if fade_time then
									 self:linear(fade_time)
									 self:diffusealpha(0)
								 end
							end}
	if not scale then
		scale= (_screen.w * .75) / (#text * letter_w)
	end
	thick= thick or (scale * .75)
	local space= scale * letter_w
	local text_start= (space*.25)-((#text * space) / 2)
	local step_ordering= {}
	for i= 1, #text do step_ordering[i]= i end
	shuffle(step_ordering)
	for i= 1, #text do
		local l= text:sub(i, i)
		local lx= text_start+(space*(i-1))
		args[#args+1]= unfolding_letter(
			l, lx, 0, l, color, unfold_time/#text, scale, thick, step_ordering[i])
	end
	return Def.ActorFrame(args)
end
