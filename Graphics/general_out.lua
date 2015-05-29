local conf_data= misc_config:get_data()
local trans_time= conf_data.transition_time
if conf_data.transition_split_max <= 0 or conf_data.transition_split_min <= 0 then
	return Def.Actor{
		StartTransitioningCommand= function(self)
			SCREENMAN:GetTopScreen():GetChild("Overlay")
				:linear(trans_time):diffusealpha(0)
			self:sleep(trans_time)
		end
	}
end

local function fade_out(self)
	self:sleep(trans_time/2):linear(trans_time/2):diffusealpha(0)
end
local function pot(i)
	return 2^(math.ceil(math.log(i) / math.log(2)))
end
local dwidth= DISPLAY:GetDisplayWidth()
local dheight= DISPLAY:GetDisplayHeight()
local ratio= dwidth / dheight
local split_min= math.floor(force_to_range(1, conf_data.transition_split_min, 64))
local split_max= math.ceil(force_to_range(1, conf_data.transition_split_max, 64))
local xq= math.max(split_max, split_min)
if split_max - split_min > 1 then
	xq= math.random(split_min, split_max)
end
local yq= math.ceil(xq / ratio)
local max_var= 0
local meta_var_max= conf_data.transition_meta_var_max
if misc_config:get_data().disable_extra_processing then
	xq= math.min(xq, 2)
	yq= math.min(yq, 2)
	meta_var_max= 0
end

if meta_var_max > 0 then
	meta_var_max= force_to_range(1, math.ceil(meta_var_max), 96)
	local var_var= .125
	if meta_var_max > 1 then
		var_var= math.random(1, math.ceil(meta_var_max)) / 8
	end
	max_var= math.ceil(dwidth / xq * var_var)
end
local vc= color("#ffffff")
local spx= _screen.w / xq
local spy= _screen.h / yq
local max_texx= dwidth / pot(dwidth)
local max_texy= dheight / pot(dheight)
local sptx= max_texx / xq
local spty= max_texy / yq
local tex_load_time= 0
local vert_set_time= 0
local tex_pos_time= 0

local scramble_chosen= false
if conf_data.transition_type == "scramble" then
	scramble_chosen= true
elseif conf_data.transition_type == "random" then
	scramble_chosen= (math.random(2) == 1)
end
if scrambler_mode then scramble_chosen= true end
if not ActorMultiVertex.SetStateProperties then scramble_chosen= false end

local overlay_render= Def.ActorFrameTexture{
	InitCommand= function(self)
		self:visible(false)
	end,
	StartTransitioningCommand= function(self)
		self:setsize(DISPLAY:GetDisplayWidth(), DISPLAY:GetDisplayHeight())
			:SetTextureName("trans_overlay")
			:EnableAlphaBuffer(true):Create()
			:EnablePreserveTexture(false)
	end,
	Def.ActorProxy{
		StartTransitioningCommand= function(self)
			local overlay= SCREENMAN:GetTopScreen():GetChild("Overlay")
			overlay:visible(false)
			self:SetTarget(overlay):zoom(DISPLAY:GetDisplayHeight() / _screen.h)
				:blend("BlendMode_WeightedMultiply")
			self:GetParent():visible(true):Draw():visible(false)
		end
	},
}

if scramble_chosen then
	xq= math.max(xq, 2)
	yq= math.max(yq, 2)
	return Def.ActorFrame{
		StartTransitioningCommand= fade_out,
		overlay_render,
		swapping_amv("swapper", 0, 0, _screen.w, _screen.h, xq, yq,
								 "trans_overlay", "StartTransitioning", false, false),
	}
end

local unskewed_verts= {}
local skewed_verts= {}
local function random_var()
	return math.random(max_var*2+1) - max_var - 1
end
for x= -1, xq+1 do
	unskewed_verts[x]= {}
	skewed_verts[x]= {}
	for y= -1, yq+1 do
		if x >= 0 and x < xq+1 and y >= 0 and y < yq+1 then
			if max_var > 0 then
				skewed_verts[x][y]= {
					(spx * x) + random_var(), (spy * y) + random_var(),
				}
			else
				skewed_verts[x][y]= {(spx * x), (spy * y)}
			end
			unskewed_verts[x][y]= {(spx * x), (spy * y)}
		else
			skewed_verts[x][y]= {(spx * x), (spy * y)}
			unskewed_verts[x][y]= {(spx * x), (spy * y)}
		end
	end
end
local vert_poses= {unskewed_verts, skewed_verts}

local texcalc= {
	function(c, cm, sp, tmax)
		if c == 0 then return 0, sp * (c-1) end
		if c == cm then return sp * (c-1), tmax end
		return sp * (c-1), sp * c
	end,
	function(c, cm, sp, tmax)
		return 0, tmax
	end
}

return Def.ActorFrame{
	StartTransitioningCommand= fade_out,
	overlay_render,
	Def.ActorMultiVertex{
		Name= "transplitter", StartTransitioningCommand= function(self)
			self:LoadTexture("trans_overlay")
			local after_verts= GetTimeSinceStart()
			vert_set_time= after_verts - after_tex
			tex_pos_time= GetTimeSinceStart() - after_verts
			self:SetDrawState{Mode="DrawMode_Quads"}:playcommand("new_verts", {1})
				:sleep(vert_set_time+(tex_pos_time*2))
				:linear(trans_time):playcommand("new_verts", {2})
		end,
		showCommand= function(self)
			self:visible(true)
		end,
		new_vertsCommand= function(self, params)
			local calc_use= texcalc[params[1]]
			local pose_use= vert_poses[params[1]]
			local verts= {}
			for x= 0, xq+1 do
				local ltx, rtx= calc_use(x, xq+1, sptx, max_texx)
				for y= 0, yq+1 do
					local ltv= pose_use[x-1][y-1]
					local rtv= pose_use[x][y-1]
					local rbv= pose_use[x][y]
					local lbv= pose_use[x-1][y]
					local tty, bty= calc_use(y, yq+1, spty, max_texy)
					verts[#verts+1]= {{ltv[1], ltv[2], 0}, vc, {ltx, tty}}
					verts[#verts+1]= {{rtv[1], rtv[2], 0}, vc, {rtx, tty}}
					verts[#verts+1]= {{rbv[1], rbv[2], 0}, vc, {rtx, bty}}
					verts[#verts+1]= {{lbv[1], lbv[2], 0}, vc, {ltx, bty}}
				end
			end
			self:SetVertices(verts)
		end
	},
}
