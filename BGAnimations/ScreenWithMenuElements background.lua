local black= {0, 0, 0, 1}

local bg_tex_size= 256
local hbg_tex_size= bg_tex_size / 2

local bubble= false
local bg_sprite= false
local bubble_currs= {}
local bubble_goals= {}
local bubble_speeds= {}
local speed_funcs= {
	function() return math.random()*.015625 end,
	function() return math.random()*.015625 end,
	function() return math.random()*(2^-15) end,
	function() return math.random()*.0078125 end,
}
local goal_funcs= {
	function() return math.random()*_screen.w end,
	function() return math.random()*_screen.h end,
	function() return (((1-math.random())^8) * 128) / big_circle_size end,
--	function() return math.random(4, 128) / big_circle_size end,
	function() return math.random()*.125 end,
}
local epsilon= 2^-16
local function bubbles_update()
	multiapproach(bubble_currs, bubble_goals, bubble_speeds)
	for i= 1, #bubble_currs do
		if math.abs(bubble_goals[i] - bubble_currs[i]) < epsilon then
			local funi= math.floor(((i-1)%4)+1)
			bubble_goals[i]= goal_funcs[funi]()
			bubble_speeds[i]= speed_funcs[funi]()
		end
	end
end
local function bubbles_draw()
	bg_sprite:Draw()
	for i= 1, #bubble_currs, 4 do
		bubble:xy(bubble_currs[i], bubble_currs[i+1])
			:zoom(bubble_currs[i+2])--:diffusealpha(bubble_currs[i+3])
			:Draw()
	end
end
for i= 1, 64*4, 4 do
	for j= 0, 3 do
		bubble_currs[i+j]= goal_funcs[j+1]()
		bubble_goals[i+j]= goal_funcs[j+1]()
		bubble_speeds[i+j]= speed_funcs[j+1]()
	end
end

local args= {
	Def.ActorFrame{
		InitCommand= function(self)
			self
				:SetUpdateFunction(bubbles_update):SetDrawFunction(bubbles_draw)
		end,
		Def.ActorFrameTexture{
			InitCommand= function(self)
				self:setsize(bg_tex_size, bg_tex_size)
					:SetTextureName("colored_bg")
					:EnableAlphaBuffer(true):Create()
					:EnablePreserveTexture(false):Draw()
					:hibernate(math.huge)
			end,
			Def.Quad{
				InitCommand= function(self)
					local outer_colors= fetch_color("common_background.outer_colors")
					self:setsize(bg_tex_size, bg_tex_size):diffuse(outer_colors[1])
						:xy(hbg_tex_size, hbg_tex_size)
				end
			},
			Def.ActorMultiVertex{
				InitCommand= function(self)
					local center_color= fetch_color("common_background.center_color")
					local inner_colors= fetch_color("common_background.inner_colors")
					local outer_colors= fetch_color("common_background.outer_colors")
					local circle_vert_count= bg_tex_size * 2
					local inner_circle= calc_circle_verts(
						hbg_tex_size*.5, circle_vert_count, 0, 0)
					local outer_circle= calc_circle_verts(
						hbg_tex_size, circle_vert_count, 0, 0)
					color_verts_with_color_set(inner_circle, inner_colors)
					color_verts_with_color_set(outer_circle, outer_colors)
					local center_vert= {{0, 0, 0}, center_color}
					self:SetNumVertices(circle_vert_count * 3 + circle_vert_count * 6)
					for i= 2, circle_vert_count do
						local triseti= (i-2) * 9
						self:SetVertex(triseti + 1, center_vert)
							:SetVertex(triseti + 2, inner_circle[i-1])
							:SetVertex(triseti + 3, inner_circle[i])
							:SetVertex(triseti + 4, inner_circle[i-1])
							:SetVertex(triseti + 5, outer_circle[i-1])
							:SetVertex(triseti + 6, outer_circle[i])
							:SetVertex(triseti + 7, inner_circle[i])
							:SetVertex(triseti + 8, inner_circle[i-1])
							:SetVertex(triseti + 9, outer_circle[i])
					end
					do
						local triseti= (circle_vert_count-1) * 9
						self:SetVertex(triseti + 1, center_vert)
							:SetVertex(triseti + 2, inner_circle[circle_vert_count])
							:SetVertex(triseti + 3, inner_circle[1])
							:SetVertex(triseti + 4, inner_circle[circle_vert_count])
							:SetVertex(triseti + 5, outer_circle[circle_vert_count])
							:SetVertex(triseti + 6, outer_circle[1])
							:SetVertex(triseti + 7, inner_circle[1])
							:SetVertex(triseti + 8, inner_circle[circle_vert_count])
							:SetVertex(triseti + 9, outer_circle[1])
					end
					self:SetDrawState{Mode= "DrawMode_Triangles"}
						:xy(hbg_tex_size, hbg_tex_size)
				end
			},
			Def.Sprite{
				Texture= THEME:GetPathB("ScreenNoise", "background/noise.png"),
				InitCommand= function(self)
					self:xy(hbg_tex_size, hbg_tex_size):texturewrapping(true)
						:SetTextureFiltering(false):diffusealpha(2^-6):zoom(.25)
				end
			},
		},
		Def.Sprite{
			Texture= "colored_bg", InitCommand= function(self)
				bg_sprite= self
				self:xy(_screen.cx, _screen.cy):diffuse(color("#7f7f7f"))
					:zoomx(_screen.w * 1.25 / bg_tex_size)
					:zoomy(_screen.h * 1.25 / bg_tex_size)
			end
		},
		Def.Sprite{
		Texture= "big_circle", InitCommand= function(self)
			bubble= self
			self:blend("BlendMode_WeightedMultiply")
		end
		},
	},
}

return Def.ActorFrame(args)
--[[
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
]]
