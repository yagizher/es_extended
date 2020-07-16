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

local utils    = M('utils')
local identity = M('identity')
local camera   = M("camera")
M("table")

local spawn = {x = 402.869, y = -996.5966, z = -99.0003, heading = 180.01846313477}

module.isInMenu = false
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
  emit("esx:identity:openRegistration")
end

module.DoSpawn = function(data, cb)
  exports.spawnmanager:spawnPlayer(data, cb)
end

module.EnterMenu = function()
  module.DoSpawn({

    x        = spawn.x,
    y        = spawn.y,
    z        = spawn.z,
    heading  = spawn.heading,
    model    = 'mp_m_freemode_01',
    skipFade = false

  }, function()

    local playerPed = PlayerPedId()

  end)

  module.isInMenu = true

  Citizen.Wait(2000)

  ShutdownLoadingScreen()
  ShutdownLoadingScreenNui()
end

module.SetCamera = function()
  camera.start()

  camera.setRadius(1.25)
end

module.CameraToSkin = function()
  camera.pointToBone(SKEL_Head, vector3(0.0,0.0,0.0))
end

module.RequestIdentitySelection = function(identities)

  module.EnterMenu()

  module.SetCamera()

  local player = ESX.Player

  local items = {}

  if identities then
    items = table.map(identities, function(identity)
      return {type = 'button', name = identity:getId(), label = identity:getFirstName() .. " " .. identity:getLastName(), identity = identity:serialize()}
    end)

    table.insert(items, {name = "register", label = ">> Create a New Identity <<", type = "button", shouldDestroyMenu = true})
  else
    items = {
      {name = "register", label = ">> Create a New Identity <<", type = "button", shouldDestroyMenu = true}
    }
  end


  Citizen.Wait(100)

  module.characterMenu = Menu('character.select', {
      title = 'Choose An Identity',
      float = 'top|left',
      items = items
  })

  module.currentMenu = module.characterMenu

  -- bind item click with module specific method onItemClicked
  module.characterMenu:on('item.click', function(item)

    if item.name == 'register' then
      emit("esx:identity:openRegistration")
      module.characterMenu:destroy()
      camera.stop()
      module.currentMenu = nil
      module.isInMenu = false
    elseif item.name == "none" then

    else
      request("esx:character:loadSkin", function(skinContent)
        if skinContent then
          emit("esx:skin:loadSkin", skinContent)
          module.SelectCharacter(item.name, item.label, item.identity)
        else
          module.SelectCharacter(item.name, item.label, item.identity)
        end
      end, item.name)
    end

    -- if item.shouldDestroyMenu then
    --   module.characterMenu:destroy()
    --   module.currentMenu = nil
    -- end

    -- if (item.name == "submit") then
    --   return module.SelectIdentity(module.selectedIdentity)
    -- end

    -- if (item.name == "register") then
    --   return module.OpenMenu()
    -- end

    -- module.selectedIdentity = Identity(item.identity)
  end)

end

module.SelectCharacter = function(name, label, identity)

  module.CameraToSkin()

  local items = {
    {name = "submit", label = "Start", type = "button"},
    {name = "back", label = "Go Back", type = "button"}
  }
  
  if module.characterMenu.visible then
    module.characterMenu:hide()
  end

  module.confirmMenu = Menu('character.confirm', {
    title = 'Start with ' .. label .. '?',
    float = 'top|left',
    items = items
  })

  module.currentMenu = module.confirmMenu

  module.confirmMenu:on('destroy', function()
    module.characterMenu:show()
  end)

  module.confirmMenu:on('item.click', function(item, index)
    if item.name == "submit" then
      module.SelectIdentity(identity)
      module.confirmMenu:destroy()
      module.characterMenu:destroy()
      camera.stop()
      module.currentMenu = nil
      module.isInMenu = false
    elseif item.name == "back" then
      module.confirmMenu:destroy()
      
      module.currentMenu = module.characterMenu

      module.characterMenu:focus()
    end
  end)
end

module.SelectIdentity = function(identity)
  emit("esx:identity:selectIdentity", Identity(identity))
end