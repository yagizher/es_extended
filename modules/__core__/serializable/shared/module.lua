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

Serializable = Extends(nil)

function Serializable:constructor(data)
  self.__ACCESSORS = {}
end

function Serializable:field(name, value)
  self[name]             = value
  self.__ACCESSORS[name] = Extends.Accessor(self, name)
end

function Serializable:serialize()

  local data = {}

  for name, accessor in pairs(self.__ACCESSORS) do
    data[name] = accessor.get(self)
  end

  return data

end
