local obs = obslua							--obs
local ssid_current_version = "v0.3.2"
local ssid_switch = true 					--Флаг таймера
local ssid_random = false 					--рандомное срабатывание
local ssid_total_seconds = 10 				--секунды таймера
local ssid_total_seconds_from = 1 			--секунды таймера для рандома от
local ssid_total_seconds_to = 10 			--секунды таймера для рандома до
local ssid_source_name = "" 				--имя источника
local local_file_array = {}					--список файлов
local ssid_visible = false					--Видимость источника
local ssid_mode = 1
local ssid_locale = 1
local ssid_playlist_mode = 1
local ssid_number = 0

local localization = require 'Locale/Localization'
require 'Locale/En'
require 'Locale/Ru'

----------------------------------------------MAIN FUNCTION----------------------------------------------------------------
function play_source() 						--Запустить источник
	print(localization.translate('play_source'))
	print(localization.translate('time_delay') .. ssid_total_seconds)
	obs.timer_remove(play_source)
	local ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	if ssid_sceneitem then
		local pr_settings = obs.obs_source_get_settings(ssid_sceneitem)
		if ssid_visible then
			obs.obs_data_set_string(pr_settings, "local_file", obs.obs_data_get_string(obs.obs_data_array_item(local_file_array, array_number()), "value"))  --Устанавливаем свой файл
			obs.obs_source_update(ssid_sceneitem, pr_settings)
		end
		obs.timer_add(play_source,ssid_total_seconds*1000)
		obs.obs_data_release(pr_settings)
	end
	obs.obs_source_release(ssid_sceneitem)
	print(localization.translate('func_done'))
	print(" ")
	print(" ")
end

function play_source_random()				--Запускать источник рандомно
	print(localization.translate('play_source_random'))
	local rand = random(ssid_total_seconds_from, ssid_total_seconds_to)
	print(localization.translate('time_delay') .. rand)
	obs.timer_remove(play_source_random)
	local ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	if ssid_sceneitem then
		local pr_settings = obs.obs_source_get_settings(ssid_sceneitem)
		if ssid_visible then
			obs.obs_data_set_string(pr_settings, "local_file", obs.obs_data_get_string(obs.obs_data_array_item(local_file_array, array_number()), "value"))  --Устанавливаем свой файл
			obs.obs_source_update(ssid_sceneitem, pr_settings)
		end
		obs.timer_add(play_source_random,rand*1000)
		obs.obs_data_release(pr_settings)
	end
	obs.obs_source_release(ssid_sceneitem)
	print(localization.translate('func_done'))
	print(" ")
	print(" ")
end

----------------------------------------------SECOND FUNCTION----------------------------------------------------------------
function timers_remove()					--Останавливаем все таймеры
	obs.timer_remove(play_source)
	obs.timer_remove(play_source_random)
end

function media_stop()
	print(localization.translate('media_stop'))
	local ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	if ssid_sceneitem then
		obs.obs_source_media_stop(ssid_sceneitem)
	end
	obs.obs_source_release(ssid_sceneitem)
end

local u = 0 								--don't delete for random
function random(x, y) 						--random функция
    u = u + 1
	math.randomseed(os.time()+u)
    if x ~= nil and y ~= nil and y > x then
        return math.floor(math.random(x, y))
    else
		print(localization.translate('random_err'))
        return math.floor(math.random(10, 100))
    end
end

function on_event(event)					--ожидаем когда загрузится сцена, чтобы запустить скрипт
	if event == 26 then
		obs.obs_frontend_remove_event_callback(on_event)
		print(localization.translate('scene_work'))
		start_update()
	end
end

function signal_visible_event(event)		--Обрабатываем сигнал включения отображения источника
	--media_stop()
	--ssid_visible = true
	start_update()
end

function signal_not_visible_event(event)	--Обрабатываем сигнал выключения отображения источника
	media_stop()
	ssid_visible = false
	timers_remove()
end

function connect_signal()					--Подписываемся на сигналы
	local ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	if ssid_sceneitem then
		obs.signal_handler_connect(obs.obs_source_get_signal_handler(ssid_sceneitem), "activate", signal_visible_event)
		obs.signal_handler_connect(obs.obs_source_get_signal_handler(ssid_sceneitem), "deactivate", signal_not_visible_event)
	end
	obs.obs_source_release(ssid_sceneitem)
end

function disconnect_signal()				--Отписываемся от сигналов
	local ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	if ssid_sceneitem then
		obs.signal_handler_disconnect(obs.obs_source_get_signal_handler(ssid_sceneitem), "activate", signal_visible_event)
		obs.signal_handler_disconnect(obs.obs_source_get_signal_handler(ssid_sceneitem), "deactivate", signal_not_visible_event)
	end
	obs.obs_source_release(ssid_sceneitem)
end

function array_number()						--Выбираем файл в плейлисте--
	if ssid_playlist_mode == 1 then
		if obs.obs_data_array_count(local_file_array) == ssid_number then
			ssid_number = 1
		else
			ssid_number = ssid_number + 1
		end
	else
		ssid_number = random(1, obs.obs_data_array_count(local_file_array))
	end
	print(ssid_number - 1)
	return ssid_number - 1
end


---------------------------------------------------------------SETTINGS------------------------------------------------------------------
function start_update()						--При обновлении параметров настраиваем таймеры
	timers_remove()
	local ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	if ssid_sceneitem then
		ssid_visible = obs.obs_source_active(ssid_sceneitem)
		print(localization.translate('func_update_end'))
		--connect_signal()
		media_stop()
		if ssid_switch then
			print(localization.translate('script_on') .. tostring(ssid_switch))
			if ssid_random then
				local rand = random(ssid_total_seconds_from, ssid_total_seconds_to)
				print(localization.translate('time_delay') .. rand)
				obs.timer_add(play_source_random,rand*1000)
			else
				print(localization.translate('time_delay') .. ssid_total_seconds)
				obs.timer_add(play_source,ssid_total_seconds*1000)
			end
		else
			timers_remove()
			print(localization.translate('script_off') .. tostring(ssid_switch))
		end
	end
	obs.obs_source_release(ssid_sceneitem)
	print(" ")
	print(" ")
end

my_settings = nil
function script_properties() 				--Страница настроек
	local props = obs.obs_properties_create()
	obs.obs_properties_add_bool(props, "ssid_switch", localization.translate('on_off_timer'))
	local p1 = obs.obs_properties_add_list(props, "ssid_locale", localization.translate('select_lang'), obslua.OBS_COMBO_TYPE_LIST, obslua.OBS_COMBO_FORMAT_INT)
	MY_OPTIONS = {"English", "Русский"}
	for i,v in ipairs(MY_OPTIONS) do
		obs.obs_property_list_add_int(p1, v, i)
	end
	local p2 = obs.obs_properties_add_list(props, "ssid_mode", localization.translate('select_mode'), obslua.OBS_COMBO_TYPE_LIST, obslua.OBS_COMBO_FORMAT_INT)
	MY_OPTIONS_1 = {localization.translate('standart_repeat'), localization.translate('random_repeat')}
	for i,v in ipairs(MY_OPTIONS_1) do
		obs.obs_property_list_add_int(p2, v, i)
	end
	obs.obs_property_set_modified_callback(p2, set_props_visibility)
	obs.obs_properties_add_int(props, "ssid_total_seconds", localization.translate('repeat_every_sec'), 1, 100000, ssid_total_seconds)
	obs.obs_properties_add_int(props, "ssid_total_seconds_from", localization.translate('repeat_from'), 1, 100000, ssid_total_seconds_from)
	obs.obs_properties_add_int(props, "ssid_total_seconds_to", localization.translate('repeat_to'), 1, 100000, ssid_total_seconds_to)
	local p3 = obs.obs_properties_add_list(props, "ssid_source_name", localization.translate('select_source'), obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "ffmpeg_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p3, name, name)
			end
		end
	end
	local p4 = obs.obs_properties_add_list(props, "ssid_playlist_mode", localization.translate('select_playlist_mode'), obslua.OBS_COMBO_TYPE_LIST, obslua.OBS_COMBO_FORMAT_INT)
	MY_OPTIONS_1 = {localization.translate('standart_playlist'), localization.translate('random_playlist')}
	for i,v in ipairs(MY_OPTIONS_1) do
		obs.obs_property_list_add_int(p4, v, i)
	end
	obs.obs_properties_add_editable_list(props, "local_file_array", localization.translate('video_list'), obs.OBS_EDITABLE_LIST_TYPE_FILES, " (*.mp4 *.ts *.mov *.flv *.mkv *.avi *.gif *.webm);;", nil)
	obs.source_list_release(sources)
	obs.obs_properties_apply_settings(props, my_settings)
	return props
end

function set_props_visibility(props, property, settings)
	local ssid_mode = obs.obs_data_get_int(settings, "ssid_mode")
	obs.obs_property_set_visible(obslua.obs_properties_get(props, "ssid_total_seconds"), ssid_mode==1)
	obs.obs_property_set_visible(obslua.obs_properties_get(props, "ssid_total_seconds_from"), ssid_mode==2)
	obs.obs_property_set_visible(obslua.obs_properties_get(props, "ssid_total_seconds_to"), ssid_mode==2)
	return true
end

function script_description() 				--описание
	return [[
<center><h2>]] .. localization.translate('title') .. [[</h2></center>
<p>]] .. localization.translate('title_text') .. [[</p>
<p> </p>
<p><center><a href="https://github.com/Ssid113/obs-script-delay-repeat-media/releases">]] .. localization.translate('update_script') .. [[</a>  ]] .. localization.translate('script_ver') .. ssid_current_version .. [[</center></p>
<p><center><a href="https://github.com/Ssid113/obs-script-delay-repeat-media">Ssid113</a> - 2021</center><hr/></p>]]
end

function script_update(settings) 			--Обновление настроек.
	ssid_locale = obs.obs_data_get_int(settings, "ssid_locale")
	localization.setLocale(ssid_locale)	
	print(" ")
	print(localization.translate('func_update'))
	print(" ")
	disconnect_signal()
	ssid_visible = false
	ssid_switch = obs.obs_data_get_bool(settings, "ssid_switch")
	ssid_mode = obs.obs_data_get_int(settings, "ssid_mode")
	if ssid_mode == 1 then
		ssid_random = false
	else
		ssid_random = true
	end
	ssid_playlist_mode = obs.obs_data_get_int(settings, "ssid_playlist_mode")
	ssid_source_name = obs.obs_data_get_string(settings, "ssid_source_name")
	ssid_total_seconds = obs.obs_data_get_int(settings, "ssid_total_seconds")
	ssid_total_seconds_from = obs.obs_data_get_int(settings, "ssid_total_seconds_from")
	ssid_total_seconds_to = obs.obs_data_get_int(settings, "ssid_total_seconds_to")
	local_file_array = obs.obs_data_get_array(settings, "local_file_array")
	connect_signal()
	start_update()
	
	my_settings = settings
end

function script_save(settings) 				--сохраняем настройки
    obs.obs_data_set_bool(settings, "ssid_switch", ssid_switch)
	obs.obs_data_set_int(settings, "ssid_locale", ssid_locale)
	obs.obs_data_set_int(settings, "ssid_mode", ssid_mode)
	obs.obs_data_set_int(settings, "ssid_playlist_mode", ssid_playlist_mode)
	obs.obs_data_set_bool(settings, "ssid_random", ssid_random)
	obs.obs_data_set_int(settings, "ssid_total_seconds", ssid_total_seconds)
	obs.obs_data_set_int(settings, "ssid_total_seconds_from", ssid_total_seconds_from)
	obs.obs_data_set_int(settings, "ssid_total_seconds_to", ssid_total_seconds_to)
	obs.obs_data_set_string(settings, "ssid_source_name", ssid_source_name)
end

function script_load(settings) 				--загружаем настройки
	ssid_locale = obs.obs_data_get_int(settings, "ssid_locale")
	localization.setLocale(ssid_locale)	
	print(" ")
	print(localization.translate('func_load'))
	print(" ")
	ssid_switch = obs.obs_data_get_bool(settings, "ssid_switch")
	ssid_mode = obs.obs_data_get_int(settings, "ssid_mode")
	ssid_playlist_mode = obs.obs_data_get_int(settings, "ssid_playlist_mode")
	ssid_random = obs.obs_data_get_bool(settings, "ssid_random")
	ssid_total_seconds = obs.obs_data_get_int(settings, "ssid_total_seconds")
	ssid_total_seconds_ot = obs.obs_data_get_int(settings, "ssid_total_seconds_from")
	ssid_total_seconds_to = obs.obs_data_get_int(settings, "ssid_total_seconds_to")
	ssid_source_name = obs.obs_data_get_string(settings, "ssid_source_name")
	local_file_array = obs.obs_data_get_array(settings, "local_file_array")
end

function script_defaults(settings) 			--начальные значения
	obs.obs_data_set_default_bool(settings, "ssid_switch", false)
	obs.obs_data_set_default_int(settings, "ssid_locale", 1)
	obs.obs_data_set_default_int(settings, "ssid_mode", 1)
	obs.obs_data_set_default_int(settings, "ssid_playlist_mode", 1)
	obs.obs_data_set_default_bool(settings, "ssid_random", false)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds", 1)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds_from", 1)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds_to", 10)
	obs.obs_data_set_default_string(settings, "ssid_source_name", "")
	script_load(settings) --нам нужно загрузить данные до функции script_description()
	obs.obs_frontend_add_event_callback(on_event)
end

--function script_unload()
	--timers_remove()
--end

--function get_sceneitem_from_source_name_in_current_scene(name) --получаем медиа по имени
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

--function set_settings_source(source) 	--source = obs_source_t
--		local pr_settings = obs.obs_source_get_private_settings(source)
--		obs.obs_source_update(source, pr_settings)
--		obs.obs_data_release(pr_settings)
--end
