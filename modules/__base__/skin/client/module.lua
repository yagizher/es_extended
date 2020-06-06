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

module.Editor = Extends(EventEmitter, 'SkinEditor')

local SkinEditor = module.Editor
local humans     = table.concat({MP_M_FREEMODE_01, MP_F_FREEMODE_01}, table.filter(PED_MODELS_HUMANS, function(x) return (x ~= MP_M_FREEMODE_01) and (t ~= MP_F_FREEMODE_01) end))
local animals    = table.clone(PED_MODELS_ANIMALS)

local componentsConfig = {
  [PV_COMP_BERD] = {id = "mask",        default = 0,  label = 'Mask'             , bone = SKEL_Head       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_HAIR] = {id = "hair",        default = 4,  label = 'Hair'             , bone = SKEL_Head       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_UPPR] = {id = "arms",        default = 14,  label = 'Arms'             , bone = RB_R_ArmRoll    , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_LOWR] = {id = "legs",        default = 28,  label = 'Legs'             , bone = MH_R_Knee       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_HAND] = {id = "holdable",    default = 0,  label = 'Bag / Parachute'  , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_FEET] = {id = "shoes",       default = 12,  label = 'Shoes'            , bone = PH_R_Foot       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_TEEF] = {id = "accessories", default = 10,  label = 'Accessories'      , bone = SKEL_R_Clavicle , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_ACCS] = {id = "undershirt",  default = 13,  label = 'Undershirt'       , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_TASK] = {id = "armor",       default = 0,  label = 'Body armor'       , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_DECL] = {id = "decals",      default = 1,  label = 'Decals'           , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
  [PV_COMP_JBIB] = {id = "torso",       default = 24,  label = 'Torso / Top'      , bone = SKEL_ROOT       , offset = vector3(0.0, 0.0, 0.0), radius = 1.25},
}

local componentOrder = {
  PV_COMP_BERD,
  PV_COMP_HAIR,
  PV_COMP_UPPR,
  PV_COMP_LOWR,
  PV_COMP_HAND,
  PV_COMP_FEET,
  PV_COMP_TEEF,
  PV_COMP_ACCS,
  PV_COMP_TASK,
  PV_COMP_DECL,
  PV_COMP_JBIB,
}

local getComponentIdentifierFromNumber = function(num)
  return componentsConfig[num].id
end

local getComponentNumberFromIdentifier = function(id)
  for k,v in pairs(componentsConfig) do
    if (v.id == id) then
      return k
    end
  end
  return nil
end

function SkinEditor:constructor(ped)

  self.super:ctor()

  self._ped = 0

  self.tick                = nil
  self.cam                 = nil
  self.mainMenu            = nil
  self.currentMenu         = nil
  self.ped                 = ped
  self.camIsActive         = false
  self.camRadius           = 1.25
  self.camCoords           = vector3(0.0, 0.0, 0.0)
  self.camPolarAngle       = 0.0
  self.camAzimuthAngle     = 0.0
  self.camTargetBone       = SKEL_ROOT
  self.camTargetBoneOffset = vector3(0.0, 0.0, 0.0)
  self.timestamp           = utils.time.timestamp()
  self.modelTimeout        = nil

  self.skin                = {}

  self:bindEvents()
  self:ensurePed()

end

function SkinEditor:destructor()

  self:unbindEvents()
  self:disableCam()
  self.mainMenu:destroy()

  self.super:destructor()

end

function SkinEditor:save()
  request('skin:save', function()
    self:destructor()
  end, self.skin)
end

function SkinEditor:bindEvents()

  self.onMouseMoveOffest = on('mouse:move:offset', function(offsetX, offsetY, data)

    -- Mouse not inside menu
    if not self.currentMenu.mouseIn then
      
      if data.down[0] then

        self.camPolarAngle   = self.camPolarAngle   + offsetX / 5.0;
        self.camAzimuthAngle = self.camAzimuthAngle + offsetY / 5.0;

        self.camPolarAngle = self.camPolarAngle % 360

        if self.camAzimuthAngle >= 180 then
          self.camAzimuthAngle = 180;
        elseif self.camAzimuthAngle <= 0 then
          self.camAzimuthAngle = 0;
        end

      elseif data.down[2] then

        if data.direction.right then
          self.timestamp = self.timestamp + 250
        elseif data.direction.left then
          self.timestamp = self.timestamp - 250
        end

      end

    end

  end)

  self.onMouseWheel = on('mouse:wheel', function(delta)
    
    if not self.currentMenu.mouseIn then

      self.camRadius = self.camRadius + delta * -0.25
      
      if self.camRadius < 0.75 then
        self.camRadius = 0.75
      elseif self.camRadius > 2.5 then
        self.camRadius = 2.5
      end

    end

  end)

end

function SkinEditor:unbindEvents()

  off('mouse:move:offset', self.onMouseMoveOffest)
  off('mouse:move:wheel',  self.onMouseWheel)

end

function SkinEditor:getPed()
  self:ensurePed()
  return self._ped
end

function SkinEditor:ensurePed()

  local ped = type(self.ped) == 'function' and self.ped() or self.ped

  if ped ~= self._ped then

    self._ped                 = ped
    self.pedModel             = GetEntityModel(ped)
    self.isPedPlayer          = IsPedAPlayer(ped)
    self.isPedHuman           = utils.game.isHumanModel(self.pedModel)
    self.isPedFreemode        = self.isPedHuman and utils.game.isFreemodeModel(self.pedModel)
    self.canEnforceComponents = self.isPedFreemode

    if self.isPedPlayer then
      
      self.player = NetworkGetPlayerIndexFromPed(self._ped)

      if self.player ~= PlayerId() then
        error('Editing other player is forbidden')
      end

    end

    if self.isPedHuman then
      self.models = humans
    else
      self.models = animals
    end

  end

end

function SkinEditor:start()

  self:enableCam()
  self:openMenu()

  self.tick = ESX.SetTick(function()
    self:onTick()
  end)

  self:pointBone(SKEL_ROOT)

  self:emit('start')

end

function SkinEditor:stop()

  ESX.ClearTick(self.tick)

  self:destroyCam()
  self:destroyMenu()

  self:emit('stop')

end

function SkinEditor:ensureCam()

  if not DoesCamExist(self.cam) then
    self.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
  end

end

function SkinEditor:destroyCam()
  self:disableCam()
  DestroyCam(self.cam, false)
  self.cam = nil
end

function SkinEditor:destroyMenu()
  self.mainMenu:destroy()
  self.mainMenu = nil
end

function SkinEditor:enableCam()

  local ped       = self:getPed()
  local pedCoords = GetEntityCoords(ped)
  local forward   = GetEntityForwardVector(ped)

  self.camRadius                           = 1.25
  self.camCoords                           = pedCoords + forward * self.camRadius
  self.camPolarAngle, self.camAzimuthAngle = utils.math.world3DtoPolar3D(pedCoords, self.camCoords)

  self:ensureCam()

  SetCamActive(self.cam, true)
  RenderScriptCams(true, false, 500, true, true)

  SetCamCoord(self.cam, self.camCoords.x, self.camCoords.y, self.camCoords.z)

  self.camIsActive = true

  self:emit('cam.enable')

end

function SkinEditor:disableCam()

  SetCamActive(module.cam, false)
  RenderScriptCams(false, true, 500, true, true)

  self.camIsActive = false

  self:emit('cam.disable')

end

function SkinEditor:onTick()

  -- cam
  local ped    = self:getPed()
  local coords = GetPedBoneCoords(ped, self.camTargetBone, self.camTargetBoneOffset.x, self.camTargetBoneOffset.y, self.camTargetBoneOffset.z)

  self.camCoords = utils.math.polar3DToWorld3D(coords, self.camPolarAngle, self.camAzimuthAngle, self.camRadius)

  SetCamCoord(self.cam, self.camCoords.x, self.camCoords.y, self.camCoords.z)

  -- time
  local w, d, h, m, s = utils.time.fromTimestamp(self.timestamp)
  NetworkOverrideClockTime(h, m, s)

end

function SkinEditor:pointBone(boneIndex, offset)

  self.camTargetBone       = boneIndex
  self.camTargetBoneOffset = offset or vector3(0.0, 0.0, 0.0)

  PointCamAtPedBone(self.cam, self:getPed(), self.camTargetBone, self.camTargetBoneOffset.x, self.camTargetBoneOffset, self.camTargetBoneOffset.z, 0)

end

function SkinEditor:openMenu()

  local items = {
    {name = 'model',   label = self:getModelLabel(0),         type = 'slider', max   = #self.models - 1, visible = self.isPedPlayer},
    {name = 'enforce', label = 'Enforce compatible elements', type = 'check',  value = false,            visible = self.canEnforceComponents},
  }

  for i=1, #componentOrder, 1 do

    local comp  = componentOrder[i]
    local label = componentsConfig[comp].label

    items[#items + 1] = {type= 'button', name = 'component.' .. GetEnumKey(PED_COMPONENTS, comp), component = comp, label = label}

  end

  items[#items + 1] = {name = 'sep', label = ""}
  items[#items + 1] = {type= 'button', name = 'save', label = "💾 Save 💾"}

  self.mainMenu = Menu('skin', {
    title = 'Character',
    float = 'top|left', -- not needed, default value
    items = items
  })

  self.currentMenu = self.mainMenu

  self.mainMenu:on('item.change', function(item, prop, val, index)
    self:onItemChanged(item, prop, val, index)
  end)

  self.mainMenu:on('item.click', function(item, index)
    
    if item.component ~= nil then
      self:openComponentMenu(item.component)
    elseif item.name == 'save' then
      self:save()
    end

  end)

end

function SkinEditor:onItemChanged(item, prop, val, index)
  
  if prop == 'value' then

    if item.name == 'model' then

      item.label = self:getModelLabel(val)

      -- Ensure not spamming model changes
      if self.modelTimeout ~= nil then
        ESX.ClearTimeout(self.modelTimeout)
      end

      self.modelTimeout = ESX.SetTimeout(250, function()

        local model  = self.models[val + 1]
        local ped    = self:getPed()
  
        utils.game.requestModel(model, function()
          
          local byName = self.mainMenu:by('name')

          SetPlayerModel(self.player, model)
          editor:setModel(self:getModelLabel(model))
  
          ped = self:getPed()
          
          byName['enforce'].visible = self.isPedFreemode

          SetPedDefaultComponentVariation(ped)
          SetModelAsNoLongerNeeded(model)

          self:pointBone(self.camTargetBone, self.camTargetBoneOffset)
  
        end)

      end)

    elseif item.name == 'ensure' then
    
      self.canEnforceComponents = val

    end
  
  end

end

function SkinEditor:getModelLabel(value)
  return 'Model (' .. PED_MODELS_BY_HASH[self.models[value + 1]] .. ')'
end

function SkinEditor:setComponentVariation(component, drawableId, textureId, paletteId)

  textureId = textureId or 0
  paletteId = paletteId or 0

  local ped = self:getPed()

  if self.canEnforceComponents then

    local byComponent = self.mainMenu:by('component')
    local enforced    = utils.game.setEnforcedPedComponentVariation(ped, component, drawableId, textureId, paletteId)

    for k,v in pairs(enforced) do
    
      local compId = tonumber(k)
  
      for i=1, #v, 1 do
        local forcedComponent     = v[i]
        byComponent[compId].value = forcedComponent[2]
      end
  
    end
    
  else
    SetPedComponentVariation(ped, component, drawableId, textureId, paletteId)
  end
end

function SkinEditor:setModel(model)
  self.skin['model'] = model
end

function SkinEditor:setSkinComponentDrawable(componentId, drawableId)
  local textureId = self:getSkinComponentTexture(componentId) or 0

  self.skin[getComponentIdentifierFromNumber(componentId)] = {
    drawable = drawableId,
    texture = textureId,
  }
end

function SkinEditor:setSkinComponentTexture(componentId, textureId)
  local drawableId = self:getSkinComponentDrawable(componentId) or 0

  self.skin[getComponentIdentifierFromNumber(componentId)] = {
    drawable = drawableId,
    texture = textureId,
  }
end

-- either by componentId or component identifier (mask)
function SkinEditor:getSkinComponentDrawable(component)
  if type(component) == 'number' then
    if (self.skin[getComponentIdentifierFromNumber(component)]) then
      return self.skin[getComponentIdentifierFromNumber(component)].drawable or 0
    else
      return 0
    end
  else
    if (self.skin[getComponentNumberFromIdentifier(component)]) then
      return self.skin[getComponentIdentifierFromNumber(component)].drawable or 0
    else
      return 0
    end
  end
end

-- either by componentId or component identifier (mask)
function SkinEditor:getSkinComponentTexture(component)
  if type(component) == 'number' then
    if (self.skin[getComponentIdentifierFromNumber(component)]) then
      return self.skin[getComponentIdentifierFromNumber(component)].texture or 0
    else
      return 0
    end
  else
    if (self.skin[getComponentNumberFromIdentifier(component)]) then
      return self.skin[getComponentIdentifierFromNumber(component)].texture or 0
    else
      return 0
    end
  end
end

function SkinEditor:openComponentMenu(comp)

  local cfg = componentsConfig[comp]

  self.camRadius = cfg.radius
  
  self:pointBone(cfg.bone, cfg.offset)

  local items = {}
  local label = cfg.label

  local drawable = self:getSkinComponentDrawable(comp)
  local texture = self:getSkinComponentTexture(comp)

  self:setSkinComponentDrawable(comp, drawable)
  self:setSkinComponentTexture(comp, texture)

  local getDrawableLabel = function(drawable)
    local currentDrawable = self:getSkinComponentDrawable(comp)
    return 'Model (' .. (currentDrawable + 1) .. ' / ' .. (GetNumberOfPedDrawableVariations(self._ped, comp)) .. ')'
  end

  local getTextureLabel = function(texture)
    local currentDrawable = self:getSkinComponentDrawable(comp)
    local currentTexture = self:getSkinComponentTexture(comp)
    return 'Variant (' .. (currentTexture + 1) .. ' / ' .. (GetNumberOfPedTextureVariations(self._ped, comp, currentDrawable) + 1) .. ')'
  end

  items[#items + 1] = {
    name  = 'drawable',
    label = getDrawableLabel(drawable),
    type  = 'slider',
    min   = 0,
    max   = GetNumberOfPedDrawableVariations(self._ped, comp),
    value = drawable,
  }

  items[#items + 1] = {
    name  = 'texture',
    label = getTextureLabel(texture),
    type  = 'slider',
    min   = 0,
    max   = GetNumberOfPedTextureVariations(self._ped, comp, GetPedDrawableVariation(self._ped, comp)),
    value = texture,
  }

  items[#items + 1] = {name = 'submit', label = '>> apply <<', type = 'button'}
  
  if self.mainMenu.visible then
    self.mainMenu:hide()
  end

  
  local menu = Menu('skin.component.' .. GetEnumKey(PED_COMPONENTS, comp), {
    title = label,
    float = 'top|left', -- not needed, default value
    items = items
  })

  self.currentMenu = menu

  menu:on('destroy', function()
    self.mainMenu:show()
  end)

  menu:on('item.change', function(item, prop, val, index)
    
    if prop == 'value' then

      local byName = menu:by('name')

      if item.name == 'drawable' then
        self:setSkinComponentDrawable(comp, val)
        self:setSkinComponentTexture(comp, 0)
        textureMax = GetNumberOfPedTextureVariations(self._ped, comp, self:getSkinComponentDrawable(comp))

        byName['drawable'].label = getDrawableLabel(self:getSkinComponentDrawable(comp))
        byName['texture' ].max   = textureMax
        byName['texture' ].value = 0

      elseif item.name == 'texture' then
        self:setSkinComponentTexture(comp, val)
      end

      local currentTexture  = self:getSkinComponentTexture(comp)
      local currentDrawable = self:getSkinComponentDrawable(comp)

      byName['texture' ].label = getTextureLabel()
    
      self:setComponentVariation(comp, currentDrawable, currentTexture)
    end

  end)

  menu:on('item.click', function(item, index)
    
    if item.name == 'submit' then
      
      menu:destroy()
      
      self.currentMenu = self.mainMenu

      self.mainMenu:focus()
      
      local ped       = self:getPed()
      local pedCoords = GetEntityCoords(ped)
      local forward   = GetEntityForwardVector(ped)

      self.camRadius                           = 1.25
      self.camCoords                           = pedCoords + forward * self.camRadius
      self.camPolarAngle, self.camAzimuthAngle = utils.math.world3DtoPolar3D(pedCoords, self.camCoords)

      self:pointBone(SKEL_ROOT)

    end

  end)

end

module.loadPlayerSkin = function(skin)

  local model  = GetHashKey(skin['model'])
  SetPlayerModel(PlayerId(), model)

  local playerPed = GetPlayerPed(-1)

  for componentId, componentConfig in pairs(componentsConfig) do
    local skinComponent = skin[componentConfig.id]
    local drawableId = skinComponent.drawable
    local textureId = skinComponent.texture

    SetPedComponentVariation(playerPed, componentId, drawableId, textureId, 0)
  end
end

module.init = function()
  -- check if the player already has a skin
  request("skin:getIdentitySkin", function(skin)

    if not(skin) then
      module.askOpenEditor()
    else
      module.loadPlayerSkin(skin)
    end
  end)
end

module.askOpenEditor = function(skin)
  -- We pass PlayerPedId function so we alwys have fresh ped
  local editor = SkinEditor(PlayerPedId)
  local model  = GetHashKey(skin and skin["model"] or 'mp_m_freemode_01')

  utils.game.requestModel(model, function()
    SetPlayerModel(PlayerId(), model)
    editor:setModel(skin and skin["model"] or 'mp_m_freemode_01')

    if (skin == nil) then
      for k,v in pairs(componentsConfig) do
        SetPedComponentVariation(GetPlayerPed(-1), k, v.default or 0, 0, 0)
        editor:setSkinComponentDrawable(k, v.default)
        editor:setSkinComponentTexture(k, 0)
      end
    else
      for componentIdentifier,components in pairs(skin) do
        local componentId = getComponentNumberFromIdentifier(componentIdentifier)
        local drawableId = components.drawable
        local textureId = components.texture

        SetPedComponentVariation(GetPlayerPed(-1), componentId, drawableId, textureId, 0)
        editor:setSkinComponentDrawable(componentId, drawableId)
        editor:setSkinComponentTexture(componentId, textureId)
      end
    end
  
    SetModelAsNoLongerNeeded(model)

    editor:start()

  end)
end