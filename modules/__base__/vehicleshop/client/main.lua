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

M('events')
M('serializable')
M('cache')
M('ui.menu')

local HUD   = M('game.hud')
local utils = M("utils")

module.Init()

-- Enter / Exit marker events & Draw Markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		local playerCoords = GetEntityCoords(PlayerPedId())
		local playerPed = PlayerPedId()
		
		module.isInMarker = false
		module.letSleep = true

		for k,v in pairs(module.zones) do
			if IsPedInAnyVehicle(playerPed, false) then
				if tostring(k) == "shopSell" then
					local distance = #(playerCoords - v.pos)

					if distance < module.drawDistance then
						module.letSleep = false

						if v.Type ~= -1 then
							-- DrawMarker(v.type, v.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.size.x, v.size.y, v.size.z, v.markerColor.r, v.markerColor.g, v.markerColor.b, 100, false, true, 2, true, nil, nil, false)
							DrawMarker_2(v.type, v.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.size.x, v.size.y, v.size.z, v.markerColor.r, v.markerColor.g, v.markerColor.b, 50, false, false, 2, true, nil, nil, false, true)
						end

						if distance < v.size.x then
							module.isInMarker  = true
							module.currentZone = k
						end
					end
				end
			else
				if tostring(k) == "shopBuy" then
					local distance = #(playerCoords - v.pos)

					if distance < module.drawDistance then
						module.letSleep = false

						if v.Type ~= -1 then
							-- DrawMarker(v.type, v.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.size.x, v.size.y, v.size.z, v.markerColor.r, v.markerColor.g, v.markerColor.b, 100, false, true, 2, true, nil, nil, false)
							DrawMarker_2(v.type, v.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.size.x, v.size.y, v.size.z, v.markerColor.r, v.markerColor.g, v.markerColor.b, 50, false, false, 2, true, nil, nil, false, true)
						end

						if distance < v.size.x then
							module.isInMarker  = true
							module.currentZone = k
						end
					end
				end
			end
		end

		if (module.isInMarker and not module.hasAlreadyEnteredMarker) or (module.isInMarker and module.lastZone ~= module.currentZone) then
			module.hasAlreadyEnteredMarker = true
			module.lastZone                = module.currentZone
			emit('vehicleshop:hasEnteredMarker', module.currentZone)
		end

		if not module.isInMarker and module.hasAlreadyEnteredMarker then
			module.hasAlreadyEnteredMarker = false
			emit('vehicleshop:hasExitedMarker', module.lastZone)
		end

		if module.letSleep then
			Citizen.Wait(500)
		end
	end
end)

-- Key controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if module.currentAction then
			utils.ui.showHelpNotification(module.currentActionMsg, false, false, 1)

			if IsControlJustReleased(0, 38) then
				if module.currentAction == 'shop_menu' then
					module.OpenShopMenu()
				elseif module.currentAction == "resell_vehicle" then
					module.SellVehicle()
				end

				module.currentAction = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)

Citizen.CreateThread(function()
	RequestIpl('shr_int') -- Load walls and floor

	local interiorID = 7170
	LoadInterior(interiorID)
	EnableInteriorProp(interiorID, 'csr_beforeMission') -- Load large window
	RefreshInterior(interiorID)
end)
