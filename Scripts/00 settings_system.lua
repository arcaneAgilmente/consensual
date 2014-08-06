local settings_prefix= "/consensual_settings/"

local function slot_to_prof_dir(slot, reason)
	local prof_dir= "Save"
	if slot and slot ~= "ProfileSlot_Invalid" then
		prof_dir= PROFILEMAN:GetProfileDir(slot)
		if not prof_dir or prof_dir == "" then
			Warn("Could not fetch profile dir to " .. reason .. ".")
			return
		end
	end
	return prof_dir
end

local setting_mt= {
	__index= {
		init= function(self, name, file, default)
			self.name= name
			self.file= file
			self.default= default
			self.dirty_table= {}
			self.data_set= {}
			return self
		end,
		load= function(self, slot)
			slot= slot or "ProfileSlot_Invalid"
			local prof_dir= slot_to_prof_dir(slot, "read " .. self.name)
			if not prof_dir then
				self.data_set[slot]= DeepCopy(self.default)
			else
				local fname= prof_dir .. settings_prefix .. self.file
				if not FILEMAN:DoesFileExist(fname) then
					self.data_set[slot]= DeepCopy(self.default)
				else
					self.data_set[slot]= dofile(fname)
				end
			end
			return self.data_set[slot]
		end,
		get_data= function(self, slot)
			slot= slot or "ProfileSlot_Invalid"
			return self.data_set[slot] or self.default
		end,
		set_data= function(self, slot, data)
			slot= slot or "ProfileSlot_Invalid"
			self.data_set[slot]= data
		end,
		set_dirty= function(self, slot)
			slot= slot or "ProfileSlot_Invalid"
			self.dirty_table[slot]= true
		end,
		check_dirty= function(self, slot)
			slot= slot or "ProfileSlot_Invalid"
			return self.dirty_table[slot]
		end,
		clear_slot= function(self, slot)
			slot= slot or "ProfileSlot_Invalid"
			self.dirty_table[slot]= nil
			self.data_set[slot]= nil
		end,
		save= function(self, slot)
			slot= slot or "ProfileSlot_Invalid"
			if not self:check_dirty(slot) then return end
			local prof_dir= slot_to_prof_dir(slot, "write " .. self.name)
			if not prof_dir then return end
			local fname= prof_dir .. settings_prefix .. self.file
			local file_handle= RageFileUtil.CreateRageFile()
			if not file_handle:Open(fname, 2) then
				Warn("Could not open '" .. fname .. "' to write " .. self.name .. ".")
			else
				local output= "return " .. lua_table_to_string(self.data_set[slot])
				file_handle:Write(output)
				file_handle:Close()
				file_handle:destroy()
			end
		end,
		save_all= function(self)
			for slot, data in pairs(self.data_set) do
				self:save(slot)
			end
		end
}}

function create_setting(name, file, default)
	return setmetatable({}, setting_mt):init(name, file, default)
end

function write_str_to_file(str, fname, str_name)
	local file_handle= RageFileUtil.CreateRageFile()
	if not file_handle:Open(fname, 2) then
		Warn("Could not open '" .. fname .. "' to write " .. str_name .. ".")
	else
		file_handle:Write(str)
		file_handle:Close()
		file_handle:destroy()
	end
end
