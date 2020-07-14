
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

on('vehicleshop:hasEnteredMarker', function(zone)
	if zone == 'shopBuy' then
		module.currentAction     = 'shop_menu'
		module.currentActionMsg  = tostring("Press ~INPUT_CONTEXT~ to access the vehicle shop.")
		module.currentActionData = {}
	elseif zone == 'shopSell' then
		local playerPed = PlayerPedId()

		if IsPedSittingInAnyVehicle(playerPed) then
			local vehicle = GetVehiclePedIsIn(playerPed, false)

			if GetPedInVehicleSeat(vehicle, -1) == playerPed then

				for i=1, #module.sellableVehicles, 1 do
					if tostring(GetHashKey(module.sellableVehicles[i].model)) == tostring(GetEntityModel(vehicle)) then
						module.vehicleData = module.sellableVehicles[i]
						break
					end
				end

				if module.vehicleData then
					local resellPrice = module.Round(module.vehicleData.price / 100 * module.resellPercentage)
					local model = GetEntityModel(vehicle)
					local plate = module.Trim(GetVehicleNumberPlateText(vehicle))

					request("vehicleshop:checkOwnedVehicle", function(result)
						if result then
							module.currentAction    = 'resell_vehicle'
							module.currentActionMsg = tostring("Press ~INPUT_CONTEXT~ to sell your ~y~"..module.vehicleData.name.."~s~ for ~g~$"..module.GroupDigits(resellPrice).."~s~.")
			
							module.currentActionData = {
								vehicle = vehicle,
								label   = module.vehicleData.name,
								price   = resellPrice,
								model   = model,
								plate   = plate
							}
						else
							module.currentAction    = 'not_owned'
							module.currentActionMsg = "~r~You must own this vehicle in order to use this marker."
						end
					end, plate)
				else
					module.currentAction    = 'error'
					module.currentActionMsg = "~r~This vehicle is not sellable."
				end
			else
				module.currentAction    = 'not_driver'
				module.currentActionMsg = "~r~You must be in the driver seat in order to use this marker."
			end
		else
			module.currentAction    = 'not_in_car'
			module.currentActionMsg = "~r~You must be in a vehicle in order to use this marker."
		end
	end
end)

on('vehicleshop:hasExitedMarker', function(zone)
	module.currentAction = nil
end)

onServer('vehicleshop:removedOwnedVehicle', function()
	local playerPed = PlayerPedId()

	if IsPedSittingInAnyVehicle(playerPed) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)

		if GetPedInVehicleSeat(vehicle, -1) == playerPed then
			module.DeleteVehicle(vehicle)
		end
	end
end)