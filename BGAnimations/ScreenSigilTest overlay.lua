dofile(THEME:GetPathO("", "sigil.lua"))

local sigil= setmetatable({}, sigil_controller_mt)

local function make_actor_of_new_class(name, x, y, class_params)
	local actor_vars= {}
	return Def.ActorFrame{
		InitCommand= cmd(xy, x, y),
		FancyCommand=
			function(self)
				actor_vars.foo= 1
			end
	}
end

local args= {
	sigil:create_actors("sigil", SCREEN_CENTER_X, SCREEN_CENTER_Y, solar_colors.cyan(), 64),
	InitCommand=
		function(self)
			sigil:find_actors(self:GetChild(sigil.name))
		end,
	CodeMessageCommand=
		function(self, param)
			if param.Name == "left" then
				sigil:redetail((sigil.detail or 1) - 1)
			elseif param.Name == "right" then
				sigil:redetail((sigil.detail or 1) + 1)
			end
		end,
}

return Def.ActorFrame(args)
