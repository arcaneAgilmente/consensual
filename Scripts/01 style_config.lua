local game_name= GAMESTATE:GetCurrentGame():GetName()
local styles_for_game= GAMEMAN:GetStylesForGame(game_name)
local default_config= {{}, {}}
-- This will not work when someone makes a chart actually intended for versus
-- style, but is necessary because Steps do not have a StyleType or other
-- direct way to figure out what style they're meant for.
stepstype_to_style= {}
for i, style in ipairs(styles_for_game) do
	local stepstype= style:GetStepsType()
	local stame= style:GetName()
	local stype= style:GetStyleType()
	if not stepstype_to_style[stepstype] then
		stepstype_to_style[stepstype]= {}
	end
	local for_players= 1
	local for_sides= 1
	if stype:find("TwoPlayers") then for_players= 2 end
	if stype:find("TwoSides") then for_sides= 2 end
	stepstype_to_style[stepstype][for_players]= {
		name= stame, stype= stype, for_players= for_players, for_sides= for_sides}
	if stype == "StyleType_OnePlayerOneSide" then
		table.insert(
			default_config[1], {style= stame, stepstype= stepstype, visible= true})
	elseif stype == "StyleType_OnePlayerTwoSides" then
		table.insert(
			default_config[1], {style= stame, stepstype= stepstype, visible= true})
	elseif stype == "StyleType_TwoPlayersTwoSides" then
		table.insert(
			default_config[2], {style= stame, stepstype= stepstype, visible= true})
	end
end

style_config= create_setting(
	"style config", "style_config_" .. game_name .. ".lua", default_config, -1)
style_config:load()
visible_styles= style_config:get_data()

function first_compat_style(num_players)
	for stype, stype_info in pairs(stepstype_to_style) do
		if stype_info[num_players] then return stype_info[num_players].name end
	end
	lua.ReportScriptError("No compatible style for " .. num_players .. " players found.")
	return ""
end

function combined_visible_styles()
	local visible= {}
	local enabled= GAMESTATE:GetEnabledPlayers()
	for i, pn in ipairs(enabled) do
		for si, style in ipairs(style_config:get_data(pn_to_profile_slot(pn))[#enabled]) do
			if style.visible then
				visible[style.style]= style
			end
		end
	end
	local ret= {}
	for name, style in pairs(visible) do
		ret[#ret+1]= style
	end
	if kyzentun_birthday and GAMESTATE:GetCurrentGame():GetName():lower() == "dance" then
		local double_ret= {}
		for i, style in ipairs(styles_for_game) do
			if style:GetName():find("double") then
				double_ret[#double_ret+1]= {
					visible= true, style= style:GetName(),
					stepstype= style:GetStepsType()}
			end
		end
		if #double_ret > 0 then
			ret= double_ret
		end
	end
	table.sort(ret, function(a, b) return a.style < b.style end)
	return ret
end
