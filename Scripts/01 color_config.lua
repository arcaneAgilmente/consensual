unchangeable_color= {
	text= color("#93a1a1"),
	bg= color("#002b36"),
	cursor= color("#6c71c4"),
	hilight= color("#fdf6e3"),
}

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
		 {"hilight", "rev_bg"},
	}},

	{"judgment", {
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
	{"confetti", "percent"},

	{"help", {
		 {"bg", "bg", .75},
		 {"text", "text"},
		 {"stroke", "stroke"},
	}},

	{"music_select", {
		 {"song_name", "text"},
		 {"song_length", "text"},
		 {"remaining_time", "text_other"},
		 {"sort_head", "text_other"},
		 {"sort_type", "text"},
		 {"sort_value", "text_other"},
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
		 {"steps_selector", {
				{"number_stroke", "stroke"},
				{"name_stroke", "stroke"},
				{"number_color", "text"},
				{"name_color", "text_other"},
		 }},
	}},

	{"gameplay", {
		 {"text_stroke", "stroke"},
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
		 {"song_progress_bar", {
				{"frame", "rev_bg", .5},
				{"bg", "bg", .5},
				{"text", "text"},
				{"stroke", "stroke"},
				{"length", "percent"},
				{"progression", "percent", .5},
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
				{"stroke", "stroke"},
		 }},
		 {"graphs", {
				{"color", "accent.violet"},
				{"bg", "bg", .875},
		 }},
		 {"song_name", "text"},
		 {"stroke", "stroke"},
		 {"bg", "bg", .5},
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

}

color_config= create_setting("color config", "color_config.lua", default_config, 0)
color_config:load()

local default_color= color("#000000")

local function convert_name(name)
	return (name ~= "nan" and tonumber(name)) or name
end

function is_color(t)
	return type(t) == "table" and #t == 4 and type(t[1]) == "number"
	and type(t[2]) == "number" and type(t[3]) == "number"
	and type(t[4]) == "number"
end

local cdig= "[0-9a-fA-F]"
local opcdig= cdig.."?"
local cmatch_str= "^#"..cdig:rep(6)..opcdig:rep(2).."$"
function is_color_not_ref(s)
	if type(s) ~= "string" then return nil end
	if s:match(cmatch_str) and (#s == 7 or #s == 9) then return color(s) end
	return nil
end
function is_color_string(s)
	if type(s) ~= "string" then return nil end
	return is_color_not_ref(s)
		or lookup_color_reference(s, true, true)
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
	if cur_part_start <= #refstring then
		parts[#parts+1]= refstring:sub(cur_part_start)
	end
	return parts
end

local function maybe_report_lookup_error(err, no_default, silent)
	if not silent then lua.ReportScriptError(err) end
	if no_default then return nil, err end
	return default_color, err
end
function lookup_color_reference(refstring, no_default, silent, lookup_chain, depth)
	lookup_chain= lookup_chain or ""
	depth= depth or 1
	if depth > 10 then
		return maybe_report_lookup_error(
			"Reference chains cannot be more than 10 deep.\n" ..
			"Lookup chain: " .. lookup_chain, no_default, silent)
	end
	local name_parts= split_name(refstring)
	local current_group= color_config:get_data()
	local lookup_str= "'.  Lookup chain: " .. lookup_chain
	for i, part in ipairs(name_parts) do
		local result= lookup_named_element(current_group, part)
		if not result then
			return maybe_report_lookup_error(
				"Color name reference '" .. refstring ..
					"' could not be resolved at '" .. part .. lookup_str, no_default,
				silent)
					-- .. "\n" ..
					-- "name_parts: '" .. table.concat(name_parts, "', '") .. "'\n" ..
					-- "group: " .. list_group(current_group), no_default, silent)
		end
		local eltype= type(result)
		if eltype == "table" then
			current_group= result
		elseif eltype == "string" then
			return lookup_color_reference(
				result, no_default, silent, lookup_chain.." -> "..refstring, depth+1)
		else
			return maybe_report_lookup_error(
				"Color name reference '" ..refstring.. "' pointed to bad color at '"
					.. part .. lookup_str, no_default, silent)
		end
	end
	if not current_group then
		return maybe_report_lookup_error(
			"Color name reference could not be resolved:  '" .. refstring ..
				lookup_str, no_default, silent)
	end
	return current_group
end

function fetch_default_color_setting(name)
	local name_parts= split_name(name)
	local current_group= default_config
	for i, part in ipairs(name_parts) do
		local result= lookup_named_element(current_group, part)
		if type(result) == "string" and i < #name_parts then
			result= lookup_color_reference(result, true, true)
		end
		if not result then
			return nil
		end
		current_group= result
	end
	return current_group
end

local function check_group_for_reference(check_group, name)
	for i= 1, #check_group do
		if type(check_group[i][2]) == "table" then
			if not is_color(check_group[i][2]) then
				local sub_ret= check_group_for_reference(check_group[i][2], name)
				if sub_ret then return true end
			end
		elseif check_group[i][2] == name then
			return true
		end
	end
	return false
end
function color_is_referenced(name)
	local current_group= color_config:get_data()
	return check_group_for_reference(current_group, name)
end

function color_can_be_removed(name)
	if color_is_referenced(name) then return false end
	if not fetch_default_color_setting(name) then return true end
	local name_parts= split_name(name)
	local end_part= convert_name(name_parts[#name_parts])
	if type(end_part) ~= "number" then return false end
	return end_part > 1
end

function sanity_check_color_config()
	-- ScreenColorConfig took the route of preventing all actions that would
	-- compromise the sanity of the configuration, so this function isn't
	-- actually needed.
	return true
end

local function rec_resolve_references(refgroup, colgroup, alpha, lineage)
	for i, value in ipairs(refgroup) do
		if type(value) == "table" then
			if type(value[1]) == "string" then
				local colname= convert_name(value[1])
				if type(value[2]) == "string" then
					local resolved= lookup_color_reference(value[2])
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

local function maybe_resolve(a)
	if type(a) == "string" then
		return is_color_not_ref(a) or lookup_color_reference(a, true, true)
	end
	return a
end
local function color_similarity_test(left, right)
	if is_color(left) then
		return is_color(right), "New reference does not refer to a color."
	end
	if is_color(right) then
		return false, "Old item does not refer to a color."
	end
	return true, ""
end
local function resolved_groups_are_similar(left, right)
	if #left > 0 then
		if #right < 1 then
			return false, "New group does not have required list of numbers."
		end
	end
	for name, value in pairs(left) do
		if type(convert_name(name)) == "string" then
			if right[name] then
				local color_passed, err= color_similarity_test(
					left[name], right[name])
				if not color_passed then return false, err end
				if is_color(left[name]) then return true, "" end
				local group_passed, errg= resolved_groups_are_similar(
					left[name], right[name])
				if not group_passed then return false, errg end
			else
				return false, "New group must have '" .. name .. "' member."
			end
		end
	end
	return true, ""
end
function groups_are_similar(a, b)
	local left= maybe_resolve(a)
	local right= maybe_resolve(b)
	if not left or not right then return false, "One reference is nil." end
	local color_passed, err= color_similarity_test(left, right)
	if not color_passed then return false, err end
	if is_color(left) then return true, "" end
	local left_resolved= {}
	local right_resolved= {}
	rec_resolve_references(left, left_resolved, 1, "")
	rec_resolve_references(right, right_resolved, 1, "")
	return resolved_groups_are_similar(left_resolved, right_resolved)
end

local function group_has_entry(group, entry_name)
	for i, entry in ipairs(group) do
		if entry[1] == entry_name then return entry end
	end
	return false
end

function rec_ensure_color_existence(a, b)
	for i, entry in ipairs(a) do
		local should_have= true
		local name= convert_name(entry[1])
		if type(name) == "number" and name > 1 then should_have= false end
		if should_have then
			local from_b= group_has_entry(b, entry[1])
			if from_b then
				local ant= type(entry[2])
				local bnt= type(from_b[2])
				if ant == "string" then
					if bnt == "string" then
						local refa= fetch_default_color_setting(entry[2])
						local refb= lookup_color_reference(from_b[2], false, true)
						if is_color(refa) then
							if not is_color(refb) then
								from_b[2]= entry[2]
							end
						else
							if is_color(refb) then
								from_b[2]= entry[2]
							else
								rec_ensure_color_existence(refa, refb)
							end
						end
					elseif is_color(from_b[2]) then
						if not is_color(fetch_default_color_setting(entry[2])) then
							from_b[2]= entry[2]
						end
					else
						rec_ensure_color_existence(
							fetch_default_color_setting(entry[2]),
							from_b[2])
					end
				elseif is_color(entry[2]) then
					if bnt == "string" then
						if not is_color(lookup_color_reference(from_b[2], false, true)) then
							from_b[2]= DeepCopy(entry[2])
						end
					elseif is_color(from_b[2]) then
						-- good.
					else
						from_b[2]= DeepCopy(entry[2])
					end
				else
					if bnt == "string" then
						local refb= lookup_color_reference(from_b[2], false, true)
						if is_color(refb) then
							from_b[2]= DeepCopy(entry[2])
						else
							rec_ensure_color_existence(entry[2], refb)
						end
					elseif is_color(from_b[2]) then
						from_b[2]= DeepCopy(entry[2])
					else
						rec_ensure_color_existence(entry[2], from_b[2])
					end
				end
			else
				b[#b+1]= DeepCopy(entry)
			end
		end
	end
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

function resolve_color_references()
	resolved_colors= {}
	rec_resolve_references(color_config:get_data(), resolved_colors, 1, "")
	local judgment= fetch_color("judgment")
	local tns_reverse= TapNoteScore:Reverse()
	local hns_reverse= HoldNoteScore:Reverse()
	for name, col in pairs(judgment) do
		if type(name) == "string" then
			if tns_reverse[name] then
				judgment[tns_reverse[name]]= col
			elseif hns_reverse[name] then
				judgment[hns_reverse[name]]= col
			end
		end
	end
end
rec_ensure_color_existence(default_config, color_config:get_data())
resolve_color_references()
function print_resolved_colors()
	Trace("Resolved colors:")
	rec_print_table(resolved_colors)
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
	if not set[index] then
		lua.ReportScriptError("Index '" .. tostring(index) .. "' is not in set.")
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
	return color_in_set(fetch_color(set_name), n, true)
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
