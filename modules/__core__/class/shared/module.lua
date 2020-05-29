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

local prototypes = {}

Extends = setmetatable({}, {

  __call = function(o, baseType)

    local newType

    if baseType == nil then

      newType = {}

    else

      newType = setmetatable({super = baseType}, {__index = baseType})

    end

    local mt  = {__index = newType}

    function newType:new(...)

      local newInst = setmetatable({}, mt)

      local override

      if type(newInst.constructor) == 'function' then
        override = newInst:constructor(...)
      end

      if override ~= nil then
        return override
      else
        return newInst
      end

    end

    -- Implementation of additional OO properties starts here --

    -- Return the type of the instance
    function newType:proto()
      return newType
    end

    -- Return the parent type of the instance
    function newType:prototype()
      return baseType
    end

    -- Return true if the caller is an instance of theType
    function newType:instanceOf(theType)

      local isInstanceOf = false
      local curType      = newType

      while (curType ~= nil) and (not isInstanceOf) do
        if curType == theType then
          isInstanceOf = true
        else
          curType = curType:prototype()
        end
      end

      return isInstanceOf

    end

    -- Return true if the caller is a type of theType
    function newType:typeOf(theType)

      local isTypeOf = false
      local curType  = theType

      while (curType ~= nil) and (not isTypeOf) do

        local proto = curType:prototype()

        if curType == newType then
          isTypeOf = true
        else
          curType = curType:prototype()
        end
      end

      return isTypeOf

    end

    -- Return true if the theType is a type of the caller
    function newType:prototypeOf(theType)

      local isPrototypeOf = false
      local curType       = theType

      while (curType ~= nil) and (not isPrototypeOf) do

        local proto = theType:prototype()

        if curType == theType then
          isPrototypeOf = true
        else
          curType = curType:prototype()
        end
      end

      return isPrototypeOf

    end

    -- Return prototype chain of caller (top parent is last element)
    function newType:prototypes()
      return prototypes[newType]
    end

    local cls   = newType
    local chain = {}

    while cls ~= nil do
      cls = cls:prototype()
      chain[#chain + 1] = cls
    end

    prototypes[newType] = chain

    return newType

  end

})

Extends.Accessor = function(baseType, name)

  return {
    get = Extends.Getter(baseType, name),
    set = Extends.Setter(baseType, name)
  }

end

Extends.HasGetter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local getter         = 'get' .. firstCharUpper

  return rawget(baseType, getter) ~= nil

end

Extends.Getter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local getter         = 'get' .. firstCharUpper

  local get = function(self)
    return self[name]
  end

  rawset(baseType, getter, get)

  return get

end

Extends.HasSetter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local setter         = 'set' .. firstCharUpper

  return rawget(baseType, setter) ~= nil

end

Extends.Setter = function(baseType, name)

  local firstCharUpper = name:gsub("^%l", string.upper)
  local setter         = 'set' .. firstCharUpper

  local set = function(self, val)
    self[name] = val
  end

  rawset(baseType, setter, set)

  return set

end
