local default_config= {
	amount= 500,
	min_size= 8,
	max_size= 8,
	min_fall= 4,
	max_fall= 16,
	lumax= 4,
	spin= 360,
}

confetti_config= create_setting("confetti config", "confetti_config.lua", default_config, -1)
confetti_config:load()

local confetti_data= confetti_config:get_data()
local real_rand= math.random
local function maybe_rand(a, b)
	if a < b then return real_rand(a, b) end
	return a
end

function confetti_count()
	return confetti_data.amount
end

function confetti_size()
	return maybe_rand(confetti_data.min_size, confetti_data.max_size)
end

function confetti_fall_time()
	local ret= scale(
		math.random(), 0, 1, confetti_data.min_fall, confetti_data.max_fall)
	if ret <= .1 then return .1 end
	return ret
end

function confetti_hibernate()
	return confetti_fall_time() - confetti_data.min_fall
end

local xmin= 0
local xmax= _screen.w
function set_confetti_side(side)
	if side == "left" then
		xmin= 0
		xmax= _screen.w * .5
	elseif side == "full" then
		xmin= 0
		xmax= _screen.w
	else
		xmin= _screen.w * .5
		xmax= _screen.w
	end
end

function confetti_x()
	return math.random(xmin, xmax)
end

function confetti_fall_start()
	return confetti_data.max_size * -2
end

function confetti_fall_end()
	return _screen.h + (confetti_data.max_size * 2)
end

function confetti_spin()
	return maybe_rand(-confetti_data.spin, confetti_data.spin)
end

local function rand_lum()
	if confetti_data.lumax < 1 then return 1 end
	if math.random(2) == 1 then
		return scale(math.random(), 0, 1, 1, confetti_data.lumax)
	end
	return 1 / scale(math.random(), 0, 1, 1, confetti_data.lumax)
end

local color_set= fetch_color("confetti")
function update_confetti_color()
	color_set= fetch_color("confetti")
end

function confetti_color()
	local cindex= math.floor((math.random() * #color_set) + 1)
	return adjust_luma(color_in_set(color_set, cindex), rand_lum())
end
