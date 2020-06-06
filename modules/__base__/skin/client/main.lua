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
M('constants')
M('events')
M('ui.menu')

--[[
module.Init()

Citizen.CreateThread(
	function()
		while true do
			Citizen.Wait(0)

			if module.isCameraActive then
				DisableControlAction(2, 30, true)
				DisableControlAction(2, 31, true)
				DisableControlAction(2, 32, true)
				DisableControlAction(2, 33, true)
				DisableControlAction(2, 34, true)
				DisableControlAction(2, 35, true)
				DisableControlAction(0, 25, true) -- Input Aim
				DisableControlAction(0, 24, true) -- Input Attack

				local playerPed = PlayerPedId()
				local coords = GetEntityCoords(playerPed)

				local angle = module.heading * math.pi / 180.0
				local theta = {
					x = math.cos(angle),
					y = math.sin(angle)
				}

				local pos = {
					x = coords.x + (module.zoomOffset * theta.x),
					y = coords.y + (module.zoomOffset * theta.y)
				}

				local angleToLook = module.heading - 140.0

				if angleToLook > 360 then
					angleToLook = angleToLook - 360
				elseif angleToLook < 0 then
					angleToLook = angleToLook + 360
				end

				angleToLook = angleToLook * math.pi / 180.0

				local thetaToLook = {
					x = math.cos(angleToLook),
					y = math.sin(angleToLook)
				}

				local posToLook = {
					x = coords.x + (module.zoomOffset * thetaToLook.x),
					y = coords.y + (module.zoomOffset * thetaToLook.y)
				}

				SetCamCoord(module.cam, pos.x+module.camOffsetX, pos.y + module.camOffsetY, coords.z+module.camOffsetZ)
				PointCamAtCoord(module.cam, posToLook.x, posToLook.y, coords.z - module.camPointOffset)

				-- NEED INPUT FROM NUI TO ROTATE CAMERA

				-- utils.ui.showHelpNotification(_U('skin:use_rotate_view'))
			else
				Citizen.Wait(500)
			end
		end
	end
)
]]--
-- NEED INPUT FROM NUI TO ROTATE CAMERA

-- Citizen.CreateThread(
-- 	function()
-- 		local angle = 90

-- 		while true do
-- 			Citizen.Wait(0)

-- 			if module.isCameraActive then
-- 				if IsControlPressed(0, 108) then
-- 					module.angle = angle - 1
-- 				elseif IsControlPressed(0, 109) then
-- 					module.angle = angle + 1
-- 				end

-- 				if module.angle > 360 then
-- 					module.angle = module.angle - 360
-- 				elseif angle < 0 then
-- 					module.angle = module.angle + 360
-- 				end

-- 				module.heading = angle + 0.0
-- 			else
-- 				Citizen.Wait(500)
-- 			end
-- 		end
-- 	end
-- )
