local default_config= {
	-- Color Scheme:  Solarized (http://ethanschoonover.com/solarized)
	{"bg", color("#002b36")},
	{"bg_shadow", color("#073642")},
	{"rev_bg", color("#fdf6e3")},
	{"rev_bg_shadow", color("#eee8d5")},
	{"text", color("#93a1a1")},
	{"text_other", color("#657b83")},
	{"stroke", "bg"},
	{"rev_text", color("#586e75")},
	{"rev_text_other", color("#839496")},

	{"accent", {
		 {"yellow", color("#b58900")},
		 {"orange", color("#cb4b16")},
		 {"red", color("#dc322f")},
		 {"magenta", color("#d33682")},
		 {"violet", color("#6c71c4")},
		 {"blue", color("#268bd2")},
		 {"cyan", color("#2aa198")},
		 {"green", color("#859900")},
	}},

	{"credits", "accent.violet"},

	{"player", {
		 {"both", "accent.violet"},
		 {"p1", "accent.red"},
		 {"p2", "accent.cyan"},
	}},

	{"judgment", {
		 {"1", "accent.red"},
		 {"2", "accent.cyan"},
		 {"3", "accent.red"},
		 {"4", "accent.red"},
		 {"5", "accent.violet"},
		 {"6", "accent.blue"},
		 {"7", "accent.green"},
		 {"8", "accent.yellow"},
		 {"9", "accent.cyan"},
		 {"HoldNoteScore_LetGo", "accent.red"},
		 {"HoldNoteScore_Held", "accent.cyan"},
		 {"HoldNoteScore_MissedHold", "accent.orange"},
		 {"TapNoteScore_Miss", "accent.red"},
		 {"TapNoteScore_W5", "accent.violet"},
		 {"TapNoteScore_W4", "accent.blue"},
		 {"TapNoteScore_W3", "accent.green"},
		 {"TapNoteScore_W2", "accent.yellow"},
		 {"TapNoteScore_W1", "accent.cyan"},
	}},

	{"difficulty", {
		 {"unknown", "accent.violet"},
		 {"Difficulty_Beginner", "accent.violet"},
		 {"Difficulty_Easy", "accent.green"},
		 {"Difficulty_Medium", "accent.yellow"},
		 {"Difficulty_Hard", "accent.red"},
		 {"Difficulty_Challenge", "accent.cyan"},
		 {"Difficulty_Edit", "accent.blue"},
	}},

	{"percent", {
		 {"nan", "text_other"},
		 {"too_low", "text"},
		 {"too_high", "rev_bg"},
		 {"1", "accent.green"},
		 {"2", "accent.yellow"},
		 {"3", "accent.orange"},
		 {"4", "accent.red"},
		 {"5", "accent.magenta"},
		 {"6", "accent.violet"},
		 {"7", "accent.blue"},
		 {"8", "accent.cyan"},
	}},
	{"number", "percent"},
	{"score", "percent"},
	{"bpm", "percent"},
	{"speed", "percent"},
	{"hours", "percent"},

	{"music_wheel", {
		 {"current_group", "accent.cyan"},
		 {"group", "accent.violet"},
		 {"random", "accent.red"},
		 {"censored_song", "accent.orange"},
		 {"prev_song", "text"},
		 {"song", "text_other"},
		 {"sort", "accent.yellow"},
		 {"sort_head", "text_other"},
		 {"sort_type", "text"},
		 {"sort_value", "text_other"},
	}},

	{"song_progress_bar", {
		 {"frame", "rev_bg"},
		 {"bg", "bg"},
		 {"progression", "percent"},
	}},

	{"gameplay", {
		 {"text_stroke", "bg"},
		 {"chart_info", "text"},
		 {"song_name", "text"},
		 {"failed", "accent.magenta"},
		 {"normal_exit", "accent.violet"},
		 {"cancel", "accent.red"},
		 {"lifemeter", {
				{"battery", {
					 {"lost_life", "bg"},
					 {"1", "accent.yellow"},
					 {"2", "accent.red"},
					 {"3", "accent.violet"},
					 {"4", "accent.cyan"},
				}},
				{"time", {
					 {"bg", "bg"},
				}},
		 }},
	}},

	{"initial_menu", {
				{"frame", "rev_bg"},
				{"menu_bg", "bg"},
				{"cant_play", {
					 {"frame", "rev_bg"},
					 {"bg", "bg"},
					 {"text", "text"},
				}},
				{"song_count", "text_other"},
				{"group_count", "text_other"},
	}},

	{"evaluation", {
		 {"best_score", {
				{"frame", "rev_bg"},
				{"bg", "bg", .875},
				{"text", "text"},
				{"rank_colors", {
					 {"too_low", "text"},
					 {"too_high", "accent.cyan"},
					 {"1", "accent.cyan"},
					 {"2", "accent.blue"},
					 {"3", "accent.violet"},
					 {"4", "accent.magenta"},
					 {"5", "accent.red"},
					 {"6", "accent.orange"},
					 {"7", "accent.yellow"},
					 {"8", "accent.green"},
				}},
		 }},
		 {"judge_key", {
				{"frame", "rev_bg"},
				{"bg", "bg", .875},
		 }},
		 {"reward", {
				{"frame", "rev_bg"},
				{"bg", "bg", .875},
				{"used_label", "text_other"},
				{"used_amount", "text"},
				{"reward_label", "text_other"},
				{"reward_amount", "text"},
				{"remain_label", "text_other"},
				{"remain_amount", "text"},
		 }},
		 {"score_report", {
				{"chart_info", "text"},
				{"bg", "bg", .875},
				{"column_heads", "text_other"},
				{"pct_column", "text"},
				{"stroke", "bg"},
		 }},
		 {"graphs", {
				{"color", "accent.violet"},
				{"bg", "bg", .875},
		 }},
		 {"song_name", "text"},
		 {"stroke", "bg"},
		 {"bg", "bg", .5},
	}},

	{"help", {
		 {"bg", "bg", .75},
		 {"text", "text"},
		 {"stroke", "bg"},
	}},

	{"music_select", {
		 {"song_name", "text"},
		 {"song_length", "text"},
		 {"remaining_time", "text_other"},
		 {"sort_head", "text_other"},
		 {"sort_type", "text"},
		 {"sort_value", "text_other"},
	}},

	{"prompt", {
		 {"frame", "rev_bg"},
		 {"bg", "bg"},
		 {"text", "accent.green"},
	}},

	{"score_list", {
		 {"time", "text"},
		 {"song_name", "text"},
		 {"chart_info", "text"},
		 {"arrows", "text_other"},
		 {"entry_bg", {
				{"1", "bg"},
				{"2", "bg_shadow"},
		 }},
	}},

	{"steps_selector", {
		 {"number_stroke", "bg"},
		 {"name_stroke", "bg"},
		 {"number_color", "text"},
		 {"name_color", "text_other"},
	}},
}

color_config= create_setting("color config", "color_config.lua", default_config, 0)
color_config:load()

local default_color= color("#000000")

local function convert_name(name)
	return (name ~= "nan" and tonumber(name)) or name
end

function recursive_alpha(group, alpha)
	for cname, cvalue in pairs(group) do
		if type(cvalue[1]) == "number" and #cvalue == 4 then
			group[cname]= Alpha(cvalue, alpha)
		else
			recursive_alpha(cvalue, alpha)
		end
	end
end

local resolved_colors= {}

local function list_group(group)
	local ret= ""
	for i, value in ipairs(group) do
		ret= ret .. "'" .. tostring(value[1]) .. "': " .. tostring(value[2])
		if i < #group then
			ret= ret .. ", "
		end
	end
	return ret
end

local function lookup_named_element(group, name)
	for i, value in ipairs(group) do
		if value[1] == name then
			return value[2]
		end
	end
	return nil
end

local function split_name(refstring)
	local parts= {}
	local cur_part_start= 1
	for i= 1, #refstring do
		local c= refstring:sub(i, i)
		if c == "." then
			parts[#parts+1]= refstring:sub(cur_part_start, i-1)
			cur_part_start= i+1
		end
	end
	if cur_part_start < #refstring then
		parts[#parts+1]= refstring:sub(cur_part_start)
	end
	return parts
end

local function lookup_color_reference(refstring, lookup_chain)
	local name_parts= split_name(refstring)
	local current_group= color_config:get_data()
	local lookup_str= "'.  Lookup chain: " .. lookup_chain
	for i, part in ipairs(name_parts) do
		local result= lookup_named_element(current_group, part)
		if not result then
			lua.ReportScriptError(
				"Color name reference '" .. refstring ..
					"' could not be resolved at '" .. part .. lookup_str)
			lua.ReportScriptError("name_parts: '" .. table.concat(name_parts, "', '") .. "'")
			lua.ReportScriptError("group: " .. list_group(current_group))
			return default_color
		end
		if type(result) ~= "table" then
			lua.ReportScriptError(
				"Color name reference '" .. refstring ..
					"' pointed to bad color entry at '" .. part .. lookup_str)
			return default_color
		end
		local eltype= type(result)
		if eltype == "table" then
			current_group= result
		elseif eltype == "string" then
			return lookup_color_reference(result, lookup_chain .. " -> " .. refstring)
		else
			lua.ReportScriptError(
				"Color name reference '" .. refstring ..
					"' pointed to bad color at '" .. part .. lookup_str)
			return default_color
		end
	end
	if not current_group then
		lua.ReportScriptError(
			"Color name reference could not be resolved:  '" .. refstring ..
				lookup_str)
		return default_color
	end
	return current_group
end

local function rec_resolve_references(refgroup, colgroup, alpha, lineage)
	for i, value in ipairs(refgroup) do
		if type(value) == "table" then
			if type(value[1]) == "string" then
				local colname= convert_name(value[1])
				if type(value[2]) == "string" then
					local resolved= lookup_color_reference(value[2], "")
					if type(resolved[1]) == "table" then
						colgroup[colname]= {}
						rec_resolve_references(
							resolved, colgroup[colname], alpha * (value[3] or 1),
							lineage .. "." .. value[1])
					else
						colgroup[colname]= Alpha(resolved, alpha * (value[3] or 1))
					end
				elseif type(value[2]) == "table" then
					if type(value[2][1]) == "number" then
						colgroup[colname]= Alpha(value[2], alpha * (value[3] or 1))
					else
						if not colgroup[colname] then
							colgroup[colname]= {}
						end
						rec_resolve_references(
							value[2], colgroup[colname], alpha * (value[3] or 1),
							lineage .. "." .. value[1])
					end
				else
					lua.ReportScriptError(
						"Malformed color '" .. value[1] .. "' at '" .. lineage ..
							"' in color config.")
				end
			else
				lua.ReportScriptError(
					"Entry with malformed name '" .. tostring(value[1]) ..
						"' in color config at '" .. lineage .. "'.")
			end
		else
			lua.ReportScriptError(
				"Malformed entry '" .. i .. "' at '" .. lineage ..
					"' in color config.")
		end
	end
end

function resolve_color_references()
	resolved_colors= {}
	rec_resolve_references(color_config:get_data(), resolved_colors, 1, "")
end
resolve_color_references()
function print_resolved_colors()
	Trace("Resolved colors:")
	rec_print_table(resolved_colors)
end

function fetch_color(name, alpha)
	local name_parts= split_name(name)
	local current_group= resolved_colors
	for i, part in ipairs(name_parts) do
		local real_part= convert_name(part)
		current_group= current_group[real_part]
		if not current_group then
			lua.ReportScriptError("Missing color '" .. name .. "'.")
			return default_color
		end
	end
	local ret= current_group
	if type(alpha) == "number" then
		if type(current_group[1]) == "number" and #current_group == 4 then
			ret= Alpha(current_group, alpha)
		else
			ret= DeepCopy(current_group)
			recursive_alpha(ret, alpha)
		end
	end
	return ret
end

function pn_to_color(pn)
	local pn_colors= fetch_color("player")
	if not pn then return pn_colors.both end
	local cname= ToEnumShortString(pn):lower()
	return pn_colors[cname] or pn_colors.both
end

function judge_to_color(judge)
	local set= fetch_color("judgment")
	return set[judge] or fetch_color("text")
end

function diff_to_color(diff)
	local set= fetch_color("difficulty")
	return set[diff] or set.unknown
end

function color_in_set(set, index, wrap, cap_low, cap_high)
	if index ~= index then
		return set.nan or set.too_low
	end
	if wrap then
		index= ((index-1) % #set) + 1
	end
	if index < 1 then
		if cap_low then return set[1]
		else return set.too_low end
	end
	if index > #set then
		if cap_high then return set[#set]
		else return set.too_high end
	end
	return set[index] or default_color
end

function percent_to_color(p, cap_low, cap_high, set_name)
	set_name= set_name or "percent"
	local set= fetch_color(set_name)
	return color_in_set(
		set, math.ceil(p * #set), false, cap_low, cap_high)
end

function number_to_color(n, cap_low, cap_high, set_name)
	set_name= set_name or "number"
	return color_in_set(fetch_color(set_name), n, false, cap_low, cap_high)
end

function wrapping_number_to_color(n, set_name)
	set_name= set_name or "number"
	return color_in_set(fetch_color(set_name), index, true)
end

function color_percent_above(val, above, set_name)
	return percent_to_color((val-above)/(1-above), false, true, set_name)
end

score_color_threshold= 31/32

function color_for_score(score)
	return color_percent_above(score, score_color_threshold, "score")
end

function color_for_bpm(bpm)
	if bpm > 200 then
		return color_in_set(
			fetch_color("bpm"), math.ceil((bpm-200)/25), false, false, false)
	end
	if bpm < 100 then
		return color_in_set(
			fetch_color("bpm"), math.ceil((100-bpm)/6.25), false, false, false)
	end
	return fetch_color("text")
end

function color_for_read_speed(speed)
	if speed > 400 then
		return color_in_set(
			fetch_color("speed"), math.ceil((speed-400)/100), false, false, false)
	end
	return fetch_color("text")
end

function set_bmt_to_bpms(bmt, bpms)
	bmt:ClearAttributes()
	if #bpms == 1 or bpms[1] == bpms[#bpms] then
		bmt:settext(format_bpm(bpms[1]))
		bmt:diffuse(color_for_bpm(bpms[1]))
	else
		bmt:diffuse(fetch_color("text"))
		local first= format_bpm(bpms[1])
		local second= format_bpm(bpms[#bpms])
		bmt:settext(first .. "-" .. second)
		bmt:AddAttribute(0, {Length= #first, Diffuse= color_for_bpm(bpms[1])})
		bmt:AddAttribute(
			#first+1, {Length= #second, Diffuse= color_for_bpm(bpms[#bpms])})
	end
end

function adjust_luma(from_color, adjustment)
	local res_color= {}
	for i, v in pairs(from_color) do
		if i == 4 then
			res_color[i]= v
		else
			res_color[i]= (v^2.2 * adjustment)^(1/2.2)
		end
	end
	return res_color
end
