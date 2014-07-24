-- A unified system for controlling all the background and text colors used in this theme.  This way, the only code that needs to know whether the theme is in dark or light mode is this file.  Everything else simply requests the appropriate color.
-- Color Scheme:  Solarized (http://ethanschoonover.com/solarized)
--
-- background tones:
local bg0= color("#002b36")
local bg1= color("#073642")
local bg2= color("#eee8d5")
local bg3= color("#fdf6e3")
--
-- content tones:
local fg0= color("#93a1a1")
local fg1= color("#839496")
local fg2= color("#657b83")
local fg3= color("#586e75")
--
-- accent colors:
local accents= {
   yellow= color("#b58900"),
   orange= color("#cb4b16"),
   red= color("#dc322f"),
   magenta= color("#d33682"),
   violet= color("#6c71c4"),
   blue= color("#268bd2"),
   cyan= color("#2aa198"),
   green= color("#859900")
}

local palette= {}

local palette_dark_map= {
   bg= bg0, bg_shadow= bg1,
   rbg= bg3, rbg_shadow= bg2,
   f_text= fg0, f_text_shadow= fg1,
   uf_text= fg3, uf_text_shadow= fg2
}
local palette_light_map= {
   bg= bg3, bg_shadow= bg2,
   rbg= bg0, rbg_shadow= bg1,
   f_text= fg3, f_text_shadow= fg2,
   uf_text= fg0, uf_text_shadow= fg1
}

solar_colors=
   {
   set_dark_map= function()
                    palette= palette_dark_map
                 end,

   set_light_map= function()
                     palette= palette_light_map
                  end,

   palette_is_sane= function()
                       local sane= true
                       for k,v in pairs(palette) do
                          if not v then
                             sane= false
                          end
                       end
                       for k,v in pairs(palette_dark_map) do
                          if not palette[k] then
                             Trace("Palette missing key " .. k)
                             sane= false
                          end
                       end
                       return sane
                    end,
   print_palette= function()
                     Trace("Palette:")
                     for k,v in pairs(palette) do
                        Trace("  " .. k .. ": " .. type(v))
                     end
                     Trace("End palette.")
                  end,
}

solar_colors[PLAYER_1]= function() return solar_colors.red() end
solar_colors[PLAYER_2]= function() return solar_colors.cyan() end

local function write_palette_function(key_name)
   solar_colors[key_name]= function(alpha)
                              if alpha then
                                 return Alpha(palette[key_name], alpha)
                              else
                                 return palette[key_name]
                              end
                           end
end

local function write_accent_color_function(key_name)
   solar_colors[key_name]= function(alpha)
                              if alpha then
                                 return Alpha(accents[key_name], alpha)
                              else
                                 return accents[key_name]
                              end
                           end
end

local function write_palette_access_functions()
   for k,v in pairs(palette_dark_map) do
      write_palette_function(k)
   end
   for k,v in pairs(accents) do
      write_accent_color_function(k)
   end
end

write_palette_access_functions()

judgement_colors= {
   [1]= solar_colors.red(),
   [2]= solar_colors.cyan(),
   [4]= solar_colors.red(),
   [5]= solar_colors.violet(),
   [6]= solar_colors.blue(),
   [7]= solar_colors.green(),
   [8]= solar_colors.yellow(),
   [9]= solar_colors.cyan(),
   HoldNoteScore_LetGo= solar_colors.red(),
   HoldNoteScore_Held= solar_colors.cyan(),
   TapNoteScore_Miss= solar_colors.red(),
   TapNoteScore_W5= solar_colors.violet(),
   TapNoteScore_W4= solar_colors.blue(),
   TapNoteScore_W3= solar_colors.green(),
   TapNoteScore_W2= solar_colors.yellow(),
   TapNoteScore_W1= solar_colors.cyan()
}

local percent_colors= {
	solar_colors.green,
	solar_colors.yellow,
	solar_colors.orange,
	solar_colors.red,
	solar_colors.magenta,
	solar_colors.violet,
	solar_colors.blue,
	solar_colors.cyan,
}
function convert_percent_to_color(p, a)
	local index= force_to_range(1, math.ceil(p * #percent_colors), #percent_colors)
	return percent_colors[index](a)
end

function convert_number_to_color(n, a)
	local index= force_to_range(1, n, #percent_colors)
	return percent_colors[index](a)
end

function convert_wrapping_number_to_color(n, a)
	local index= ((n-1) % #percent_colors) + 1
	return percent_colors[index](a)
end

function color_for_score(score)
	if score > 31/32 then
		return convert_percent_to_color(((score) - (31/32)) * 32)
	else
		return solar_colors.f_text()
	end
end

function adjust_luma(from_color, adjustment)
	local res_color= {}
	for i, v in pairs(from_color) do
		if i == 4 then
			res_color[i]= v
		else
			res_color[i]= (v^2.2 * adjustment)^(1/2.2)
		end
	end
	return res_color
end

function solar_report()
   for k, v in pairs(solar_colors) do
      Trace("solar_colors." .. k .. " is a " .. type(v))
   end
end

solar_colors.set_dark_map()
if not solar_colors.palette_is_sane() then
   Trace("Palette is not sane.")
end
