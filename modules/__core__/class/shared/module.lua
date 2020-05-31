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

module.debug = {
  extends = false,
  ctor    = false,
  set     = false,
}

local last

Extends = function(baseType, debugName)

  debugName         = debugName or '<anonymous>'
  local newTypeBase = {super = baseType}
  local newType     = setmetatable({super = baseType}, {__index = baseType})

  function newType.new(...)

    last = nil

    local self = newType.init(nil)

    if module.debug.ctor then
      newType.tracemethod(self, 'ctor', ...)
    end

    self:constructor(...)

    return self

  end

  function newType.init(self)

    local first    = self == nil
    local self     = self or {}
    local touched  = {}
    local data     = {}
    local fastpath = {}

    local this

    local __index = function(t, k)

      if touched[k] then
        return rawget(t, k)
      end

      if self[k] ~= nil then
        return self[k]
      end

      local v = newType[k]

      if type(v) ~= 'function' then

        if fastpath[k] ~= nil then
          return fastpath[k][k]
        end

        local caller = rawget(t, '__next')
        local obj    = caller

        while obj ~= nil do

          if obj[k] ~= nil then
            caller = obj
          end

          obj = obj.__next

        end

        if caller ~= nil then
          fastpath[k] = caller
          return fastpath[k][k]
        end

      end

      return v

    end

    local __newindex = function(t, k, v)

      if module.debug.set then
        this:traceset(k, v)
      end

      touched[k] = true
      rawset(t, k, v)

    end

    this = setmetatable(data, {__index = __index, __newindex = __newindex})
    this.__prev = last

    if last ~= nil then
      last.__next = this
    end

    last = this

    return this

  end

  function newType:ctor(...)

    if module.debug.ctor then
      newType.tracemethod(self, 'ctor', ...)
    end

    newType.init(self):constructor(...)

  end

  function newType:constructor(...)
    if self.super ~= nil then
      self.super:ctor(...)
    end
  end

  function newType:type()
    return newType
  end

  function newType:base()
    return baseType
  end

  function newType:typename()
    return debugName
  end

  function newType:traceset(k, v)
    print('^4' .. self:typename() .. '^1 set ^7' .. tostring(k) .. ' => ^2' .. tostring(v or 'nil'))
  end

  function newType:trace(...)
    print('^4' .. self:typename() .. '^7', ...)
  end

  function newType:tracemethod(name, ...)

    local args = {...}
    local str  = '^4' .. self:typename() .. '^7:^1' .. name .. '^7('

    for i=1, #args, 1 do

      local arg = args[i]

      if i > 1 then
        str = str .. ', '
      end

      str = str .. '^2' .. type(arg) .. '^7'

    end

    str = str .. ')'

    print(str)

  end

  if module.debug.extends then
    print('^4' .. newType:typename() .. '^1 extends ^4' .. (baseType and baseType:typename() or 'nil'))
  end

  return newType

end

DefineAccessor = function(baseType, name, get, set)

  return {
    get = DefineGetter(baseType, name, get),
    set = DefineSetter(baseType, name, set)
  }

end

HasGetter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local getter         = 'get' .. firstCharUpper

  return baseType[getter] ~= nil

end

DefineGetter = function(baseType, name, fn)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local getter         = 'get' .. firstCharUpper

  local get = fn or function(self)
    return self[name]
  end

  baseType[getter] = get

  return get

end

HasSetter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local setter         = 'set' .. firstCharUpper

  return baseType[setter] ~= nil

end

DefineSetter = function(baseType, name, fn)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local setter         = 'set' .. firstCharUpper

  local set = fn or function(self, val)
    self[name] = val
  end

  baseType[setter] = set

  return set

end
