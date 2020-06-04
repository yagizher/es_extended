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

local JSONFiles = {
  {'PED_BONE_INDEXES', 'data/ped_bones.json'},
}

local loadJSONFile = function(key, path)
  local data  = json.decode(LoadResourceFile(__RESOURCE__, path))
  module[key] = data
end

for i=1, #JSONFiles, 1 do
  local entry = JSONFiles[i]
  loadJSONFile(entry[1], entry[2])
end

module.DEG2RAD = math.pi / 180.0
module.RAD2DEG = 180.0 / math.pi
