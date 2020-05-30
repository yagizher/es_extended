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

-- From => http://lua-users.org/wiki/InheritanceTutorial

M('table')

local envs = {}

Extends = function(baseType, vars)

  local vars = vars or {}
  local env  = table.clone(envs[baseType] or {})

  for i=1, #vars, 1 do
    env[vars[i]] = 0
  end

  local baseType = baseType or {}
  local newType  = setmetatable({super = baseType}, {__index = baseType})

  envs[newType]  = env

  function newType.new(...)

    local data = table.clone(env)

    data.get = function(k)
      return rawget(data, k)
    end

    data.set = function(k, v)
      rawset(data, k, v)
      return v
    end

    local self = setmetatable(data, {__index = newType, __newindex = data})

    if type(newType.constructor) == 'function' then
      newType.constructor(self, data.get, data.set, ...)
    end

    return self

  end


  function newType:set(k, v)
    rawset(self, k, v)
  end

  function newType:get(k)
    return rawget(self, k)
  end

  return newType

end

DefineAccessor = function(baseType, name)

  return {
    get = DefineGetter(baseType, name),
    set = DefineSetter(baseType, name)
  }

end

HasGetter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local getter         = 'get' .. firstCharUpper

  return rawget(baseType, getter) ~= nil

end

DefineGetter = function(baseType, name, fn)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local getter         = 'get' .. firstCharUpper

  local get = fn or function(self)
    return self[name]
  end

  rawset(baseType, getter, get)

  return get

end

HasSetter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local setter         = 'set' .. firstCharUpper

  return rawget(baseType, setter) ~= nil

end

DefineSetter = function(baseType, name, fn)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local setter         = 'set' .. firstCharUpper

  local set = fn or function(self, val)
    self[name] = val
  end

  rawset(baseType, setter, set)

  return set

end
