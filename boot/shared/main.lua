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

for i=1, #module.GroupNames, 1 do

  local groupName = module.GroupNames[i]
  local group     = module.Groups[groupName]

  for j=1, #group, 1 do

    local name = group[j]

    if module.ModuleHasEntryPoint(name, groupName) then
      M(name, groupName)
    end

  end

end

ESX.Loaded = true

emit('esx:load')

if not IsDuplicityVersion() then
  Citizen.CreateThread(function()
    AddTextEntry('FE_THDR_GTAO', 'ESX')
  end)
end
