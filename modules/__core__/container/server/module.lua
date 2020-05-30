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

module.Containers = {}

local DataStore      = M('datastore')
local AddonAccount   = M('addonaccount')
local AddonInventory = M('addoninventory')

module.MissingDeps = 3

module.OnDependencyReady = function()

  module.MissingDeps = module.MissingDeps - 1

  if module.MissingDeps == 0 then
    emit('esx:container:ready')
  end

end

module.Ensure = function(name, label, owner, data)
  module.Containers[name] = module.Create(name, label, owner, data)
end

module.Get = function(name)
  return module.Containers[name]
end

module.Create = function(name, label, owner, data)

  local _module = {}

  data = data or {}

  for k,v in pairs(data) do
    _module[k] = v
  end

  _module._datastore = nil
  _module._account   = nil
  _module._inventory = nil

  _module.modified = {
    datastore = false,
    account   = false,
    inventory = false,
  }

  _module.name     = name
  _module.label    = label
  _module.owner    = owner

  _module.Init = function()

    if _module.owner == nil then

      _module._datastore = DataStore.GetSharedDataStore(name)
      _module._account   = AddonAccount.GetSharedAccount(name)
      _module._inventory = AddonInventory.GetSharedInventory(name)

    else

      _module._datastore = DataStore.GetDataStore(name, owner)
      _module._account   = AddonAccount.GetAccount(name, owner)
      _module._inventory = AddonInventory.GetInventory(name, owner)

    end

    _module._datastore.set('weapons', _module._datastore.get('weapons') or {})
    -- _module._datastore.set('clothes', _module._datastore.get('clothes') or {})

  end

  -- all
  _module.getAll = function()

    local data = {}

    local money   = _module.getMoney()
    local items   = _module.getItems()
    local weapons = _module.getWeapons()

    data[#data + 1] = {type = 'account', name = _module.name, count = money}

    for i=1, #items, 1 do
      data[#data + 1] = items[i]
    end

    for i=1, #weapons, 1 do

      local _data = {}

      for k,v in pairs(weapons[i]) do
        _data[k] = v
      end

      data[#data + 1] = _data

    end

    return data

  end

  _module.get = function(itemType, itemName)

    if itemType == 'account' then
      return {type = 'account', name = _module.name, count = _module.getMoney()}
    elseif itemType == 'item' then
      return _module.getItem(itemName)
    elseif itemType == 'weapon' then
      return _module.getWeapon(itemName)
    end

  end

  _module.set = function(itemType, itemName, itemCount)

    if itemType == 'account' then
      return _module.setMoney(itemCount)
    elseif itemType == 'item' then
      return _module.setItem(itemName, itemCount)
    elseif itemType == 'weapon' then
      return _module.setWeapon(itemName, itemCount)
    end

  end

  _module.add = function(itemType, itemName, itemCount)

    if itemType == 'account' then
      return _module.addMoney(itemCount)
    elseif itemType == 'item' then
      return _module.addItem(itemName, itemCount)
    elseif itemType == 'weapon' then
      return _module.addWeapon(itemName, itemCount)
    end

  end

  _module.remove = function(itemType, itemName, itemCount)

    if itemType == 'account' then
      return _module.removeMoney(itemCount)
    elseif itemType == 'item' then
      return _module.removeItem(itemName, itemCount)
    elseif itemType == 'weapon' then
      return _module.removeWeapon(itemName, itemCount)
    end

  end

  -- weapon
  _module.getWeapon = function(name)

    local weapons = _module._datastore.get('weapons')

    if weapons[name] == nil then
      weapons[name] = {count = 0}
    end

    return weapons[name]

  end

  _module.getWeapons = function()

    local weapons = _module._datastore.get('weapons')
    local data    = {}

    for k,v in pairs(weapons) do
      data[#data + 1] = {type = 'weapon', name = k, count = v.count}
    end

    return data

  end

  _module.setWeapon = function(name, count)

    local weapon = _module.getWeapon(name)
    weapon.count = 0

    _module.modified.datastore = true

  end

  _module.addWeapon = function(name, count)

    local weapon = _module.getWeapon(name)
    weapon.count = weapon.count + count

    _module.modified.datastore = true

  end

  _module.removeWeapon = function(name, count)

    local weapon = _module.getWeapon(name)

    weapon.count = weapon.count - count

    if weapon.count < 0 then
      weapon.count = 0
    end

    _module.modified.datastore = true

  end

  -- account
  _module.getMoney = function()
    return _module._account.getMoney()
  end

  _module.setMoney = function(amount)

    _module._account.setMoney(amount)
    _module.modified.account = true

  end

  _module.addMoney = function(amount)

    _module._account.addMoney(amount)
    _module.modified.account = true

  end

  _module.removeMoney = function(amount)

    _module._account.removeMoney(amount)
    _module.modified.account = true

  end

  -- inventory
	_module.getItem = function(name)
    return _module._inventory.getItem(name)
	end

  _module.getItems = function()

    local items = _module._inventory.getItems()
    local data  = {}

    for i=1, #items, 1 do
      data[#data + 1] = {type = 'item', name = items[i].name, count = items[i].count, label = items[i].label}
    end

    return data

  end

	_module.setItem = function(name, count)
    _module._inventory.setItem(name, count)
    _module.modified.inventory = true
  end

	_module.addItem = function(name, count)
    _module._inventory.addItem(name, count)
    _module.modified.inventory = true
	end

	_module.removeItem = function(name, count)
    _module._inventory.removeItem(name, count)
    _module.modified.inventory = true
  end

  _module.save = function()

    if _module.modified.datastore then
      _module._datastore.save()
    end

    if _module.modified.account then
      _module._account.save()
    end

    if _module.modified.inventory then
      -- _module._inventory.save()
    end

  end

  _module.Init()

  return _module

end
