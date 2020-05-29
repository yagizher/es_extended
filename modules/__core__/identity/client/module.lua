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

local utils = M("utils")

local spawn = {x = -269.4, y = -955.3, z = 31.2, heading = 205.8}

Identity = Extends(Serializable)

function Identity:constructor(data)

  self.super:constructor()

  for k,v in pairs(data) do
    self:field(k, v)
  end

end

IdentityCacheConsumer = Extends(CacheConsumer)

function IdentityCacheConsumer:constructor()

  self.super:constructor(function(key, cb)

    request('esx:cache:identity:get', function(exists, data)
      cb(exists, exists and Identity:new(data) or nil)
    end, key)

  end)

end

Cache.identity = IdentityCacheConsumer:new()

self.Menu = nil

self.OpenMenu = function(cb)

  utils.ui.showNotification(_U('identity_register'))

  self.Menu =
    Menu:new(
    "identity",
    {
      float = "center|middle",
      title = "Create Character",
      items = {
        {name = "firstName", label = "First name", type = "text", placeholder = "John"},
        {name = "lastName", label = "Last name", type = "text", placeholder = "Smith"},
        {name = "dob", label = "Date of birth", type = "text", placeholder = "01/02/1234"},
        {name = "isMale", label = "Male", type = "check", value = true},
        {name = "submit", label = "Submit", type = "button"}
      }
    }
  )

  self.Menu:on(
    "item.change",
    function(item, prop, val, index)
      if (item.name == "isMale") and (prop == "value") then
        if val then
          item.label = "Male"
        else
          item.label = "Female"
        end
      end
    end
  )

  self.Menu:on(
    "item.click",
    function(item, index)
      if item.name == "submit" then

        local props = self.Menu:kvp()

        if (props.firstName ~= '') and (props.lastName ~= '') and (props.dob ~= '') then

          self.Menu:destroy()
          self.Menu = nil

          request('esx:identity:register', cb, props)

          utils.ui.showNotification(_U('identity_welcome', props.firstName, props.lastName))
        else
          utils.ui.showNotification(_U('identity_fill_in'))
        end
      end
    end
  )
end

self.DoSpawn = function(data, cb)
  exports.spawnmanager:spawnPlayer(data, cb)
end

self.Init = function(id)

  if id == nil then
    error('Identity is not defined')
  end

  Cache.identity:resolve(id, function(exists, identity)

    if not exists then
      error('Identity not found')
    end

    ESX.Player:field('identity', identity)

    local playerPed = PlayerPedId()

    if Config.EnablePvP then
      SetCanAttackFriendly(playerPed, true, false)
      NetworkSetFriendlyFireOption(true)
    end

    ESX.Ready = true

    emitServer('esx:client:ready')
    emit('esx:ready')

  end)

end

self.EnsureIdentity = function()

  local player     = ESX.Player
  local identityId = player:getIdentityId()

  if identityId == nil then

    self.DoSpawn({

      x        = spawn.x,
      y        = spawn.y,
      z        = spawn.z,
      heading  = spawn.heading,
      model    = 'mp_m_freemode_01',
      skipFade = false

    }, function()

      self.OpenMenu(self.Init)

    end)

  else

    Cache.identity:fetch(identityId, function(exists, identity)

      if exists then

        self.Init(identityId)

      else

        self.DoSpawn({

          x        = spawn.x,
          y        = spawn.y,
          z        = spawn.z,
          heading  = spawn.heading,
          model    = 'mp_m_freemode_01',
          skipFade = false

        }, function()

          self.OpenMenu(self.Init)

        end)

      end

    end)

  end

end
