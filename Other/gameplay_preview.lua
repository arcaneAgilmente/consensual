gameplay_preview_mt= {
	__index= {
		create_actors= function(self, x, y, w, h, scale, pn)
			self.pn= pn
			self.width= w
			self.height= h
			self.scale= scale
			local qw= _screen.cx
			local qh= _screen.h
			local function preview_update(frame, delta)
				self:per_frame_update(delta)
			end
			return Def.ActorFrame{
				InitCommand= function(subself)
					self.container= subself
					subself:xy(x, y):zoom(self.scale)
						:SetUpdateFunction(preview_update)
					self:hide()
					self:update_config()
				end,
				gameplay_conf_changedMessageCommand= function(subself, param)
					if param.pn ~= self.pn then return end
					self:update_config(param)
				end,
				quaid(0, qh/-2, qw, 2, {1, 0, 0, 1}),
				quaid(0, qh/2, qw, 2, {0, 1, 1, 1}),
				quaid(qw/-2, 0, 2, qh, {0, 0, 1, 1}),
				quaid(qw/2, 0, 2, qh, {1, 1, 0, 1}),
				quaid(0, 0, qw, 2, {1, 1, 1, 1}),
				quaid(0, 0, 2, qh, {1, 1, 1, 1}),
				Def.NewField{
					InitCommand= function(subself)
						self.field= subself
					end
				},
				Def.BitmapText{
					Font= "Common Normal", InitCommand= function(subself)
						self.pos_text= subself
					end
				},
			}
		end,
		per_frame_update= function(self, delta)
			if self.hidden then return end
			local song_pos= GAMESTATE:GetSongPosition()
			local music_seconds= song_pos:GetMusicSeconds()
			for i, col in ipairs(self.field:get_columns()) do
				col:set_curr_second(music_seconds)
			end
			self.pos_text:settextf("%.2f\n%.2f", song_pos:GetMusicSeconds(), song_pos:GetSongBeat())
		end,
		update_field= function(self)
			local fx, fy= rec_calc_actor_pos(self.field)
			apply_newfield_config(self.field, self.field_config, fx, fy)
			for i, col in ipairs(self.field:get_columns()) do
				col:set_use_game_music_beat(false):set_pixels_visible_after(768)
			end
		end,
		update_steps= function(self)
			local steps= gamestate_get_curr_steps(self.pn)
			if steps ~= self.curr_steps then
				self.curr_steps= steps
				self.field:set_steps(steps)
				set_speed_from_speed_info(cons_players[self.pn], self.field)
				self:update_field()
			end
		end,
		update_config= function(self, param)
			self.field_config= cons_players[self.pn].notefield_config
			local stype= find_current_stepstype(self.pn)
			local profile= PROFILEMAN:GetProfile(self.pn)
			local skin= profile:get_preferred_noteskin(stype)
			local skin_params= profile:get_noteskin_params(skin, stype)
			if skin ~= self.skin then
				self.field:set_skin(skin, skin_params)
				self.skin= skin
			end
			local steps= gamestate_get_curr_steps(self.pn)
			local song= gamestate_get_curr_song()
			if steps and song then
				set_speed_from_speed_info(cons_players[self.pn], self.field)
			end
			self:update_field()
		end,
		hide= function(self)
			self.hidden= true
			self.container:hibernate(math.huge)
		end,
		unhide= function(self)
			self.hidden= false
			self.container:hibernate(0)
		end,
}}

if not_newskin_available() then
	gameplay_preview_mt.__index.create_actors= function()
		return Def.Actor{}
	end
	for field, func in pairs(gameplay_preview_mt.__index) do
		gameplay_preview_mt.__index[field]= noop_nil
	end
end
