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

onClient('esx:player:join', Player.onJoin)

AddEventHandler('playerDropped', function(reason)

  local source = source
	local player = Player.all[source]

  if player then

		emit('esx:player:drop', player, reason)

    if player.identity ~= nil then
      player.identity:save(function()
        Identity.all[identity.id] = nil
      end)
    end

    player:save(function()
			Player.all[source] = nil
    end)

  end

end)

onRequest('esx:cache:player:get', function(source, cb, id)

  local player = Player.all[source]

  if player then
    cb(true, player:serialize())
  else
    cb(false, nil)
  end

end)

on('esx:player:load', function(player)
  print('^2loaded ^7' .. player.name .. ' (' .. player.source .. '|' .. player.identifier .. ')')
end)

on('esx:player:load:error', function(source, name)
  print(name .. ' (' .. source .. ') ^1load error')
end)

