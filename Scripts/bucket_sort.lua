local min_bucket_size= 32
local max_bucket_size= 96

local function name_sub(e)
	if type(e) == "string" then
		return e:sub(1, 5)
	else
		return e
	end
end

local function to_cmp(a, final_name)
	return a and (a.name or final_name(a))
end

local function cmp_cmp(a, b)
	if a then
		if b then
			if type(a) == type(b) then
				return a < b
			else
				return true
			end
		else
			return true
		end
	else
		return false
	end
end

local function split_set(set, get_bucket, depth)
	if #set < 2 then return set end
	assert(get_bucket)
	depth= depth or 1
	local buckets= {}
	for i, v in ipairs(set) do
		local bi= get_bucket(v, depth)
		if not buckets[bi] then
			buckets[bi]= {}
		end
		local new_index= #buckets[bi]+1
		buckets[bi][new_index]= v
	end
	return buckets
end

local function split_bucket(buckets, get_name)
	local num_subs= math.ceil(#buckets / max_bucket_size)
	local sub_size= #buckets / num_subs
	local floor_size= math.floor(sub_size)
	local size_fraction= sub_size - floor_size
	local curr_fraction= size_fraction
	local sub_buckets= {}
	local next_bucket= 1
	for n= 1, num_subs do
		if buckets[next_bucket] then
			local sub= {}
			local sub_combined= {}
			local last_bucket= next_bucket + floor_size + math.floor(curr_fraction) - 1
			if n == num_subs then
				last_bucket= #buckets
			end
			for i= next_bucket, last_bucket do
				if buckets[i] then
					if buckets[i].combined_buckets then
						for sck, scv in ipairs(buckets[i].combined_buckets) do
							sub_combined[#sub_combined+1]= scv
						end
					elseif buckets[i].name then
						sub_combined[#sub_combined+1]= buckets[i].name
					elseif get_name then
						sub_combined[#sub_combined+1]= get_name(buckets[i], -1)
					end
					sub[#sub+1]= buckets[i]
				end
			end
			next_bucket= last_bucket + 1
			local sub_name= n
			if sub[1].name and sub[#sub].name then
				sub_name= name_sub(sub[1].name) .. "..." .. name_sub(sub[#sub].name)
			end
			sub_buckets[#sub_buckets+1]= {
				name= sub_name, disp_name= sub_name, contents= sub,
				combined_buckets= sub_combined }
			if curr_fraction >= 1 then curr_fraction= curr_fraction - 1 end
			curr_fraction= curr_fraction + size_fraction
		end
	end
	return sub_buckets
end

function combine_buckets(a, b, final_name)
	function agnostic_compare(a, b)
		return cmp_cmp(to_cmp(a, final_name), to_cmp(b, final_name))
	end
	if not a.sorted then
		table.sort(a.contents, agnostic_compare)
		a.sorted= true
	end
	if not b.sorted then
		table.sort(b.contents, agnostic_compare)
		b.sorted= true
	end
	a.disp_name= name_sub(a.disp_name) .. "..." .. name_sub(b.disp_name)
	if not a.combined_buckets then a.combined_buckets= { a.name } end
	if b.combined_buckets then
		for i, v in ipairs(b.combined_buckets) do
			a.combined_buckets[#a.combined_buckets+1]= v
		end
	else
		a.combined_buckets[#a.combined_buckets+1]= b.name
	end
	local merged= {}
	local acon= a.contents
	local bcon= b.contents
	local aindex, bindex= 1, 1
	while aindex <= #acon or bindex <= #bcon do
		local ael= acon[aindex]
		local bel= bcon[bindex]
		if cmp_cmp(to_cmp(ael, final_name), to_cmp(bel, final_name)) then
			merged[#merged+1]= ael
			aindex= aindex + 1
		else
			merged[#merged+1]= bel
			bindex= bindex + 1
		end
	end
	a.contents= merged
end

local function combine_too_small_buckets(buckets, can_join, final_name)
	function agnostic_compare(a, b)
		return cmp_cmp(to_cmp(a, final_name), to_cmp(b, final_name))
	end
	can_join= can_join or function() return true end
	local i= 1
	while i <= #buckets do
		local v= buckets[i]
		local combined= false
		local should_not_break= true
		if v and not v.sorted then
			table.sort(v.contents, agnostic_compare)
			v.sorted= true
		end
		while v and #v.contents < min_bucket_size and should_not_break do
			local left_neighbor= buckets[i-1]
			local right_neighbor= buckets[i+1]
			local used_neighbor= 0
			local can_use_left= left_neighbor and can_join(left_neighbor) and
				#left_neighbor.contents + #v.contents < max_bucket_size
			local can_use_right= right_neighbor and can_join(right_neighbor) and
				#right_neighbor.contents + #v.contents < max_bucket_size
			if can_use_left then
				if can_use_right then
					if #left_neighbor.contents < #right_neighbor.contents then
						used_neighbor= -1
					else
						used_neighbor= 1
					end
				else
					used_neighbor= -1
				end
			elseif can_use_right then
				used_neighbor= 1
			end
			local switch= {
				[-1]= function()
								combine_buckets(left_neighbor, v, final_name)
								table.remove(buckets, i)
								v= buckets[i]
							end,
				[0]= function() should_not_break= false end,
				[1]= function()
							 combine_buckets(v, right_neighbor, final_name)
							 table.remove(buckets, i+1)
							 v= buckets[i]
						 end
			}
			switch[used_neighbor]()
		end
		if not combined then
			i= i + 1
		end
	end
end

local function split_too_large_buckets(real_buckets, params)
	params.depth= params.depth or 1
	local main= params.main
	local fallback= params.fallback
	local can_join= params.can_join
	local main_depth= main.depth
	local i= 1
	while i <= #real_buckets do
		local v= real_buckets[i]
		if #v.contents > max_bucket_size then
			if main_depth and #real_buckets > 1 then
				v.contents= bucket_sort{
					set= v.contents, main= main, fallback= fallback,
					can_join= can_join, depth= params.depth + 1}
			elseif fallback then
				v.contents= bucket_sort{
					set= v.contents, main= fallback, fallback= nil,
					can_join= can_join, depth= 1}
			else
				local get_name= (fallback and fallback.get_bucket) or main.get_bucket
				v.contents= split_bucket(v.contents, get_name)
			end
		end
		i= i + 1
	end
end

local function split_string_to_words(s)
	local words= {}
	local cur_word_start= 1
	for i= 1, #s do
		local c= s:sub(i, i)
		if c == " " or c == "_" then
			words[#words+1]= s:sub(cur_word_start, i-1)
			cur_word_start= i+1
			-- Yeah, this doesn't handle double space conditions well.
		end
	end
	words[#words+1]= s:sub(cur_word_start)
	return words
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

local function group_similar_buckets(real_buckets)
	local min_similarity= 3 -- the number of identical initial chars required
	local i= 2
	function rename_grouped_buckets(group)
		local shared_len= #group.name + 2
		for i, b in ipairs(group.contents) do
			local new_name= b.disp_name:sub(shared_len)
			if new_name == "" then new_name= "1" end
			b.disp_name= new_name
		end
	end
	while i <= #real_buckets do
		local pre_buck= real_buckets[i-1]
		local buck= real_buckets[i]
		local sim= get_initial_similarity(pre_buck.name, buck.name)
		local grouped= false
		if #sim >= min_similarity then
			grouped= true
			if pre_buck.is_grouped_buckets then
				pre_buck.name= sim
				pre_buck.disp_name= sim
				pre_buck.contents[#pre_buck.contents+1]= buck
				pre_buck.combined_buckets[#pre_buck.combined_buckets+1]= buck.name
				table.remove(real_buckets, i)
			else
				local grouped_buckets= {
					name= sim, disp_name= sim, is_grouped_buckets= true,
					contents= {pre_buck, buck},
					combined_buckets= {pre_buck.name, buck.name}}
				real_buckets[i-1]= grouped_buckets
				table.remove(real_buckets, i)
			end
		else
			if pre_buck.is_grouped_buckets then
				rename_grouped_buckets(pre_buck)
			end
		end
		if not grouped then
			i= i + 1
		end
	end
	if #real_buckets > 0 and real_buckets[#real_buckets].is_grouped_buckets then
		rename_grouped_buckets(real_buckets[#real_buckets])
	end
end

-- params example:
-- { set= {},
--   main= { get_bucket= function, depth= bool, group_similar= bool },
--   fallback= { identical to main },
--   can_join= function, depth= number
-- }
-- If set is too small or nil, or main is nil, set is returned.
-- main.get_bucket is a function that takes an element or bucket and returns
--   what bucket that element belongs in.  If it uses the depth argument, it
--   must accept -1 to indicate the maximum depth.
-- main.depth is whether main.get_bucket actually uses the depth
-- main.group_similar is whether buckets with names that start with the
--   same sequence should be placed into a bucket together.
-- fallback is an alternative to main, used when main doesn't seperate
--   elements enough.  fallback may be nil
-- can_join is a function that will be passed a bucket to divine whether
--   that bucket can be combined with another bucket.
-- can_join is only used if non-nil
-- depth is for internal use and is passed to the get_bucket functions
-- Limitations:
--   Do not pass in anything with "name", "disp_name", or "contents" members.
--   These are used to identify whether the thing being handled is a bucket.
function bucket_sort(params)
	params.depth= params.depth or 1
	local set= params.set
	local main= params.main
	local fallback= params.fallback
	local can_join= params.can_join
	if not set or not main then return set end
	local buckets= split_set(set, main.get_bucket, params.depth)
	local real_buckets= {}
	for k, v in pairs(buckets) do
		local new_bucket= { name= k, disp_name= k, contents= v }
		real_buckets[#real_buckets+1]= new_bucket
	end
	local final_name= (fallback and fallback.get_bucket) or main.get_bucket
	local function bucket_cmp(a, b)
		if type(a.name) ~= type(b.name) then
			return tostring(a.name) < tostring(b.name)
		end
		return a.name < b.name
	end
	table.sort(real_buckets, bucket_cmp)
	split_too_large_buckets(real_buckets, params)
	combine_too_small_buckets(real_buckets, can_join, final_name)
	if params.main.group_similar then
		group_similar_buckets(real_buckets)
	end
	if #real_buckets > max_bucket_size then
		local get_name= (fallback and fallback.get_bucket) or main.get_bucket
		real_buckets= split_bucket(real_buckets, get_name)
	end
	return real_buckets
end

-- params example:
-- { set= {}, main= { get_bucket= function, depth= bool },
--   fallback= { get_bucket= function, depth= bool },
--   final_compare= function, match_element= element
-- }
-- These must be the same params that were passed to the bucket_sort function.
--   Otherwise, the search will fail or go to the wrong place.
-- set is the set of buckets that was returned by bucket_sort.
-- main.get_bucket is a function that takes an element or bucket and returns
--   what bucket that element belongs in.
-- main.depth is whether main.get_bucket actually uses the depth
-- fallback is an alternative to main, used when main doesn't seperate
--   elements enough.  fallback may be nil
-- final_compare is a function that will be used to compare elements to
--   match_element when the bottom layer of buckets is reached.
-- match_element is the element that will be passed to the get_bucket functions
--   to determine which bucket the element being searched for fell into.
function bucket_search(params)
	local set= params.set
	local main= params.main
	local fallback= params.fallback
	local final_compare= params.final_compare
	local match_element= params.match_element
	if not set or not main or not final_compare or not match_element
	then return -1 end
	for i, v in ipairs(set) do
		if v.combined_buckets then
			for ck, cv in ipairs(v.combined_buckets) do
				if main.get_bucket(
					match_element, (type(cv) == "string" and #cv) or -1) == cv then
					local sub_params= {
						set= v.contents, main= main, fallback= fallback,
						final_compare= final_compare, match_element= match_element }
					local sub_ret= { bucket_search(sub_params) }
					if sub_ret[1] ~= -1 then
						return i, unpack(sub_ret)
					end
				end
			end
		elseif v.name then
			if main.get_bucket(
				match_element, (type(v.name) == "string" and #v.name) or -1) == v.name then
				local sub_params= {
					set= v.contents, main= main, fallback= fallback,
					final_compare= final_compare, match_element= match_element }
				local sub_ret= { bucket_search(sub_params) }
				if sub_ret[1] ~= -1 then
					return i, unpack(sub_ret)
				end
			end
		else
			if final_compare(v, match_element) then
				return i
			end
		end
	end
	if fallback then
		local sub_params= {
			set= set, main= fallback, fallback= nil, final_compare= final_compare,
			match_element= match_element }
		return bucket_search(sub_params)
	end
	-- This is not an error situation, false leads are possible.
	return -1
end

-- params example:
-- { set= {}, per_element= function, depth= number }
-- set is the set returned by bucket_sort, or any sub bucket.
-- per_element is a function that will be called with every element
-- Example per_element:
--   function per_element(element, depth)
--     if depth < 2 then
--       cool_elements.add(element)
--     end
--   end
-- depth is how deep in the traverse this function is.
function bucket_traverse(params)
	local per_element= params.per_element or function() end
	local depth= params.depth or 1
	local bucket= params.set
	if bucket.contents then bucket= bucket.contents end
	for i, v in ipairs(bucket) do
		if v.contents then
			bucket_traverse{
				set= v.contents, per_element= per_element, depth= depth + 1}
		else
			per_element(v, depth)
		end
	end
end
