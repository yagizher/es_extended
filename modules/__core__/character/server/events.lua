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

on('esx:player:load', function(player)
  Identity.allFromPlayer(player, function(hasBeenFound, identities)
    if not(hasBeenFound) then
      emitClient("esx:character:request:select", player:getSource())
    else
      emitClient("esx:character:request:select", player:getSource(), identities)
    end
  end, true)
end)

onRequest('esx:character:creation', function(source, cb, data)

  local player = Player.fromId(source)

  local identity = Identity({
    owner     = player.identifier,
    firstName = data.firstName,
    lastName  = data.lastName,
    DOB       = data.dob,
    isMale    = data.isMale
  })

  identity:save(function(id)

    Identity.all[id] = identity

    player:setIdentityId(id)
    player:field('identity', identity)
    player:save()

    cb(id)

  end)

end)

onRequest("esx:character:loadSkin", function(source, cb, id)
  print("Checking")
  local player = Player.fromId(source)

  MySQL.Async.fetchScalar('SELECT skin FROM identities WHERE id = @identityId',
  {
    ['@identityId'] = id
  }, function(skin)

    if (skin) then
      return cb(json.decode(skin))
    end
    
    return cb(nil)
  end)
end)