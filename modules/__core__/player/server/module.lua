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

M('persistent')

Player = Persist('players', 'id')

Player.define({
  {name = 'id',         field = {name = 'id',          type = 'INT',     length = nil, default = nil,    extra = 'NOT NULL AUTO_INCREMENT'}},
  {name = 'identifier', field = {name = 'identifier',  type = 'VARCHAR', length = 64,  default = nil,    extra = 'NOT NULL'}},
  {name = 'name',       field = {name = 'name',        type = 'VARCHAR', length = 255, default = 'NULL', extra = nil}},
  {name = 'identityId', field = {name = 'identity_id', type = 'VARCHAR', length = 64,  default = 'NULL', extra = nil}},
})

Player.all = setmetatable({}, {
  __index    = function(t, k) return rawget(t, tostring(k)) end,
  __newindex = function(t, k, v) rawset(t, tostring(k), v) end,
})

Player.fromId = function(id)
  return Player.all[tostring(id)]
end

Player.onJoin = function(source)

  local name = GetPlayerName(source)

  Citizen.CreateThread(function()

    while not ESX.Ready do
      Citizen.Wait(0)
    end

    if not Player.all[source] then

      -- Get identifier
      local identifiers = GetPlayerIdentifiers(source)
      local identifier  = nil

      for i=1, #identifiers, 1 do

        local current = identifiers[i]

        if current:match('license:') then
          identifier = current:sub(9)
          break
        end

      end

      print('loading ' .. name .. ' (' .. source .. '|' .. (identifier or '<no identifier>') .. ')')

      -- Load
      if identifier == nil then

        emit('esx:player:load:error', source, name)
        emitClient('esx:player:load:error', source)

      else

        Player.ensure({
          identifier = identifier
        }, {
          identifier = identifier,
          name       = name,
        }, function(player)

          player:field('source', source)
          player:on('change', print)

          Player.all[source] = player

          emit('esx:player:load', player)
          emitClient('esx:player:load', source, source)

          player:save()

        end)

      end

    end

  end)

end

local p = Player.new({})

p = nil


