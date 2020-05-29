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

M('db')
M('serializable')
M('table')

Persistent = Extends(Serializable)

function Persistent:constructor(schema, pk, data)

  self.super:constructor(data)

  self.__SCHEMA = schema
  self.__PK     = pk
  self.__ID     = data[pk]

end

local pass = function(x) return x end

Persist = function(schema, pk)

  local fields   = {}
  local dbfields = {}

  local pType = Extends(Persistent)

  local set = function(name, field, encode, decode)

    encode                  = encode or pass
    decode                  = decode or pass
    dbfields[#dbfields + 1] = field
    fields[name]            = {data = field, encode = encode, decode = decode}

  end

  pType.define = function(data)
    for i=1, #data, 1 do
      local entry = data[i]
      set(entry.name, entry.field, entry.encode, entry.decode)
    end
  end

  pType.findOne = function(key, value, cb)

    local keys  = ''
    local count = 0

    for k,v in pairs(fields) do

      local backticked = '`' .. v.data.name .. '`'

      if count > 0 then
        keys   = keys   .. ', '
      end

      keys  = keys   .. backticked
      count = count + 1

    end

    local sql = 'SELECT ' .. keys .. ' FROM `' .. schema .. '` WHERE `' .. fields[key].data.name .. '` = @value'

    MySQL.Async.fetchAll(sql, {['@value'] = value}, function(rows)

      if rows[1] == nil then
        cb(nil)
      else

        local row  = rows[1]
        local data = {}

        for k,v in pairs(fields) do
          data[k] = v.decode(row[v.data.name])
        end

        cb(pType:new(data))

      end

    end)

  end

  pType.find = function(key, value, cb)

    local keys  = ''
    local count = 0

    for k,v in pairs(fields) do

      local backticked = '`' .. v.data.name .. '`'

      if count > 0 then
        keys   = keys   .. ', '
      end

      keys  = keys   .. backticked
      count = count + 1

    end

    local sql = 'SELECT ' .. keys .. ' FROM `' .. schema .. '` WHERE `' .. fields[key].data.name .. '` = @value'

    MySQL.Async.fetchAll(sql, {['@value'] = value}, function(rows)

      cb(table.map(rows, function(e)

        local row  = e
        local data = {}

        for k,v in pairs(fields) do
          data[k] = v.decode(row[v.data.name])
        end

        cb(pType:new(data))

      end))

    end)

  end

  pType.ensure = function(key, data, cb)

    local id = data[key]

    if id == nil then

      local instance = pType:new(data)

      instance:save(function(id)
        cb(instance)
      end)

    else

      pType.findOne(key, id, function(instance)

        if instance == nil then

          local instance = pType:new(data)

          instance:save(function(id)
            cb(instance)
          end)

        else

          for k,v in pairs(data) do
            instance[k] = v
          end

          cb(instance)

        end

      end)

    end

  end

  function pType:constructor(data)

    data = data or {}

    self.super:constructor(schema, pk, data)

    for k,v in pairs(fields) do
      self:field(k, data[k])
    end

  end

  function pType:save(cb)

    local keys   = ''
    local values = ''
    local update = ''

    local data   = {
      ['@pk'] = pk,
      ['@id'] = self.__ID,
    }

    local count = 0

    for k,v in pairs(fields) do

      if self[k] ~= nil then

        local escaped    = '@' .. k
        local backticked = '`' .. v.data.name .. '`'

        if count > 0 then
          keys   = keys   .. ', '
          values = values .. ', '
          update = update .. ', '
        end

        keys          = keys   .. backticked
        values        = values .. escaped
        update        = update .. backticked .. '=' .. escaped
        data[escaped] = fields[k].encode(self[k])

        count = count + 1

      end

    end

    local sql = 'INSERT INTO `' .. schema .. '` (' .. keys .. ') VALUES (' .. values .. ') ON DUPLICATE KEY UPDATE ' .. update .. '; SELECT LAST_INSERT_ID();'

    MySQL.Async.fetchAll(sql, data, function(rows)

      if cb ~= nil then

        if self[pk] == nil then
          self[pk] = rows[2][1]['LAST_INSERT_ID()']
        end

          cb(id)

      end

    end)

  end

  on('esx:db:init', function(initTable, extendTable)
    initTable(schema, pk, dbfields)
  end)

  return Extends(pType)

end

