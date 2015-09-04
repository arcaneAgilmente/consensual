local field= false

local function input(event)
	
end

local args= {
	OnCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	Def.NewField{
		InitCommand= function(self)
			field= self
		end,
	},
}

return Def.ActorFrame(args)
