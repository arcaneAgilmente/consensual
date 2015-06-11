local text_and_number_interface= {}

function normal_text(name, text, color, stroke, tx, ty, z, align, commands)
	color= color or fetch_color("text")
	tx= tx or 0
	ty= ty or 0
	z= z or 1
	align= align or center
	local passed_init= commands and commands.InitCommand
	commands= commands or {}
	commands.Name= name
	commands.Text= text
	commands.InitCommand= function(self)
		self:xy(tx,ty):zoom(z):diffuse(color):horizalign(align)
		if stroke and stroke[4] > 0 then self:strokecolor(stroke) end
		maybe_distort_text(self)
		if passed_init then passed_init(self) end
	end
	return LoadFont("Common Normal") .. commands
end

function set_text_from_parts(self, parts)
	self:ClearAttributes()
	local full_text= ""
	for i, part in ipairs(parts) do
		full_text= full_text .. part[1]
	end
	self:settext(full_text)
	local curr_pos= 0
	for i, part in ipairs(parts) do
		local part_len= #part[1]
		self:AddAttribute(curr_pos, {Length= part_len, Diffuse= part[2]})
		curr_pos= curr_pos + part_len
	end
end

function attributed_text(name, x, y, z, align, parts, commands)
	local ret=  Def.BitmapText{
		Name= name, Font= "Common Normal", InitCommand= function(self)
			self:xy(x, y):zoom(z):horizalign(align)
			set_text_from_parts(self, parts)
			maybe_distort_text(self)
			if commands.InitCommand then commands.InitCommand(self) end
		end
	}
	for k, v in pairs(commands) do
		if k ~= "InitCommand" then
			ret[k]= v
		end
	end
	return ret
end

do
	local default_params= {
		sx= 0, sy= 0, tx= 0, ty= 0, tz= 1, tc= fetch_color("text"), tt= "",
		ts= "", ta= right, na= left, tf= "Common Normal", nf= "Common Normal",
		text_section= "Misc", nx= 0, ny= 0, nz= 1, nc= fetch_color("text"),
		nt= "0" }

	function text_and_number_interface:create_actors(name, params)
		if not name then return nil end
		self.name= name
		-- This is to avoid modifying the passed in table, which allows the caller
		-- to reuse it.
		local real_params= {}
		if params then
			for k, v in pairs(params) do
				real_params[k]= v
			end
		end
		params= real_params
		for k, v in pairs(default_params) do
			if not params[k] then params[k]= default_params[k] end
		end
		self.x= params.sx
		self.y= params.sy
		self.tx= params.tx
		self.ts= params.ts
		self.nx= params.nx
		self.text_section= params.text_section
		return Def.ActorFrame{
			Name= name,
			InitCommand= function(subself)
				subself:xy(params.sx, params.sy)
				self.container= subself
				self.text= subself:GetChild("text")
				self.number= subself:GetChild("number")
			end,
			LoadFont(params.tf) .. {
				Name= "text",
				Text= self:get_string(params.tt),
				InitCommand= function(self)
					self:xy(params.tx, params.ty):zoom(params.tz):diffuse(params.tc)
						:horizalign(params.ta)
					maybe_distort_text(self)
				end
														 },
			LoadFont(params.nf) .. {
				Name= "number", Text= params.nt,
				InitCommand= function(self)
					self:xy(params.nx, params.ny):zoom(params.nz):diffuse(params.nc)
						:horizalign(params.na)
					maybe_distort_text(self)
				end
			},
		}
	end
end

function text_and_number_interface:get_string(text)
	if not text then text= "" end
	local t= get_string_wrapper(self.text_section, text)
	if self.upper then
		--Trace("Uppering.")
		t= t:upper()
	end
	return t .. self.ts
end

function text_and_number_interface:set_text(text)
	if self.text then
		self.text:settext(self:get_string(text))
	end
end

function text_and_number_interface:set_number(n)
	if self.number then
		self.number:settext(n)
	end
end

function text_and_number_interface:get_widths()
	local total= 0
	local tw= 0
	local nw= 0
	if self.text then
		tw= self.text:GetZoomedWidth() + math.abs(self.tx)
	end
	if self.number then
		nw= self.number:GetZoomedWidth() + math.abs(self.nx)
	end
	total= tw + nw
	return total, tw, nw
end

function text_and_number_interface:move_to(x, y, time)
	if self.container then
		if tonumber(time) then
			self.container:finishtweening():linear(time)
		end
		self.x= x
		self.y= y
		self.container:xy(x, y)
	end
end

function text_and_number_interface:get_text_actor()
	return self.text
end

function text_and_number_interface:get_number_actor()
	return self.number
end

function text_and_number_interface:hide()
	if self.container then
		self.text:diffusealpha(0)
		self.number:diffusealpha(0)
	end
end

function text_and_number_interface:unhide()
	if self.container then
		self.text:diffusealpha(1)
		self.number:diffusealpha(1)
	end
end

text_and_number_interface_mt= { __index= text_and_number_interface }

function width_limit_text(text, limit, natural_zoom)
	natural_zoom= natural_zoom or 1
	if text:GetWidth() * natural_zoom > limit then
		text:zoomx(limit / text:GetWidth())
	else
		text:zoomx(natural_zoom)
	end
end

function width_clip_text(text, limit)
	local full_text= text:GetText()
	local fits= text:GetZoomedWidth() <= limit
	local prev_max= #full_text - 1
	local prev_min= 0
	if not fits then
		while prev_max - prev_min > 1 do
			local new_max= math.round((prev_max + prev_min) / 2)
			text:settext(full_text:sub(1, 1+new_max))
			if text:GetZoomedWidth() <= limit then
				prev_min= new_max
			else
				prev_max= new_max
			end
		end
		text:settext(full_text:sub(1, 1+prev_min))
	end
end

function width_clip_limit_text(text, limit, natural_zoom)
	natural_zoom= natural_zoom or text:GetZoomY()
	local text_width= text:GetWidth() * natural_zoom
	if text_width > limit * 2 then
		text:zoomx(natural_zoom * .5)
		width_clip_text(text, limit)
	else
		width_limit_text(text, limit, natural_zoom)
	end
end

local function is_delim(c)
	return c == " " or c == "_" or c == "-" or c == "."
end

function split_string_to_words(s)
	local words= {}
	s= tostring(s)
	for word in s:gmatch("[%w']+") do
		words[#words+1]= word
	end
	if #words < 1 then
		words[1]= s
	end
	return words
end

function rec_calc_actor_extent(aframe, depth)
	depth= depth or ""
	if not aframe then return 0, 0, 0, 0 end
	local halign= aframe:GetHAlign()
	local valign= aframe:GetVAlign()
	local w= aframe:GetZoomedWidth()
	local h= aframe:GetZoomedHeight()
	local halignjust= (halign - .5) * w
	local valignjust= (valign - .5) * h
	local xmin= w * -halign
	local xmax= w * (1 - halign)
	local ymin= h * -valign
	local ymax= h * (1 - valign)
	if aframe.GetChildren then
		local xz= aframe:GetZoomX()
		local yz= aframe:GetZoomY()
		local children= aframe:GetChildren()
		for i, c in pairs(children) do
			if c:GetVisible() then
				local cx= c:GetX() + halignjust
				local cy= c:GetY() + valignjust
				--Trace(depth .. "child " .. i .. " at " .. cx .. ", " .. cy)
				local cxmin, cxmax, cymin, cymax= rec_calc_actor_extent(c,depth.."  ")
				xmin= math.min((cxmin * xz) + cx, xmin)
				ymin= math.min((cymin * yz) + cy, ymin)
				xmax= math.max((cxmax * xz) + cx, xmax)
				ymax= math.max((cymax * yz) + cy, ymax)
			end
		end
	else
		--Trace(depth .. "no children")
	end
	--Trace(depth .. "rec_calc_actor_extent:")
	--Trace(depth .. "ha: " .. halign .. " va: " .. valign .. " w: " .. w ..
	--			" h: " .. h .. " haj: " .. halignjust .. " vaj: " .. valignjust ..
	--			" xmn: " .. xmin .. " xmx: " .. xmax .. " ymn: " .. ymin .. " ymx: "
	--			.. ymax)
	return xmin, xmax, ymin, ymax
end

function rec_calc_actor_pos(actor)
	-- This doesn't handle zooming.
	if not actor then return 0, 0 end
	local x= actor:GetDestX()
	local y= actor:GetDestY()
	local wx, wy= 0, 0
	if actor.GetNumWrapperStates then
		local wrappers= actor:GetNumWrapperStates()
		for i= 1, wrappers do
			local nitori= actor:GetWrapperState(i)
			wx= wx + nitori:GetDestX()
			wy= wy + nitori:GetDestY()
		end
	end
	local px, py= rec_calc_actor_pos(actor:GetParent())
	return x+px+wx, y+py+wy
end

local frame_tester_interface= {}
frame_tester_interface_mt= { __index= frame_tester_interface }
function frame_tester_interface:create_actors(name, x, y, remaining_depth)
	
end

function create_frame_quads(label, pad, fw, fh, outer_color, inner_color, fx, fy)
	if not fx then fx= fw/2 end
	if not fy then fy= fh/2 end
	return Def.ActorFrame{
		InitCommand=cmd(xy,fx,fy),
		Name=label,
		Def.Quad{
			Name="outer",
			InitCommand=cmd(xy,0,0;diffuse,outer_color;setsize,fw,fh)
		},
		Def.Quad{
			Name="inner",
			InitCommand=cmd(xy,0,0;diffuse,inner_color;setsize,fw-(pad*2),fh-(pad*2))
		}
	}
end

local halvable_sides= {top= true, bottom= true}
local function generic_left_half(self)
	self:cropright(0.5)
end
local function generic_right_half(self)
	self:cropleft(0.5)
end
local function generic_unhalf(self)
	self:cropright(0):cropleft(0)
end

local function generic_icon_sprite(button, side, add_to)
	local path= THEME:GetPathG("", "button_icons/"..button..".png", true)
	if not path or path == "" then return nil end
	local icon_scale= misc_config:get_data().cursor_button_icon_size
	local args= {
		Name= button, Texture= path, InitCommand= function(self)
			add_to[#add_to+1]= {side, self}
			scale_to_fit(self, 16 * icon_scale, 16 * icon_scale)
			self:diffusealpha(.5)
			if side == "top" then
				self:vertalign(bottom)
			elseif side == "bottom" then
				self:vertalign(top)
			elseif side == "left" then
				self:horizalign(right)
			elseif side == "right" then
				self:horizalign(left)
			end
		end,
	}
	if halvable_sides[side] then
		args.LeftCommand= generic_left_half
		args.RightCommand= generic_right_half
		args.FullCommand= generic_unhalf
	end
	return Def.Sprite(args)
end

local arrow_h= 8
local full_arrow_verts= {
	left= {-arrow_h, 0, 0, arrow_h, 0, -arrow_h},
	right= {arrow_h, 0, 0, -arrow_h, 0, arrow_h},
	top= {0, -arrow_h, -arrow_h, 0, arrow_h, 0},
	bottom= {0, arrow_h, arrow_h, 0, -arrow_h, 0},
}
local left_half_arrow_verts= {
	left= full_arrow_verts.left,
	right= {0, 0, 0, 0, 0, 0},
	top= {0, -arrow_h, -arrow_h, 0, 0, 0},
	bottom= {0, arrow_h, 0, 0, -arrow_h, 0},
}
local right_half_arrow_verts= {
	left= {0, 0, 0, 0, 0, 0},
	right= full_arrow_verts.right,
	top= {0, -arrow_h, 0, 0, arrow_h, 0},
	bottom= {0, arrow_h, arrow_h, 0, 0, 0},
}
local function generic_arrow(button, side, add_to, add_approaches, cursor_self)
	return Def.ActorMultiVertex{
		Name= button, InitCommand= function(self)
			add_to[#add_to+1]= {side, self}
			self:SetDrawState{Mode= "DrawMode_Triangles"}:SetNumVertices(3)
			add_approaches(cursor_self, 3)
		end,
		RefitCommand= noop_blank,
		LeftCommand= function(self, param)
			cursor_self:set_verts_for_part(param[1], left_half_arrow_verts[side])
		end,
		RightCommand= function(self, param)
			cursor_self:set_verts_for_part(param[1], right_half_arrow_verts[side])
		end,
		FullCommand= function(self, param)
			cursor_self:set_verts_for_part(param[1], full_arrow_verts[side])
		end,
	}
end
local vert_speed= 512
local function handle_approach(currents, goals, delta)
	local speeds= {}
	for i= 1, #currents do
		speeds[i]= vert_speed;
	end
	if get_music_file_length then
		multiapproach(currents, goals, speeds, delta)
	else
		multiapproach(currents, goals, speeds)
	end
end
local function align_x(x, align, w)
	return x + (align * w)
end

local pulse_cycle= 1
local move_time= 0.1
cursor_mt= {
	__index= {
		create_actors= function(
				self, name, x, y, t, main, hilight, button_list, align)
			self.main_color= main or fetch_color("player.both")
			self.hilight_color= hilight or fetch_color("player.hilight")
			self.x= x
			self.x= y
			self.align= align or 0
			self.w= 0
			self.h= 0
			self.t= t
			self.hw= 0
			self.hh= 0
			self.sprite_parts= {}
			self.parts= {}
			self.part_ranges= {}
			self.currents= {}
			self.goals= {}
			self.corner_currents= {0, 0, 0, 0}
			self.corner_goals= {0, 0, 0, 0}
			self.update= function(frame, delta)
				local lerp_t= self.pulse_time / pulse_cycle
				self.pulse_time= self.pulse_time + delta
				self.curr_color= lerp_color(lerp_t, self.start_color, self.goal_color)
				self.curr_alpha= lerp(lerp_t, self.start_alpha, self.goal_alpha)
				-- I think something is causing a negative delta.
				self.curr_thick= math.abs(lerp(lerp_t, self.start_thick, self.goal_thick))
				handle_approach(self.currents, self.goals, delta)
				handle_approach(self.corner_currents, self.corner_goals, delta)
				for i= 1, #self.parts do
					self:update_part(i, self.parts[i])
					self:position_part(self.parts[i])
				end
				for i= 1, #self.sprite_parts do
					self:position_part(self.sprite_parts[i])
					self.sprite_parts[i][2]:diffusealpha(self.curr_alpha)
				end
				if self.pulse_time > pulse_cycle then
					self:reverse_pulse()
				end
			end
			self:start_pulse()
			local args= {
				Name= "cursor", InitCommand= function(subself)
					self.container= subself
					subself:xy(x, y):SetUpdateFunction(self.update)
					self:un_half()
				end,
				LoadActor(THEME:GetPathG("", "cursor_outline.lua"), {self= self}),
			}
			for i, button_info in ipairs(button_list) do
				-- button_info= {side, button}
				-- side= "left" or "top" or "right" or "bottom"
				local sprite= generic_icon_sprite(
					button_info[2], button_info[1], self.sprite_parts)
				if sprite then
					args[#args+1]= sprite
				else
					args[#args+1]= generic_arrow(
						button_info[2], button_info[1], self.parts, self.add_approaches,
						self)
				end
			end
			return Def.ActorFrame(args)
		end,
		start_pulse= function(self)
			self.start_color= self.main_color
			self.goal_color= self.hilight_color
			self.start_alpha= 1
			self.goal_alpha= 0
			self.start_thick= self.t*2
			self.goal_thick= self.t
			self.pulse_time= 0
		end,
		reverse_pulse= function(self)
			self.start_color, self.goal_color= self.goal_color, self.start_color
			self.start_thick, self.goal_thick= self.goal_thick, self.start_thick
			self.start_alpha, self.goal_alpha= self.goal_alpha, self.start_alpha
			self.pulse_time= 0
		end,
		add_approaches= function(self, vert_count)
			table.insert(self.part_ranges, {#self.currents, vert_count})
			for i, tab in ipairs{self.currents, self.goals} do
				for v= 1, vert_count*2 do
					table.insert(tab, 0)
				end
			end
		end,
		update_part= function(self, id, part)
			local range= self.part_ranges[id]
			local start= range[1]
			local currs= self.currents
			local verts= {}
			for v= 0, range[2]-1 do
				local i= start+(v*2)
				table.insert(verts, {{currs[i+1], currs[i+2], 0}, self.curr_color})
			end
			part[2]:SetVertices(verts):SetLineWidth(self.curr_thick)
		end,
		position_part= function(self, part)
			local corcur= self.corner_currents
			local xadd= ({none= 0, left= corcur[1], right= corcur[3],
										top= 0, bottom= 0})[part[1]]
			local yadd= ({none= 0, left= 0, right= 0, top= corcur[2],
										bottom= corcur[4]})[part[1]]
			if part[1] ~= "none" then
				xadd= align_x(xadd, self.align, corcur[3] - corcur[1])
			end
			part[2]:xy(xadd, yadd)
		end,
		set_verts_for_part= function(self, id, verts)
			local start= self.part_ranges[id][1]
			local goals= self.goals
			for v= 1, #verts do
				if v % 2 == 1 then
					goals[start+v]= align_x(verts[v], self.align, self.w)
				else
					goals[start+v]= verts[v]
				end
			end
		end,
		refit= function(self, nx, ny, nw, nh)
			nx= nx or self.container:GetX()
			ny= ny or self.container:GetY()
			local new_size= ((nw and (self.w ~= nw)) or (nh and (self.h ~= nh)))
			self.x= nx
			self.y= ny
			self.w= nw or self.w
			self.h= nh or self.h
			self.hw= self.w/2
			self.hh= self.h/2
			self.corner_goals= {
				align_x(-self.hw, self.align, self.w), -self.hh,
				align_x(self.hw, self.align, self.w), self.hh,
			}
			local secs_into_pulse= self.container:GetSecsIntoEffect()
			local remain= pulse_cycle - secs_into_pulse
			self.container:stoptweening():linear(move_time):xy(nx, ny)
			if new_size then
				for i= 1, #self.parts do
					self.parts[i][2]:playcommand("Refit", {i})
				end
			end
		end,
		left_half= function(self)
			for i= 1, #self.parts do
				self.parts[i][2]:playcommand("Left", {i})
			end
			for i= 1, #self.sprite_parts do
				self.sprite_parts[i][2]:playcommand("Left")
			end
		end,
		right_half= function(self)
			for i= 1, #self.parts do
				self.parts[i][2]:playcommand("Right", {i})
			end
			for i= 1, #self.sprite_parts do
				self.sprite_parts[i][2]:playcommand("Right")
			end
		end,
		un_half= function(self)
			for i= 1, #self.parts do
				self.parts[i][2]:playcommand("Full", {i})
			end
			for i= 1, #self.sprite_parts do
				self.sprite_parts[i][2]:playcommand("Full")
			end
		end,
		hide= function(self)
			for i= 1, #self.parts do
				self.parts[i][2]:visible(false)
			end
			for i= 1, #self.sprite_parts do
				self.sprite_parts[i][2]:visible(false)
			end
		end,
		unhide= function(self)
			for i= 1, #self.parts do
				self.parts[i][2]:visible(true)
			end
			for i= 1, #self.sprite_parts do
				self.sprite_parts[i][2]:visible(true)
			end
		end,
		set_parts_vis= function(self, sides, part_list, vis)
			for i= 1, #part_list do
				if string_in_table(part_list[i][1], sides) then
					part_list[i][2]:visible(vis)
				end
			end
		end,
		set_sides_vis= function(self, sides, vis)
			self:set_parts_vis(sides, self.parts, vis)
			self:set_parts_vis(sides, self.sprite_parts, vis)
		end
}}

amv_outline_mt= {
	__index= {
		create_actors= function(self, name, x, y, w, h, t, color)
			x= x or 0
			y= y or 0
			w= w or 0
			h= h or 0
			t= t or 0
			color= color or fetch_color("player.both")
			self.name= name
			self.w= w
			self.h= h
			self.t= t
			return Def.ActorMultiVertex{
				Name= name,
				InitCommand= function(subself)
					self.container= subself
					-- 6 verts, so the cursor can easily be cut in half.
					subself:xy(x, y):SetVertices{
						{{0, -h/2, 0}, color},
						{{w/2, -h/2, 0}, color},
						{{w/2, h/2, 0}, color},
						{{0, h/2, 0}, color},
						{{-w/2, h/2, 0}, color},
						{{-w/2, -h/2, 0}, color},
						{{0, -h/2, 0}, color},
					}
						:SetLineWidth(t):SetDrawState{Mode= "DrawMode_LineStrip"}
				end
			}
		end,
		refit= function(self, nx, ny, nw, nh)
			nx= nx or self.container:GetX()
			ny= ny or self.container:GetY()
			nw= nw or self.w
			nh= nh or self.h
			self.w= nw
			self.h= nh
			self.container:finishtweening()
			self.container:linear(0.05)
			self.container:xy(nx, ny)
			self.container:SetVertices{
				{{0, -nh/2, 0}},
				{{nw/2, -nh/2, 0}},
				{{nw/2, nh/2, 0}},
				{{0, nh/2, 0}},
				{{-nw/2, nh/2, 0}},
				{{-nw/2, -nh/2, 0}},
				{{0, -nh/2, 0}},
			}
		end,
		recolor= function(self, color)
			if color then
				self:SetVertices{{color}, {color}, {color}, {color}, {color}, {color}, {color}}
			end
		end,
		rethicken= function(self, thickness)
			thickness= thickness or self.t
			self.t= thickness
			self.container:SetLineWidth(thickness)
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end
}}

frame_helper_mt= {
	__index= {
		create_actors= function(self, name, pad, fw, fh, outer_color, inner_color, fx, fy)
			self.name= name
			self.pad= pad
			self.x= fx
			self.y= fy
			self.w= fw
			self.h= fh
			self.outer= setmetatable({}, amv_outline_mt)
			return Def.ActorFrame{
				Name= name,
				InitCommand= function(subself)
					self.container= subself
					subself:xy(fx, fy)
					self.inner= subself:GetChild("inner")
				end,
				Def.Quad{
					Name= "inner",
					InitCommand= cmd(xy, 0, 0; diffuse, inner_color; setsize, fw, fh)
				},
				self.outer:create_actors("outer", 0, 0, fw-pad/2, fh-pad/2, pad, outer_color)
			}
		end,
		resize= function(self, now, noh)
			self.w= now or self.w
			self.h= noh or self.h
			self.outer:refit(0, 0, now, noh)
			self.inner:setsize(self.w, self.h)
		end,
		resize_to_outline= function(self, frame, pad)
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(frame)
			self:move((xmx+xmn)/2, (ymx+ymn)/2)
			self:resize((xmx-xmn)+(pad*2), (ymx-ymn)+(pad*2))
		end,
		move= function(self, x, y)
			x= x or self.x
			y= y or self.y
			self.container:stoptweening():linear(0.1):xy(x, y)
			self.x, self.y= x, y
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end,
}}

function credit_reporter(x, y, show_credits)
	return normal_text(
		"credit", "Credits", fetch_color("credits"), nil, x, y, 1, center,
		{ OnCommand= cmd(playcommand, "set"),
			CoinsChangedMessageCommand= cmd(playcommand, "set"),
			setCommand= function(self)
				local credits, coins, needed= get_coin_info()
				local text= credits .. " : " .. coins .. " / " .. needed
				if show_credits then
					text= "Credits: " .. text
				end
				if needed == 0 then
					text= ""
				end
				self:settext(text)
			end
	})
end

function chart_info_text(steps, song)
	local info_text= ""
	if steps then
		local author= steps_get_author(steps, song)
		if not author or author == "" then
			author= "Uncredited"
		end
		local difficulty= steps_to_string(steps)
		local rating= steps:GetMeter()
		info_text= author .. ": " .. difficulty .. ": " .. rating
	end
	return info_text
end

-- Because somebody decided stepmania's scaletofit should change the position
-- of the actor.
function scale_to_fit(actor, width, height)
	local xscale= width / actor:GetWidth()
	local yscale= height / actor:GetHeight()
	actor:zoom(math.min(xscale, yscale))
end

-- Until my fix of the engine side version is merged.
-- usage:  clip_scale(some_actor, width, height)
function clip_scale(self, zw, zh)
	local uzw= self:GetWidth()
	local uzh= self:GetHeight()
	local xz= zw / uzw
	local yz= zh / uzh
	self:cropleft(0):cropright(0):croptop(0):cropbottom(0)
	local function handle_dim(dimz, dim, dimdest, cropa, cropb)
		self:zoom(dimz)
		local clip_amount= (1 - (dimdest / dim)) / 2
		cropa(self, clip_amount)
		cropb(self, clip_amount)
	end
	if xz > yz then
		handle_dim(xz, self:GetZoomedHeight(), zh, self.croptop, self.cropbottom)
	else
		handle_dim(yz, self:GetZoomedWidth(), zw, self.cropleft, self.cropright)
	end
end
