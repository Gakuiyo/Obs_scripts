obs           = obslua
source_name   = ""

last_text     = ""
activated     = false

wins  = 0
loses = 0

hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

hotkey_WinPlus_id     = obs.OBS_INVALID_HOTKEY_ID
hotkey_WinMinus_id     = obs.OBS_INVALID_HOTKEY_ID

hotkey_LosePlus_id     = obs.OBS_INVALID_HOTKEY_ID
hotkey_LoseMinus_id     = obs.OBS_INVALID_HOTKEY_ID

-- Function to set the time text
function set_time_text()
	local text          = string.format("%d - %d", wins, loses)

	if text ~= last_text then
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end
	end

	last_text = text
end

function timer_callback()
	set_time_text()
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		set_time_text()
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset(pressed)
	if not pressed then
		return
	end

	activate(false)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

function WinsPlus(pressed)
	if not pressed then
		return
	end

	activate(false)
	wins = wins + 1
	set_time_text()
end

function WinsMinus(pressed)
	if not pressed then
		return
	end

	activate(false)
	wins = wins - 1
	set_time_text()
end

function LosesPlus(pressed)
	if not pressed then
		return
	end

	activate(false)
	loses = loses + 1
	set_time_text()
end

function LosesMinus(pressed)
	if not pressed then
		return
	end

	activate(false)
	loses = loses - 1
	set_time_text()
end

function reset_button_clicked(props, p)
	reset(true)
	return false
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)
	obs.obs_properties_add_button(props, "reset_button", "Reset Count", reset_button_clicked)

	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Sets a text source to act as a Wins/Loses ratio when the source is active.\n\nMade by Gakuiyo, and inspired my countdown included with OBS by Jim"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	activate(false)

	loses = 0
	wins = 0
	source_name = obs.obs_data_get_string(settings, "source")

	reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)

end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)


	local hotkey_save_array = obs.obs_hotkey_save(hotkey_WinPlus_id)
	obs.obs_data_set_array(settings, "winsPlus_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	local hotkey_save_array = obs.obs_hotkey_save(hotkey_WinMinus_id)
	obs.obs_data_set_array(settings, "winsMinus_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)


	local hotkey_save_array = obs.obs_hotkey_save(hotkey_LosePlus_id)
	obs.obs_data_set_array(settings, "losePlus_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	local hotkey_save_array = obs.obs_hotkey_save(hotkey_LoseMinus_id)
	obs.obs_data_set_array(settings, "loseMinus_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- a function named script_load will be called on startup
function script_load(settings)
	-- Connect hotkey and activation/deactivation signal callbacks
	--
	-- NOTE: These particular script callbacks do not necessarily have to
	-- be disconnected, as callbacks will automatically destroy themselves
	-- if the script is unloaded.  So there's no real need to manually
	-- disconnect callbacks that are intended to last until the script is
	-- unloaded.
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Count", reset)
	local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)


	hotkey_WinPlus_id = obs.obs_hotkey_register_frontend("win_plus_thingy", "Win Plus", WinsPlus)
	local hotkey_save_array = obs.obs_data_get_array(settings, "winsPlus_hotkey")
	obs.obs_hotkey_load(hotkey_WinPlus_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_WinMinus_id = obs.obs_hotkey_register_frontend("win_minus_thingy", "Win Minus", WinsMinus)
	local hotkey_save_array = obs.obs_data_get_array(settings, "winsMinus_hotkey")
	obs.obs_hotkey_load(hotkey_WinMinus_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)


	hotkey_LosePlus_id = obs.obs_hotkey_register_frontend("lose_plus_thingy", "Lose Plus", LosesPlus)
	local hotkey_save_array = obs.obs_data_get_array(settings, "losePlus_hotkey")
	obs.obs_hotkey_load(hotkey_LosePlus_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_LoseMinus_id = obs.obs_hotkey_register_frontend("lose_minus_thingy", "Lose Minus", LosesMinus)
	local hotkey_save_array = obs.obs_data_get_array(settings, "loseMinus_hotkey")
	obs.obs_hotkey_load(hotkey_LoseMinus_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end
