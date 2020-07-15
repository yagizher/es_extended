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

local utils = M('utils')
local identityModule = M('identity')
M("table")

module.menu = nil
module.selectedIdentity = nil

module.OpenMenu = function(cb)

  utils.ui.showNotification(_U('identity_register'))

  module.Menu = Menu("character_creation", {
    float = "center|middle",
    title = "Create Character",
    items = {
      {name = "firstName", label = "First name",    type = "text", placeholder = "John"},
      {name = "lastName",  label = "Last name",     type = "text", placeholder = "Smith"},
      {name = "dob",       label = "Date of birth", type = "text", placeholder = "01/02/1234"},
      {name = "isMale",    label = "Male",          type = "check", value = true},
      {name = "submit",    label = "Submit",        type = "button"}
    }
  })

  module.Menu:on("item.change", function(item, prop, val, index)

    if (item.name == "isMale") and (prop == "value") then
      if val then
        item.label = "Male"
      else
        item.label = "Female"
      end
    end

  end)

  module.Menu:on("item.click", function(item, index)

    if item.name == "submit" then

      local props = module.Menu:kvp()

      if (props.firstName ~= '') and (props.lastName ~= '') and (props.dob ~= '') then

        module.Menu:destroy()
        module.Menu = nil

        request('esx:character:creation', cb, props)

        utils.ui.showNotification(_U('identity_welcome', props.firstName, props.lastName))
      else
        utils.ui.showNotification(_U('identity_fill_in'))
      end

    end

  end)

end

module.RequestRegister = function()
  utils.game.doSpawn({

    x        = spawn.x,
    y        = spawn.y,
    z        = spawn.z,
    heading  = spawn.heading,
    model    = 'mp_m_freemode_01',
    skipFade = false

  }, function()

    module.OpenMenu()

  end)
end

module.RequestIdentitySelection = function(identities)
  local player     = ESX.Player

  local items = table.map(identities, function(identity)
    return {name = identity:getId(), label = identity:getFirstName() .. " " .. identity:getLastName(), identity = identity:serialize(), type = 'button'}
  end)

  table.insert(items, {name = "submit", label = "Enter The World", type = "button", shouldDestroyMenu = true})
  table.insert(items, {name = "register", label = "Or Create a New Identity", type = "button", shouldDestroyMenu = true})

  module.menu = Menu('character_selection', {
      title = 'Choose the identity to play',
      float = 'top|left',
      items = items
  })

  -- bind item click with module specific method onItemClicked
  module.menu:on('item.click', function(item)

    if item.shouldDestroyMenu then
      module.menu:destroy()
      module.menu = nil
    end

    if (item.name == "submit") then
      return module.SelectIdentity(module.selectedIdentity)
    end

    if (item.name == "register") then
      return module.OpenMenu()
    end

    module.selectedIdentity = Identity(item.identity)
  end)

end

module.SelectIdentity = function(identity)
  identityModule.SelectIdentity(identity)
end