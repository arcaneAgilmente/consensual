local args= {
	Def.Quad{
		InitCommand= cmd(setsize, _screen.w, _screen.h; xy, _screen.cx, _screen.cy; diffuse, color("0,0,0,1"))
	}
}

local time_colors= fetch_color("accent")

local hold_colors= {
	fetch_color("accent.green"), fetch_color("accent.magenta")
}

local player_colors= {
	fetch_color("bg"), fetch_color("player.p1"), fetch_color("player.p2")
}

local function simple_star(name, x, y, t, c)
	return Def.ActorMultiVertex{
		Name= name,
		InitCommand= function(self)
			self:xy(x, y)
			local points= 7
			local point_poses= calc_circle_verts(26, points, 0, 0)
			local step= 4
			local verts= {}
			local curr_point= 1
			repeat
				local curr_pos= point_poses[curr_point]
				local next_point= wrapped_index(curr_point, step, points)
				local next_pos= point_poses[next_point]
				local forward= {next_pos[1][1] - curr_pos[1][1], next_pos[1][2] - curr_pos[1][2]}
				local right= {forward[2], -forward[1]}
				local rmag= math.sqrt(right[1] * right[1] + right[2] * right[2])
				right[1]= right[1] / rmag * t / 2
				right[2]= right[2] / rmag * t / 2
				verts[#verts+1]= {{curr_pos[1][1] + right[1], curr_pos[1][2] + right[2], 0}, c}
				verts[#verts+1]= {{curr_pos[1][1] - right[1], curr_pos[1][2] - right[2], 0}, c}
				verts[#verts+1]= {{next_pos[1][1] - right[1], next_pos[1][2] - right[2], 0}, c}
				verts[#verts+1]= {{next_pos[1][1] + right[1], next_pos[1][2] + right[2], 0}, c}
				curr_point= next_point
			until curr_point == 1
			self:SetDrawState{Mode="DrawMode_Quads"}
			self:SetVertices(verts)
			self:SetLineWidth(t)
		end
	}
end

local xs= 36
local xsp= 68
local ys= 36
local ysp= 68
for y, pc in ipairs(player_colors) do
	local ypos= ys + (ysp * (y-1))
	local repy= ys + (ysp * (y+#player_colors-1))
	for x, tc in ipairs(time_colors) do
		local xpos= xs + (xsp * (x-1))
		args[#args+1]= noteskin_arrow_amv(
			"tap"..x..y, xpos, ypos, 0, 64, tc, pc)
		args[#args+1]= Def.ActorMultiVertex{
			Name= "Lift" .. x .. y,
			InitCommand= function(self)
				self:xy(xpos, repy)
				local verts= {
					{{-32, -16, 0}, pc}, {{32, -16, 0}, pc},
					{{32, 16, 0}, pc}, {{-32, 16, 0}, pc},
					{{-24, -16, 0}, tc}, {{24, -16, 0}, tc},
					{{24, 16, 0}, tc}, {{-24, 16, 0}, tc},
				}
				self:SetDrawState{Mode= "DrawMode_Quads"}
				self:SetVertices(verts)
			end
		}
	end
	for x, hc in ipairs(hold_colors) do
		args[#args+1]= Def.ActorMultiVertex{
			Name= "hold" .. x .. y,
			InitCommand= function(self)
				local verts= {}
				self:xy(xs + (xsp * (x-1+#time_colors)), ypos)
				local hcol= hc
				if y == 1 then
					hcol= adjust_luma(hc, 2)
				elseif y == 2 then
					hcol= adjust_luma(hc, .5)
				end
				if x == 1 then
					verts= {
						{{-32, -32, 0}, pc}, {{32, -32, 0}, pc},
						{{32, 32, 0}, pc}, {{-32, 32, 0}, pc},
						{{-24, -32, 0}, hcol}, {{24, -32, 0}, hcol},
						{{24, 32, 0}, hcol}, {{-24, 32, 0}, hcol},
					}
				else
					verts= {
						{{-32, -32, 0}, pc}, {{32, -32, 0}, pc},
						{{16, -16, 0}, pc}, {{-16, -16, 0}, pc},
						{{16, -16, 0}, pc}, {{-16, -16, 0}, pc},
						{{-32, 0, 0}, pc}, {{32, 0, 0}, pc},
						{{-32, 0, 0}, pc}, {{32, 0, 0}, pc},
						{{16, 16, 0}, pc}, {{-16, 16, 0}, pc},
						{{16, 16, 0}, pc}, {{-16, 16, 0}, pc},
						{{-32, 32, 0}, pc}, {{32, 32, 0}, pc},
						{{-24, -32, 0}, hcol}, {{24, -32, 0}, hcol},
						{{8, -16, 0}, hcol}, {{-8, -16, 0}, hcol},
						{{8, -16, 0}, hcol}, {{-8, -16, 0}, hcol},
						{{-24, 0, 0}, hcol}, {{24, 0, 0}, hcol},
						{{-24, 0, 0}, hcol}, {{24, 0, 0}, hcol},
						{{8, 16, 0}, hcol}, {{-8, 16, 0}, hcol},
						{{8, 16, 0}, hcol}, {{-8, 16, 0}, hcol},
						{{-24, 32, 0}, hcol}, {{24, 32, 0}, hcol},
					}
				end
				self:SetDrawState{Mode= "DrawMode_Quads"}
				self:SetVertices(verts)
			end
		}
	end
	args[#args+1]= simple_star(
		y.."mine", xs + (xsp * (#time_colors + #hold_colors)), ypos, 12, pc)
	args[#args+1]= simple_star(
		y.."mine", xs + (xsp * (#time_colors + #hold_colors)), ypos, 4,
		fetch_color("accent.magenta"))
end
local othery= ys + (#player_colors*2 * ysp)
for x, tc in ipairs(time_colors) do
	args[#args+1]= noteskin_arrow_amv(
		"fake"..x, xs + ((x-1)*xsp), othery, 0, 64, tc, fetch_color("text"))
end
args[#args+1]= noteskin_arrow_amv(
	"receptor", xs + (#time_colors*xsp), othery, 0, 64,
	fetch_color("text"), fetch_color("text_other")

args[#args+1]= noteskin_arrow_amv(
	"explosion", xs+((#time_colors+1)*xsp), othery, 0, 64,
		color("1,1,1"), color("0,0,0"))



return Def.ActorFrame(args)
