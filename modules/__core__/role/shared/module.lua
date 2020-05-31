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

--[[

local data = module.parse('job.lspd.boss')

-- print(M('utils').table.dump(data))

for i=1, #data, 1 do

  local entry = data[i]

  if entry.label ~= nil then
    local label = utils.string.parsetpl(entry.label, data)
    print('job label =>', label)
  end

end

local tpl = {'@test', ' foo ', '@a.b'}

local data = {
  test = 'this is a test',
  a    = {
    b = 'foo'
  }
}


-- print(utils.string.parsetpl(tpl, data))
]]--
