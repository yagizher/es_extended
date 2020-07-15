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
M('table')
M('ui.menu')
local HUD   = M('game.hud')
local utils = M('utils')

local spawn = {x = -269.4, y = -955.3, z = 31.2, heading = 205.8}

Identity = Extends(Serializable, 'Identity')

Identity.parseRole = module.Identity_parseRoles
Identity.getRole   = module.Identity_getRole
Identity.hasRole   = module.Identity_hasRole

IdentityCacheConsumer = Extends(CacheConsumer, 'IdentityCacheConsumer')

function IdentityCacheConsumer:provide(key, cb)

  request('esx:cache:identity:get', function(exists, identities)
    local instancedIdentities = nil
    if exists then
      instancedIdentities = table.map(identities, function(identity)
        return Identity(identity)
      end)
    end
    cb(exists, exists and instancedIdentities or nil)
  end, key)

end

Cache.identity = IdentityCacheConsumer()

-- @TODO: need to first select the identity server-side
-- then confirm to client (via request), and finally update it client side if confirmeds 
module.SelectIdentity = function(identity)
  if identity == nil then
    error('Expect identity to be defined')
  end

  ESX.Player:field('identity', identity)
  local position = identity:getPosition()

  request('esx:identity:getSavedPosition', function(savedPos)
      utils.game.doSpawn({

        x        = savedPos and savedPos.x or position.x,
        y        = savedPos and savedPos.y or position.y,
        z        = savedPos and savedPos.z or position.z,
        heading  = savedPos and savedPos.heading or position.heading,
        model    = 'mp_m_freemode_01',
        skipFade = false

      }, function()
        local playerPed = PlayerPedId()

        if Config.EnablePvP then
          SetCanAttackFriendly(playerPed, true, false)
          NetworkSetFriendlyFireOption(true)
        end

        if Config.EnableHUD then
          module.LoadHUD()
        end

        ESX.Ready = true

        emitServer('esx:client:ready')
        emit('esx:ready')

        Citizen.Wait(2000)

        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
      end)
  end, id)
end

module.LoadHUD = function()

  Citizen.CreateThread(function()

    while (not HUD.Frame) or (not HUD.Frame.loaded) do
      Citizen.Wait(0)
    end

    HUD.RegisterElement('display_name', 1, 0, '{{firstName}} {{lastName}}', ESX.Player.identity:serialize())

  end)

end

module.SavePosition = ESX.SetInterval(60000, function()
  if NetworkIsPlayerActive(PlayerId()) then
    local playerCoords = GetEntityCoords(PlayerPedId())
    local heading      = GetEntityHeading(PlayerPedId())
    local position     = {
      x       = math.round(playerCoords.x, 1),
      y       = math.round(playerCoords.y, 1),
      z       = math.round(playerCoords.z, 1),
      heading = math.round(heading, 1)
    }

    emitServer('esx:identity:updatePosition', position)
  end
end)
