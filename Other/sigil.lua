-- calc_sigil_verts_alt is the one that is actually used.  Other functions are kept for posterity.
-- Use by creating a table with sigil_controller_mt as its metatable.  Standard create_actors/find_actors interface, resize for tweening to a new size.  See definition of create_actors for special args.

local function dswa_create_actors()
	local x, y= 0, 0
	local num_sigil_actors= 256
	local sigil_line_len= 16
	local player_number= PLAYER_1
	local args= { Name= name, InitCommand= cmd(x,fx;y,fy) }
	for n= 1, num_sigil_actors do
		args[#args+1]= Def.Quad{
			Name= "l" .. n, InitCommand=
				function(self)
					self:xy(0, 0)
					self:horizalign(left)
					self:SetWidth(sigil_line_len)
					self:SetHeight(2)
					self:diffuse(solar_colors[player_number]())
				end
		}
	end
	return Def.ActorFrame(args)
end
local function dswa_find_actors(self)
	for n= 1, num_sigil_actors do
		self.actor_set[#self.actor_set+1]= container:GetChild("l" .. n)
	end
	self:draw_sigil(self.prev_state.detail)
end
local function convert_detail_and_life_to_update_index(detail, life)
	return math.floor(detail * detail * life)
end
local function dswa_resize(self)
	if new_detail ~= self.prev_state.detail then
		self:draw_sigil(new_detail)
	end
	local dsq= new_detail * new_detail
	local curr_life_fill= life * dsq
	local prev_update_index= convert_detail_and_life_to_update_index(self.prev_state.detail, self.prev_state.fill_amount)
	local new_update_index= convert_detail_and_life_to_update_index(new_detail, life)
	local min_update_index= prev_update_index
	local max_update_index= new_update_index + 1
	if new_update_index < prev_update_index then
		min_update_index= new_update_index
		max_update_index= prev_update_index + 1
	end
	for n= min_update_index, max_update_index do
		if self.actor_set[n] then
			local curr_fill= math.max(0, math.min(1, curr_life_fill - (n - 1)))
			--Trace(tostring(actors[n]) .. ": line " .. n .. ", life " .. life .. ", fill " .. tostring(curr_fill))
			self.actor_set[n]:zoomx(curr_fill)
			self.actor_set[n]:zoomy(1)
		end
	end
end
-- Draws a sigil in circles mode.  Intended for a collection of Quads.
local function draw_sigil_with_actors(num_rots, actors, line_len, cx, cy)
	--Trace("dswa actor list: " .. #actors .. "  detail: " .. num_rots)
	num_rots= force_to_range(1, num_rots, max_sigil_detail)
	--print_table(actors, "  ")
	local edge_rots= {}
	local edge_rots_num= {}
	local rot_seperation= ((math.pi*2) / num_rots)
	local rotsep_num= (360 / num_rots)
	for n= 1, num_rots do
		edge_rots[n]= rot_seperation * n
		edge_rots_num[n]= ((rotsep_num * n)) % 360
	end
	local num_edges= (num_rots * num_rots)
	local prev_pos= {x= cx, y= cy}
	local prev_index= 1
	local index_offset= 0
	for n= 1, num_edges do
		local act= actors[n]
		local real_index= ((prev_index + index_offset) % num_rots) + 1
		local px, py= prev_pos.x, prev_pos.y
		--Trace("dswa actor " .. n .. ": " .. px .. ", " .. py .. "  rot: " .. edge_rots[real_index])
		act:linear(0.1)
		act:rotationz(edge_rots_num[real_index])
		act:linear(0.4)
		act:xy(px, py)
		--real_index= ((real_index - 1) % num_rots) + 1
		prev_pos.x= prev_pos.x + math.cos(edge_rots[real_index]) * line_len
		prev_pos.y= prev_pos.y + math.sin(edge_rots[real_index]) * line_len
		prev_index= prev_index + 1
		if prev_index > num_rots then
			prev_pos= {x= cx, y= cy}
			index_offset= index_offset + 1
			prev_index= 1
		end
	end
end

local function calc_max_verts(size)
	return (size * size) + 1
end

-- Draws a sigil in circles mode.  Intended for an AMV in linestrip mode.
local function calc_sigil_verts(size, max_size)
	local length= 16
	local verts= {}
	local vert_advances= {}
	local rot_seperation= ((math.pi*2) / size)
	local start_angle= math.pi
	for n= 1, size do
		local angle= start_angle + ((n-1) * rot_seperation)
		vert_advances[n]= {
			math.cos(angle) * length,
			math.sin(angle) * length}
	end
	local num_edges= size * size
	local max_edges= calc_max_verts(max_size)
	local prev_pos= {0, 0}
	local prev_index= 1
	local index_offset= 1
	for n= 1, num_edges do
		local offset_index= (((prev_index-1) + (index_offset-1)) % size)+1
		local px, py= prev_pos[1], prev_pos[2]
		verts[n]= {{prev_pos[1], prev_pos[2], 0}}
		prev_pos[1]= px + math.cos((offset_index-1) * rot_seperation) * length
		prev_pos[2]= py + math.sin((offset_index-1) * rot_seperation) * length
		prev_index= prev_index+1
		if prev_index > size then
			prev_pos[1]= 0
			prev_pos[2]= 0
			index_offset= index_offset + 1
			prev_index= 1
		end
	end
	for n= num_edges+1, max_edges do
		verts[n]= {{0, 0, 0}}
	end
	return verts
end

local function calc_sigil_layers(detail)
	return math.ceil(detail * .5)
end

local function calc_max_verts_alt(detail)
	local layers= calc_sigil_layers(detail)
	return (detail * 2 * layers) + layers
end

-- Draws a sigil in layer style.  Intendeded for an AMV in linestrip mode.
local function calc_sigil_verts_alt(detail, max_detail, length)
	local verts= {}
	local vert_advances= {}
	local rot_seperation= ((math.pi*2) / detail)
	local start_angle= math.pi
	for n= 1, detail do
		local angle= start_angle + ((n-1) * rot_seperation)
		vert_advances[n]= {
			math.cos(angle) * length,
			math.sin(angle) * length}
	end
	local max_verts= calc_max_verts_alt(max_detail)
	verts[#verts+1]= {{0, 0, 0}}
	local layers= calc_sigil_layers(detail)
	local fraction_pervert= (max_verts / calc_max_verts_alt(detail)) - 1
	local fractional_vert= 0
	local function add_fraction(curr_pos, laycol)
		fractional_vert= fractional_vert + fraction_pervert
		while fractional_vert >= 1 do
			verts[#verts+1]= {{curr_pos[1], curr_pos[2], 0}, laycol}
			fractional_vert= fractional_vert - 1
		end
	end
	for l= 1, layers do
		--local laycol= convert_wrapping_number_to_color(l)
		local next_layer_begin_vert= {}
		for v= 1, detail do
			local out_adv= vert_advances[wrapped_index(v, (l-1), #vert_advances)]
			local back_adv= vert_advances[wrapped_index(v, 0, #vert_advances)]
			local curr_pos= {verts[#verts][1][1], verts[#verts][1][2]}
			curr_pos[1]= curr_pos[1] + out_adv[1]
			curr_pos[2]= curr_pos[2] + out_adv[2]
			verts[#verts+1]= {{curr_pos[1], curr_pos[2], 0}, laycol}
			add_fraction(curr_pos, laycol)
			if v == 1 then
				next_layer_begin_vert= {curr_pos[1], curr_pos[2]}
			end
			curr_pos[1]= curr_pos[1] - back_adv[1]
			curr_pos[2]= curr_pos[2] - back_adv[2]
			verts[#verts+1]= {{curr_pos[1], curr_pos[2], 0}, laycol}
			add_fraction(curr_pos, laycol)
		end
		if l < layers then
			verts[#verts+1]= {{next_layer_begin_vert[1], next_layer_begin_vert[2], 0}, laycol}
		end
	end
	local verts_used= #verts
	local end_vert= verts[#verts]
	for n= verts_used+1, max_verts do
		verts[#verts+1]= end_vert
	end
	return verts, verts_used
end

sigil_controller_mt= {
	__index= {
		create_actors=
			function(self, name, x, y, color, max_detail, size)
				self.name= name
				self.max_detail= max_detail
				do
					local layers= calc_sigil_layers(max_detail)
					local width= 0
					local rot_seperation= ((math.pi*2) / max_detail)
					for l= 1, layers do
						local angle= (l-1) * rot_seperation
						width= width + math.sin(angle)
					end
					if width > 0 then
						self.length= size / width / 2
					else
						self.length= 1
					end
				end
				local verts= {}
				local max_verts= calc_max_verts_alt(max_detail)
				for n= 1, max_verts do
					verts[n]= {{0, 0, 0}, color}
				end
				return Def.ActorMultiVertex{
					Name= name,
					InitCommand=
						function(subself)
							self.container= subself
							self.sigil= subself
							subself:xy(x, y)
							subself:SetDrawState{Mode="DrawMode_LineStrip"}
							subself:SetVertices(verts)
							self:redetail(max_detail)
						end
				}
			end,
		redetail=
			function(self, new_detail)
				new_detail= math.max(math.min(new_detail, self.max_detail), 1)
				if self.detail == new_detail then return end
				if self.sigil then
					local new_verts, used_verts= calc_sigil_verts_alt(new_detail, self.max_detail, self.length)
--					self.sigil:SetDrawState{Num= used_verts}
					self.sigil:linear(.5)
					self.sigil:SetVertices(new_verts)
				end
				self.detail= new_detail
			end
}}
