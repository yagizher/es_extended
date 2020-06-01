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

local module = ESX.Modules['boot']

AddEventHandler('esx:manifest:check:pass', module.Boot)

AddEventHandler('esx:module:load:before', function(name, group)
  local str = string.format('^7/^5%s^7/^3%s^7] start', group, name)
  _print(str)

end)

AddEventHandler('esx:module:load:error', function(name, group)
  local str = string.format('[^7/^5%s^7/^3%s^7] start error', group, name)
  _print(str)
end)

AddEventHandler('luaconsole:getHandlers', function(cb)

  if GetResourceState('luaconsole') ~= 'started' then
    return
  end

  local name = GetCurrentResourceName()

  cb(name, function(code, env)
    if env ~= nil then
      for k,v in pairs(env) do _ENV[k] = v end
      return load(code, 'lc:' .. name, 'bt', _ENV)
    else
      return load(code, 'lc:' .. name, 'bt')
    end
  end)

end)

