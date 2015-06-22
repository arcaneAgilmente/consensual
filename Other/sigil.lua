-- calc_sigil_verts_alt is the one that is actually used.  Other functions are kept for posterity.
-- Use by creating a table with sigil_controller_mt as its metatable.  Standard create_actors/find_actors interface, resize for tweening to a new size.  See definition of create_actors for special args.

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
	local extra_per_layer= (max_detail * 2 + 1) - (detail * 2 + 1)
	local fraction_pervert= extra_per_layer / (detail * 2 + 1)
	local fractional_vert= 0
	local threshold= 1
	local function add_fraction(curr_pos, laycol)
		fractional_vert= fractional_vert + (fraction_pervert * 2)
		while fractional_vert >= threshold do
			verts[#verts+1]= {{curr_pos[1], curr_pos[2], 0}, laycol}
			fractional_vert= fractional_vert - 1
		end
	end
	local last_layer_verts= {}
	for l= 1, layers do
		--local laycol= wrapping_number_to_color(l)
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
			if l == layers then
				last_layer_verts[#last_layer_verts+1]= verts[#verts-1]
				last_layer_verts[#last_layer_verts+1]= verts[#verts]
			end
		end
		if l < layers then
			verts[#verts+1]= {{next_layer_begin_vert[1], next_layer_begin_vert[2], 0}, laycol}
		end
	end
	local extra_layers= calc_sigil_layers(max_detail) - layers
	local per_extra_layer= (max_detail * 2) + 1
	for l= 1, extra_layers do
		for v= 1, per_extra_layer do
			local ind= math.floor(v * (#last_layer_verts / per_extra_layer))
			verts[#verts+1]= last_layer_verts[ind]
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
		create_actors= function(self, name, x, y, color, max_detail, size)
			self.name= name
			self.max_detail= max_detail
			self.shift_time= .5
			self.detail_queue= {}
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
				Name= name, InitCommand= function(subself)
					self.container= subself
					self.sigil= subself
					subself:xy(x, y):SetDrawState{Mode="DrawMode_LineStrip"}
						:SetVertices(verts)
					self:internal_redetail(max_detail)
				end,
				queued_redetailCommand= function(subself)
					if self.detail_queue[1] then
						self:internal_redetail(self.detail_queue[1])
						table.remove(self.detail_queue, 1)
						subself:queuecommand("queued_redetail")
					end
				end,
				goaled_redetailCommand= function(subself)
					if self.detail < self.goal_detail then
						self:internal_redetail(self.detail + 1)
						subself:queuecommand("goaled_redetail")
					elseif self.detail > self.goal_detail then
						self:internal_redetail(self.detail - 1)
						subself:queuecommand("goaled_redetail")
					else
						self.moving_to_goal= false
					end
				end
			}
		end,
		redetail= function(self, new_detail)
			self.detail_queue[#self.detail_queue+1]= new_detail
			if #self.detail_queue == 1 then
				self.sigil:queuecommand("queued_redetail")
			end
		end,
		set_goal_detail= function(self, new_goal)
			if new_goal > 0 and new_goal <= self.max_detail then
				self.goal_detail= new_goal
				if not self.moving_to_goal then
					self.moving_to_goal= true
					self.sigil:queuecommand("goaled_redetail")
				end
			end
		end,
		internal_redetail= function(self, new_detail)
			new_detail= math.max(math.min(new_detail, self.max_detail), 1)
			if self.detail == new_detail then return end
			if self.sigil then
				local new_verts, used_verts= calc_sigil_verts_alt(new_detail, self.max_detail, self.length)
				self.sigil:april_linear(self.shift_time):SetVertices(new_verts)
			end
			self.detail= new_detail
		end
}}
