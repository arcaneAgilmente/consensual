local function explosion_actor(add_to, parts)
	local directions= {}
	local angle_per_particle= 360 / parts
	for i= 0, parts-1 do
		local angle= i * angle_per_particle
		local radan= angle / 180 * math.pi
		directions[i+1]= {angle= angle, x= math.cos(radan), y= math.sin(radan)}
	end
	local frame= Def.ActorFrame{
		Name= "explosion", InitCommand= function(self)
			self:hibernate(math.huge)
			if add_to then
				add_to.explosion= self
			end
		end,
		explodeCommand= function(self, param)
			self:hibernate(0):xy(param.x, param.y)
			local parts= self:GetChildren().parts
			for i, part in ipairs(parts) do
				local direction= directions[i]
				part:finishtweening():setsize(param.size, param.size*8)
					:diffuse(param.start_color):zoom(1):xy(0,0)
					:linear(param.time):zoom(0):diffuse(param.end_color)
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

local exploder_container= {}

local function input(event)
	if event.type == "InputEventType_Release" then return end
	if event.DeviceInput.button == "DeviceButton_n" then
		exploder_container.explosion:playcommand(
			"explode", {
				x= _screen.cx, y= _screen.cy, start_color= {1, 1, 1, 1},
				end_color= {1, 0, 0, 0}, dist= 128, time= 4, size= 2})
	elseif event.DeviceInput.button == "DeviceButton_m" then
		exploder_container.adj_explosion:playcommand(
			"explode", {
				x= _screen.cx, y= _screen.cy, start_color= {1, 1, 1, 1},
				end_color= {1, 0, 0, 0}, dist= 128, time= 4, size= 2})
	end
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	explosion_actor(exploder_container, 16),
	quaid(_screen.cx, _screen.cy, 1, 1, {0, 1, 0, 1}),
	quaid(_screen.cx+8, _screen.cy, 1, 1, {1, 0, 0, 1}),
	quaid(_screen.cx-8, _screen.cy, 1, 1, {1, 0, 0, 1}),
	quaid(_screen.cx, _screen.cy+8, 1, 1, {0, 0, 1, 1}),
	quaid(_screen.cx, _screen.cy-8, 1, 1, {0, 0, 1, 1}),
}

return Def.ActorFrame(args)
