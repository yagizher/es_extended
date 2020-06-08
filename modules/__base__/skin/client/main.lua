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

-- TODO: move to a config file when it gets added to FxManifest
Config.componentsConfig = {
  [PV_COMP_BERD] = {id = "mask",        default = {0, 0},  label = 'Mask'             , bone = SKEL_Head       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_HAIR] = {id = "hair",        default = {4, 0},  label = 'Hair'             , bone = SKEL_Head       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_UPPR] = {id = "arms",        default = {14, 0},  label = 'Arms'             , bone = RB_R_ArmRoll    , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_LOWR] = {id = "legs",        default = {28, 0},  label = 'Legs'             , bone = MH_R_Knee       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_HAND] = {id = "holdable",    default = {0, 0},  label = 'Bag / Parachute'  , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_FEET] = {id = "shoes",       default = {12, 0},  label = 'Shoes'            , bone = PH_R_Foot       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_TEEF] = {id = "accessories", default = {10, 0},  label = 'Accessories'      , bone = SKEL_R_Clavicle , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_ACCS] = {id = "undershirt",  default = {13, 0},  label = 'Undershirt'       , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_TASK] = {id = "armor",       default = {0, 0},  label = 'Body armor'       , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_DECL] = {id = "decals",      default = {1, 0},  label = 'Decals'           , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_JBIB] = {id = "torso",       default = {24, 0},  label = 'Torso / Top'      , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
}

Config.defaultBlend = {45, 45, 45, 45, 45, 45}
Config.defaultBlendFaceMix = 5
Config.defaultBlendSkinMix = 5
Config.defaultBlendOverrideMix = 5
Config.defaultHairColor = {1, 1}

Config.humans     = table.concat({MP_M_FREEMODE_01, MP_F_FREEMODE_01}, table.filter(PED_MODELS_HUMANS, function(x) return (x ~= MP_M_FREEMODE_01) and (t ~= MP_F_FREEMODE_01) end))
Config.animals    = table.clone(PED_MODELS_ANIMALS)

Config.componentOrder = {
  PV_COMP_BERD,
  PV_COMP_HAIR,
  PV_COMP_UPPR,
  PV_COMP_LOWR,
  PV_COMP_HAND,
  PV_COMP_FEET,
  PV_COMP_TEEF,
  PV_COMP_ACCS,
  PV_COMP_TASK,
  PV_COMP_DECL,
  PV_COMP_JBIB,
}

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
