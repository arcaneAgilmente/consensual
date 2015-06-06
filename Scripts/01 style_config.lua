local game_name= GAMESTATE:GetCurrentGame():GetName()
local styles_for_game= GAMEMAN:GetStylesForGame(game_name)
local default_config= {{}, {}}
-- This will not work when someone makes a chart actually intended for versus
-- style, but is necessary because Steps do not have a StyleType or other
-- direct way to figure out what style they're meant for.
stepstype_to_style= {}
local function add_style_to_lists(style)
	local stepstype= style:GetStepsType()
	local stame= style:GetName()
	local stype= style:GetStyleType()
	-- Why is couple-edit marked as OnePlayerTwoSides?  I'm throwing it out as
	-- unsupported rather than trying to write special case code for it.
	if stame == "couple-edit" then return end
	if stame == "couple" then return end
	if not stepstype_to_style[stepstype] then
		stepstype_to_style[stepstype]= {}
	end
	local for_players= 1
	local for_sides= 1
	if stype:find("TwoPlayers") then for_players= 2 end
	if stype:find("TwoSides") then for_sides= 2 end
	if stype:find("SharedSides") then for_sides= 2 end
	stepstype_to_style[stepstype][for_players]= {
		name= stame, stype= stype, steps_type= stepstype, for_players= for_players, for_sides= for_sides}
	if stype == "StyleType_OnePlayerOneSide" then
		table.insert(
			default_config[1], {style= stame, stepstype= stepstype, visible= true})
	elseif stype == "StyleType_OnePlayerTwoSides" then
		table.insert(
			default_config[1], {style= stame, stepstype= stepstype, visible= true})
	elseif stype == "StyleType_TwoPlayersTwoSides" then
		table.insert(
			default_config[2], {style= stame, stepstype= stepstype, visible= true})
	elseif stype == "StyleType_TwoPlayersSharedSides" then
		table.insert(
			default_config[2], {style= stame, stepstype= stepstype, visible= true})
	end
end

for i, style in ipairs(styles_for_game) do
	add_style_to_lists(style)
end

style_config= create_setting(
	"style config", "style_config_" .. game_name .. ".lua", default_config, -1)
style_config:load()
visible_styles= style_config:get_data()

function style_config_sanity_enforcer(config)
	for np, style_set in pairs(config) do
		for i, entry in ipairs(style_set) do
			local def_entry= default_config[np][i]
			if entry.stepstype ~= def_entry.stepstype or entry.style ~= def_entry.style then
				entry.style= def_entry.style
				entry.stepstype= def_entry.stepstype
				entry.visible= true
			end
		end
	end
end

function first_compat_style_info(num_players)
	-- The best match is a stepstype that is compatible with 1 player and 2
	-- players.
	local best_match= {}
	for stype, stype_info in pairs(stepstype_to_style) do
		if stype_info[num_players] then
			if stype_info[1] and stype_info[2] then
				if best_match[2] ~= "both" then
					best_match= {stype_info, "both"}
				end
			elseif best_match[2] ~= "both" and not best_match[1] then
				if stype_info[1] then
					best_match= {stype_info, "1_only"}
				else
					best_match= {stype_info, "2_only"}
				end
			end
		end
	end
	if best_match[1] then
		return best_match[1]
	end
	return nil
end

function first_compat_style(num_players)
	local best_match= first_compat_style_info(num_players)
	if best_match then
		return best_match[num_players].name
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
