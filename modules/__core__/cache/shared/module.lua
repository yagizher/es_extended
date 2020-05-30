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

M('class')
M('events')

-- Declare
Cache         = {}
CacheConsumer = Extends(EventEmitter)

function CacheConsumer:constructor(get, set)

  self.super:constructor(get, set)

  set('data', {})

  if self.provide == nil then

    function self:provide(key, cb)

      ESX.SetTimeout(0, function()
        cb(self:has(key), self:get(key))
      end)

    end

  end

end

function CacheConsumer:set(key, value, refresh)

  if refresh then

    self.data[key] = value
    self:emit('update', key, value)

  else

    local changed = (value ~= self.data[key])

    if changed then
      self.data[key] = value
      self:emit('update', key, value)
    end

  end

end

function CacheConsumer:get(key)
  return self.data[key]
end

function CacheConsumer:has(key)
  return self.data[key] ~= nil
end

function CacheConsumer:fetch(key, cb)

  self:provide(key, function(exists, data)

    if exists then
      self:set(key, data)
    end

    self:emit('fetch', key, exists, data)

    if cb ~= nil then
      cb(exists, data)
    end

  end)

end

function CacheConsumer:resolve(key, cb)

  if self:has(key) then

    if cb ~= nil then
      cb(true, self:get(key))
    end

  else
    self:fetch(key, cb)
  end

end

