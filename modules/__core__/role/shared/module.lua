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

M('class')
M('events')
M('string')

local utils = M('utils')

module.parse = function(name)

  local chain = string.split(name, '.')
  local data  = {}
  local curr  = ''

  for i=1, #chain, 1 do

    local part  = chain[i]
    local entry

    if i > 1 then
      curr = curr .. '.'
    end

    curr = curr .. part

    local found = false

    for k,v in pairs(Config.Roles) do

      local test = (curr == k)

      if test then

        found      = true
        entry      = table.clone(v)
        entry.name = curr
        entry.part = part

        data[#data + 1] = entry

        break

      end
    end

    if not found then
      data[#data + 1] = {name = curr, part = part}
    end

  end

  return data

end

Enrolable = Extends(EventEmitter, 'Enrolable')

function Enrolable:constructor()
  self.roles = {}
end

function Enrolable.parseRole(name)
  return module.parse(name)
end

function Enrolable:hasRole(name)
  return table.indexOf(self.roles, name) ~= -1
end

function Enrolable:addRole(name)

  if not self:hasRole(name) then
    self.roles[#self.roles + 1] = name
    self:emit('role.add', name)
  end

end

function Enrolable:removeRole(name)

  local newRoles = {}
  local found    = false

  for i=1, #self.roles, 1 do

    local role = self.roles[i]

    if role == name then
      found = true
    else
      newRoles[#newRoles + 1] = role
    end

  end

  self.roles = newRoles

  if found then
    self:emit('role.remove', name)
  end

end

--[[
local data = module.parse('job.lspd.boss')

print(M('utils').table.dump(data))

for i=1, #data, 1 do

  local entry = data[i]

  if entry.label ~= nil then
    local label = utils.string.parsetpl(entry.label, data)
    print('job label =>', label)
  end

end
]]--
