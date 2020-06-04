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

M('constants')
M('events')
M('ui.menu')

local utils = M('utils')

module.Editor = Extends(EventEmitter, 'SkinEditor')

local SkinEditor = module.Editor
local humans     = table.concat({MP_M_FREEMODE_01, MP_F_FREEMODE_01}, table.filter(PED_MODELS_HUMANS, function(x) return (x ~= MP_M_FREEMODE_01) and (t ~= MP_F_FREEMODE_01) end))
local animals    = table.clone(PED_MODELS_ANIMALS)

local componentLabels = {
  [PV_COMP_BERD] = 'Mask',
  [PV_COMP_HAIR] = 'Hair',
  [PV_COMP_UPPR] = 'Arms',
  [PV_COMP_LOWR] = 'Legs',
  [PV_COMP_HAND] = 'Bag / Parachute',
  [PV_COMP_FEET] = 'Shoes',
  [PV_COMP_TEEF] = 'Accessories',
  [PV_COMP_ACCS] = 'Undershirt',
  [PV_COMP_TASK] = 'Body armor',
  [PV_COMP_DECL] = 'Decals',
  [PV_COMP_JBIB] = 'Torso / Top',
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

function SkinEditor:constructor(ped)

  self.super:ctor()

  self._ped = 0

  self.tick                = nil
  self.cam                 = nil
  self.mainMenu            = nil
  self.currentMenu         = nil
  self.ped                 = ped
  self.camIsActive         = false
  self.camRadius           = 1.5
  self.camCoords           = vector3(0.0, 0.0, 0.0)
  self.camPolarAngle       = 0.0
  self.camAzimuthAngle     = 0.0
  self.camTargetBone       = SKEL_ROOT
  self.camTargetBoneOffset = vector3(0.0, 0.0, 0.0)
  self.timestamp           = utils.time.timestamp()
  self.modelTimeout        = nil

  self:ensurePed()

  self.canEnforceComponents = self.isPedFreemode

  self.onMouseMoveOffest = on('mouse:move:offset', function(offsetX, offsetY, data)

    if not self.currentMenu.mouseIn then -- not self.currentMenu.mouseIn => Mouse not inside menu
      
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

end

function SkinEditor:destructor()

  off('mouse:move:offset', self.onMouseMoveOffest)

end

function SkinEditor:getPed()
  self:ensurePed()
  return self._ped
end

function SkinEditor:ensurePed()

  local ped = type(self.ped) == 'function' and self.ped() or self.ped

  if ped ~= self._ped then

    self._ped          = ped
    self.pedModel      = GetEntityModel(ped)
    self.isPedPlayer   = IsPedAPlayer(ped)
    self.isPedHuman    = utils.game.isHumanModel(self.pedModel)
    self.isPedFreemode = self.isPedHuman and utils.game.isFreemodeModel(self.pedModel)
    
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

  self.camRadius                           = 1.5
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
  local ped       = self:getPed()
  local pedCoords = GetEntityCoords(ped)

  self.camCoords = utils.math.polar3DToWorld3D(pedCoords, self.camPolarAngle, self.camAzimuthAngle, self.camRadius)

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
    local label = componentLabels[comp]

    items[#items + 1] = {type= 'button', name = 'component.' .. GetEnumKey(PED_COMPONENTS, comp), component = comp, label = label}

  end

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

function SkinEditor:openComponentMenu(comp)

  local items = {}
  local label = componentLabels[comp]

  local drawable    = GetPedDrawableVariation(self._ped, comp)
  local texture     = GetPedTextureVariation(self._ped, comp)
  local drawableMax = GetNumberOfPedDrawableVariations(self._ped, comp)
  local textureMax  = GetNumberOfPedTextureVariations(self._ped, comp, drawable)

  local getDrawableLabel = function(drawable)
    return 'Model (' .. (drawable + 1) .. ' / ' .. (drawableMax + 1) .. ')'
  end

  local getTextureLabel = function(texture)
    return 'Variant (' .. (texture + 1) .. ' / ' .. (textureMax + 1) .. ')'
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
        drawable   = val
        texture    = 0
        textureMax = GetNumberOfPedTextureVariations(self._ped, comp, drawable)
      elseif item.name == 'texture' then
        texture = val
      end

      byName['drawable'].label = getDrawableLabel(drawable)
      byName['texture' ].label = getTextureLabel(texture)
      byName['texture' ].max   = textureMax

      self:setComponentVariation(comp, val)

    end

  end)

  menu:on('item.click', function(item, index)
    
    if item.name == 'submit' then
      menu:destroy()
      self.currentMenu = self.mainMenu
      self.mainMenu:focus()
    end

  end)

end

on('esx:ready', function()

  local editor = SkinEditor(PlayerPedId)  -- We pass PlayerPedId function so we alwys have fresh ped
  local model  = GetHashKey('mp_m_freemode_01')

  utils.game.requestModel(model, function()

    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(model)

    editor:start()

  end)

end)

