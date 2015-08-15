local refall= true
local confetti_container= false
local confetti_levels= {}
local active= false
local fall_side= false

function confetti_refall()
	return refall
end

local function trigger_confetti()
	local confetti= confetti_container:GetChild("confetti")
	if confetti then
		if #confetti > 0 then
			for i= 1, #confetti do
				confetti[i]:playcommand("Trigger")
			end
		else
			confetti:playcommand("Trigger")
		end
	end
end

local function add_confetti(num_already, amount)
	for i= 1, amount do
		confetti_container:AddChildFromPath(THEME:GetPathG("", "confetti.lua"))
	end
	local confetti= confetti_container:GetChild("confetti")
	if #confetti > 0 then
		for i= 1 + num_already, #confetti do
			confetti[i]:playcommand("Trigger")
		end
	else
		confetti:playcommand("Trigger")
	end
end

function update_confetti_count()
	local count= confetti_count()
	local confetti= confetti_container:GetChild("confetti")
	if confetti then
		local num_already= #confetti
		if num_already == 0 then
			num_already= 1
		end
		if num_already > count then
			if count < 1 then
				confetti_container:RemoveAllChildren()
			else
				local remove= num_already - count
				for i= 1, remove do
					confetti_container:RemoveChild("confetti")
				end
			end
		elseif num_already < count then
			add_confetti(num_already, count - num_already)
		end
	elseif count > 0 then
		add_confetti(0, count)
	end
end

local function update_confetti_active()
	local still_active= false
	local combo_only= true
	for name, act in pairs(confetti_levels) do
		if act then
			if name ~= "combo" then combo_only= false end
			still_active= true
		end
	end
	refall= not combo_only
	if combo_only then
		if fall_side and GAMESTATE:GetNumPlayersEnabled() > 1 then
			if fall_side == PLAYER_1 then
				set_confetti_side("left")
			else
				set_confetti_side("right")
			end
		else
			set_confetti_side("full")
		end
	else
		set_confetti_side("full")
	end
	if still_active then
		if not active then
			confetti_container:visible(true)
			trigger_confetti()
		end
	else
		confetti_container:visible(false)
	end
	if combo_only then
		still_active= false
		confetti_levels.combo= false
	end
	active= still_active
end

function activate_confetti(level, value, side)
	confetti_levels[level]= value
	fall_side= side
	update_confetti_active()
end

function get_confetti(level)
	return confetti_levels[level]
end

local inversion_level= 1

dofile(THEME:GetPathO("", "art_helpers.lua"))
big_circle_size= 512
hbig_circle_size= big_circle_size * .5
hollow_circle_inner_zoom= .8
local circle_pos= hbig_circle_size-1
local circle_rad= hbig_circle_size
local circle_chords= hbig_circle_size
local circle_smoother_thick= 8

return Def.ActorFrame{
	Def.ActorFrame{
		Name= "confetti_container", InitCommand= function(self)
			confetti_container= self
			update_confetti_count()
			update_confetti_active()
		end,
		gameplay_yversionMessageCommand= function(self, param)
			if param[2] then
				inversion_level= param[1]
				rand_tween(self, param[1])
			end
			self:zoomy(self:GetZoomY() * -1):y(_screen.h - self:GetDestY())
		end,
		gameplay_xversionMessageCommand= function(self, param)
			if param[2] then
				inversion_level= param[1]
				rand_tween(self, param[1])
			end
			self:zoomx(self:GetZoomX() * -1):x(_screen.w - self:GetDestX())
		end,
		gameplay_unversionMessageCommand= function(self)
			if self:GetZoomY() < 0 or self:GetZoomX() < 0 then
				rand_tween(self, inversion_level)
				self:zoomy(1):y(0):zoomx(1):x(0)
			end
		end
	},
	Def.ActorFrame{
		Name= "rendered_things", InitCommand= function(self)
			self:hibernate(math.huge)
		end,
		Def.ActorFrameTexture{
			InitCommand= function(self)
				self:setsize(big_circle_size, big_circle_size)
					:SetTextureName("big_circle")
					:EnableAlphaBuffer(true):Create()
					:EnablePreserveTexture(false):Draw()
			end,
			circle_amv("circle", circle_pos, circle_pos,
								 circle_rad-circle_smoother_thick,
								 circle_chords, {1, 1, 1, 1}),
			hollow_circle_amv(circle_pos, circle_pos, circle_rad,
												circle_smoother_thick, circle_chords,
												{1, 1, 1, 1}, {1, 1, 1, 0}, "BlendMode_CopySrc"),
		},
		Def.ActorFrameTexture{
			InitCommand= function(self)
				self:setsize(big_circle_size, big_circle_size)
					:SetTextureName("big_spotlight")
					:EnableAlphaBuffer(true):Create()
					:EnablePreserveTexture(false):Draw()
			end,
			circle_amv("circle", hbig_circle_size-1, hbig_circle_size-1,
								 hbig_circle_size, big_circle_size,
								 {1, 1, 1, 1}, {1, 1, 1, 0}, "BlendMode_CopySrc"),
		},
		Def.ActorFrameTexture{
			InitCommand= function(self)
				self:setsize(big_circle_size, big_circle_size)
					:SetTextureName("hollow_circle")
					:EnableAlphaBuffer(true):Create()
					:EnablePreserveTexture(false):Draw()
			end,
			Def.Sprite{
				Texture= "big_circle", InitCommand= function(subself)
					subself:xy(hbig_circle_size, hbig_circle_size)
				end
			},
			Def.Sprite{
				Texture= "big_circle", InitCommand= function(subself)
					subself:xy(hbig_circle_size, hbig_circle_size)
						:zoom(hollow_circle_inner_zoom)
					if PREFSMAN:GetPreference("VideoRenderers"):sub(1, 6) == "opengl" then
						subself:blend("BlendMode_Subtract")
					else
						subself:blend("BlendMode_AlphaKnockOut")
					end
				end
			},
		},
	},
}
