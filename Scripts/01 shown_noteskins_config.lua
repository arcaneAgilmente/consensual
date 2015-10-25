shown_noteskins= create_setting("shown noteskins", "shown_noteskins.lua", {}, 0, nil, true)
shown_noteskins:load()

-- The config actually stores true for noteskins that need to be hidden,
-- because that seems more resilient to the player adding and removing
-- noteskins from the data folders.

function filter_noteskin_list_with_shown_config(pn, skin_list)
	local config= shown_noteskins:get_data(pn_to_profile_slot(pn))
	local skinny= 1
	while skinny <= #skin_list do
		if config[skin_list[skinny]] then
			table.remove(skin_list, skinny)
		else
			skinny= skinny + 1
		end
	end
	return skin_list
end
