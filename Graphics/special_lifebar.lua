local args= {...}
local pn= args[1].pn
local life= -1

if misc_config:get_data().disable_extra_processing then
	return Def.Quad{
		InitCommand= function(self)
			self:xy(args[1].x, _screen.h):vertalign(bottom):setsize(24, _screen.h)
				:diffuse(fetch_color("accent.blue"))
		end,
		LifeChangedMessageCommand= function(self, param)
			if param.Player ~= pn then return end
			if life == param.LifeMeter:GetLife() then return end
			life= param.LifeMeter:GetLife()
			self:stoptweening():linear(.1):zoomy(life)
		end
	}
else
	return Def.Actor{InitCommand= cmd(hibernate,math.huge)}
end
