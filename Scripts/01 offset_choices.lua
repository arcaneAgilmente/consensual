local default_config= {}

offset_config= create_setting("offset_config", "offset_config.lua", default_config, 0)
offset_config:load()

function sanity_check_offset_config()
	local data= offset_config:get_data()
	for k, v in pairs(data) do
		if type(v) ~= "number" then data[k]= nil end
	end
end

sanity_check_offset_config()

local function get_offset()
	return PREFSMAN:GetPreference("GlobalOffsetSeconds")
end

local function set_offset(off)
	PREFSMAN:SetPreference("GlobalOffsetSeconds", off)
end

function get_offset_menu()
	local eles= {}
	local function add_element(key, value)
		local name= key
		if type(key) == "number" then name= ("%.6f"):format(value) end
		eles[#eles+1]= {
			name= name, init= function() return math.abs(get_offset() - value) < 2^-10 end,
			set= function() set_offset(value) end,
			unset= noop_nil}
	end
	foreach_ordered(offset_config:get_data(), add_element)
	return {
		name= "offset_choice",
		meta= options_sets.mutually_exclusive_special_functions,
		args= {name= "offset_choice", eles= eles}, disallow_unset= true}
end

local offset_service_menu_mode= "edit"
local offset_edit_key= false
local offset_service_menu= false
local menu_choice_names= {
	change_to_edit= true, change_to_rename= true,
	change_to_remove= true, add_offset_choice= true,
}

local edit_offset_text_settings= {
	Question= get_string_wrapper("OffsetConfig", "edit_offset_prompt"),
	InitialAnswer= "",
	MaxInputLength= 16,
	Validate= function(answer, err)
		if not tonumber(answer) then
			return false, get_string_wrapper("OffsetConfig", "offset_must_number")
		end
		return true, ""
	end,
	OnOK= function(answer)
		offset_config:get_data()[offset_edit_key]= tonumber(answer) or 0
		offset_config:set_dirty()
		offset_service_menu:recall_init()
	end
}

local name_offset_text_settings= {
	Question= get_string_wrapper("OffsetConfig", "name_offset_prompt"),
	InitialAnswer= "",
	MaxInputLength= 16,
	Validate= function(answer, err)
		if menu_choice_names[answer] then
			return false, get_string_wrapper("OffsetConfig", "cant_be_choice_name")
		end
		return true, ""
	end,
	OnOK= function(answer)
		local offset_data= offset_config:get_data()
		local value= offset_data[offset_edit_key]
		if type(offset_edit_key) == "string" then
			offset_data[offset_edit_key]= nil
		else
			table.remove(offset_data, offset_edit_key)
		end
		local asnumber= tonumber(answer)
		if asnumber then
			if math.abs(asnumber - value) < 2^-10 then
				if type(offset_edit_key) == "string" then
					offset_data[#offset_data+1]= value
				end
			else
				asnumber= math.round(asnumber)
				if asnumber < 1 then asnumber= 1 end
				if asnumber > #offset_data+1 then asnumber= #offset_data+1 end
				table.insert(offset_data, asnumber, value)
			end
		else
			offset_data[answer]= value
		end
		offset_config:set_dirty()
		offset_service_menu:recall_init()
	end
}

function get_offset_service_menu()
	local offset_data= offset_config:get_data()
	local ret= {
		recall_init_on_pop= true,
		name= "offset_config",
		destructor= function(self)
			offset_config:save()
		end,
		special_handler= function(menu, data)
			if data.name == "change_to_edit" then
				offset_service_menu_mode= "edit"
				return {recall_init= true}
			elseif data.name == "change_to_rename" then
				offset_service_menu_mode= "rename"
				return {recall_init= true}
			elseif data.name == "change_to_remove" then
				offset_service_menu_mode= "remove"
				return {recall_init= true}
			elseif data.name == "add_offset_choice" then
				offset_config:set_dirty()
				offset_data[#offset_data+1]= 0
				return {recall_init= true}
			else
				offset_edit_key= data.key
				offset_service_menu= menu
				if offset_service_menu_mode == "edit" then
					edit_offset_text_settings.InitialAnswer=
						tostring(offset_data[offset_edit_key])
					SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
					SCREENMAN:GetTopScreen():Load(edit_offset_text_settings)
				elseif offset_service_menu_mode == "rename" then
					if type(offset_edit_key) == "string" then
						name_offset_text_settings.InitialAnswer= offset_edit_key
					else
						name_offset_text_settings.InitialAnswer=
							tostring(offset_data[offset_edit_key])
					end
					SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
					SCREENMAN:GetTopScreen():Load(name_offset_text_settings)
				elseif offset_service_menu_mode == "remove" then
					offset_config:set_dirty()
					offset_data[offset_edit_key]= nil
				end
				return {recall_init= true}
			end
		end,
		{name= "change_to_edit"},
		{name= "change_to_rename"},
		{name= "change_to_remove"},
		{name= "add_offset_choice"},
	}
	ret.status= get_string_wrapper(
		"OffsetConfig",
		({edit= "offset_edit_mode", rename= "offset_rename_mode",
			remove= "offset_remove_mode"})[offset_service_menu_mode])
	local function add_element(key, value)
		local name= key
		if type(key) == "number" then name= ("%.6f"):format(value) end
		ret[#ret+1]= {name= name, key= key}
	end
	foreach_ordered(offset_data, add_element)
	return ret
end
