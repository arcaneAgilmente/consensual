local bpm_list= {}
local by_bpm= {}
local loop_folder= "kloop_archive/"

local function find_insertion_index(list, entry)
	if not list[1] then return 1 end
	local lower= 1
	local upper= #list
	if entry < list[lower] then return 1 end
	if entry > list[upper] then return upper+1 end
	if entry == list[lower] then return nil, lower end
	if entry == list[upper] then return nil, upper end
	local diff= upper - lower
	while diff > 1 do
		local mid= math.floor(lower + (diff * .5))
		if entry == list[mid] then return nil, mid end
		if entry < list[mid] then upper= mid
		else lower= mid end
		diff= upper - lower
	end
	return upper, lower
end

local theme_loop_folder= THEME:GetCurrentThemeDirectory() .. "/Sounds/" ..
	loop_folder

function add_music_loop_entry(bpm, len, name)
	if not FILEMAN:DoesFileExist(theme_loop_folder .. name) then return end
	bpm= math.floor(bpm)
	local insert_at= find_insertion_index(bpm_list, bpm)
	if insert_at then
		table.insert(bpm_list, insert_at, bpm)
		by_bpm[bpm]= {}
	end
	table.insert(by_bpm[bpm], {name, len})
end

function rand_song_for_bpm(bpm)
	local upper, lower= find_insertion_index(bpm_list, math.floor(bpm))
	local use_bpm= bpm_list[1]
	if upper then
		if lower then
			if bpm_list[upper] - bpm > bpm - bpm_list[lower] then
				use_bpm= bpm_list[lower]
			else
				use_bpm= bpm_list[upper]
			end
		else
			if bpm_list[upper] then
				use_bpm= bpm_list[upper]
			else
				use_bpm= bpm_list[upper-1]
			end
		end
	else
		use_bpm= bpm_list[lower]
	end
	local songs_of_bpm= by_bpm[use_bpm]
	if not songs_of_bpm then
		lua.ReportScriptError(
			"No songs found for bpm " .. use_bpm .. " (" .. bpm .. ").\n" ..
				"Range: " .. tostring(lower) .. ", " .. tostring(upper))
		return "", 0
	end
	local choice= 1
	if #songs_of_bpm ~= 1 then
		choice= math.random(1, #songs_of_bpm)
	end
	return songs_of_bpm[choice][1], songs_of_bpm[choice][2]
end

local fade_time= 1
local prev_bpm= 140
function set_prev_song_bpm(bpm)
	prev_bpm= bpm
end
function update_prev_song_bpm()
	local song= GAMESTATE:GetCurrentSong()
	if song then
		local bpms= song:GetDisplayBpms()
		prev_bpm= math.floor((bpms[1] + bpms[2]) * .5)
	end
end

-- TODO:  Add a system for adding attract/bg music lists.
local prev_sample_song= "cat"
function play_sample_music(force, ignore_current)
	if GAMESTATE:IsCourseMode() then
		return
	end
	local song= GAMESTATE:GetCurrentSong()
	if song == prev_sample_song and not force then return end
	prev_sample_song= song
	if song and not ignore_current then
		local songpath= song:GetMusicPath()
		local sample_start= song:GetSampleStart()
		local sample_len= song:GetSampleLength()
		SOUND:PlayMusicPart(
			songpath, sample_start, sample_len, fade_time, fade_time, true, true)
	else
		local name, len= rand_song_for_bpm(prev_bpm)
		local path= THEME:GetPathS("", loop_folder .. name, true)
		SOUND:PlayMusicPart(path, 0, len, 0, 0)
	end
end

function stop_music()
	SOUND:PlayMusicPart("", 0, 0)
end

add_music_loop_entry(183, 31.475, "Aka yori Akai Yume [183 BPM].ogg")
add_music_loop_entry(135, 14.222, "Alegro [135 BPM] - 1.ogg")
add_music_loop_entry(135, 14.222, "Alegro [135 BPM] - 2.ogg")
add_music_loop_entry(135,  7.111, "Alegro [135 BPM] - 3.ogg")
add_music_loop_entry(132, 14.545, "Altair And Vega [132 BPM].ogg")
add_music_loop_entry(118, 16.271, "Anchor under the ruins [118 BPM].ogg")
add_music_loop_entry(140, 06.857, "Apparitions Stalk the Night - Slap Bass [140 BPM].ogg")
add_music_loop_entry(150, 12.800, "Artificial Intelligence Bomb [150 BPM].ogg")
add_music_loop_entry(170, 11.294, "Atomospheric Storm 2009 [170 BPM].ogg")
add_music_loop_entry(138, 13.913, "Bad Apple!! [138 BPM] - 1.ogg")
add_music_loop_entry(138, 13.913, "Bad Apple!! [138 BPM] - 2.ogg")
add_music_loop_entry(130, 14.769, "Beat Assassinator [130 BPM].ogg")
add_music_loop_entry(138, 27.767, "Believe (Original Mix) [138.290 BPM].ogg")
add_music_loop_entry(132, 14.545, "B L A C K O U T [132 BPM].ogg")
add_music_loop_entry( 89,  8.089, "Blaster Nation [89 BPM].ogg")
add_music_loop_entry(140, 27.428, "Bloom Nobly [140 BPM].ogg")
add_music_loop_entry(75,  12.800, "booklet choir [75 BPM].ogg")
add_music_loop_entry(140, 13.714, "Break the Sabbath [140 BPM].ogg")
add_music_loop_entry(134, 14.269, "Buzz [134.550 BPM].ogg")
add_music_loop_entry(180, 21.333, "CANDY.VOX [180 BPM].ogg")
add_music_loop_entry(134, 14.248, "Cats on Mars [134.750 BPM].ogg")
add_music_loop_entry(153, 12.549, "Chain of Pain [153 BPM].ogg")
add_music_loop_entry(175, 21.942, "Convictor Yamaxanadu! [175 BPM].ogg")
add_music_loop_entry(173, 11.098, "Cross Breeding [173 BPM] - 1.ogg")
add_music_loop_entry(173, 22.196, "Cross Breeding [173 BPM] - 2.ogg")
add_music_loop_entry(148, 12.972, "Cross Water [148 BPM].ogg")
add_music_loop_entry(136, 21.176, "Darkness Pleasure (12bar) [136 BPM].ogg")
add_music_loop_entry(136, 14.117, "Darkness Pleasure (8bar) [136 BPM].ogg")
add_music_loop_entry(140, 13.714, "D.A.T.A. [140 BPM] - 1.ogg")
add_music_loop_entry(140, 13.714, "D.A.T.A. [140 BPM] - 2.ogg")
add_music_loop_entry(140, 13.714, "D.A.T.A. [140 BPM] - 3.ogg")
add_music_loop_entry(185, 20.756, "Descendant Of PP [185 BPM].ogg")
add_music_loop_entry(128, 30.000, "Desert Years [128 BPM].ogg")
add_music_loop_entry(128, 15.000, "Diagramma della Verita [128 BPM].ogg")
add_music_loop_entry(140, 27.428, "Dial Connected [140 BPM] .ogg")
add_music_loop_entry(170, 22.588, "Drop Zone [170 BPM].ogg")
add_music_loop_entry(120, 21.236, "Everglades [120 BPM].ogg")
add_music_loop_entry(130, 14.769, "excube (part 1) [130 BPM].ogg")
add_music_loop_entry(130, 14.769, "excube (part 2) [130 BPM].ogg")
add_music_loop_entry(175, 10.971, "Foughten Field [175 BPM].ogg")
add_music_loop_entry( 94, 10.212, "Ghostwriter [94 BPM].ogg")
add_music_loop_entry(142,  6.760, "Girl's Mind [142 BPM] - 1.ogg")
add_music_loop_entry(142, 13.521, "Girl's Mind [142 BPM] - 2.ogg")
add_music_loop_entry( 87, 22.068, "Good Mooning End [87 BPM].ogg")
add_music_loop_entry(140, 13.714, "Graveyard [140 BPM].ogg")
add_music_loop_entry(157,  6.080, "Hard Reset [157.881 BPM].ogg")
add_music_loop_entry(100, 19.200, "Hello Mr. Tree [100 BPM].ogg")
add_music_loop_entry(100, 19.200, "Hello Mr. Tree (feat. Heavy) [100 BPM].ogg")
add_music_loop_entry(150, 12.800, "Hiirogekka Kyousai no Zetsu -1st Anniversary Remix- [150 BPM].ogg")
add_music_loop_entry(128, 15.000, "Hop! Step! Instant Death! [128 BPM].ogg")
add_music_loop_entry(170, 22.588, "Invoker [170 BPM].ogg")
add_music_loop_entry(176, 10.909, "Just the Death of Us [176 BPM] - 1.ogg")
add_music_loop_entry(176, 10.909, "Just the Death of Us [176 BPM] - 2.ogg")
add_music_loop_entry(150, 12.800, "Last Moment [150 BPM].ogg")
add_music_loop_entry(175, 10.971, "Last Remote [175 BPM].ogg")
add_music_loop_entry(180, 21.333, "log [180 BPM] - 1.ogg")
add_music_loop_entry(180, 15.999, "log [180 BPM] - 2.ogg")
add_music_loop_entry(140, 13.714, "Love is Eternity [140 BPM] - 1.ogg")
add_music_loop_entry(140, 13.714, "Love is Eternity [140 BPM] - 2.ogg")
add_music_loop_entry(158, 24.303, "Lucent Wish [158 BPM].ogg")
add_music_loop_entry(140, 13.714, "Lunatic Phaser [140 BPM].ogg")
add_music_loop_entry(180, 10.666, "maid in Japan [180 BPM].ogg")
add_music_loop_entry(170, 22.588, "Make Me Feel [170 BPM].ogg")
add_music_loop_entry(140, 13.714, "Maple Wizen (Crosswize Remix) [140 BPM] - 1.ogg")
add_music_loop_entry(140, 13.714, "Maple Wizen (Crosswize Remix) [140 BPM] - 2.ogg")
add_music_loop_entry(128, 15.000, "Masquerade [128 BPM].ogg")
add_music_loop_entry(147, 26.122, "Mercury Lamp [147 BPM].ogg")
add_music_loop_entry(128,  7.500, "Mind Mapping [128 BPM] - 1.ogg")
add_music_loop_entry(128,  7.500, "Mind Mapping [128 BPM] - 2.ogg")
add_music_loop_entry( 86, 22.312, "mists [86.050 BPM].ogg")
add_music_loop_entry(172, 11.162, "Olive [172 BPM] - 1.ogg")
add_music_loop_entry(172, 22.325, "Olive [172 BPM] - 2.ogg")
add_music_loop_entry(172, 11.162, "Olive [172 BPM] - 3.ogg")
add_music_loop_entry(181, 10.607, "orion [181 BPM].ogg")
add_music_loop_entry(128, 15.000, "Oxygen Graffiti [128 BPM].ogg")
add_music_loop_entry(143, 13.426, "Particles [143 BPM] - 1.ogg")
add_music_loop_entry(143, 26.853, "Particles [143 BPM] - 2.ogg")
add_music_loop_entry(128, 30.000, "PARTY KiLLER [128 BPM].ogg")
add_music_loop_entry(166, 11.524, "Perky Pat [166.600 BPM].ogg")
add_music_loop_entry( 86, 22.325, "Phantasma plant [86 BPM].ogg")
add_music_loop_entry(145, 13.241, "Providence [145 BPM].ogg")
add_music_loop_entry(175, 10.971, "Purple Storm [175 BPM].ogg")
add_music_loop_entry(112, 34.285, "Raptate [112 BPM].ogg")
add_music_loop_entry(109, 17.454, "Remember Tomorrow [109.998 BPM].ogg")
add_music_loop_entry(146, 13.150, "Saturation [146 BPM].ogg")
add_music_loop_entry(160, 24.000, "Shinto Shrine [160 BPM] - 1.ogg")
add_music_loop_entry(160, 12.000, "Shinto Shrine [160 BPM] - 2.ogg")
add_music_loop_entry(148, 12.972, "Shisorinne Reirou no Owari [148 BPM].ogg")
add_music_loop_entry( 95, 20.210, "Silent Moonlight [95 BPM].ogg")
add_music_loop_entry(170, 22.588, "Space Diver Tama [170 BPM].ogg")
add_music_loop_entry( 87, 44.137, "Stellar Lights [87 BPM].ogg")
add_music_loop_entry(178, 21.573, "Sweetness and Love [178 BPM].ogg")
add_music_loop_entry(180, 21.333, "Tc-ma_009 [180 BPM].ogg")
add_music_loop_entry(148, 12.972, "Technotris [148 BPM].ogg")
add_music_loop_entry(130, 14.769, "The Legend Of KAGE [130 BPM].ogg")
add_music_loop_entry(132, 14.545, "The Unbroken Shield 9 [132 BPM].ogg")
add_music_loop_entry(116, 16.551, "to Luv me I --- for u. (uno Remix) [116 BPM] - 1.ogg")
add_music_loop_entry(116, 33.103, "to Luv me I --- for u. (uno Remix) [116 BPM] - 2.ogg")
add_music_loop_entry(142, 13.521, "Total Sphere [142 BPM].ogg")
add_music_loop_entry(100, 19.199, "Travelling towards the Lake [100 BPM] - 1.ogg")
add_music_loop_entry(100, 19.199, "Travelling towards the Lake [100 BPM] - 2.ogg")
add_music_loop_entry(175, 10.971, "Unseal [175 BPM].ogg")
add_music_loop_entry(158, 12.151, "Vanishing Point [158 BPM].ogg")
add_music_loop_entry(150, 25.600, "Vanishing Point -slash- [150 BPM].ogg")
add_music_loop_entry(140, 26.482, "Violent wind [140 BPM].ogg")
add_music_loop_entry(128, 15.000, "We Interrupt This Programme (JCA Remix) [128 BPM].ogg")
add_music_loop_entry(170, 11.294, "Ziggurat [170 BPM].ogg")

-- Add your own entries for any loop music you wish to add in
-- "Scripts/03 extra_music.lua".  Create that file and put entries just like
-- the ones above in it.  Stepmania will take care of loading it.

-- The entries above are for the music from K's Loop Archive:
-- https://dl.dropboxusercontent.com/u/24962829/loops/index.html
-- Menu music is not distributed with this theme for legal reasons.
-- Create the folder Sounds/kloop_archive and put the ogg files inside it.

-- If you're on linux, the commandline tool ogginfo is a good way to get the
-- length of ogg files.  If you have more than a few, send me a message and I
-- can write something that uses ogginfo to produce entries.
-- add_music_loop_entry(bpm, length, filename)
