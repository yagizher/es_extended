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


M('player')

onRequest('esx:identity:register', function(source, cb, data)

  local player = Player.fromId(source)

  Identity.ensure({

    owner     = player.identifier,
    firstName = data.firstName,
    lastName  = data.lastName,
    DOB       = data.dob,
    isMale    = data.isMale

  }, function(identity)

    Identity.all[identity.id] = identity.id

    player:setIdentityId(identity.id)
    player:field('identity', identity)
    player:save()

    cb(identity.id)

  end)

end)

onRequest('esx:cache:identity:get', function(source, cb, id)

  local identity = Identity.all[id]

  if identity then

    cb(true, identity:serialize())

  else

    Identity.findOne('id', id, function(instance)

      if instance == nil then
        cb(false, nil)
      else
        Identity.all[id] = identity
        cb(true, identity:serialize())
      end

    end)

  end

end)
