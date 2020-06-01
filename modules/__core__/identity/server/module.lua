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

M('table')
M('persistent')

local spawn = {x = -269.4, y = -955.3, z = 31.2, heading = 205.8}

Identity = Persist('identities', 'id')

Identity.define({
  {name = 'id',         field = {name = 'id',         type = 'INT',        length = nil, default = nil,                extra = 'NOT NULL AUTO_INCREMENT'}},
  {name = 'identifier', field = {name = 'identifier', type = 'VARCHAR',    length = 64,  default = 'UUID()',           extra = 'NOT NULL'}},
  {name = 'owner',      field = {name = 'owner',      type = 'VARCHAR',    length = 64,  default  = nil,               extra = 'NOT NULL'}},
  {name = 'position',   field = {name = 'position',   type = 'VARCHAR',    length = 255, default = json.encode(spawn), extra = nil}, encode = json.encode, decode = json.decode},
  {name = 'firstName',  field = {name = 'first_name', type = 'VARCHAR',    length = 32,  default = 'NULL',             extra = nil}},
  {name = 'lastName',   field = {name = 'last_name',  type = 'VARCHAR',    length = 32,  default = 'NULL',             extra = nil}},
  {name = 'DOB',        field = {name = 'dob',        type = 'VARCHAR',    length = 10,  default = 'NULL',             extra = nil}},
  {name = 'isMale',     field = {name = 'is_male',    type = 'INT',        length = nil, default = 1,                  extra = nil}},
  {name = 'roles',      field = {name = 'roles',      type = 'MEDIUMTEXT', length = nil, default = '[]',               extra = nil}},
})

Identity.all = setmetatable({}, {
  __index    = function(t, k) return rawget(t, tostring(k)) end,
  __newindex = function(t, k, v) rawset(t, tostring(k), v) end,
})

Identity.fromId = function(id)
  return Identity.all[id]
end

Identity.parseRole = module.Identity_parseRole

function Identity:constructor(data, source)
  self.super:ctor(data)
  self.source = source
end

Identity.getRole = module.Identity_getRole
Identity.hasRole = module.Identity_hasRole

function Identity:addRole(name)

  if not self:hasRole(name) then
    self.roles[#self.roles + 1] = name
    self:emit('role.add', name)
  end

end

function Identity:removeRole(name)

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

function Identity:getPlayer()
  return Player.fromId(self.source)
end
