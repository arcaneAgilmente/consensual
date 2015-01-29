local special_sections= {
	RadarCategory= "RadarCategory"
}

local game_sections= {
	kickbox= {
		OptionNames= "OptionNamesKickbox",
		ProfileData= "ProfileDataKickbox",
		RadarCategory= "RadarCategoryKickbox",
	}
}
local game_name= GAMESTATE:GetCurrentGame():GetName()

function first_word(s)
	s= tostring(s)
	for word in s:gmatch("[%w']+") do
		return word
	end
end

function get_string_wrapper(section, str)
	if not str then return "" end
	if str == "" then return "" end
	if tonumber(str) then return str end
	local alternates= {section}
	alternates[#alternates+1]= special_sections[first_word(str)]
	if game_sections[game_name] then
		alternates[#alternates+1]= game_sections[game_name][alternates[2]]
		alternates[#alternates+1]= game_sections[game_name][section]
	end
	for i= #alternates, 1, -1 do
		if alternates[i] and alternates[i] ~= ""
		and THEME:HasString(alternates[i], str) then
			return THEME:GetString(alternates[i], str)
		end
	end
	return str
end
