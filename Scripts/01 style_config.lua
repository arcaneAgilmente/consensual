local game_name= GAMESTATE:GetCurrentGame():GetName()
local styles_for_game= GAMEMAN:GetStylesForGame(game_name)
local default_config= {{}, {}}
-- This will not work when someone makes a chart actually intended for versus
-- style, but is necessary because Steps do not have a StyleType or other
-- direct way to figure out what style they're meant for.
stepstype_to_style= {}
local function supported_style(name)
	-- TODO:  Fix the fact that solo only requires one person, but cannot be
	-- played when two people are joined.
	return name == "single" or name == "double"
--	return name ~= "couple-edit" and name ~= "couple" and name ~= "routine"
end
for i, style in ipairs(styles_for_game) do
	local stepstype= style:GetStepsType()
	local stame= style:GetName()
	local stype= style:GetStyleType()
	if not stepstype_to_style[stepstype] then
		local for_players= 1
		local for_sides= 1
		if stype:find("TwoPlayers") then for_players= 2 end
		if stype:find("TwoSides") then for_sides= 2 end
		stepstype_to_style[stepstype]= {
			name= stame, stype= stype, for_players= for_players, for_sides= for_sides}
	end
	-- unsupported styles:
	if supported_style(stame) then
		if stype:find("OnePlayer") then
			table.insert(
				default_config[1], {style= stame, stepstype= stepstype, visible= true})
		end
		if stype:find("TwoPlayers") or stype:find("OneSide") then
			table.insert(
				default_config[2], {style= stame, stepstype= stepstype, visible= true})
		end
	end
end

style_config= create_setting(
	"style config", "style_config_" .. game_name .. ".lua", default_config, -1)
style_config:load()
visible_styles= style_config:get_data()

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
	if kyzentun_birthday then
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