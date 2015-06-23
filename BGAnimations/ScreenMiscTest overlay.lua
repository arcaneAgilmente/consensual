dofile(THEME:GetPathO("", "strokes.lua"))
dofile(THEME:GetPathO("", "art_helpers.lua"))

local xamv= false
local yamv= false
local yfxamv= false
local bezier= create_bezier()
local xquad= bezier:get_x()
local yquad= bezier:get_y()
local xcol= fetch_color("accent.red")
local ycol= fetch_color("accent.blue")
local yfxcol= fetch_color("accent.green")
local vert_count= 256
local zoom= 128
local valstep= .01

local xqvals= {0, .5, -.25, 1}
local yqvals= {0, 2, .5, 1}

local xvaltexts= {}
local yvaltexts= {}

local function add_vals_to_set(vals, set)
	for i, v in ipairs(vals) do
		set[#set+1]= v
	end
end

local function revtab(tab)
	local ret= {}
	for i= #tab, 1, -1 do
		ret[#ret+1]= tab[i]
	end
	return ret
end

local function set_amv_from_quadratic(amv, quad, setx, color)
	local verts= {}
	for i= 1, vert_count do
		local pos= (i-1) / (vert_count-1)
		local ev= quad:evaluate(pos)
		if setx then
			verts[i]= {{ev*zoom, pos*zoom, 0}, color}
		else
			verts[i]= {{pos*zoom, ev*zoom, 0}, color}
		end
	end
	amv:SetVertices(verts)
end

local function update_val_texts(valt, qvals)
	for i, text in ipairs(valt) do
		text:settext(qvals[i])
	end
end

local function update_bezier()
	update_val_texts(xvaltexts, xqvals)
	update_val_texts(yvaltexts, yqvals)
--					local bezvals= {}
--					add_vals_to_set(xqvals, bezvals)
--					add_vals_to_set(yqvals, bezvals)
--					bezier:set_from_bezier(unpack(bezvals))
	xquad:set_from_bezier(unpack(xqvals))
	yquad:set_from_bezier(unpack(yqvals))
	set_amv_from_quadratic(xamv, xquad, true, xcol)
	set_amv_from_quadratic(yamv, yquad, false, ycol)
	local verts= {}
	for i= 1, vert_count do
		local pos= (i-1) / (vert_count-1)
		local ev= bezier:evaluate_y_from_x(pos)
		verts[i]= {{pos*zoom, ev*zoom, 0}, yfxcol}
	end
	yfxamv:SetVertices(verts)
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
	if button == "q" then
		xqvals[1]= xqvals[1] - valstep
	elseif button == "a" then
		xqvals[1]= xqvals[1] + valstep
	elseif button == "z" then
		xqvals[1]= 0
	elseif button == "w" then
		xqvals[2]= xqvals[2] - valstep
	elseif button == "s" then
		xqvals[2]= xqvals[2] + valstep
	elseif button == "x" then
		xqvals[2]= 0
	elseif button == "e" then
		xqvals[3]= xqvals[3] - valstep
	elseif button == "d" then
		xqvals[3]= xqvals[3] + valstep
	elseif button == "c" then
		xqvals[3]= 0
	elseif button == "r" then
		xqvals[4]= xqvals[4] - valstep
	elseif button == "f" then
		xqvals[4]= xqvals[4] + valstep
	elseif button == "v" then
		xqvals[4]= 0
	elseif button == "u" then
		yqvals[1]= yqvals[1] - valstep
	elseif button == "j" then
		yqvals[1]= yqvals[1] + valstep
	elseif button == "m" then
		yqvals[1]= 0
	elseif button == "i" then
		yqvals[2]= yqvals[2] - valstep
	elseif button == "k" then
		yqvals[2]= yqvals[2] + valstep
	elseif button == "comma" then
		yqvals[2]= 0
	elseif button == "o" then
		yqvals[3]= yqvals[3] - valstep
	elseif button == "l" then
		yqvals[3]= yqvals[3] + valstep
	elseif button == "period" then
		yqvals[3]= 0
	elseif button == "p" then
		yqvals[4]= yqvals[4] - valstep
	elseif button == ";" then
		yqvals[4]= yqvals[4] + valstep
	elseif button == "/" then
		yqvals[4]= 0
	end
	update_bezier()
end

local function make_valtexts(x, y, color, holder)
	local args= {
		InitCommand= function(self) self:xy(x, y) end,
	}
	for i= 1, 4 do
		args[#args+1]= Def.BitmapText{
			Font= "Common Normal", InitCommand= function(self)
				holder[#holder+1]= self:diffuse(color):y(12*i):zoom(.5)
			end
		}
	end
	return Def.ActorFrame(args)
end

local function action_quads()
	local args= {}
	local count= 16
	local time= 2
	for i= 1, count do
		args[#args+1]= Def.ActorFrame{
			InitCommand= function(self)
				self:hibernate((i-1)*(time/count))
				self:queuecommand("action")
			end,
			actionCommand= function(self)
				self:xy(0, 0):linear(time):xy(zoom, 0):queuecommand("action")
				self:GetChild("pix"):playcommand("action")
			end,
			Def.Quad{
				Name= "pix",
				InitCommand= function(self)
					self:setsize(4, 4)
				end,
				actionCommand= function(self)
					local bezvals= {}
					for i= 1, 4 do
						bezvals[#bezvals+1]= xqvals[i]
						bezvals[#bezvals+1]= yqvals[i]
					end
					self:stoptweening()
						:xy(0, 0):diffuse(xcol)
						:tween(time, "TweenType_Bezier", bezvals)
						:xy(0, zoom):diffuse(ycol)
				end
			}
		}
	end
	return Def.ActorFrame(args)
end

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
		update_bezier()
	end,
	Def.ActorFrame{
		InitCommand= function(self)
			self:xy(_screen.cx-zoom, _screen.cy-zoom)
		end,
		quaid(zoom*.5, zoom*.0, zoom, 1, adjust_luma(xcol, .0)),
		quaid(zoom*.5, zoom*.25, zoom, 1, adjust_luma(xcol, .25)),
		quaid(zoom*.5, zoom*.5, zoom, 1, adjust_luma(xcol, .5)),
		quaid(zoom*.5, zoom*.75, zoom, 1, adjust_luma(xcol, .25)),
		quaid(zoom*.5, zoom*1., zoom, 1, adjust_luma(xcol, .0)),
		quaid(zoom*.0, zoom*.5, 1, zoom, adjust_luma(ycol, .0)),
		quaid(zoom*.25, zoom*.5, 1, zoom, adjust_luma(ycol, .25)),
		quaid(zoom*.5, zoom*.5, 1, zoom, adjust_luma(ycol, .5)),
		quaid(zoom*.75, zoom*.5, 1, zoom, adjust_luma(ycol, .25)),
		quaid(zoom*1., zoom*.5, 1, zoom, adjust_luma(ycol, .0)),
		Def.ActorMultiVertex{
			InitCommand= function(self)
				xamv= self:SetDrawState{Mode="DrawMode_LineStrip"}
			end
		},
		Def.ActorMultiVertex{
			InitCommand= function(self)
				yamv= self:SetDrawState{Mode="DrawMode_LineStrip"}
			end
		},
		Def.ActorMultiVertex{
			InitCommand= function(self)
				yfxamv= self:SetDrawState{Mode="DrawMode_LineStrip"}
			end
		},
		quaid(0, 0, 2, 2, {0, 0, 0, 1}),
		quaid(zoom, zoom, 2, 2, {0, 0, 0, 1}),
		action_quads(),
	},
	make_valtexts(_screen.cx*.5, 0, xcol, xvaltexts),
	make_valtexts(_screen.cx*1.5, 0, ycol, yvaltexts),
}

return Def.ActorFrame(args)
