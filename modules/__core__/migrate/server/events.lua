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

on('esx:db:init:done', function()

	print('ensuring migrations')

  local boot    = ESX.Modules['boot']
	local index   = 0
	local results = {}
	local manifest = LoadResourceFile(GetCurrentResourceName(), 'fxmanifest.lua')
	local start

	module.Ensure('base')

  for i=1, #boot.GroupNames, 1 do

    local group = boot.GroupNames[i]

    for i=1, #boot.EntriesOrders, 1 do
      local module = boot.EntriesOrders[i]
      module.Ensure(module, group)
    end
  end

  emit('esx:db:ready')

  ESX.Ready = true

  emit('esx:ready')

end)
