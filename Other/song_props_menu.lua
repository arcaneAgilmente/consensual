local song_prop_funcs= {
	prof_favor_inc= function(pn)
		change_favor(pn_to_profile_slot(pn), gamestate_get_curr_song(), 1)
	end,
	prof_favor_dec= function(pn)
		change_favor(pn_to_profile_slot(pn), gamestate_get_curr_song(), -1)
	end,
	mach_favor_inc= function(pn)
		change_favor("ProfileSlot_Machine", gamestate_get_curr_song(), 1)
	end,
	mach_favor_dec= function(pn)
		change_favor("ProfileSlot_Machine", gamestate_get_curr_song(), -1)
	end,
	censor= function()
		censor(gamestate_get_curr_song())
	end,
	end_credit= function()
		SOUND:PlayOnce("Themes/_fallback/Sounds/Common Start.ogg")
		end_credit_now()
	end
}
function interpret_common_song_props_code(pn, code)
	if song_prop_funcs[code] then
		song_prop_funcs[code](pn)
		return true
	end
	return false
end
