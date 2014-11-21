local min_bucket_size= 32
local max_bucket_size= 64

local invalid_sort_item_name= "invalid_sort_item_name"
local bad_name_source_factor= {
	name= "bad_name", get_names= function() return {invalid_sort_item_name} end,
		can_join= noop_true, group_similar= false
}
local bad_sort_name_warning_occurred= false

local function depth_clip_name(name, depth)
	if type(name) == "number" then return name, -1 end
	return name:sub(1, depth), #name - depth
end

local function str_cmp(a, b)
	return a:lower() < b:lower()
end

local function less_cmp(a, b)
	return a < b
end

local function is_not_valid_name(ntype, name, spew)
	if ntype == "string" or ntype == "number" then
		return false
	end
	if spew then
		Warn("Invalid name: '" .. ntype .. "' : '" .. tostring(name) .. "'")
	end
	return true
end

local function validate_name_set(names, sf, spew)
	if type(names) ~= "table" then
		if spew then
			Warn("sort_factor " .. (sf.name or tostring(sf)) .. " returned non-table name set: '" .. tostring(names) .. "'")
		end
		local sub_names, sub_spew= validate_name_set({names}, sf, spew)
		return sub_names, true
	end
	local did_spew= false
	for i, name in ipairs(names) do
		if is_not_valid_name(type(name), name, spew) then
			names[i]= tostring(name)
			Warn("sort_factor " .. (sf.name or tostring(sf)) .. " returned invalid name.")
			did_spew= true
		end
	end
	return names, did_spew
end

local cmp_table= {
	number= {number= less_cmp, string= noop_true},
	string= {number= noop_false, string= str_cmp}
}
local function name_cmp(left, right)
	local ltype= type(left)
	local rtype= type(right)
	if not cmp_table[ltype] then
		Trace("ltype of: " .. ltype)
		ltype= "string"
		left= "bad"
	end
	if not cmp_table[rtype] then
		Trace("rtype of: " .. rtype)
		rtype= "string"
		right= "bad"
	end
	return cmp_table[ltype][rtype](left, right)
end

local function bckt_cmp(left, right)
	if not left then return false end
	if not right then return true end
	return name_cmp(left.name.value, right.name.value)
end

local function item_cmp_wrapper(sort_depth)
	return function(left, right)
		if not left then return false end
		if not right then return true end
		local lnames= left.name_set
		local rnames= right.name_set
		assert(#lnames == #rnames)
		for i= sort_depth, #lnames do
			if #lnames[i].names == 1 and #rnames[i].names == 1 then
				if lnames[i].names[1] ~= rnames[i].names[1] then
					return lnames[i].names[1] < rnames[i].names[1]
				end
			end
		end
		return lnames[#lnames].names[1] < rnames[#rnames].names[1]
	end
end

local function simple_copy(source)
	local ret= {}
	for i, v in ipairs(source) do
		ret[i]= v
	end
	return ret
end

local function copy_name_set(source)
	local ret= {}
	for i, name in ipairs(source) do
		if #name.names > 1 then
			ret[i]= {source= name.source, names= simple_copy(name.names)}
		else
			ret[i]= name
		end
	end
	return ret
end

local function add_item_to_uns_buckets(uns, item, sort_depth, name_depth)
	local source= item.name_set[sort_depth].source
	if not source.uses_depth then
		name_depth= -1
	end
	local depth_remains= -1
	local multi_names= #item.name_set[sort_depth].names > 1
	for i, name in ipairs(item.name_set[sort_depth].names) do
		local bucket_name, remain= depth_clip_name(name, name_depth)
		depth_remains= math.max(depth_remains, remain)
		local bucket= uns[bucket_name]
		local split_item= item
		if multi_names then
			split_item= {name_set= copy_name_set(item.name_set), el= item.el}
			split_item.name_set[sort_depth].names= {name}
		end
		if bucket then
			bucket.contents[#bucket.contents+1]= split_item
		else
			-- bucket creation marker
			uns[bucket_name]= {
				from_adduns= true,
				name= {value= bucket_name, source= source}, contents= {split_item}}
		end
	end
	return depth_remains
end

local function sort_uns_buckets(uns)
	local bucketed_set= {}
	for name, bucket in pairs(uns) do
		bucketed_set[#bucketed_set+1]= bucket
	end
	maybe_yield("Bucketing", fracstr(#bucketed_set, #bucketed_set))
	table.sort(bucketed_set, bckt_cmp)
	return bucketed_set
end

local function get_name_from_item(thing, sort_depth)
	-- Just assume there's only one name.
	local name= thing.name_set[sort_depth] or thing.name_set[#thing.name_set]
	return name.names[1], name.source
end

local function get_name_from_bucket_or_item(thing, sort_depth)
	if thing.contents then
		if thing.from_split then
			if thing.contents[1].name_set then
				return get_name_from_item(thing.contents[1], sort_depth)
			elseif not thing.contents[1].name then
				if not bad_sort_name_warning_occurred then
					local message= "Something ended up without a name while sorting.  Please generate sort test data to send back to Kyzentun by pressing 'x' on the main menu."
					message= message .. "\nBucket name info: '" .. thing.name.value .. "' from '" .. thing.name.source.name .. "'"
					lua.ReportScriptError(message)
					rec_print_table(thing.contents, "  ", 2)
					bad_sort_name_warning_occurred= true
				end
				return invalid_sort_item_name, bad_name_source_factor
			end
			return thing.contents[1].name.value, thing.contents[1].name.source
		end
		return thing.name.value, thing.name.source
	else
		return get_name_from_item(thing, sort_depth)
	end
end

local function set_range_name_from_contents(bucket, sort_depth)
	local first_name, first_source= get_name_from_bucket_or_item(
		bucket.contents[1], sort_depth)
	local last= bucket.contents[#bucket.contents]
	local last_name, last_source= get_name_from_bucket_or_item(last, sort_depth)
	if not bucket.from_similar and last.contents and last.contents_name_range
	and last.contents_name_range[1].source == first_source then
		last_name, last_source= get_name_from_bucket_or_item(
			last.contents[#last.contents], sort_depth)
	end
	bucket.contents_name_range= {
		{value= first_name, source= first_source},
		{value= last_name, source= last_source}}
end

local function evenly_split_bucket(items, name_source)
	local num_subs= math.ceil(#items / max_bucket_size)
	local sub_size= #items / num_subs
	local sub_buckets= {}
	local curr_sub= {}
	local curr_sub_index= 1
	local function add_curr_sub_to_buckets()
		sub_buckets[curr_sub_index]= {
			-- bucket creation marker
			name= {value= curr_sub_index, source= name_source},
			contents= curr_sub, sorted= true, from_split= true}
		curr_sub= {}
		curr_sub_index= #sub_buckets+1
	end
	local num_items= #items
	for i= 1, num_items do
		local item= items[i]
		curr_sub[#curr_sub+1]= item
		if i >= math.floor(curr_sub_index * sub_size) then
			add_curr_sub_to_buckets()
		end
		if i % 1000 == 0 then maybe_yield("Splitting", fracstr(i, num_items)) end
	end
	if #curr_sub > 0 then
		add_curr_sub_to_buckets()
	end
	return sub_buckets
end

local function make_sub_buckets_from_items(items, sort_depth, name_depth)
	local buckets= {}
	local depth_remains= -1
	local icount= #items
	for i= 1, icount do
		local remain= add_item_to_uns_buckets(
			buckets, items[i], sort_depth, name_depth)
		depth_remains= math.max(depth_remains, remain)
		if i % 100 == 0 then maybe_yield("Bucketing", fracstr(i, icount)) end
	end
	return sort_uns_buckets(buckets), depth_remains
end

local function make_sub_buckets(items, sort_factors, sort_depth, name_depth)
	if items[1].contents then
		table.sort(items, bckt_cmp)
		local buckets= evenly_split_bucket(items, sort_factors[sort_depth])
		return buckets
	else
		return make_sub_buckets_from_items(items, sort_depth, name_depth)
	end
end

local function ensure_can_join(sf)
	if sf then
		sf.can_join= sf.can_join or noop_true
	end
end

local function convert_elements_to_items(els, sfs)
	local items= {}
	local sf_spew_flags= {}
	local elcount= #els
	local sfcount= #sfs
	for ei= 1, elcount do
		local el= els[ei]
		local name_set= {}
		for si= 1, sfcount do
			local sf= sfs[si]
			local names
			names, sf_spew_flags[si]= validate_name_set(
				sf.get_names(el), sf, not sf_spew_flags[si])
			if sf.insensitive_names then
				for i, n in ipairs(names) do
					names[i]= n:lower()
				end
			end
			table.sort(names)
			local i= 1
			while i < #names do
				local curr= names[i]
				while curr == names[i+1] do
					table.remove(names, i+1)
				end
				i= i + 1
			end
			name_set[#name_set+1]= {source= sf, names= names}
		end
		items[#items+1]= {el= el, name_set= name_set}
		if ei % 100 == 0 then maybe_yield("Converting", fracstr(ei, elcount)) end
	end
	return items
end

local function ensure_sorted(bucket, sort_depth)
	if not bucket.sorted then
		if bucket.contents[1].contents then
			table.sort(bucket.contents, bckt_cmp)
		else
			table.sort(bucket.contents, item_cmp_wrapper(sort_depth))
		end
		bucket.sorted= true
	end
end

local function combine_buckets(left, right, sort_depth)
	ensure_sorted(left, sort_depth)
	ensure_sorted(right, sort_depth)
	local merged= {}
	local lcon, rcon= left.contents, right.contents
	local cmp
	if left.contents[1].contents then
		cmp= bckt_cmp
	else
		cmp= item_cmp_wrapper(sort_depth)
	end
	local lindex, rindex= 1, 1
	while lindex <= #lcon or rindex <= #rcon do
		local lit, rit= lcon[lindex], rcon[rindex]
		if cmp(lit, rit) then
			merged[#merged+1]= lit
			lindex= lindex + 1
		else
			merged[#merged+1]= rit
			rindex= rindex + 1
		end
	end
	local left_comb_name= left.name
	if left.combined_name_range then
		left_comb_name= left.combined_name_range[1]
	end
	local right_comb_name= right.name
	if right.combined_name_range then
		right_comb_name= right.combined_name_range[2]
	end
	left.combined_name_range= {left_comb_name, right_comb_name}
	left.contents= merged
	set_range_name_from_contents(left, sort_depth)
end

local function combine_small_buckets(left, middle, right, can_join, sort_depth)
	local can_use_left= left and can_join(left, middle)
	local can_use_right= right and can_join(middle, right)
	if can_use_left then
		if can_use_right then
			if #left.contents < #right.contents then
				combine_buckets(left, middle, sort_depth)
				return -1
			else
				combine_buckets(middle, right, sort_depth)
				return 1
			end
		else
			combine_buckets(left, middle, sort_depth)
			return -1
		end
	else
		if can_use_right then
			combine_buckets(middle, right, sort_depth)
			return 1
		else
			return 0
		end
	end
end

local function get_initial_similarity(a, b)
	local ret= ""
	local a_words= split_string_to_words(a)
	local b_words= split_string_to_words(b)
	local len= math.min(#a_words, #b_words)
	for i= 1, len do
		if not a_words[i] or not b_words[i] then break end
		if a_words[i] == b_words[i] then
			if ret ~= "" then
				ret= ret .. " "
			end
			ret= ret .. a_words[i]
		else
			break
		end
	end
	return ret
end

local function group_similar_buckets(left, right, dont_clip)
	if not left or not right then return nil end
	local min_sim= 2
	local function rename_grouped_buckets(group)
		set_range_name_from_contents(group)
		if dont_clip then return end
		local shared_len= #group.name.value + 2
		for i, b in ipairs(group.contents) do
			local new_name= tostring(b.name.value):sub(shared_len)
			if new_name == "" then new_name= i end
			b.name.disp= new_name
		end
	end
	local sim= get_initial_similarity(left.name.value, right.name.value)
	if #sim > min_sim then
		if left.from_similar then
			left.name.value= sim
			left.contents[#left.contents+1]= right
		else
			-- bucket creation marker
			left= {
				name= {value= sim, source= left.name.source},
				contents= {left, right},
				sorted= true, from_similar= true}
		end
		rename_grouped_buckets(left)
		return left
	end
	return nil
end

local function recursive_sort(items, sort_factors, sort_depth, name_depth)
	local curr_factor= sort_factors[sort_depth]
	local should_split= false
	if #items > max_bucket_size then
		should_split= true
		-- Forcing a split just because one of the items has multiple names
		-- causes infinite recursion because the splitting doesn't know when to
		-- advance to the next sort_factor.
--	elseif curr_factor and curr_factor.returns_multiple then
--		for i, item in ipairs(items) do
--			if #item.name_set[sort_depth].names > 1 then
--				should_split= true
--				break
--			end
--		end
	end
	local function can_join_wrapper(left, right)
		local can_join= left.name.source.can_join
		local left_has_items= not left.contents[1].contents
		local right_has_items= not right.contents[1].contents
		if (left_has_items ~= right_has_items) or
			(left.name.source ~= right.name.source) or
			(#left.contents + #right.contents > max_bucket_size) or
			left.from_similar or right.from_similar or
		(not can_join(left, right)) then
			return false
		end
		if not left_has_items and
		(left.contents[1].from_split or right.contents[1].from_split) then
			return false
		end
		return true
	end
	local sub_sort_depth= sort_depth
	local function process_sub_buckets(buckets, depth_remains)
		local num_buckets= #buckets
		for i= 1, num_buckets do
			local bucket= buckets[i]
			if bucket.from_split then
				bucket.contents= recursive_sort(
					bucket.contents, sort_factors, sort_depth, name_depth)
			else
				if not depth_remains then
					bucket.contents= recursive_sort(
						bucket.contents, sort_factors, sub_sort_depth, name_depth)
				else
					if depth_remains >= 0 then
						bucket.contents= recursive_sort(
							bucket.contents, sort_factors, sub_sort_depth, name_depth + 1)
					elseif sort_depth < #sort_factors then
						bucket.contents= recursive_sort(
							bucket.contents, sort_factors, sub_sort_depth + 1, 1)
					end
				end
			end
			set_range_name_from_contents(bucket, sub_sort_depth)
			if i % 100 == 0 then maybe_yield("Sorting", fracstr(i, num_buckets)) end
		end
		local i= 1
		while i <= #buckets do
			local bucket= buckets[i]
			if #bucket.contents < min_bucket_size then
				local used= combine_small_buckets(
					buckets[i-1], bucket, buckets[i+1], can_join_wrapper, sort_depth)
				if used == -1 then
					table.remove(buckets, i)
					bucket= nil
				elseif used == 1 then
					table.remove(buckets, i+1)
					bucket= nil
				end
			end
			if bucket then
				if curr_factor and curr_factor.group_similar then
					local new_left= group_similar_buckets(
						buckets[i-1], bucket, curr_factor and curr_factor.dont_clip)
					if new_left then
						buckets[i-1]= new_left
						table.remove(buckets, i)
						bucket= nil
					end
				end
			end
			if bucket then
				i= i + 1
			end
			if i % 100 == 0 then maybe_yield("Combining", fracstr(i, #buckets)) end
		end
	end
	if should_split then
		local buckets, depth_remains= make_sub_buckets(
			items, sort_factors, sort_depth, name_depth)
		if (curr_factor and curr_factor.uses_depth and depth_remains < 0) or
			#buckets == 1 then
			-- make_sub_buckets didn't actually accomplish anything because it had
			-- insufficient depth to work with.
			if sort_depth < #sort_factors then
				sub_sort_depth= sub_sort_depth + 1
				buckets, depth_remains= make_sub_buckets(
					items, sort_factors, sub_sort_depth, 1)
			else
				if items[1].contents then
					table.sort(items, bckt_cmp)
				else
					table.sort(items, item_cmp_wrapper(sort_depth))
				end
				buckets= evenly_split_bucket(items, sort_factors[sort_depth])
			end
		end
		process_sub_buckets(buckets, depth_remains)
		while #buckets > max_bucket_size do
			buckets= evenly_split_bucket(buckets, sort_factors[sort_depth])
			for i, bucket in ipairs(buckets) do
				set_range_name_from_contents(bucket, sort_depth)
			end
		end
		return buckets
	elseif #items > 0 then
		if items[1].contents then
			process_sub_buckets(items)
			return items
		else
			table.sort(items, item_cmp_wrapper(sort_depth))
			return items
		end
	else
		return items
	end
end

-- element definition:
-- One element of the source set that is being sorted.

-- sort_factor definition:
-- {
--   name= string, -- optional human readable name, used by bucket_print.
--   get_names= function(element), -- returns a table of names for element.
--   returns_multiple= bool, -- whether get_names can return multiple names.
--   uses_depth= bool, -- whether the name is a string that can be clipped
--     -- for depth.  This is useful for title sort, where you want to clip
--     -- the names down to just the first letter for the first layer of
--     -- buckets, then add a letter with each layer.
--   can_join= function(name, name),
--     -- returns whether the buckets made by this sort_factor can be joined
--     -- if they are below min_bucket_size.
--   insensitive_names= bool,
--     -- whether the names are case-insensitive strings.
--   group_similar= bool, -- whether to group buckets with similar names.
--   dont_clip= bool, -- whether to clip names when grouping similar buckets.
-- }

-- item definition:
-- {
--   name_set=
--   {
--     {
--       source= sort_factor,
--       names= {string/number, ...}
--     },
--     ...
--   },
--   el= element,
-- }

-- bucket definition:
-- {
--   name=
--   {
--     value= string/number,
--     disp= string/number, -- Has precedence over value for display.
--     source= sort_factor,
--   },
--   combined_name_range= {name, name}
--   contents_name_range= {name, name}
--   contents= {item/bucket, ...}
--   sorted= bool, -- whether this bucket has been sorted by table.sort yet.
--   from_adduns= bool, -- whether bucket was made by add_item_to_uns_buckets
--   from_split= bool, -- whether bucket was made by evenly_split_bucket
--   from_similar= bool, -- whether bucket was made by grouping similar
-- }
-- bucket contents must be homogenous:  all items or all buckets.

-- bucket_sort params:
-- (
--   set= {element, ...}
--   sort_factors= {sort_factor, ...}
-- )
-- The final sort_factor in sort_factors must not return multiple names.

function bucket_sort(set, sort_factors)
	for i, sf in ipairs(sort_factors) do
		ensure_can_join(sf)
	end
	local conv_start= GetTimeSinceStart()
	local items= convert_elements_to_items(set, sort_factors)
	local conv_end= GetTimeSinceStart()
--	Trace("Converting to items took " .. conv_end - conv_start)
	local setcount= #set
	coroutine.yield("converted", setcount .. "/" .. setcount)
	local sort_start= GetTimeSinceStart()
	local ret= recursive_sort(items, sort_factors, 1, 1)
	local sort_end= GetTimeSinceStart()
--	Trace("Sorting took " .. sort_end - sort_start)
	return ret
end

local function short_name(name, len)
	if type(name) == "string" then
		return name:sub(1, len)
	end
	return name
end

local function name_len(name)
	if type(name) == "string" then
		return #name
	end
	return 0
end

local function cmp_names_to_range_begin(names, begin)
	for i, name in ipairs(names) do
		if not name_cmp(short_name(name, name_len(begin)), begin) then
			return true
		end
	end
	return false
end

local function cmp_names_to_range_end(names, last)
	for i, name in ipairs(names) do
		if not name_cmp(last, short_name(name, name_len(last))) then
			return true
		end
	end
	return false
end

local function cmp_names_to_single_name(names, single)
	local sin_is_str= type(single) == "string"
	for i, name in ipairs(names) do
		if type(name) == "string" then
			if sin_is_str and name:sub(1, #single) == single then
				return true
			end
		else
			if not sin_is_str and name == single then
				return true
			end
		end
	end
	return false
end

-- bucket_search params:
-- (
--   set= {bucket, ...}, -- the set of buckets returned by bucket_sort
--   match_element= element, -- used to fetch the names to find the element
--   final_compare= function, -- passed a candidate element and match_element
--     to determine if the candidate matches.
--     If final_compare(candidate, match_element) returns true, the element
--     has been found and the full path is returned.
--   default_to_brute= bool -- Use brute search if bucket_search fails.
-- )
function bucket_search(set, match_element, final_compare, default_to_brute)
	for i, item in ipairs(set) do
		if item.contents then
			local in_bucket= false
			local names= item.name.source.get_names(match_element)
			local con_range= item.contents_name_range
			if item.from_split or item.from_similar then
				local con_names= con_range[1].source.get_names(match_element)
				in_bucket= cmp_names_to_range_begin(con_names, con_range[1].value)
					and cmp_names_to_range_end(con_names, con_range[2].value)
			else
				if con_range then
					local con_names= con_range[1].source.get_names(match_element)
					in_bucket= cmp_names_to_range_begin(con_names, con_range[1].value)
						and cmp_names_to_range_end(con_names, con_range[2].value)
				else
					in_bucket= cmp_names_to_single_name(names, item.name.value)
				end
			end
			if in_bucket then
				local sub_ret= {
					bucket_search(item.contents, match_element, final_compare, false)}
				if sub_ret[1] ~= -1 then
					return i, unpack(sub_ret)
				end
			end
		else
			if final_compare(item.el, match_element) then
				return i
			end
		end
	end
	if default_to_brute then
		return bucket_brute_search(set, match_element, final_compare)
	end
	-- This is not an error situation, false leads are possible.
	return -1
end

-- bucket_search_for_item params:
-- (
--   set= {bucket, ...}, -- the set of buckets returned by bucket_sort
--   match_item= item, -- an item from a bucket
-- )
-- This requires no compare function or brute search option because it uses
-- the names the item provides.  If the search fails, the item doesn't exist
-- in the tree.
function bucket_search_for_item(set, match_item)
	local function get_bucket_source(bucket)
		return bucket.name.source.name
	end
	local function find_same_source_depth(name_set, compare_to)
		local depth= 1
		while name_set[depth]
		and name_set[depth].source.name ~= compare_to do
			depth= depth + 1
		end
		return depth
	end
	local function get_last_name(name_set)
		return name_set[#name_set].names[1]
	end
	local sub_search_reports= {}
	local match_last_name= get_last_name(match_item.name_set)
	local not_in= ""
	for i, item in ipairs(set) do
		if item.contents then
			-- TODO:  This probably doesn't work right if a sort_factor occurs
			-- multiple times in the list of sort_factors passed to bucket_sort.
			local depth= find_same_source_depth(
				match_item.name_set, get_bucket_source(item))
			local names= match_item.name_set[depth]
			local reason= ""
			local in_bucket= false
			if names then
				names= names.names
				local con_range= item.contents_name_range
				if con_range then
					local con_depth= find_same_source_depth(
						match_item.name_set, con_range[1].source.name)
					local con_names= match_item.name_set[con_depth]
					if con_names then
						con_names= con_names.names
						in_bucket= cmp_names_to_range_begin(con_names, con_range[1].value)
							and cmp_names_to_range_end(con_names, con_range[2].value)
						reason= "range(" .. con_names[1] .. " in " ..
							con_range[1].value .. ", " .. con_range[2].value .. ")"
					else
						reason= "range(no source)"
					end
				else
					in_bucket= cmp_names_to_single_name(names, item.name.value)
					reason= "single(" .. item.name.value .. ")"
				end
			else
				reason= "no source"
			end
			local name_reason= item.name.value .. ": " .. reason
			if in_bucket then
--				Trace(item.name.value .. ": inside(): " .. reason)
				local sub_ret= {bucket_search_for_item(item.contents, match_item)}
				if sub_ret[1] == -1 then
--					Trace("not inside")
				else
					return i, unpack(sub_ret)
				end
			else
--				Trace(name_reason)
				if not_in == "" then
					not_in= name_reason
				else
					not_in= not_in .. ", " .. name_reason
				end
			end
		else
--			Trace("match(" .. match_last_name .. ", " ..
--							get_last_name(item.name_set) .. ")")
			if match_last_name == get_last_name(item.name_set) then
				return i
			end
		end
	end
	return -1, "Not in set:  ", not_in
end

-- bucket_traverse params:
-- (
--   set= {bucket, ...} -- the set of buckets returned by bucket_sort
--   per_bucket= function, -- called on each bucket, optional
--   per_item= function, -- called on each item, optional
--   depth= number, -- for internal use, passed to callbacks.
-- )
function bucket_traverse(set, per_bucket, per_item, depth)
	if not per_bucket and not per_item then return end
	per_bucket= per_bucket or noop_nil
	per_item= per_item or noop_nil
	depth= depth or 1
	local indent= ("  "):rep(depth)
	for i, bucket in ipairs(set) do
		if bucket.contents then
			per_bucket(bucket, depth)
			if per_bucket == bucket_print then
				Trace(indent .. "{")
			end
			bucket_traverse(bucket.contents, per_bucket, per_item, depth + 1)
			if per_bucket == bucket_print then
				Trace(indent .. "}")
			end
		else
			local new_item= per_item(bucket, depth)
			if new_item then set[i]= new_item end
		end
	end
end

-- bucket_brute_search params:
-- (
--   set= {bucket, ...} -- the set of buckets returned by bucket_sort
--   match_element= element,
--   final_compare= function, -- passed a candidate element and match_element
--     to determine if the candidate matches.
-- )
function bucket_brute_search(set, match_element, final_compare)
	for i, bucket in ipairs(set) do
		if bucket.contents then
			local sub_ret= {
				bucket_brute_search(bucket.contents, match_element, final_compare)}
			if sub_ret[1] ~= -1 then
				return i, unpack(sub_ret)
			end
		else
			if final_compare(bucket.el, match_element) then
				return i
			end
		end
	end
	return -1
end

function bucket_disp_name(bucket)
	if bucket.name.disp then
		return bucket.name.disp
	elseif bucket.from_split then
		return bucket.contents_name_range[1].value .. "..." ..
			bucket.contents_name_range[2].value
	elseif bucket.combined_name_range then
		return bucket.combined_name_range[1].value .. "..." ..
			bucket.combined_name_range[2].value
	else
		return bucket.name.value
	end
end

local function source_name(sf)
	return sf.name or tostring(sf)
end

function item_name_str(name)
	return "(" .. source_name(name.source) .. "): '" ..
		table.concat(name.names, "', '") .. "'"
end

function item_print(item, depth)
	do return end
	local indent= ("  "):rep(depth)
	if #item.name_set > 1 then
		Trace(indent .. "Names:")
		for i, name in ipairs(item.name_set) do
			Trace(indent .. "  " .. item_name_str(name))
		end
	else
		Trace(indent .. "Name: " .. item_name_str(item.name_set[1]))
	end
end

function bucket_long_name(name)
	return "'" .. name.value .. "' (" .. tostring(name.disp) .. ") (" ..
		source_name(name.source) .. ")"
end

local function bool_str(b, name)
	if b[name] then return name end
	return "not " .. name
end

function bucket_print(bucket, depth)
	local indent= ("  "):rep(depth)
	Trace(indent .. "Name: " .. bucket_name_str(bucket.name))
	if bucket.contents_name_range then
		Trace(indent .. "Contents range:")
		Trace(indent .. "  " .. bucket_long_name(bucket.contents_name_range[1]))
		Trace(indent .. "  " .. bucket_long_name(bucket.contents_name_range[2]))
	end
	Trace(indent .. #bucket.contents .. " items.")
	Trace(indent .. bool_str(bucket, "sorted") .. ", " ..
					bool_str(bucket, "from_adduns") .. ", " ..
					bool_str(bucket, "from_split") .. ", " ..
					bool_str(bucket, "from_similar"))
end

function bucket_tree_print(set)
	bucket_traverse(set, bucket_print, item_print)
end

function generate_song_sort_test_data(sort_factors)
	local song_data= {}
	for si, sf in pairs(sort_factors) do
		if sf.pre_sort_func then sf.pre_sort_func(sf.pre_sort_arg) end
		for i, song in ipairs(SONGMAN:GetAllSongs()) do
			local data= song_data[i] or {}
			data[sf.name or tostring(sf)]= sf.get_names(song)
			song_data[i]= data
		end
	end
	local test_sorts= {}
	for si, sf in pairs(sort_factors) do
		local sf_name= sf.name or tostring(sf)
		test_sorts[#test_sorts+1]=
			"{name= \"" .. sf_name .. "\",\n" ..
			"get_names= function(el)\n" ..
			"	return el[\"" .. sf_name .. "\"]\n" ..
			"end,\n" ..
			-- can_join not saved because it can't be.
			"uses_depth= " .. tostring(sf.uses_depth) .. ",\n" ..
			"insensitive_names= " .. tostring(sf.insensitive_names) .. ",\n" ..
			"group_similar= " .. tostring(sf.group_similar) .. ",\n" ..
			"dont_clip= " .. tostring(sf.dont_clip) .. "},\n"
	end
	local file_handle= RageFileUtil.CreateRageFile()
	local file_name= "Save/consensual_settings/test_song_sort_data.lua"
	if not file_handle:Open(file_name, 2) then
		Trace("Could not open '" .. file_name .. "' to write test song sort data.")
	else
		file_handle:Write("return {\n")
		for i, song in ipairs(song_data) do
			file_handle:Write(lua_table_to_string(song) .. ",\n")
		end
		file_handle:Write("},\n{\n")
		for i, sort in ipairs(test_sorts) do
			file_handle:Write(sort)
		end
		file_handle:Write("}\n")
		file_handle:Close()
		file_handle:destroy()
		lua.ReportScriptError("test song sort data written to '" .. file_name .. "'")
	end
end
