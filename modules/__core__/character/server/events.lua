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
      -- request the user to register a new character
      emitClient("esx:character:request:register", player:getSource())
      print("we want you to create an ID sir !")
    else
      -- request the user to select between one of the characters
      emitClient("esx:character:request:select", player:getSource(), identities)
      print("identities has been found.")
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