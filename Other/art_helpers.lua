function quaid(x, y, w, h, c, ha, va)
	return Def.Quad{
		InitCommand= function(self)
			self:xy(x, y):setsize(w, h):diffuse(c)
				:horizalign(ha or center):vertalign(va or middle)
		end
	}
end

function calc_circle_verts(radius, chords, start_angle, end_angle, color)
	if start_angle == end_angle then
		end_angle= start_angle + (math.pi*2)
	end
	local chord_angle= (end_angle - start_angle) / chords
	local verts= {}
	for c= 0, chords do
		local angle= start_angle + (chord_angle * c)
		verts[c+1]= {{radius * math.cos(angle), radius * math.sin(angle), 0}, color}
	end
	return verts
end

function color_verts_with_color_set(verts, color_set)
	local verts_per_color= math.round(#verts / #color_set)
	local color_ranges= {}
	for c= 1, #color_set do
		local b= ((c-1)*verts_per_color)+1
		color_ranges[c]= {
			b= b, e= b+verts_per_color-1, bcol= color_set[c], ecol= color_set[c+1]}
	end
	color_ranges[#color_ranges].e= #verts
	color_ranges[#color_ranges].ecol= color_set[1]
	for c, range in ipairs(color_ranges) do
		for v= range.b, range.e do
			if not verts[v] then break end
			verts[v][2]= lerp_color(
				(v-range.b) / verts_per_color, range.bcol, range.ecol)
		end
	end
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

function circle_amv(name, x, y, r, chords, color, out_color, blend)
	x= x or 0
	y= y or 0
	r= r or 4
	chords= chords or 6
	out_color= out_color or color
	return Def.ActorMultiVertex{
		Name= name, InitCommand= function(self)
			local verts= calc_circle_verts(r, chords, 0, 0, out_color)
			table.insert(verts, 1, {{0, 0, 0}, color})
			for i, v in ipairs(verts) do
				v[2]= out_color
			end
			verts[1][2]= color
			self:xy(x, y):SetDrawState{Mode="DrawMode_Fan"}:SetVertices(verts)
			if blend then self:blend(blend) end
	end}
end

function hollow_circle_amv(x, y, r, t, chords, color, out_color, blend)
	x= x or 0
	y= y or 0
	r= r or 4
	t= t or r / 8
	chords= chords or 6
	out_color= out_color or color
	return Def.ActorMultiVertex{
		InitCommand= function(self)
			local inner_verts= calc_circle_verts(r-t, chords, 0, 0, color)
			local outer_verts= calc_circle_verts(r, chords, 0, 0, out_color)
			local verts= {}
			for i= 1, #inner_verts do
				verts[#verts+1]= inner_verts[i]
				verts[#verts+1]= outer_verts[i]
			end
			self:xy(x, y):SetDrawState{Mode= "DrawMode_Strip"}
				:SetVertices(verts)
			if blend then self:blend(blend) end
	end}
end

local function adj_explosion_actor(add_to, parts)
	-- Ex:
	--	explosion:playcommand(
	--		"explode", {
	--			x= _screen.cx, y= _screen.cy, start_color= {1, 1, 1, 1},
	--			end_color= {1, 0, 0, 0}, dist= 128, time= 4, size= 2})
	local directions= {}
	local angle_per_particle= 360 / parts
	for i= 0, parts-1 do
		local angle= i * angle_per_particle
		local radan= angle / 180 * math.pi
		directions[i+1]= {angle= angle, x= math.cos(radan), y= math.sin(radan)}
	end
	local frame= Def.ActorFrame{
		Name= "adj_explosion", InitCommand= function(self)
			self:hibernate(math.huge)
			if add_to then
				add_to.adj_explosion= self
			end
		end,
		explodeCommand= function(self, param)
			self:hibernate(0):xy(param.x, param.y)
			local parts= self:GetChildren().parts
			local grow_fraction= param.size*16 / param.dist
			local grow_dist= grow_fraction * param.dist
			local time_to_full_size= math.min(param.time * grow_fraction, param.time)
			local remaining_time= param.time - time_to_full_size
			for i, part in ipairs(parts) do
				local direction= directions[i]
				part:finishtweening():setsize(param.size, param.size*8)
					:diffuse(param.start_color):zoom(0):xy(0,0)
					:linear(time_to_full_size):zoom(1)
					:xy(direction.x * grow_dist, direction.y * grow_dist)
					:linear(remaining_time):diffuse(param.end_color)
					:xy(direction.x * param.dist, direction.y * param.dist)
			end
		end
	}
	for i= 1, parts do
		frame[i]= Def.Quad{
			Name= "parts", InitCommand= function(self)
				self:rotationz(directions[i].angle)
			end
		}
	end
	return frame
end

star_amv_mt= {
	__index= {
		create_actors= function(self, name, x, y, r, a, points, time)
			self.name= name
			self.x= x or 0
			self.y= y or 0
			self.r= r or 24
			self.a= a or 0
			self.points= points or 5
			self.shift_time= time or 8
			self.colors= DeepCopy(fetch_color("common_background.inner_colors"))
			for ic, color in ipairs(self.colors) do
				for chan= 1, 3 do
					color[chan]= color[chan] * .125
				end
			end
			self:repoint(self.points, self.r, 0)
			return Def.ActorMultiVertex{
				Name= name, InitCommand= function(subself)
					self.container= subself
					subself:xy(x, y):blend("BlendMode_Add"):queuecommand("change")
				end,
				changeCommand= function(subself)
					local step= self.step_set[self.curr_step]
					local curr_point= 1
					local verts= {}
					repeat
						local curr_pos= self.point_poses[curr_point]
						verts[#verts+1]= {curr_pos[1]}
						curr_point= wrapped_index(curr_point, step, self.points)
					until curr_point == 1
					color_verts_with_color_set(verts, self.colors)
					verts[#verts+1]= verts[1]
					subself:SetDrawState{Mode="DrawMode_LineStrip"}
						:SetVertices(verts):SetNumVertices(#verts):SetLineWidth(.125)
						:queuecommand("change"):linear(self.shift_time)
					self.curr_step= wrapped_index(self.curr_step, 1, #self.step_set)
				end
			}
		end,
		move= function(self, x, y)
			self.x= x or self.x
			self.y= y or self.y
			self.container:xy(self.x, self.y)
		end,
		repoint= function(self, new_points, new_radius, progress)
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
			self.curr_step= math.floor(progress * #self.step_set) + 1
			--self.curr_step= wrapped_index(1, math.round(GetTimeSinceStart()/self.shift_time), #self.step_set)
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
			local points= 512
			local spp= 64
			if misc_config:get_data().disable_extra_processing then
				points= 64
				spp= 4
			end
			for i= 1, points+1 do
				verts[#verts+1]= {{0, 0, 0}, edge_color}
			end
			local expansion_vectors= calc_circle_verts(end_radius * .05, spp, math.pi*.5, math.pi*.5)
			self:xy(x, y):SetVertices(verts):SetDrawState{Mode= "DrawMode_Fan"}
			local spline= self:GetSpline(1)
			spline:set_size(spp+1):set_loop(true)
			for i= 1, 20 do
				for v= 1, spp do
					local scale= i + ((MersenneTwister.Random(1, 11) - 6) * .05)
					spline:set_point(v, {expansion_vectors[v][1][1] * scale,
															 expansion_vectors[v][1][2] * scale, 0})
				end
				spline:set_point(spp+1, spline:evaluate(0))
				spline:solve()
				self:linear(step_time):SetVertsFromSplines()
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
			if misc_config:get_data().disable_extra_processing then
				cols= 4
			end
			local xdiff= w / cols
			local verts= {}
			for i= 1, cols*8 do
				verts[#verts+1]= {{0, 0, 0}, bottom_color}
				verts[#verts+1]= {{0, 0, 0}, top_color}
			end
			local grow_amount= end_h / 20
			self:xy(x, y):SetVertices(verts):SetDrawState{Mode= "DrawMode_Strip"}
			local still_spline= self:GetSpline(1)
			still_spline:set_size(2):set_point(1, {sx, 0, 0})
				:set_point(2, {sx + (cols * xdiff), 0, 0})
				:solve()
			local moving_spline= self:GetSpline(2)
			moving_spline:set_size(cols+1)
			for i= 1, 20 do
				for p= 1, cols+1 do
					local vx= sx + ((p-1) * xdiff)
					local scale= i
					if i < 20 then
						scale= i + ((MersenneTwister.Random(1, 11) - 6) * .2)
					end
					moving_spline:set_point(p, {vx, grow_amount * scale, 0})
				end
				moving_spline:solve()
				self:SetVertsFromSplines():linear(step_time)
			end
		end
	}
end

local pad_image_names= {
	dance= "pad_outline",
	pump= "pad_outline",
	techno= "pad_outline",
	kickbox= "kickboxes",
}

dance_pad_mt= {
	__index= {
		create_actors= function(self, name, x, y, pn)
			self.name= name
			local sepw= .5
			local args= {
				Name= name, InitCommand= function(subself)
					self.container= subself
					subself:xy(x, y)
					self:init()
				end,
				Def.Quad{
					Name= "pad_bg", InitCommand= function(subself) self.bg= subself end
				},
			}
			local game_name= GAMESTATE:GetCurrentGame():GetName():lower()
			if pad_image_names[game_name] then
				args[#args+1]= Def.Sprite{
					Name= "pad_fg", Texture= THEME:GetPathG(
						"", "controller_icons/" .. pad_image_names[game_name]),
					InitCommand= function(subself) self.fg= subself end
				}
			end
			local panel_positions= get_controller_panel_positions(pn)
			local minx, maxx, miny, maxy= 0, 0, 0, 0
			for i, pos in ipairs(panel_positions) do
				minx= math.min(minx, pos[2])
				maxx= math.max(maxx, pos[2])
				miny= math.min(miny, pos[3])
				maxy= math.max(maxy, pos[3])
			end
			local panel_size= 10
			local button_size= 8
			local controller_height= 32
			local width= (maxx - minx) + 1
			local height= (maxy - miny) + 1
			local scale= controller_height / (height * panel_size)
			local panel_scale= panel_size * scale
			local button_scale= button_size * scale
			self.pad_width= width * panel_scale
			self.pad_height= height * panel_scale
			self.indicators= {}
			self.arrows= {}
			for i, pos in ipairs(panel_positions) do
				local px= pos[2] * panel_scale
				local py= pos[3] * panel_scale
				args[#args+1]= Def.Quad{
					Name= "dai"..i, InitCommand= function(subself)
						self.indicators[i]= subself
						subself:xy(px, py):setsize(panel_scale, panel_scale)
							:diffuse(Alpha(fetch_color("rev_bg_shadow"), 0))
					end
				}
				args[#args+1]= Def.Sprite{
					Name= "daa"..i,
					Texture= THEME:GetPathG("", "controller_icons/" .. pos[1]),
					InitCommand= function(subself)
						self.arrows[i]= subself
						subself:xy(px, py):setsize(button_scale, button_scale)
							:diffusealpha(0)
						if math.abs(pos[4]) == 1 then
							subself:zoomx(pos[4])
						else
							subself:rotationz(pos[4])
						end
					end
				}
			end
			return Def.ActorFrame(args)
		end,
		init= function(self)
			self.bg:setsize(self.pad_width, self.pad_height)
				:diffuse(fetch_color("bg_shadow"))
			if self.fg then
				self.fg:setsize(self.pad_width, self.pad_height)
			end
		end,
		color_arrow= function(self, aid, color)
			if self.arrows[aid] then
				self.arrows[aid]:diffuse(color)
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

function shuffle_verts(verts)
	local ordering= {}
	for i= 1, #verts do ordering[i]= i end
	shuffle(ordering)
	local shuffled_verts= {}
	for i= 1, #verts do
		local sv= verts[ordering[i]]
		shuffled_verts[i]= {sv[1], sv[2], sv[3]}
	end
	return shuffled_verts
end

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

local function shuffle_spline(spline, points)
	local shuffled_points= shuffle_verts(points)
	for i= 1, #points do
		spline:set_point(i, shuffled_points[i])
	end
	spline:solve()
end
local function color_verts(amv, color, num_verts)
	for v= 1, num_verts do
		amv:SetVertex(v, {color})
	end
end

function animated_glyph(glyph_data, x, y, zoom, anim_time, fade_time)
	local args= {InitCommand= function(self) self:xy(x, y):zoom(zoom) end}
	for i, stroke_data in ipairs(glyph_data) do
		local stroke_length= math.max(#stroke_data[1], #stroke_data[2])
		args[#args+1]= Def.ActorMultiVertex{
			InitCommand= function(self)
				local num_verts= stroke_length * 2 * 2
				local curr_color= {.5, .5, .5, 1}
				self:SetNumVertices(num_verts):SetDrawState{Mode= "DrawMode_Strip"}
					:blend("BlendMode_WeightedMultiply")
				color_verts(self, curr_color, num_verts)
				local move_time= scale(math.random(), 0, 1, anim_time * .25, anim_time)
				local anim_steps= math.random(1, 8)
				local per_step_time= move_time / anim_steps
				local per_step_color= .5 / anim_steps
				for s= 1, 2 do
					self:GetSpline(s):set_size(#stroke_data[s]):set_loop(stroke_data[s].loop)
				end
				for a= 1, anim_steps do
					for s= 1, 2 do
						shuffle_spline(self:GetSpline(s), stroke_data[s])
					end
					self:SetVertsFromSplines():linear(per_step_time)
					for c= 1, 3 do
						curr_color[c]= curr_color[c] + per_step_color
					end
					color_verts(self, curr_color, num_verts)
				end
				for s= 1, 2 do
					local spline= self:GetSpline(s)
					for p, point in ipairs(stroke_data[s]) do
						spline:set_point(p, point)
					end
					spline:solve()
				end
				self:SetVertsFromSplines()
					:sleep(anim_time - move_time):linear(fade_time)
				for c= 1, 3 do
					curr_color[c]= .5
				end
				color_verts(self, curr_color, num_verts)
			end
		}
	end
	return Def.ActorFrame(args)
end

function animated_text(text, x, y, zoom, anim_time, fade_time)
	local args= {
		InitCommand= function(self)
			self:xy(x, y):linear(anim_time)
	end}
	local letter_w= 16
	local space= zoom * letter_w
	local text_start= (space*.75)-((#text * space) / 2)
	for i= 1, #text do
		local l= text:sub(i, i)
		local lx= text_start+(space*(i-1))
		local glyph_data= animated_text_glyphs[l]
		if glyph_data then
			-- Extra layers for opaqueness.
			for i= 1, 4 do
				args[#args+1]= animated_glyph(glyph_data, lx, 0, zoom, anim_time, fade_time)
			end
		else
			lua.ReportScriptError(l .. " is not in the stroke data.")
		end
	end
	return Def.ActorFrame(args)
end

local vc= color("#ffffff")
function swapping_amv(name, x, y, w, h, xq, yq, texname, activate_name,
											reload_tex, center, init_activate, commands)
	local next_swap_time= 0
	local function update(self)
		if GetTimeSinceStart() < next_swap_time then return end
		next_swap_time= GetTimeSinceStart() + .0625
		local amv= self:GetChild("amv")
		local num_states= amv:GetNumQuadStates()
		if num_states < 2 then return end
		local x= math.random(0, xq-1)
		local y= math.random(0, yq-1)
		local sx= x
		local sy= y
		local choice= math.random(4)
		if choice == 1 then
			sy= y-1
			if sy < 0 then sy= yq-1 end
		elseif choice == 2 then
			sx= x-1
			if sx < 0 then sx= xq-1 end
		elseif choice == 3 then
			sy= y+1
			if sy >= yq then sy= 0 end
		else
			sx= x+1
			if sx >= xq then sx= 0 end
		end
		local first= ((x * yq) + y) + 1
		local second= ((sx * yq) + sy) + 1
		second= force_to_range(1, second, num_states)
		local first_state= amv:GetQuadState(first)
		local second_state= amv:GetQuadState(second)
		amv:SetQuadState(first, second_state)
			:SetQuadState(second, first_state)
			:ForceStateUpdate()
	end
	local com= "Command"
	local frame_act= activate_name
	if init_activate then frame_act= "Init" end
	local args={
		Name= name, [frame_act..com]= function(self)
			self:SetUpdateFunction(update)
				:playcommand("SubInit")
		end,
		Def.ActorMultiVertex{
			Name= "amv", InitCommand= function(self) amv= self:xy(x, y) end,
			[activate_name..com]= function(self)
				if texname then
					self:playcommand("ChangeTexture", {texname})
				end
			end,
			ChangeTextureCommand= function(self, param)
				next_swap_time= 0
				self:LoadTexture(param[1])
				local tex= self:GetTexture()
				if reload_tex then tex:Reload() end
				local iw= tex:GetImageWidth()
				local ih= tex:GetImageHeight()
				local image_aspect= iw / ih
				local space_aspect= w / h
				local sw, sh= w, h
				if image_aspect < space_aspect then
					sw= h * image_aspect
				else
					sh= w / image_aspect
				end
				local disp_space_x= iw / xq
				local disp_space_y= ih / yq
				local spx= sw / xq
				local spy= sh / yq
				local hw= sw * .5
				local hh= sh * .5
				local verts= {}
				local states= {}
				for x= 0, xq-1 do
					local lx= x * spx
					if center then lx= lx - hw end
					local rx= lx + spx
					local disp_lx= math.floor(x * disp_space_x)
					local disp_rx= math.floor(disp_lx + disp_space_x)
					for y= 0, yq-1 do
						local ty= y * spy
						if center then ty= ty - hh end
						local by= ty + spy
						local disp_ty= math.floor(y * disp_space_y)
						local disp_by= math.floor(disp_ty + disp_space_y)
						verts[#verts+1]= {{lx, ty, 0}, vc}
						verts[#verts+1]= {{rx, ty, 0}, vc}
						verts[#verts+1]= {{rx, by, 0}, vc}
						verts[#verts+1]= {{lx, by, 0}, vc}
						states[#states+1]= {{disp_lx, disp_ty, disp_rx, disp_by}, 0}
						self:AddQuadState(#states)
					end
				end
				self:SetDrawState{Mode="DrawMode_Quads"}:SetVertices(verts)
					:animate(true):SetUseAnimationState(true):SetStateProperties(states)
			end
		},
	}
	if commands then
		for k, v in pairs(commands) do
			if type(k) == "number" then
				args[#args+1]= v
			else
				args[k]= v
			end
		end
	end
	return Def.ActorFrame(args)
end

local chactor_width= 16
color_manipulator_mt= {
	__index= {
		create_actors= function(self, name, x, y, colors, zoom)
			colors= colors or {}
			zoom= zoom or 1
			self.zoom= zoom
			local text_color= colors.text or fetch_color("text")
			local bg_color= colors.bg or fetch_color("bg")
			self.name= name
			self.chactors= {}
			self.chex= {}
			local args= {
				Name= name, InitCommand= function(subself)
					subself:xy(x, y):zoom(zoom)
					self.container= subself
					self.mode= subself:GetChild("mode")
					self.done_actor= subself:GetChild("done")
					self.editing_name= subself:GetChild("editing")
					for i= 1, 8 do
						self.chactors[i]= subself:GetChild("ch"..i)
					end
				end,
				Def.Quad{
					Name= "exbg", InitCommand= function(subself)
						subself:setsize(chactor_width*8, 80):vertalign(bottom):xy(8, -16)
							:diffuse{0, 0, 0, 1}
					end
				},
				Def.Quad{
					Name= "chbg", InitCommand= function(subself)
						subself:setsize(chactor_width*8, 256):vertalign(top):xy(8, 16)
							:diffuse{0, 0, 0, 1}
					end
				},
				Def.Quad{
					Name= "example", InitCommand= function(subself)
						self.example= subself
						subself:setsize(chactor_width*8, 80):vertalign(bottom):xy(8, -16)
					end
				},
				normal_text("done", get_string_wrapper("ColorConfig", "done"),
										text_color, bg_color, -112, 0, 1),
				normal_text("mode", "#", text_color, bg_color, -64, 0),
				normal_text("editing", "", text_color, bg_color, -128, -84),
			}
			for i= 1, 4 do
				args[#args+1]= Def.Quad{
					Name= "chex"..i, InitCommand= function(subself)
						self.chex[i]= subself
						subself:setsize(chactor_width*2, 256)
							:xy(-64 + (chactor_width*2 * i) - chactor_width/2, 16)
							:vertalign(top)
					end
				}
			end
			for i= 1, 8 do
				args[#args+1]= normal_text(
					"ch"..i, "", text_color, bg_color, -64 + (chactor_width*i), 0)
			end
			return Def.ActorFrame(args)
		end,
		initialize= function(self, edit_name, example_color, live_edit, color_path, pn)
			self.done= false
			self.edit_channel= "done"
			self.locked_in_editing= false
			self.editing_name:settext(edit_name)
			width_limit_text(self.editing_name, 128)
			self.example:diffuse(example_color)
			self.example_color= DeepCopy(example_color)
			self.color_path= color_path
			self.pn= pn
			self.live_edit= live_edit
			self.internal_values= {}
			for i= 1, 4 do
				self.internal_values[i]= math.round(example_color[i] * 255)
			end
			for i= 1, 4 do
				self:set_channel_text(i, self.internal_values[i])
				self:set_channel_example(i)
			end
		end,
		set_channel_text= function(self, chid, chval)
			local text= ("%02X"):format(chval)
			self.chactors[(chid-1)*2+1]:settext(text:sub(1, 1))
			self.chactors[(chid-1)*2+2]:settext(text:sub(2, 2))
		end,
		set_channel_example= function(self, chid)
			local top_color= DeepCopy(self.example_color)
			local bottom_color= DeepCopy(self.example_color)
			top_color[chid]= 1
			bottom_color[chid]= 0
			self.chex[chid]:diffusetopedge(top_color)
				:diffusebottomedge(bottom_color)
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end,
		adjust_channel= function(self, chid, amount)
			if not chid then return end
			local new_val= self.internal_values[chid] + amount
			if new_val < 0 then new_val= 0 end
			if new_val > 255 then new_val= 255 end
			self.internal_values[chid]= new_val
			self.example_color[chid]= self.internal_values[chid] / 255
			self.example:diffuse(self.example_color)
			self:set_channel_text(chid, self.internal_values[chid])
			for i= 1, 4 do
				self:set_channel_example(i)
			end
			if self.live_edit then
				set_element_by_path(cons_players[self.pn], self.color_path, DeepCopy(self.example_color))
				MESSAGEMAN:Broadcast("color_changed", {name= self.color_path, pn= self.pn})
			end
		end,
		interpret_code= function(self, code)
			if self.locked_in_editing then
				if code == "MenuLeft" then
					code= "MenuDown"
				elseif code == "MenuRight" then
					code= "MenuUp"
				end
			end
			if code == "Start" then
				if self.edit_channel == "done" then
					self.done= true
				elseif tonumber(self.edit_channel) then
					self.locked_in_editing= not self.locked_in_editing
				end
			elseif code == "MenuLeft" then
				if self.edit_channel == "done" then
					self.edit_channel= #self.chactors
				elseif tonumber(self.edit_channel) then
					if self.edit_channel == 1 then
						self.edit_channel= "done"
					else
						self.edit_channel= self.edit_channel - 1
					end
				end
			elseif code == "MenuRight" then
				if self.edit_channel == "done" then
					self.edit_channel= 1
				elseif tonumber(self.edit_channel) then
					if self.edit_channel == #self.chactors then
						self.edit_channel= "done"
					else
						self.edit_channel= self.edit_channel + 1
					end
				end
			elseif code == "MenuUp" then
				if tonumber(self.edit_channel) then
					local chid= math.ceil(self.edit_channel / 2)
					if self.edit_channel % 2 == 1 then
						self:adjust_channel(chid, 16)
					else
						self:adjust_channel(chid, 1)
					end
				end
			elseif code == "MenuDown" then
				if tonumber(self.edit_channel) then
					local chid= math.ceil(self.edit_channel / 2)
					if self.edit_channel % 2 == 1 then
						self:adjust_channel(chid, -16)
					else
						self:adjust_channel(chid, -1)
					end
				end
			end
			return true, self.done
		end,
		get_cursor_fit= function(self)
			local cx= self.container:GetX()
			local cy= self.container:GetY()
			local chact
			if self.edit_channel == "done" then
				chact= self.done_actor
			elseif tonumber(self.edit_channel) then
				chact= self.chactors[self.edit_channel]
			end
			local fit= {
				cx + chact:GetX() * self.zoom, cy + chact:GetY() * self.zoom,
				chact:GetWidth() * self.zoom, 24 * self.zoom}
			return fit
		end
}}
