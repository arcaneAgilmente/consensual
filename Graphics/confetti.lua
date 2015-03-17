return Def.ActorFrame{
	Def.Quad{
		Name= "part", InitCommand= cmd(setsize, confetti_size(), confetti_size())
	},
	Name= "confetti", InitCommand= cmd(visible, false),
	TriggerCommand= function(self)
		self:stoptweening():hibernate(confetti_hibernate()):queuecommand("Fall")
	end,
	HideCommand= cmd(hibernate,math.huge;visible, false),
	FallCommand= function(self)
		self:stoptweening():hibernate(0):visible(true)
			:xy(confetti_x(), confetti_fall_start())
			:linear(confetti_fall_time()):y(confetti_fall_end())
		local part= self:GetChild("part")
		part:setsize(confetti_size(), confetti_size()):diffuse(confetti_color())
			:spin()
			:effectmagnitude(confetti_spin(), confetti_spin(), confetti_spin())
		if confetti_refall() then
			self:queuecommand("Fall")
		else
			self:queuecommand("Hide")
		end
	end
}
