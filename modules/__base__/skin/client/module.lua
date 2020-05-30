-- Copyright (c) Jérémie N'gadi
--
-- All rights reserved.
--
-- Even if 'All rights reserved' is very clear :
--
--   You shall not use any piece of this software in a commercial product / service
--   You shall not resell this software
--   You shall not provide any facility to install this particular software in a commercial product / service
--   If you redistribute this software, you must link to ORIGINAL repository at https://github.com/ESX-Org/es_extended
--   This copyright should appear in every part of the project code
local utils = M("utils")
M("ui.menu")
M("table")

module.lastSkin = nil
module.playerLoaded = false
module.cam = nil
module.isCameraActive = false

module.firstSpawn = true
module.zoomOffset = 1.5
module.camOffsetX = 0.0
module.camOffsetY = 1.2
module.camOffsetZ = 0.8
module.camPointOffset = 0.2
module.heading = 90.0
module.angle = 0.0

module.Init = function()
	local translations = run('data/locales/' .. Config.Locale .. '.lua')['Translations']
	LoadLocale('skin', Config.Locale, translations)
end

module.OpenMenu = function(submitCb, cancelCb, restrict)
	local playerPed = PlayerPedId()

	local props = {}
	local body = {}
	local clothes = {}

	local bodymenuelements = {}
	local clothesmenuelements = {}

	local bodyparts = {
		"sex",
		"face",
		"hair_1",
		"hair_2",
		"hair_color_1",
		"hair_color_2",
		"eye_color",
		"skin",
		"eyebrows_2",
		"eyebrows_1",
		"eyebrows_3",
		"eyebrows_4",
		"makeup_1",
		"makeup_2",
		"makeup_3",
		"makeup_4",
		"lipstick_1",
		"lipstick_2",
		"lipstick_3",
		"lipstick_4",
		"chest_1",
		"chest_2",
		"chest_3",
		"bodyb_1",
		"bodyb_2",
		"age_1",
		"age_2",
		"blemishes_1",
		"blemishes_2",
		"blush_1",
		"blush_2",
		"blush_3",
		"complexion_1",
		"complexion_2",
		"sun_1",
		"sun_2",
		"moles_1",
		"moles_2",
		"beard_1",
		"beard_2",
		"beard_3",
		"beard_4"
	}

	table.insert(
		bodymenuelements,
		1,
		{
			name = "back",
			label = "Back",
			type = "button"
		}
	)
	table.insert(
		clothesmenuelements,
		1,
		{
			name = "back",
			label = "Back",
			type = "button"
		}
	)

	TriggerEvent(
		"skinchanger:getSkin",
		function(skin)
			module.lastSkin = skin
		end
	)

	TriggerEvent(
		"skinchanger:getData",
		function(components, maxVals)
			local _components = {}

			-- Restrict menu
			if restrict == nil then
				for i = 1, #components, 1 do
					_components[i] = components[i]
				end
			else
				for i = 1, #components, 1 do
					local found = false

					for j = 1, #restrict, 1 do
						if components[i].name == restrict[j] then
							found = true
						end
					end

					if found then
						table.insert(_components, components[i])
					end
				end
			end

			-- Insert elements
			for i = 1, #_components, 1 do
				local value = _components[i].value
				local componentId = _components[i].componentId

				if componentId == 0 then
					value = GetPedPropIndex(playerPed, _components[i].componentId)
				end
				local data = {
					label = _components[i].label,
					name = _components[i].name,
					value = value,
					min = _components[i].min,
					textureof = _components[i].textureof,
					zoomOffset = _components[i].zoomOffset,
					camOffset = _components[i].camOffset,
					type = "slider"
				}

				local found = false
				if found == false then
					for _, v in ipairs(bodyparts) do
						if v == data.name then
							found = true
							table.insert(bodymenuelements, data)
							break
						end
					end
				end
				if found == false then
					table.insert(clothesmenuelements, data)
				end
			end

			module.CreateSkinCam()
			module.zoomOffset = _components[1].zoomOffset
			module.camOffset = _components[1].camOffset
		end
	)

	function createMainMenu()
		local menu =
			Menu.new(
			"principalmenu",
			{
				title = _U("skin:skin_menu"),
				float = "top|left",
				items = {
					{name = "body", label = "Body", type = "button"},
					{name = "clothes", label = "Clothes", type = "button"},
					{name = "done", label = "Submit", type = "button"}
				}
			}
		)

		menu:on(
			"item.click",
			function(item, index)
				if item.name == "body" then
					menu:destroy()
					menu = nil

					createBodySubmenu()
				elseif item.name == "clothes" then
					menu:destroy()
					menu = nil

					createClothesSubmenu()
				elseif item.name == "done" then
					if next(body) == nil then
						-- print("body false")
					elseif next(clothes) == nil then
						-- print("clothes false")
					else
						table.merge(props, body)
						table.merge(props, clothes)

						-- print(json.encode(props))
						menu:destroy()
						menu = nil
						module.DeleteSkinCam()

						TriggerServerEvent("esx_skin:save", props)
					end
				end
			end
		)
	end

	function createBodySubmenu()
		local menu =
			Menu.new(
			"bodymenu",
			{
				title = "Body",
				float = "top|left",
				items = bodymenuelements
			}
		)

		menu:on(
			"item.change",
			function(item, prop, val, index)
				TriggerEvent("skinchanger:change", item.name, item.value)
			end
		)

		menu:on(
			"item.click",
			function(item, index)
				if item.name == "back" then
					body = menu:kvp()

					menu:destroy()
					menu = nil

					createMainMenu()
				end
			end
		)
	end

	function createClothesSubmenu()
		local menu =
			Menu.new(
			"bodymenu",
			{
				title = "Clothes",
				float = "top|left",
				items = clothesmenuelements
			}
		)

		menu:on(
			"item.change",
			function(item, prop, val, index)
				TriggerEvent("skinchanger:change", item.name, item.value)
			end
		)

		menu:on(
			"item.click",
			function(item, index)
				if item.name == "back" then
					clothes = menu:kvp()
					-- print(json.encode(head))

					menu:destroy()
					menu = nil

					createMainMenu()
				end
			end
		)
	end

	createMainMenu()
end

module.CreateSkinCam = function()
	local playerPed = PlayerPedId()

	RenderScriptCams(false, false, 0, 1, 0)
	DestroyCam(module.cam, false)

	if not DoesCamExist(module.cam) then
		module.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
		SetCamActive(module.cam, true)
		RenderScriptCams(true, false, 500, true, true)
		module.isCameraActive = true
		SetEntityHeading(playerPed, 0.0)
		SetCamRot(module.cam, 0.0, 0.0, 270.0, 2)
	end
end

module.DeleteSkinCam = function()
	module.isCameraActive = false
	SetCamActive(module.cam, false)
	RenderScriptCams(false, true, 500, true, true)
	module.cam = nil
end

module.OpenSaveableMenu = function(submitCb, cancelCb, restrict)
	TriggerEvent(
		"skinchanger:getSkin",
		function(skin)
			lastSkin = skin
		end
	)

	module.OpenMenu(
		function(data, menu)
			menu.close()
			module.DeleteSkinCam()

			TriggerEvent(
				"skinchanger:getSkin",
				function(skin)
					TriggerServerEvent("esx_skin:save", skin)

					if submitCb ~= nil then
						submitCb(data, menu)
					end
				end
			)
		end,
		cancelCb,
		restrict
	)
end
