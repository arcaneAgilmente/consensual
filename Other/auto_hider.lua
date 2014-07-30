function Def.AutoHider(params)
	if not params.HideTime then params.HideTime= 5 end
	local args= {
		InitCommand= function(self)
			self:hibernate(params.HideTime)
			if params.InitCommand then params.InitCommand(self) end
		end,
		OnCommand= function(self)
			local function input(event)
				self:hibernate(params.HideTime)
			end
			SCREENMAN:GetTopScreen():AddInputCallback(input)
			if params.OnCommand then params.OnCommand(self) end
		end
	}
	for k, v in ipairs(params) do
		if k ~= "InitCommand" and k ~= "OnCommand" then
			args[k]= v
		end
	end
	return Def.ActorFrame(args)
end
