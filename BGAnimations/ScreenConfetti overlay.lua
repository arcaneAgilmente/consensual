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

return Def.ActorFrame{
	Def.ActorFrame{
		Name= "confetti_container", InitCommand= function(self)
			confetti_container= self
			update_confetti_count()
		end
	}
}
