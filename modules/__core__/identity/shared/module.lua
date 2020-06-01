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

module.Identity_parseRole = function(name)

  for k,v in pairs(Config.Roles) do

    local len  = k:len()
    local test = name:sub(1, len) == k

    if test then

      local entry = table.clone(v)
      entry.name  = name:sub(len + 2)

      return entry

    end

  end

end

module.Identity_getRole = function(self, name)
  return Identity.parseRole(name)
end

module.Identity_hasRole = function(self, name)
  return table.indexOf(self.roles, name) ~= -1
end
