local obs = obslua					--obs
local selected_source

local ssid_switch = true 			--Флаг таймера
local ssid_random = false 			--рандомное срабатывание
local ssid_start = false  			--признак запуска функции таймера (чтобы не подписываться по несколько раз)
local ssid_total_seconds = 10 		--секунды таймера
local ssid_total_seconds_from = 1 	--секунды таймера для рандома от
local ssid_total_seconds_to = 10 	--секунды таймера для рандома до
local ssid_source_name = "" 		--имя источника
local ssid_sceneitem = nil 			--объект медиа источник

function on_off() 					--Функция включения таймера
	if ssid_switch and not ssid_start then 
		if ssid_random then
			local seconds = random(ssid_total_seconds_from, ssid_total_seconds_to)
			local mseconds = seconds*1000
			print("Секунд до нового таймера: " .. tostring(seconds))
			obs.timer_add(play_source, mseconds) --Подписываемся
			ssid_start = not ssid_start
		else
			print("Секунд до нового таймера: " .. tostring(ssid_total_seconds))
			obs.timer_add(play_source,ssid_total_seconds*1000) --Подписываемся
			ssid_start = not ssid_start
		end
		print("Скрипт запущен. Состояние активации таймера = " .. tostring(ssid_start))
	elseif not ssid_switch and ssid_start then
		ssid_start = not ssid_start
		play_source() 				--отписываемся
		print("Скрипт выключен. Состояние активации таймера = " .. tostring(ssid_start))
	else
		print("Текущее состояние = " .. tostring(ssid_start))
	end
end

function play_source() 				--Запустить источник
	if not ssid_start then			--Если состояние системы выключено, то надо отписаться от таймера
		obs.timer_remove(play_source)
	else
		if ssid_sceneitem then		--Если объект есть, то запускаем
			local pr_settings = obs.obs_source_get_private_settings(ssid_sceneitem)
			obs.obs_source_update(ssid_sceneitem, pr_settings)
			obs.obs_data_release(pr_settings)
			--obs.obs_source_release(source)
		end
	end
	if ssid_random then				--Для рандома требуется каждый раз отписываться и подписываться на таймер с указанием нового времени.
		obs.timer_remove(play_source)
		local seconds = random(ssid_total_seconds_from, ssid_total_seconds_to)
		local mseconds = seconds*1000
		print("Секунд до нового таймера: " .. tostring(seconds))
		obs.timer_add(play_source, mseconds)
	end
end

local u = 0 						--не удалять для рандома
function random(x, y) 				--random функция
    u = u + 1	
    if x ~= nil and y ~= nil then
        return math.floor(x +(math.random(math.randomseed(os.time()+u))*999999 %y))
    else
        return math.floor((math.random(math.randomseed(os.time()+u))*100))
    end
end

---------------------------------------------------------------НАСТРОЙКИ------------------------------------------------------------------
function script_properties() 		--Страница настроек
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int(props, "ssid_total_seconds", "Повторять каждые (сек):", 1, 100000, ssid_total_seconds)
	obs.obs_properties_add_bool(props, "ssid_random", "Повторять случайно")
	obs.obs_properties_add_int(props, "ssid_total_seconds_from", "От (сек):", 1, 100000, ssid_total_seconds_from)
	obs.obs_properties_add_int(props, "ssid_total_seconds_to", "До (сек):", 1, 100000, ssid_total_seconds_to)
	local p = obs.obs_properties_add_list(props, "ssid_source_name", "Выберите источник", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
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
	obs.obs_properties_add_bool(props, "ssid_switch", "Вкл/Выкл Таймер")
	obs.source_list_release(sources)
	return props
end

function script_description() 		--описание
	return "Скрипт для активации/перезапуска Медиа файла по истечении определенного времени.\nК примеру вам требуется во время трансляции периодически раз в 30 минут выводить информацию о себе(канале, подписках, рекламе и другое).\n\n1. Если активировано \"повторять случайно\" тогда повторение срабатывает в диапазоне ОТ и ДО секунд. Повторять каждые - игнорируется.\n2. Выберите источник для повторения.\n3. Теперь можно использовать Вкл/Выкл Таймер.\n\nMade by Ssid113"
end

function script_update(settings) 	--Обновление настроек.
	selected_source = obs.obs_data_get_string(settings, "selected_source")
	ssid_switch = obs.obs_data_get_bool(settings, "ssid_switch")
	ssid_random = obs.obs_data_get_bool(settings, "ssid_random")  
	ssid_total_seconds_from = obs.obs_data_get_int(settings, "ssid_total_seconds_from")
	ssid_total_seconds_to = obs.obs_data_get_int(settings, "ssid_total_seconds_to")
	ssid_total_seconds = obs.obs_data_get_int(settings, "ssid_total_seconds")
	ssid_source_name = obs.obs_data_get_string(settings, "ssid_source_name")
	obs.obs_source_release(ssid_sceneitem)
	ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
	on_off() 						--подписываемся на таймер
end

function script_save(settings) 		--сохраняем настройки
    obs.obs_data_set_bool(settings, "ssid_switch", ssid_switch)
	obs.obs_data_set_bool(settings, "ssid_random", ssid_random)
	obs.obs_data_set_int(settings, "ssid_total_seconds", ssid_total_seconds)
	obs.obs_data_set_int(settings, "ssid_total_seconds_from", ssid_total_seconds_from)
	obs.obs_data_set_int(settings, "ssid_total_seconds_to", ssid_total_seconds_to)
	obs.obs_data_set_string(settings, "ssid_source_name", ssid_source_name)
end

function script_load(settings) 		--загружаем настройки
	ssid_switch = obs.obs_data_get_bool(settings, "ssid_switch")
	ssid_random = obs.obs_data_get_bool(settings, "ssid_random")
	ssid_total_seconds = obs.obs_data_get_int(settings, "ssid_total_seconds")
	sid_total_seconds_ot = obs.obs_data_get_int(settings, "ssid_total_seconds_from")
	ssid_total_seconds_to = obs.obs_data_get_int(settings, "ssid_total_seconds_to")
	ssid_source_name = obs.obs_data_get_string(settings, "ssid_source_name")
	obs.obs_source_release(ssid_sceneitem)
	ssid_sceneitem = obs.obs_get_source_by_name(ssid_source_name)
end

function script_defaults(settings) 	--начальные значения
	obs.obs_data_set_default_bool(settings, "ssid_switch", false)
	obs.obs_data_set_default_bool(settings, "ssid_random", false)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds", 1)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds_from", 1)
	obs.obs_data_set_default_int(settings, "ssid_total_seconds_to", 10)
	obs.obs_data_set_default_string(settings, "ssid_source_name", "")
end

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