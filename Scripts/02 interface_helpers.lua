local text_and_number_interface= {}
do
	function normal_text(name, text, color, tx, ty, z, align, commands)
		color = color or solar_colors.f_text()
		tx= tx or 0
		ty= ty or 0
		z= z or 1
		align= align or center
		commands= commands or {}
		commands.Name= name
		commands.Text= text
		commands.InitCommand= function(self)
														self:xy(tx,ty)
														self:diffuse(color)
														self:zoom(z)
														self:horizalign(align)
														maybe_distort_text(self)
													end
		return LoadFont("Common Normal") .. commands
	end

	local default_params= {
		sx= 0, sy= 0, tx= 0, ty= 0, tz= 1, tc= solar_colors.f_text(), tt= "",
		ta= right, na= left, tf= "Common Normal", nf= "Common Normal",
		text_section= "Misc", nx= 0, ny= 0, nz= 1, nc= solar_colors.f_text(),
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
		self.nx= params.nx
		self.text_section= params.text_section
		return Def.ActorFrame{
			Name= name,
			InitCommand= cmd(x,params.sx;y,params.sy),
			LoadFont(params.tf) .. {
				Name= "text",
				Text= self:get_string(params.tt),
				InitCommand= function(self)
											 self:xy(params.tx, params.ty)
											 self:zoom(params.tz)
											 self:diffuse(params.tc)
											 self:horizalign(params.ta)
											 maybe_distort_text(self)
										 end
			},
			LoadFont(params.nf) .. {
				Name= "number", Text= params.nt,
				InitCommand= function(self)
											 self:xy(params.nx, params.ny)
											 self:zoom(params.nz)
											 self:diffuse(params.nc)
											 self:horizalign(params.na)
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
	return t
end

function text_and_number_interface:find_actors(container)
	if not container then
		Trace("tani:fa passed nil container.")
		return nil
	end
	self.container= container
	self.text= container:GetChild("text")
	if not self.text then
		Trace("tani:fa " .. self.name .. " could not find text actor in container.")
		return nil
	end
	self.number= container:GetChild("number")
	if not self.number then
		Trace("tani:fa " .. self.name .. " could not find number actor in container.")
		return nil
	end
	return true
end

function text_and_number_interface:set_text(text)
	if self.text then
		if self.upper then
			self.text:settext(self:get_string(text):upper())
		else
			self.text:settext(self:get_string(text))
		end
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
			self.container:finishtweening()
			self.container:linear(time)
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

function split_string_to_words(s)
	local words= {}
	local cur_word_start= 1
	s= tostring(s)
	for i= 1, #s do
		local c= s:sub(i, i)
		if c == " " or c == "_" or c == "-" or c == "." then
			words[#words+1]= s:sub(cur_word_start, i-1)
			cur_word_start= i+1
			-- Yeah, this doesn't handle double space conditions well.
		end
	end
	words[#words+1]= s:sub(cur_word_start)
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
	local px, py= rec_calc_actor_pos(actor:GetParent())
	return x+px, y+py
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

local frame_helper= {}
function frame_helper:create_actors(label, pad, fw, fh, outer_color, inner_color, fx, fy)
	self.name= label
	self.pad= pad
	self.x= fx
	self.y= fy
	return create_frame_quads(label, pad, fw, fh, outer_color, inner_color, fx, fy)
end

function frame_helper:find_actors(container)
	self.container= container
	if not self.container then return nil end
	self.outer= container:GetChild("outer")
	self.inner= container:GetChild("inner")
	if self.outer and self.inner then
		self.pad= (self.outer:GetWidth() - self.inner:GetWidth()) / 2
	end
	return self.outer and self.inner
end

function frame_helper:resize(now, noh)
	if self.container then
		self.outer:SetWidth(now)
		self.outer:SetHeight(noh)
		self.inner:SetWidth(now-(self.pad*2))
		self.inner:SetHeight(noh-(self.pad*2))
	end
end

function frame_helper:resize_to_outline(frame, pad)
	local xmn, xmx, ymn, ymx= rec_calc_actor_extent(frame)
	self:move((xmx+xmn)/2, (ymx+ymn)/2)
	self:resize((xmx-xmn)+(pad*2), (ymx-ymn)+(pad*2))
end

function frame_helper:set_width(w)
	if self.container then
		self.outer:SetWidth(w)
		self.inner:SetWidth(w - (self.pad * 2))
	end
end

function frame_helper:move(x, y)
	if self.container then
		x= x or self.x
		y= y or self.y
		self.container:stoptweening()
		self.container:linear(0.1)
		self.container:xy(x, y)
		self.x, self.y= x, y
	end
end

function frame_helper:hide()
	if self.container then
		self.container:diffusealpha(0)
	end
end

function frame_helper:unhide()
	if self.container then
		self.container:diffusealpha(1)
	end
end

frame_helper_mt= { __index= frame_helper }

amv_cursor_mt= {
	__index= {
		create_actors= function(self, name, x, y, w, h, t, color)
			x= x or 0
			y= y or 0
			w= w or 0
			h= h or 0
			t= t or 0
			color= color or solar_colors.violet()
			self.name= name
			self.w= w
			self.h= h
			self.t= t
			return Def.ActorMultiVertex{
				Name= name,
				InitCommand= function(self)
					self:xy(x, y)
					-- 6 verts, so the cursor can easily be cut in half.
					self:SetVertices{
						{{0, -h/2, 0}, color},
						{{w/2, -h/2, 0}, color},
						{{w/2, h/2, 0}, color},
						{{0, h/2, 0}, color},
						{{-w/2, h/2, 0}, color},
						{{-w/2, -h/2, 0}, color},
						{{0, -h/2, 0}, color},
					}
					self:SetLineWidth(t)
					self:SetDrawState{Mode= "DrawMode_LineStrip"}
				end
			}
		end,
		find_actors= function(self, container)
			self.container= container
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
				self:SetVertices{{color}, {color}, {color}, {color}, {color}}
			end
		end,
		rethicken= function(self, thickness)
			thickness= thickness or self.t
			self.t= thickness
			self.container:SetLineWidth(thickness)
		end,
		left_half= function(self)
			self.container:SetDrawState{First= 4}
		end,
		right_half= function(self)
			self.container:SetDrawState{First= 1, Num= 4}
		end,
		un_half= function(self)
			self.container:SetDrawState{First= 1, Num= -1}
		end,
		hide= function(self)
			self.container:visible(false)
		end,
		unhide= function(self)
			self.container:visible(true)
		end
}}

function credit_reporter(x, y, show_credits)
	return normal_text(
		"credit", "Credits", solar_colors.violet(), x, y, 1, center,
		{ OnCommand= cmd(playcommand, "set"),
			CoinsChangedMessageCommand= cmd(playcommand, "set"),
			setCommand=
				function(self)
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

function chart_info_text(steps)
	local info_text= ""
	if steps then
		local author= steps_get_author(steps)
		if GAMESTATE:IsCourseMode() then
			author= GAMESTATE:GetCurrentCourse():GetScripter()
		end
		if not author or author == "" then
			author= "Uncredited"
		end
		local difficulty= steps_to_string(steps)
		local rating= steps:GetMeter()
		info_text= author .. ": " .. difficulty .. ": " .. rating
	end
	return info_text
end

function chart_info(steps, x, y, z)
	return normal_text("chart_info", chart_info_text(steps),
										 solar_colors.f_text(), x, y, z or 1, center)
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
	self:cropleft(0)
	self:cropright(0)
	self:croptop(0)
	self:cropbottom(0)
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
