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

Player = Extends(Serializable, 'Player')

function Player:constructor(data)

  self.super:ctor(data)

  if data.identityId == nil then
    self:field('identityId')
  end

end

PlayerCacheConsumer = Extends(CacheConsumer)

function PlayerCacheConsumer:provide(key, cb)

  request('esx:cache:player:get', function(exists, data)
    cb(exists, exists and Player(data) or nil)
  end, key)

end

Cache.player = PlayerCacheConsumer()


