-- Usage:
-- Use the following two lines to load this file on some screen.
--   local menu_path= THEME:GetPathO("", "options_menu.lua")
--   dofile(menu_path)
-- Then declare whatever special menus you need inside the options_sets table
-- options_sets.menu and options_sets.special_functions are provided as
--   examples and for general use.
-- After declaring the specialized menus, call set_option_set_metatables().
-- Create a table with option_display_mt as the metatable.
-- option_display_mt follows my convention for actor wrappers of having
--   create_actors, find_actors, and name.
-- After calling option_display_mt.find_actors, call
--   option_display_mt.set_underline_color if you are going to use the
--   underline feature.
-- option_display_mt is not meant to be controlled directly, instead it is
--   meant to be given to a menu to control.  Control commands should be sent
--   to the menu, and the menu will take care of manipulating the display.
-- See ScreenSickPlayerOptions for a complicated example.

local move_time= 0.1
local underline_offset= 12
local underline_thickness= 2
local line_height= 24

local option_item_mt= {
	__index= {
		create_actors=
			function(self, name)
				self.name= name
				self.zoom= 1
				self.width= SCREEN_WIDTH
				return Def.ActorFrame{
					Name= name,
					normal_text("text", "", nil, nil, nil, self.zoom),
					Def.Quad{
						Name= "underline", InitCommand= cmd(y,underline_offset;horizalign,left;SetHeight,underline_thickness)
					}
				}
			end,
		find_actors=
			function(self, container)
				self.container= container
				self.text= container:GetChild("text")
				self.underline= container:GetChild("underline")
				self.underline:horizalign(center)
				return true
			end,
		set_geo=
			function(self, width, height, zoom)
				self.width= width
				self.zoom= zoom
				self.height= height
				self.text:zoom(zoom)
			end,
		set_underline_color=
			function(self, color)
				self.underline:diffuse(color)
			end,
		transform=
			function(self, item_index, num_items, is_focus)
				local changing_edge=
					((self.prev_index == 1 and item_index == num_items) or
				 (self.prev_index == num_items and item_index == 1))
				if changing_edge then
					self.container:diffusealpha(0)
				end
				self.container:finishtweening()
				self.container:linear(move_time)
				self.container:xy(0, (item_index - 1) *
												(self.height or self.text:GetZoomedHeight()))
				self.container:linear(move_time)
				self.container:diffusealpha(1)
				self.prev_index= item_index
			end,
		set=
			function(self, info)
				self.info= info
				if info then
					self:set_text(info.text)
					self:set_underline(info.underline)
				else
					self.text:settext("")
					self:set_underline(false)
				end
			end,
		set_underline=
			function(self, u)
				if u then
					self.underline:accelerate(0.25)
					self.underline:zoom(1)
				else
					self.underline:decelerate(0.25)
					self.underline:zoom(0)
				end
			end,
		set_text=
			function(self, t)
				self.text:settext(get_string_wrapper("OptionNames", t))
				width_limit_text(self.text, self.width, self.zoom)
				self.underline:SetWidth(self.text:GetZoomedWidth())
			end,
}}

option_display_mt= {
	__index= {
		create_actors=
			function(self, name, x, y, el_count, el_width, el_height, el_zoom, no_heading, no_display)
				self.name= name
				self.el_width= el_width or SCREEN_WIDTH
				self.el_height= el_height or 24
				self.el_zoom= el_zoom or 1
				self.no_heading= no_heading
				self.no_display= no_display
				local args= { Name= name, InitCommand= cmd(xy, x, y) }
				local next_y= 0
				if not no_heading then
					args[#args+1]= normal_text("heading", "")
					next_y= next_y + line_height
				end
				if not no_display then
					args[#args+1]= normal_text("display", "", nil, 0, line_height)
					next_y= next_y + line_height
				end
				if (not no_heading) or (not no_display) then
					next_y= next_y + line_height * .5
				end
				self.sick_wheel= setmetatable({disable_wrapping= true}, sick_wheel_mt)
				args[#args+1]= self.sick_wheel:create_actors(
					el_count, option_item_mt, 0, next_y)
				return Def.ActorFrame(args)
			end,
		find_actors=
			function(self, container)
				self.container= container
				if not self.no_heading then
					self.heading= container:GetChild("heading")
				end
				if not self.no_display then
					self.display= container:GetChild("display")
				end
				self.sick_wheel:find_actors(container:GetChild(self.sick_wheel.name))
				for i, item in ipairs(self.sick_wheel.items) do
					item:set_geo(self.el_width, self.el_height, self.el_zoom)
				end
			end,
		set_underline_color=
			function(self, color)
				for i, item in ipairs(self.sick_wheel.items) do
					item:set_underline_color(color)
				end
			end,
		set_heading=
			function(self, h)
				if not self.no_heading then
					self.heading:settext(get_string_wrapper("OptionTitles", h))
					width_limit_text(self.heading, self.el_width, self.el_zoom)
				end
			end,
		set_display=
			function(self, d)
				if not self.no_display then
					self.display:settext(d)
					width_limit_text(self.display, self.el_width, self.el_zoom)
				end
			end,
		set_info_set=
			function(self, info, pos)
				self.sick_wheel:set_info_set(info, pos or 1)
				self:unhide()
			end,
		set_element_info=
			function(self, element, info)
				self.sick_wheel:set_element_info(element, info)
			end,
		get_element=
			function(self, element)
				return self.sick_wheel:get_items_by_info_index(element)[1]
			end,
		scroll=
			function(self, pos)
				self.sick_wheel:scroll_to_pos(pos)
			end,
		hide=
			function(self) self.hidden= true self.container:diffusealpha(0) end,
		unhide=
			function(self) self.hidden= false self.container:diffusealpha(1) end
}}

function up_element()
	return {text= "<--"}
end

local option_set_general_mt= {
	__index= {
		set_player_info=
			function(self, player_number)
				self.player_number= player_number
			end,
		set_display=
			function(self, display)
				self.display= display
				display:set_info_set(self.info_set, self.cursor_pos)
				self:set_status()
			end,
		set_status= function() end, -- This is meant to be overridden.
		can_exit=
			function(self)
				return self.cursor_pos == 1
			end,
		get_cursor_element=
			function(self)
				if self.display then
					return self.display:get_element(self.cursor_pos)
				else
					return nil
				end
			end,
		interpret_code=
			function(self, code)
				local funs= {
					up= function(self)
								if self.cursor_pos > 1 then
									self.cursor_pos= self.cursor_pos - 1
								else
									self.cursor_pos= #self.info_set
								end
								self.display:scroll(self.cursor_pos)
								return true
							end,
					down= function(self)
									if self.cursor_pos < #self.info_set then
										self.cursor_pos= self.cursor_pos + 1
									else
										self.cursor_pos= 1
									end
									self.display:scroll(self.cursor_pos)
									return true
								end,
					start= function(self)
									 if self.info_set[self.cursor_pos].text ==
										 up_element().text then
										 -- This position is the "up" element that moves the
										 -- cursor back up the options tree.
										 return false
									 end
									 if self.interpret_start then
										 local hand, extra= self:interpret_start()
										 if self.scroll_to_move_on_start then
											 local pos_diff= 1 - self.cursor_pos
											 self.cursor_pos= 1
											 self.display:scroll(self.cursor_pos)
										 end
										 return hand, extra
									 else
										 return false
									 end
								 end
				}
				local cabinet_funs= {
					menu_left= funs.up, menu_right= funs.down, start= funs.start
				}
				local use_funs= funs
				if use_cabinet_input() then
					use_funs= cabinet_funs
				end
				if use_funs[code] then return use_funs[code](self) end
				return false
			end
}}

options_sets= {}

-- MENU ENTRIES STRUCTURE
-- {}
--   name= string -- Name for the entry
--   args= {} -- Args to return to options_menu_mt to construct the new menu
--     meta= {} -- metatable for the submenu
--     args= {} -- extra args for the initialize function of the metatable
options_sets.menu= {
	__index= {
		initialize=
			function(self, player_number, initializer_args, no_up)
				self.menu_data= initializer_args
				self.name= initializer_args.name
				self.info_set= {}
				self.no_up= no_up
				if not no_up then
					self.info_set[#self.info_set+1]= up_element()
				end
				self.cursor_pos= 1
				for i, d in ipairs(initializer_args) do
					self.info_set[#self.info_set+1]= {text= d.name}
					if d.args and type(d.args) == "table" then
						d.args.name= d.name
					end
				end
			end,
		set_status=
			function(self)
				if self.display then
					self.display:set_heading(self.name or "")
					self.display:set_display("")
				end
			end,
		interpret_start=
			function(self)
				local data= self.menu_data[self.cursor_pos-1]
				if self.no_up then
					data= self.menu_data[self.cursor_pos]
				end
				if data then
					return true, data
				else
					Trace("options_sets.menu has no data at " .. self.cursor_pos-1)
					rec_print_table(self.menu_data)
					return false
				end
			end
}}

options_sets.special_functions= {
	-- element_set structure:
	-- element_set= {}
	--   {} -- info for one element
	--     name -- string for naming the element.
	--     init(player_number) -- called to init the element, returns bool.
	--     set(player_number) -- called when the element is set.
	--     unset(player_number) -- called when the element is unset.
	__index= {
		initialize=
			function(self, player_number, extra)
				self.name= extra.name
				self.cursor_pos= 1
				self.player_number= player_number
				self.element_set= extra.eles
				self.info_set= {up_element()}
				for i, el in ipairs(self.element_set) do
					self.info_set[#self.info_set+1]= {
						text= el.name, underline= el.init(player_number)}
				end
			end,
		set_status= function(self) self.display:set_heading(self.name) end,
		interpret_start=
			function(self)
				local ele_pos= self.cursor_pos - 1
				local ele_info= self.element_set[ele_pos]
				if ele_info then
					local is_info= self.info_set[self.cursor_pos]
					if is_info.underline then
						ele_info.unset(self.player_number)
					else
						ele_info.set(self.player_number)
					end
					is_info.underline= not is_info.underline
					self.display:set_element_info(self.cursor_pos, is_info)
					return true
				else
					return false
				end
			end
}}

options_sets.mutually_exclusive_special_functions= {
	__index= {
		initialize= options_sets.special_functions.__index.initialize,
		set_status= options_sets.special_functions.__index.set_status,
		interpret_start=
			function(self)
				local ret= options_sets.special_functions.__index.interpret_start(self)
				if ret then
					for i, info in ipairs(self.info_set) do
						if i ~= self.cursor_pos then
							if info.underline then
								info.underline= false
								self.display:set_element_info(i, info)
							end
						end
					end
				end
				return ret
			end
}}

local function find_scale_for_number(num, min_scale)
	local cv= math.round(num /10^min_scale) * 10^min_scale
	local prec= math.max(0, -min_scale)
	local cs= ("%." .. prec .. "f"):format(cv)
	local ret_scale= 0
	for n= 1, #cs do
		if cs:sub(-n, -n) ~= "0" then
			ret_scale= math.min(ret_scale, min_scale + (n-1))
		end
	end
	return ret_scale, cv
end

options_sets.adjustable_float= {
	__index= {
		initialize=
			function(self, player_number, extra)
				local function check_member(member_name)
					assert(self[member_name],
								 "adjustable_float '" .. self.name .. "' warning: " ..
									member_name .. " not provided.")
				end
				local function to_text_default(player_number, value)
					if value == -0 then return "0" end
					return tostring(value)
				end
				--Trace("adjustable_float extra:")
				--rec_print_table(extra)
				assert(extra, "adjustable_float passed a nil extra table.")
				self.name= extra.name
				self.cursor_pos= 1
				self.player_number= player_number
				self.reset_value= extra.reset_value or 0
				self.min_scale= extra.min_scale
				check_member("min_scale")
				self.scale= extra.scale or 0
				self.current_value= extra.initial_value(player_number) or 0
				if self.current_value ~= 0 then
					self.min_scale_used, self.current_value=
						find_scale_for_number(self.current_value, self.min_scale)
				end
				self.min_scale_used= math.min(self.scale, self.min_scale_used or 0)
				self.max_scale= extra.max_scale
				check_member("max_scale")
				self.set= extra.set
				check_member("set")
				self.validator= extra.validator or noop_true
				self.val_to_text= extra.val_to_text or to_text_default
				self.scale_to_text= extra.scale_to_text or to_text_default
				local scale_text= get_string_wrapper("OptionNames", "scale")
				self.pi_text= get_string_wrapper("OptionNames", "pi")
				self.info_set= {
					up_element(),
					{text= "+"..self.scale_to_text(self.player_number, 10^self.scale)},
					{text= "-"..self.scale_to_text(self.player_number, 10^self.scale)},
					{text= scale_text.."*10"}, {text= scale_text.."/10"},
					{text= "Round"}, {text= "Reset"}}
				self.menu_functions= {
					function() return false end, -- up element
					function() -- increment
						self:set_new_val(self.current_value + 10^self.scale)
						return true
					end,
					function() -- decrement
						self:set_new_val(self.current_value - 10^self.scale)
						return true
					end,
					function() -- scale up
						self:set_new_scale(self.scale + 1)
						return true
					end,
					function() -- scale down
						self:set_new_scale(self.scale - 1)
						return true
					end,
					function() -- round
						self:set_new_val(math.round(self.current_value))
						return true
					end,
					function() -- reset
						local new_scale, new_value=
							find_scale_for_number(self.reset_value, self.min_scale)
						self:set_new_scale(new_scale)
						self:set_new_val(new_value)
						return true
					end
				}
				if extra.is_angle then
					-- insert the pi option before the Round option.
					local pi_pos= #self.info_set-1
					local function pi_function()
						self.pi_exp= not self.pi_exp
						if self.pi_exp then
							self.info_set[6].text= "/"..self.pi_text
						else
							self.info_set[6].text= "*"..self.pi_text
						end
						self.display:set_element_info(6, self.info_set[6])
						self:set_new_val(self.current_value)
						return true
					end
					table.insert(self.info_set, pi_pos, {text= "*"..self.pi_text})
					table.insert(self.menu_functions, pi_pos, pi_function)
				end
			end,
		interpret_start=
			function(self)
				if self.menu_functions[self.cursor_pos] then
					return self.menu_functions[self.cursor_pos]()
				end
				return false
			end,
		set_status=
			function(self)
				if self.display then
					self.display:set_heading(self.name)
					local val_text=
						self.val_to_text(self.player_number, self.current_value)
					if self.pi_exp then
						val_text= val_text .. "*" .. self.pi_text
					end
					self.display:set_display(val_text)
				end
			end,
		set_new_val=
			function(self, nval)
				local raise= 10^-self.min_scale_used
				local lower= 10^self.min_scale_used
				local rounded_val= math.round(nval * raise) * lower
				if self.validator(rounded_val) then
					self.current_value= rounded_val
					if self.pi_exp then
						rounded_val= rounded_val * math.pi
					end
					self.set(self.player_number, rounded_val)
					self:set_status()
				end
			end,
		set_new_scale=
			function(self, nscale)
				if nscale >= self.min_scale and nscale <= self.max_scale then
					self.min_scale_used= math.min(nscale, self.min_scale_used)
					self.scale= nscale
					self.info_set[2].text= "+" .. self.scale_to_text(self.player_number, 10^nscale)
					self.info_set[3].text= "-" .. self.scale_to_text(self.player_number, 10^nscale)
					self.display:set_element_info(2, self.info_set[2])
					self.display:set_element_info(3, self.info_set[3])
				end
			end
}}

options_sets.enum_option= {
	__index= {
		initialize=
			function(self, player_number, extra)
				self.name= extra.name
				self.player_number= player_number
				self.enum_vals= {}
				self.info_set= { up_element() }
				self.cursor_pos= 1
				self.get= extra.get
				self.set= extra.set
				self.ops_obj= extra.obj_get(player_number)
				local cv= self:get_val()
				for i, v in ipairs(extra.enum) do
					self.enum_vals[#self.enum_vals+1]= v
					self.info_set[#self.info_set+1]= {text= v, underline= v == cv}
				end
			end,
		interpret_start=
			function(self)
				if self.cursor_pos > 1 then
					for i, info in ipairs(self.info_set) do
						if info.underline then
							info.underline= false
							self.display:set_element_info(i, info)
						end
					end
					self.info_set[self.cursor_pos].underline= true
					self.display:set_element_info(self.cursor_pos, self.info_set[self.cursor_pos])
					if self.ops_obj then
						self.set(self.ops_obj, self.enum_vals[self.cursor_pos-1])
					else
						self.set(self.enum_vals[self.cursor_pos-1])
					end
					self.display:set_display(self:get_val())
					return true
				else
					return false
				end
			end,
		get_val=
			function(self)
					if self.ops_obj then
						return self.get(self.ops_obj)
					else
						return self.get()
					end
			end,
		set_status=
			function(self)
				self.display:set_heading(self.name)
				self.display:set_display(self:get_val())
			end
}}

function set_option_set_metatables()
	for k, set in pairs(options_sets) do
		setmetatable(set.__index, option_set_general_mt)
	end
end
