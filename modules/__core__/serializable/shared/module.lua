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

Serializable = Extends(EventEmitter)

function Serializable:constructor(get, set, data)

  data = data or {}

  self.super:constructor(get, set)

  self.__ACCESSORS = {}

  for k,v in pairs(data) do
    self:field(k, v)
  end

end

function Serializable:field(name, value)

  rawset(self, name, value)

  self.__ACCESSORS[name] = {

    get = DefineGetter(self, name),

    set = DefineSetter(self, name, function(self, value)
      rawset(self, name, value)
      self:emit('change', name, value)
    end)

  }

end

function Serializable:serialize()

  local data = {}

  for name, accessor in pairs(self.__ACCESSORS) do
    data[name] = accessor.get(self)
  end

  return data

end
