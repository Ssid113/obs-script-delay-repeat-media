local obs = obslua					--obs
local selected_source

local ssid_switch = true 			--timer bool
local ssid_random = false 			--random bool
local ssid_start = false  			--state system bool
local ssid_total_seconds = 10 		--second timer
local ssid_total_seconds_from = 1 	--second random from
local ssid_total_seconds_to = 10 	--second random to
local ssid_source_name = "" 		--name source media
local ssid_sceneitem = nil 			--media obgect  obs_source_t

function on_off() 					--function on/off timer
	if ssid_switch and not ssid_start then 
		if ssid_random then 		--random mode
			local seconds = random(ssid_total_seconds_from, ssid_total_seconds_to)
			local mseconds = seconds*1000
			print("Seconds before new timer: " .. tostring(seconds))
			obs.timer_add(play_source, mseconds)
			ssid_start = not ssid_start
		else						--normal mode
			print("Seconds before new timer: " .. tostring(ssid_total_seconds))
			obs.timer_add(play_source, ssid_total_seconds*1000)
			ssid_start = not ssid_start
		end
		print("Start script timer. State timer = " .. tostring(ssid_start))
	elseif not ssid_switch and ssid_start then
		ssid_start = not ssid_start
		play_source()
		print("End script timer. State timer = " .. tostring(ssid_start))
	else
		print("State timer = " .. tostring(ssid_start))
	end
end

function play_source() 				--Run source media
	if not ssid_start then			--If state system false than stop timer script
		obs.timer_remove(play_source)
	else
		if ssid_sceneitem then		--If state system true than run timer script	
			local pr_settings = obs.obs_source_get_private_settings(ssid_sceneitem)
			obs.obs_source_update(ssid_sceneitem, pr_settings)
			obs.obs_data_release(pr_settings)
			--obs.obs_source_release(source)
		end
	end
	if ssid_random then				--Re-timer for random mode
		obs.timer_remove(play_source)
		local seconds = random(ssid_total_seconds_from, ssid_total_seconds_to)
		local mseconds = seconds*1000
		print("Seconds before new timer: " .. tostring(seconds))
		obs.timer_add(play_source, mseconds)
	end
end

local u = 0 						--don't delete for random
function random(x, y) 				--random function
    u = u + 1	
    if x ~= nil and y ~= nil then
        return math.floor(x +(math.random(math.randomseed(os.time()+u))*999999 %y))
    else
        return math.floor((math.random(math.randomseed(os.time()+u))*100))
    end
end

---------------------------------------------------------------Settings------------------------------------------------------------------
function script_properties() 		--Page properties
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int(props, "ssid_total_seconds", "Repeat every (sec):", 1, 100000, ssid_total_seconds)
	obs.obs_properties_add_bool(props, "ssid_random", "Random repeat")
	obs.obs_properties_add_int(props, "ssid_total_seconds_from", "Random from (sec):", 1, 100000, ssid_total_seconds_from)
	obs.obs_properties_add_int(props, "ssid_total_seconds_to", "Random to (sec):", 1, 100000, ssid_total_seconds_to)
	local p = obs.obs_properties_add_list(props, "ssid_source_name", "Source media", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "ffmpeg_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			elseif source_id == "vlc_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			else
				-- obs.script_log(obs.LOG_INFO, source_id)
			end
		end
	end
	obs.obs_data_set_string(settings, "ssid_source_name", ssid_source_name)
	obs.obs_properties_add_bool(props, "ssid_switch", "On/Off Timer")
	obs.source_list_release(sources)
	return props
end

function script_description() 		--description
	return "The script for activating/restarting the Media file some time later.\nFor example, you need to periodically display information about yourself(channel, subscriptions, advertising, etc.) every 30 minutes during the broadcast.\n\n1. If \"Random repeat\" is activated, then the repetition is triggered in the range FROM and TO seconds. Repeat every - ignored.\n2. Select the source to repeat.\n3. You can now use On/Off The timer.\n\nMade by Ssid113"
end

function script_update(settings) 	--update settings
	selected_source = obs.obs_data_get_string(settings, "selected_source")
	ssid_switch = obs.obs_data_get_bool(settings, "ssid_switch")
	ssid_random = obs.obs_data_get_bool(settings, "ssid_random")  
	ssid_total_seconds_from = obs.obs_data_get_int(settings, "ssid_total_seconds_from")
	ssid_total_seconds_to = obs.obs_data_get_int(settings, "ssid_total_seconds_to")
	ssid_total_seconds = obs.obs_data_get_int(settings, "ssid_total_seconds")
	ssid_source_name = obs.obs_data_get_string(settings, "ssid_source_name")
	obs.obs_source_release(ssid_sceneitem)
	ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	on_off() 						--start script
end

function script_save(settings) 		--save settings
    obs.obs_data_set_bool(settings, "ssid_switch", ssid_switch)
	obs.obs_data_set_bool(settings, "ssid_random", ssid_random)
	obs.obs_data_set_int(settings, "ssid_total_seconds", ssid_total_seconds)
	obs.obs_data_set_int(settings, "ssid_total_seconds_from", ssid_total_seconds_from)
	obs.obs_data_set_int(settings, "ssid_total_seconds_to", ssid_total_seconds_to)
	obs.obs_data_set_string(settings, "ssid_source_name", ssid_source_name)
end

function script_load(settings) 		--load settings
	ssid_switch = obs.obs_data_get_bool(settings, "ssid_switch")
	ssid_random = obs.obs_data_get_bool(settings, "ssid_random")
	ssid_total_seconds = obs.obs_data_get_int(settings, "ssid_total_seconds")
	sid_total_seconds_from = obs.obs_data_get_int(settings, "ssid_total_seconds_from")
	ssid_total_seconds_to = obs.obs_data_get_int(settings, "ssid_total_seconds_to")
	ssid_source_name = obs.obs_data_get_string(settings, "ssid_source_name")
	obs.obs_source_release(ssid_sceneitem)
	ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
end

function script_defaults(settings) 	--defaults settings
	obs.obs_data_set_default_bool(settings, "ssid_switch", false)
	obs.obs_data_set_default_bool(settings, "ssid_random", false)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds", 1)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds_from", 1)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds_to", 10)
	obs.obs_data_set_default_string(settings, "ssid_source_name", "")
end

--function get_sceneitem_from_source_name_in_current_scene(name) --get media from name obs_sceneitem_t
--  local result_sceneitem = nil
--  local current_scene_as_source = obs.obs_frontend_get_current_scene()
--  if current_scene_as_source then
--    local current_scene = obs.obs_scene_from_source(current_scene_as_source)
--	if current_scene then
--		result_sceneitem = obs.obs_scene_find_source_recursive(current_scene, name)
--	end
--   obs.obs_source_release(current_scene_as_source)
--  end
--  return result_sceneitem
--end