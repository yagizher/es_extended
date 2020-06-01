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

if IsDuplicityVersion() then

  onClient('esx:request', function(name, id, ...)

    local client = source

    if module.requestCallbacks[name] == nil then
      print('request callback ^4' .. name .. '^7 does not exist')
      return
    end

    module.requestCallbacks[name](client, function(...)
      emitClient('esx:response', client, id, ...)
    end, ...)

  end)

  onClient('esx:response', function(id, ...)

    local client = source

    if module.callbacks[id] ~= nil then
      module.callbacks[id](client, ...)
      module.callbacks[id] = nil
    end

  end)

else

  onServer('esx:request', function(name, id, ...)

    if module.requestCallbacks[name] == nil then
      print('request callback ^4' .. name .. '^7 does not exist')
      return
    end

    module.requestCallbacks[name](client, function(...)
      emitServer('esx:response', id, ...)
    end, ...)

  end)


  onServer('esx:response', function(id, ...)

    if module.callbacks[id] ~= nil then
      module.callbacks[id](...)
      module.callbacks[id] = nil
    end

  end)

end
