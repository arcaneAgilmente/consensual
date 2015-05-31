local config_data= steps_menu_config:get_data()
local center_text_zoom= config_data.center_text_zoom
local item_text_zoom= config_data.item_text_zoom
local center_radius= config_data.center_radius
local item_radius= config_data.item_radius
local item_pad= config_data.item_pad
local item_focus_zoom= config_data.item_focus_zoom
local xoff= config_data.xoff
local yoff= config_data.yoff
local item_move_time= .1
local text_color= fetch_color("music_select.steps_selector.number_color")
local text_stroke= fetch_color("music_select.steps_selector.number_stroke")
local pick_song_color= fetch_color("music_select.steps_selector.pick_song")
local pick_steps_type_color= fetch_color("music_select.steps_selector.pick_steps_type")
local pick_song_text= get_string_wrapper("StepsDisplayList", "pick_song")
local pick_steps_type_tex= get_string_wrapper("StepsDisplayList", "pick_steps_type")
local pick_song_short= get_string_wrapper("StepsDisplayList", "pick_song_short")
local pick_steps_type_short= get_string_wrapper("StepsDisplayList", "pick_steps_type_short")

local item_circle_radius= 0
local items= 0
local cursor_radius= 0
local center_text_width= 0
local pn_side_signs= {[PLAYER_1]= 1, [PLAYER_2]= -1}

local function recalc_dependent_sizes()
	item_circle_radius= center_radius + item_radius + item_pad
	items= (item_circle_radius * math.pi*2) / ((item_radius*2) + item_pad)
	cursor_radius= item_radius * item_focus_zoom / hollow_circle_inner_zoom
	center_text_width= center_radius*.75
end
recalc_dependent_sizes()

local enable_configuring= false

local config_functions= {
	DeviceButton_a= function()
		center_text_zoom= center_text_zoom - .1
	end,
	DeviceButton_s= function()
		center_text_zoom= center_text_zoom + .1
	end,
	DeviceButton_z= function()
		item_text_zoom= item_text_zoom - .1
	end,
	DeviceButton_x= function()
		item_text_zoom= item_text_zoom + .1
	end,
	DeviceButton_d= function()
		center_radius= center_radius - 1
	end,
	DeviceButton_f= function()
		center_radius= center_radius + 1
	end,
	DeviceButton_c= function()
		item_radius= item_radius - 1
	end,
	DeviceButton_v= function()
		item_radius= item_radius + 1
	end,
	DeviceButton_g= function()
		item_pad= item_pad - 1
	end,
	DeviceButton_h= function()
		item_pad= item_pad + 1
	end,
	DeviceButton_b= function()
		item_focus_zoom= item_focus_zoom - .1
	end,
	DeviceButton_n= function()
		item_focus_zoom= item_focus_zoom + .1
	end,
	DeviceButton_j= function()
		xoff= xoff - 1
	end,
	DeviceButton_k= function()
		xoff= xoff + 1
	end,
	DeviceButton_m= function()
		yoff= yoff - 1
	end,
	DeviceButton_comma= function()
		yoff= yoff + 1
	end,
	DeviceButton_1= function()
		config_data.center_text_zoom= center_text_zoom
		config_data.item_text_zoom= item_text_zoom
		config_data.center_radius= center_radius
		config_data.item_radius= item_radius
		config_data.item_pad= item_pad
		config_data.item_focus_zoom= item_focus_zoom
		config_data.xoff= xoff
		config_data.yoff= yoff
		steps_menu_config:set_dirty()
		steps_menu_config:save()
	end
}

local item_mt= {
	__index= {
		create_actors= function(self, name)
			self.name= name
			return Def.ActorFrame{
				Name= name, InitCommand= function(subself)
					self.container= subself
					self.text= subself:GetChild("text")
				end,
				Def.Sprite{
					Texture= "big_circle", InitCommand= function(subself)
						self.spr= subself
						subself:zoom(item_radius*2/big_circle_size)
					end
				},
				normal_text(
					"text", "", text_color, text_stroke, 0, 0, item_text_zoom),
			}
		end,
		reload_config= function(self)
			self.spr:zoom(item_radius*2/big_circle_size)
			self.text:zoom(item_text_zoom)
		end,
		transform= function(self, item_index, num_items, is_focus, focus_pos)
			local angle_per= math.pi * 2 / items
			local angle= angle_per * (item_index - focus_pos) - (math.pi * .5)
			local radius= item_circle_radius
			self.container:finishtweening():linear(item_move_time)
				:xy(math.cos(angle) * radius, math.sin(angle) * radius)
			if is_focus then
				self.container:zoom(item_focus_zoom)
			else
				self.container:zoom(1)
			end
		end,
		set= function(self, info)
			self.info= info
			if not info then
				self.container:visible(false)
				return
			end
			self.container:visible(true)
			if info[1] == "pick_song" then
				self.spr:diffuse(pick_song_color)
				self.text:settext(pick_song_short)
			elseif not info.diff then
				self.spr:diffuse(pick_steps_type_color)
				self.text:settext(info.count or pick_steps_type_short)
			else
				self.spr:diffuse(diff_to_color(info.diff))
				self.text:settext(info[1])
			end
		end
}}

local icon_scale= misc_config:get_data().cursor_button_icon_size
local icon_xoffset= cursor_radius + 2 + (8 * icon_scale)
local icon_yoffset= cursor_radius * 0
local function button_icon(path, side_sign, name)
	if not path or path == "" then return Def.Actor{} end
	return Def.Sprite{
		Name= name, Texture= path, InitCommand= function(self)
			scale_to_fit(self, 16 * icon_scale, 16 * icon_scale)
			self:xy(side_sign * icon_xoffset, -item_circle_radius - icon_yoffset)
				:vertalign(bottom)
				:diffuseshift():effectcolor1({1, 1, 1, 1}):effectcolor2({1, 1, 1, 0})
		end,
		reload_configCommand= function(self)
			scale_to_fit(self, 16 * icon_scale, 16 * icon_scale)
			self:xy(side_sign * icon_xoffset, -item_circle_radius - icon_yoffset)
		end
	}
end

steps_menu_mt= {
	__index= {
		create_actors= function(self, x, y, pn)
			self.pn= pn
			self.sick_wheel= setmetatable({disable_repeating= true}, sick_wheel_mt)
			self.orig_x= x
			self.orig_y= y
			local buttons= {{[2]= "MenuLeft"}, {[2]= "MenuRight"}}
			reverse_button_list(buttons)
			local left_path= THEME:GetPathG(
				"", "button_icons/"..buttons[1][2]..".png", true)
			local right_path= THEME:GetPathG(
				"", "button_icons/"..buttons[2][2]..".png", true)
			return Def.ActorFrame{
				InitCommand= function(subself)
					self.container= subself
					self.text= subself:GetChild("text")
					self.text:vertspacing(-8)
						:wrapwidthpixels(center_text_width/center_text_zoom)
					subself:xy(x+(xoff*pn_side_signs[pn]), y+yoff):visible(false)
					self.bl= subself:GetChild("bl")
					self.sa= subself:GetChild("sa")
				end,
				self.sick_wheel:create_actors("wheel", items, item_mt, 0, 0),
				Def.Sprite{
					Texture= "big_circle", InitCommand= function(subself)
						self.spr= subself
						subself:zoom(center_radius*2/big_circle_size)
					end
				},
				Def.Sprite{
					Texture= "hollow_circle", InitCommand= function(subself)
						self.cursor= subself
						subself:zoom(cursor_radius*2/big_circle_size)
							:xy(0, -item_circle_radius)
							:diffuse(pn_to_color(pn))
					end
				},
				normal_text(
					"text", "", text_color, text_stroke, 0, 0, center_text_zoom),
				button_icon(left_path, -1, "bl"),
				button_icon(right_path, 1, "sa"),
			}
		end,
		reload_config= function(self)
			recalc_dependent_sizes()
			self.container:xy(self.orig_x+(xoff*pn_side_signs[self.pn]), self.orig_y+yoff)
			self.text:wrapwidthpixels(center_text_width/center_text_zoom)
				:zoom(center_text_zoom)
			self.spr:zoom(center_radius*2/big_circle_size)
			self.cursor:zoom(cursor_radius*2/big_circle_size)
				:xy(0, -item_circle_radius)
			self.bl:playcommand("reload_config")
			self.sa:playcommand("reload_config")
			for i, item in ipairs(self.sick_wheel.items) do
				item:reload_config()
			end
			self.sick_wheel:scroll_to_pos(self.curr_choice)
		end,
		activate= function(self)
			self.container:visible(true)
			self.needs_deactivate= false
			self.steps_list= sort_steps_list(get_filtered_steps_list())
			self.steps_type_list= {}
			self.steps_by_type= {}
			for i, steps in ipairs(self.steps_list) do
				local steps_type= steps:GetStepsType()
				insert_into_sorted_table(self.steps_type_list, steps_type)
				if not self.steps_by_type[steps_type] then
					self.steps_by_type[steps_type]= {steps}
				else
					table.insert(self.steps_by_type[steps_type], steps)
				end
			end
			local pref_steps_type= get_preferred_steps_type(self.pn)
			if pref_steps_type == "" or #self.steps_type_list == 1
			or not self.steps_by_type[pref_steps_type] then
				self.chosen_steps_type= self.steps_type_list[1]
			else
				self.chosen_steps_type= pref_steps_type
			end
			self:change_to_pick_steps()
		end,
		deactivate= function(self)
			self.container:visible(false)
		end,
		change_to_pick_steps= function(self)
			self.curr_choice= 1
			self.choices= {}
			self.chosen_steps= nil
			if #self.steps_type_list > 1 then
				self.choices[1]= {"pick_steps_type"}
			else
				self.choices[1]= {"pick_song"}
			end
			local player_steps= gamestate_get_curr_steps(self.pn)
			for i, steps in ipairs(self.steps_by_type[self.chosen_steps_type]) do
				local met= steps:GetMeter()
				local diff= steps:GetDifficulty()
				self.choices[#self.choices+1]= {
					tostring(met), diff= diff, met= met, steps= steps}
				if steps == player_steps then
					self.curr_choice= #self.choices
				end
			end
			self.sick_wheel:set_info_set(self.choices, 1)
			self:update_selection()
		end,
		change_to_pick_steps_type= function(self)
			self.curr_choice= 1
			self.choices= {}
			self.choices[1]= {"pick_song"}
			for i, steps_type in ipairs(self.steps_type_list) do
				self.choices[#self.choices+1]= {steps_type,
					count= #self.steps_by_type[steps_type], steps_type= steps_type}
			end
			self.sick_wheel:set_info_set(self.choices, 1)
			self:update_selection()
		end,
		update_selection= function(self)
			local choice= self.choices[self.curr_choice]
			self.sick_wheel:scroll_to_pos(self.curr_choice)
			if choice[1] == "pick_song" then
				self.spr:diffuse(pick_song_color)
				self.text:settext(pick_song_text)
			elseif not choice.diff then
				self.spr:diffuse(pick_steps_type_color)
				if choice.steps_type then
					self.text:settext(get_string_wrapper("StepsTypeNames", choice.steps_type))
				else
					self.text:settext(get_string_wrapper("StepsDisplayList", choice[1]))
				end
			else
				self.spr:diffuse(diff_to_color(choice.diff))
				local diff_text= ""
				if choice.diff == "Difficulty_Edit" then
					diff_text= choice.steps:GetDescription()
				else
					diff_text= get_string_wrapper("StepsDisplayList", choice.diff)
				end
				self.text:settext(
					get_string_wrapper("StepsTypeNames", self.chosen_steps_type)
						.. "\n" .. diff_text .. "\n" .. choice.met)
				cons_set_current_steps(self.pn, choice.steps)
			end
		end,
		interpret_code= function(self, code)
			local funs= {
				MenuLeft= function(self)
					self.curr_choice= self.curr_choice - 1
					if self.curr_choice < 1 then self.curr_choice= #self.choices end
					self:update_selection()
					return true
				end,
				MenuRight= function(self)
					self.curr_choice= self.curr_choice + 1
					if self.curr_choice > #self.choices then self.curr_choice= 1 end
					self:update_selection()
					return true
				end,
				Start= function(self)
					local choice= self.choices[self.curr_choice]
					if choice[1] == "pick_steps_type" then
						self:change_to_pick_steps_type()
					elseif choice[1] == "pick_song" then
						self.needs_deactivate= true
					else
						if choice.steps_type then
							self.chosen_steps_type= choice.steps_type
							set_preferred_steps_type(self.pn, choice.steps_type)
							self:change_to_pick_steps()
						elseif choice.steps then
							self.chosen_steps= choice.steps
						end
					end
					self:update_selection()
					return true
				end
			}
			if funs[code] then return funs[code](self) end
		end,
		interpret_key= function(self, key)
			if key == "DeviceButton_2" then
				enable_configuring= not enable_configuring
			end
			if not enable_configuring then return end
			if config_functions[key] then
				config_functions[key]()
				self:reload_config()
			end
		end,
}}
