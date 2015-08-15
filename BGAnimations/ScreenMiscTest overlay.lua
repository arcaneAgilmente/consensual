local rainbow= {
	fetch_color("accent.yellow"),
	fetch_color("accent.orange"),
	fetch_color("accent.red"),
	fetch_color("accent.magenta"),
	fetch_color("accent.violet"),
	fetch_color("accent.blue"),
	fetch_color("accent.cyan"),
	fetch_color("accent.green"),
}

function dumpenv()
	local dumped = {}
	local dump_table
	local function dump_kv(indent, k, v)
		lua.Trace(("  "):rep(indent) .. k .. ": " .. tostring(v))
		if type(v) == "table"then
      if dumped[v] then
				lua.Trace(("  "):rep(indent+1))
				lua.Trace("(already dumped)\n")
      else
				dumped[v] = true
				dump_table(indent+1, v)
      end
		end
	end
	function dump_table(indent, t)
		local had_package
		for k,v in pairs(t) do
      if k == "package" then
				had_package = true
      else
				dump_kv(indent, k, v)
      end
		end
		if had_package then dump_kv(indent, "package", t.package) end
	end
	lua.Trace("inside env")
	dumped[_G] = true
	dump_table(0, _G)
end

local function input(event)
	if event.type == "InputEventType_Release" then return false end
	local button= ToEnumShortString(event.DeviceInput.button)
	if button == "n" then
		lua.ReportScriptError("calling dumpenv: " .. type(dumpenv))
		lua.run_script_in_env(dumpenv)
	end
end

local args= {
	OnCommand= function(self)
		local screen= SCREENMAN:GetTopScreen()
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
--	quaid(_screen.cx, _screen.cy, 400, 32, {0, 0, 0, 1}),
	Def.BitmapText{
		Font= "Common Normal", Text= "Attributes solve all color problems.",
		InitCommand= function(self)
			self:xy(_screen.cx, _screen.cy):blend("BlendMode_Add")
			local text_len= #self:GetText()
			for i= 1, text_len do
				self:AddAttribute(
					i-1, {Length= 1, Diffuses= {
									rainbow[math.random(#rainbow)],
									rainbow[math.random(#rainbow)],
									rainbow[math.random(#rainbow)],
									rainbow[math.random(#rainbow)]}})
			end
		end
	},
}

return Def.ActorFrame(args)
