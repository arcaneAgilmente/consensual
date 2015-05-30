local black= {0, 0, 0, 1}

local bg_tex_size= 256
local hbg_tex_size= bg_tex_size / 2
local bubble_count= 64

local bubble= false
local bg_sprite= false
local rerender_list= {}
function update_common_bg_colors()
	for i, actor in ipairs(rerender_list) do
		actor:playcommand("render")
	end
end

local bubble_currs= {}
local bubble_goals= {}
local bubble_speeds= {}
local epsilon= {2^-8, 2^-8, 2^-10, 2^-4, 2^-4, 2^-4}
local function pos_speed() return scale(math.random(), 0, 1, 1, 2) end
local function col_speed() return scale(math.random(), 0, 1, 2^-5, 2^-4) end
local speed_funcs= {
	pos_speed, pos_speed,
	function() return scale(math.random(), 0, 1, 2^-9, 2^-8) end,
	col_speed, col_speed, col_speed,
}
local function col_goal() return scale(math.random(), 0, 1, .5, .875) end
local goal_funcs= {
	function() return math.random()*_screen.w end,
	function() return math.random()*_screen.h end,
	function() return scale(((1-math.random())^8), 0, 1, 4, 128) / big_circle_size end,
	col_goal, col_goal, col_goal,
}
local real_speeds= {}
local function bubbles_update(self, delta)
	for i= 1, #bubble_speeds do
		real_speeds[i]= bubble_speeds[i] * delta;
	end
	multiapproach(bubble_currs, bubble_goals, real_speeds)
	for i= 1, #bubble_currs do
		local funi= math.floor(((i-1)%#goal_funcs)+1)
		if math.abs(bubble_goals[i] - bubble_currs[i]) < epsilon[funi] then
			bubble_goals[i]= goal_funcs[funi]()
			bubble_speeds[i]= speed_funcs[funi]()
		end
	end
end
local function bubbles_draw()
	bg_sprite:Draw()
	for i= 1, #bubble_currs, #goal_funcs do
		bubble:xy(bubble_currs[i], bubble_currs[i+1])
			:zoom(bubble_currs[i+2])
			:diffuse({bubble_currs[i+3], bubble_currs[i+4], bubble_currs[i+5], 1})
			:Draw()
	end
end
for i= 1, bubble_count*#goal_funcs, #goal_funcs do
	for j= 0, 5 do
		bubble_currs[i+j]= goal_funcs[j+1]()
		bubble_goals[i+j]= goal_funcs[j+1]()
		bubble_speeds[i+j]= speed_funcs[j+1]()
	end
end

local args= {
	Def.ActorFrame{
		InitCommand= function(self)
			common_bg= self
			self:SetUpdateFunction(bubbles_update):SetDrawFunction(bubbles_draw)
		end,
		Def.ActorFrameTexture{
			InitCommand= function(self)
				rerender_list[#rerender_list+1]= self
				self:setsize(bg_tex_size, bg_tex_size)
					:SetTextureName("colored_bg")
					:EnableAlphaBuffer(true):Create()
					:EnablePreserveTexture(false):Draw()
					:hibernate(math.huge)
			end,
			renderCommand= function(self)
				self:hibernate(0):Draw():hibernate(math.huge)
			end,
			Def.Quad{
				InitCommand= function(self)
					rerender_list[#rerender_list+1]= self
					self:playcommand("render")
				end,
				renderCommand= function(self)
					local outer_colors= fetch_color("common_background.outer_colors")
					self:setsize(bg_tex_size, bg_tex_size):diffuse(outer_colors[1])
						:xy(hbg_tex_size, hbg_tex_size)
				end
			},
			Def.ActorMultiVertex{
				InitCommand= function(self)
					rerender_list[#rerender_list+1]= self
					self:SetDrawState{Mode= "DrawMode_Triangles"}
						:xy(hbg_tex_size, hbg_tex_size)
						:playcommand("render")
				end,
				renderCommand= function(self)
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
				rerender_list[#rerender_list+1]= self
				self:xy(_screen.cx, _screen.cy):playcommand("render")
			end,
			renderCommand= function(self)
				self:diffuse(color("#7f7f7f"))
					:zoomx(_screen.w * 1.25 / bg_tex_size)
					:zoomy(_screen.h * 1.25 / bg_tex_size)
			end
		},
		Def.Sprite{
		Texture= "big_spotlight", InitCommand= function(self)
			bubble= self
			self:blend("BlendMode_WeightedMultiply")
		end
		},
	},
}

return Def.ActorFrame(args)
