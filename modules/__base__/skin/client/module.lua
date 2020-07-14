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
module.Skin   = Extends(EventEmitter, 'Skin')
-- TODO: move to another module
module.Camera = Extends(EventEmitter, 'Camera')

local SkinEditor = module.Editor
local Skin = module.Skin
local Camera = module.Camera

local getComponentIdentifierFromNumber = function(num)
  if (num == nil) then
    error("nil value passed to getComponentIdentifierFromNumber")
  end
  return Config.componentsConfig[num].id
end

local getComponentNumberFromIdentifier = function(id)
  for k,v in pairs(Config.componentsConfig) do
    if (v.id == id) then
      return k
    end
  end
  return nil
end

function Skin:constructor(config)
  self.super:ctor()

  self.model                = config and config.model or "mp_m_freemode_01"
  self.components           = config and config.components or self:getDefaultComponents()
  self.blend                = config and config.blend or self:getDefaultBlend()
  self.blendFaceMix         = config and config.blendFaceMix or self:getDefaultBlendFaceMix()
  self.blendSkinMix         = config and config.blendSkinMix or self:getDefaultBlendSkinMix()
  self.blendOverrideMix     = config and config.blendOverrideMix or self:getDefaultBlendOverrideMix()
  self.hairColor            = config and config.hair_color or self:getDefaultHairColor()
  self.transactionalChanges = {
    components = {}
  }
end

function Skin:getDefaultComponents()
  local _components = {}
  for k,v in pairs(Config.componentsConfig) do
    _components[k] = v.default or {0, 0}
  end

  return _components
end

function Skin:getDefaultBlend()
  return Config.defaultBlend
end

function Skin:getDefaultBlendFaceMix()
  return Config.defaultBlendFaceMix
end

function Skin:getDefaultBlendSkinMix()
  return Config.defaultBlendSkinMix
end

function Skin:getDefaultBlendOverrideMix()
  return Config.defaultBlendOverrideMix
end

function Skin:getDefaultHairColor()
  return Config.defaultHairColor
end

function Skin:getComponent(idOrName)
  return self.components[self:getComponentId(idOrName)]
end

function Skin:getComponentId(idOrName)
  if (type(idOrName) == "number") then
    return idOrName
  else
    return getComponentNumberFromIdentifier(idOrName)
  end
end

function Skin:getBlend()
  return self.blend
end

function Skin:getBlendFaceMix()
  return self.blendFaceMix
end

function Skin:getBlendSkinMix()
  return self.blendSkinMix
end

function Skin:getBlendOverrideMix()
  return self.blendOverrideMix
end

function Skin:getHairColor()
  return self.hairColor
end

function Skin:getModel()
  return self.model
end

function Skin:setComponentDrawable(componentIdOrName, drawableId)
  local component = self:getComponent(componentIdOrName)
  component[1] = drawableId

  self.transactionalChanges.components[self:getComponentId(componentIdOrName)] = component

  return self
end

function Skin:setComponentTexture(componentIdOrName, textureId)
  local component = self:getComponent(componentIdOrName)
  component[2] = textureId

  self.transactionalChanges.components[self:getComponentId(componentIdOrName)] = component

  return self
end

function Skin:setFaceFather(face)
  self.blend[1] = face
  self.transactionalChanges.blend = self.blend

  return self
end

function Skin:setFaceMother(face)
  self.blend[2] = face
  self.transactionalChanges.blend = self.blend

  return self
end

function Skin:setFaceOverride(face)
  self.blend[3] = face
  self.transactionalChanges.blend = self.blend

  return self
end

function Skin:setSkinToneFather(skinTone)
  self.blend[4] = skinTone
  self.transactionalChanges.blend = self.blend

  return self
end

function Skin:setSkinToneMother(skinTone)
  self.blend[5] = skinTone
  self.transactionalChanges.blend = self.blend

  return self
end

function Skin:setSkinToneOverride(skinTone)
  self.blend[6] = skinTone
  self.transactionalChanges.blend = self.blend

  return self
end

function Skin:setFaceMix(mix)
  self.blendFaceMix = mix / 100
  self.transactionalChanges.blendFaceMix = mix / 100
  
  return self
end

function Skin:setSkinMix(mix)
  self.blendSkinMix = mix / 100
  self.transactionalChanges.blendSkinMix = mix / 100
  
  return self
end

function Skin:setOverrideMix(mix)
  self.blendOverrideMix = mix / 100
  self.transactionalChanges.blendOverrideMix = mix / 100

  return self
end

function Skin:setHairColor1(hairColor1)
  self.hairColor[1] = hairColor1

  self.transactionalChanges.hairColor = self.hairColor

  return self
end

function Skin:setHairColor2(hairColor2)
  self.hairColor[2] = hairColor2

  self.transactionalChanges.hairColor = self.hairColor

  return self
end

function Skin:setModel(model)
  self.model = model

  self.transactionalChanges.model = self.model

  return self
end

function Skin:applyAll(cb)
  local modelHash = GetHashKey(self:getModel())
  
  utils.game.requestModel(modelHash, function()
    SetPlayerModel(PlayerId(), modelHash)

    local ped              = GetPlayerPed(-1)
    local blend            = self:getBlend()
    local blendFaceMix     = self:getBlendFaceMix()
    local blendSkinMix     = self:getBlendSkinMix()
    local blendOverrideMix = self:getBlendOverrideMix()

    SetPedHeadBlendData(ped, blend[1], blend[2], blend[3], blend[4], blend[5], blend[6], blendFaceMix, blendSkinMix, blendOverrideMix, true)

    for componentId,component in pairs(self.components) do
      SetPedComponentVariation(ped, componentId, component[1], component[2], 1)
    end

    local hairColor = self:getHairColor()
    SetPedHairColor(ped, hairColor[1], hairColor[2])

    SetModelAsNoLongerNeeded(modelHash)

    if (cb) then
      cb()
    end
  end)
  
end

function Skin:commit()

  local applyComponentsIfChanged = function()
    local ped = GetPlayerPed(-1)

    for componentId,component in pairs(self.transactionalChanges.components) do
      SetPedComponentVariation(ped, componentId, component[1], component[2], 1)
    end
  end

  local applyBlendIfChanged = function()
    if (self.transactionalChanges.blend
          or
        self.transactionalChanges.blendSkinMix
          or
        self.transactionalChanges.blendFaceMix
          or
        self.transactionalChanges.blendOverrideMix
    ) then

      local ped = GetPlayerPed(-1)

      local blend            = self:getBlend()
      local blendFaceMix     = self:getBlendFaceMix()
      local blendSkinMix     = self:getBlendSkinMix()
      local blendOverrideMix = self:getBlendOverrideMix()
  
      SetPedHeadBlendData(ped, blend[1], blend[2], blend[3], blend[4], blend[5], blend[6], blendFaceMix, blendSkinMix, blendOverrideMix, true)
    end
  end

  local applyHairColorIfChanged = function()
    if (self.transactionalChanges.hairColor) then
      local ped = GetPlayerPed(-1)

      local hairColor = self:getHairColor()
      SetPedHairColor(ped, hairColor[1], hairColor[2])
    end
  end

  local applyModelIfChanged = function(cb)
    if (self.transactionalChanges.model) then
      local modelHash = GetHashKey(self:getModel())

      utils.game.requestModel(modelHash, function()
        SetPlayerModel(PlayerId(), modelHash)
    
        SetModelAsNoLongerNeeded(modelHash)

        return cb()
      end)
    end
    cb()
  end

  applyModelIfChanged(function()
    applyBlendIfChanged()
    applyComponentsIfChanged()
    applyHairColorIfChanged()

    self.transactionalChanges = {
      components = {}
    }
  end)

  
end

function Skin:serialize()
  return {
    components       = self.components,
    blend            = self.blend,
    blendFaceMix     = self.blendFaceMix,
    blendSkinMix     = self.blendSkinMix,
    blendOverrideMix = self.blendOverrideMix,
    hair_color       = self.hairColor
  }
end

function Camera:constructor(shouldMoveCam)
  self.super:ctor()

  self.camIsActive         = false
  self.camRadius           = 1.25
  self.camCoords           = vector3(0.0, 0.0, 0.0)
  self.camPolarAngle       = 0.0
  self.camAzimuthAngle     = 0.0
  self.camTargetBone       = SKEL_ROOT
  self.camTargetBoneOffset = vector3(0.0, 0.0, 0.0)
  self.timestamp           = utils.time.timestamp()
  self.shouldMoveCam       = shouldMoveCam
  self.cameraId            = nil
  self.tick                = nil
end

-- TODO: split this into multiple pieces
-- and make it re-usable (extends camera so it could be use for anything)
function Camera:start()
  self.onMouseMoveOffest = on('mouse:move:offset', function(offsetX, offsetY, data)

    -- Mouse not inside menu
    if self.shouldMoveCam() then
      
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

    if self.shouldMoveCam() then

      self.camRadius = self.camRadius + delta * -0.25
      
      if self.camRadius < 0.75 then
        self.camRadius = 0.75
      elseif self.camRadius > 2.5 then
        self.camRadius = 2.5
      end

    end

  end)

  local ped = GetPlayerPed(-1)
  local pedCoords = GetEntityCoords(ped)
  local forward   = GetEntityForwardVector(ped)

  self.camRadius                           = 1.25
  self.camCoords                           = pedCoords + forward * self.camRadius
  self.camPolarAngle, self.camAzimuthAngle = utils.math.world3DtoPolar3D(pedCoords, self.camCoords)

  if not DoesCamExist(self.cameraId) then
    self.cameraId = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
  end

  SetCamActive(self.cameraId, true)
  RenderScriptCams(true, false, 500, true, true)

  SetCamCoord(self.cameraId, self.camCoords.x, self.camCoords.y, self.camCoords.z)

  self.camIsActive = true

  self:emit('cam.enable')

  self.tick = ESX.SetTick(function()
    self:onTick()
  end)
end

function Camera:stop()
  SetCamActive(self.cameraId, false)
  RenderScriptCams(false, true, 500, true, true)

  self.camIsActive = false

  self:emit('cam.disable')
end

function Camera:destroy()

  self:stop()

  off('mouse:move:offset', self.onMouseMoveOffest)
  off('mouse:move:wheel',  self.onMouseWheel)

  ESX.ClearTick(self.tick)

  DestroyCam(self.cameraId, false)
  self.cameraId = nil

  self:emit('destoyed')
end

function Camera:pointToBone(boneIndex, offset)
  self.camTargetBone       = boneIndex
  self.camTargetBoneOffset = offset or vector3(0.0, 0.0, 0.0)

  PointCamAtPedBone(self.cameraId, GetPlayerPed(-1), self.camTargetBone, self.camTargetBoneOffset.x, self.camTargetBoneOffset, self.camTargetBoneOffset.z, 0)
end

function Camera:onTick()
  local coords = GetPedBoneCoords(GetPlayerPed(-1), self.camTargetBone, self.camTargetBoneOffset.x, self.camTargetBoneOffset.y, self.camTargetBoneOffset.z)

  self.camCoords = utils.math.polar3DToWorld3D(coords, self.camPolarAngle, self.camAzimuthAngle, self.camRadius)

  SetCamCoord(self.cameraId, self.camCoords.x, self.camCoords.y, self.camCoords.z)

  -- time
  local w, d, h, m, s = utils.time.fromTimestamp(self.timestamp)
  NetworkOverrideClockTime(h, m, s)
end

function Camera:setRadius(radius)
  self.camRadius = radius
end

function Camera:setCoords(coords)
  self.camCoords = coords
end

function Camera:setPolarAzimuthAngle(polarAngle, azimuthAngle)
  self.camPolarAngle = polarAngle
  self.camAzimuthAngle = azimuthAngle
end

function SkinEditor:constructor(skinContent)
  self.super:ctor()

  self.skin = Skin(skinContent)
  self._ped = 0
  self.tick = nil
  self.mainMenu = nil
  self.currentMenu = nil
  self.modelTimeout = nil

  self.cam = Camera(function()
    return not self.currentMenu.mouseIn
  end)

  self:ensurePed()
end

function SkinEditor:destructor()

  self.cam:destroy()
  self.mainMenu:destroy()

  -- TODO : Fix this, field super is nil ?
  -- self.super:destructor()
end

function SkinEditor:start()
  self.cam:start()
  self:openMenu()

  self.skin:applyAll(function()
    self:mainCameraScene()
    self:emit('start')
  end)
end

function SkinEditor:ensurePed()
  local ped = GetPlayerPed(-1)
  self._ped                 = ped
  self.pedModel             = GetEntityModel(ped)
  self.isPedPlayer          = IsPedAPlayer(ped)
  self.isPedHuman           = utils.game.isHumanModel(self.pedModel)
  self.isPedFreemode        = self.isPedHuman and utils.game.isFreemodeModel(self.pedModel)
  self.canEnforceComponents = self.isPedFreemode

  if self.isPedPlayer then
    
    self.player = NetworkGetPlayerIndexFromPed(self._ped)

    if self.player ~= PlayerId() then
      error('Editing other players is forbidden')
    end

  end

  if self.isPedHuman then
    self.models = Config.humans
  else
    self.models = Config.animals
  end

end

function SkinEditor:getPed()
  self:ensurePed()
  return self._ped
end

function SkinEditor:openMenu()

  local items = {
    {name = 'model',   label = self:getModelLabelByIndex(0),         type = 'slider', max   = #self.models - 1, visible = self.isPedPlayer},
    {name = 'enforce', label = 'Enforce compatible elements (WIP)',  type = 'check',  value = false,            visible = self.canEnforceComponents},
  }

  items[#items + 1] = {type= 'button', name = 'component.PV_SKINTONE', label = "Skin Tone / Face"}

  for i=1, #Config.componentOrder, 1 do

    local comp  = Config.componentOrder[i]
    local label = Config.componentsConfig[comp].label

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

    if (item.name == 'component.PV_SKINTONE') then
      return self:openSkintoneMenu(item.component)
    end
    
    if item.component ~= nil then

      if (item.name == 'component.PV_COMP_HAIR') then
        return self:openHairMenu(item.component)
      end

      self:openComponentMenu(item.component)
    elseif item.name == 'save' then
      self:save()
    end

  end)

end

function SkinEditor:onItemChanged(item, prop, val, index)
  
  if prop == 'value' then

    if item.name == 'model' then

      item.label = self:getModelLabelByIndex(val)
      -- Ensure not spamming model changes
      if self.modelTimeout ~= nil then
        ESX.ClearTimeout(self.modelTimeout)
      end

      self.modelTimeout = ESX.SetTimeout(250, function()

        local model  = self.models[val + 1]
        local ped    = self:getPed()

        self.skin = nil
        self.skin = Skin({model = PED_MODELS_BY_HASH[self.models[val + 1]]})

        self.skin:applyAll(function()
          
          local byName = self.mainMenu:by('name')
          byName['enforce'].visible = self.isPedFreemode

          local modelLabel = self:getModelLabelByIndex(val)

          ped = self:getPed()

          self.cam:pointToBone(SKEL_ROOT)
        end)
      end)

    elseif item.name == 'ensure' then
    
      self.canEnforceComponents = val

    elseif item.name == 'blend.face' then

      self.skin:setFace(val)
      self.skin:commit()

      item.label = self:getBlendFaceLabel()
      
    elseif item.name == 'blend.skin' then

      self.skin:setSkinTone(val)
      self.skin:commit()

      item.label = self:getBlendSkinToneLabel()

    end
  
  end

end

function SkinEditor:getBlendFaceFatherLabel()
  return "Face One ( " .. (self.skin:getBlend()[1] + 1) .. " / " .. 46 .. " )"
end

function SkinEditor:getBlendFaceMotherLabel()
  return "Face Two ( " .. (self.skin:getBlend()[2] + 1) .. " / " .. 46 .. " )"
end

function SkinEditor:getBlendFaceOverrideLabel()
  return "Face Override ( " .. (self.skin:getBlend()[3] + 1) .. " / " .. 46 .. " )"
end

function SkinEditor:getBlendSkinToneFatherLabel()
  return "Skin One ( " .. (self.skin:getBlend()[4] + 1) .. " / " .. 46 .. " )"
end

function SkinEditor:getBlendSkinToneMotherLabel()
  return "Skin Two ( " .. (self.skin:getBlend()[5] + 1) .. " / " .. 46 .. " )"
end

function SkinEditor:getBlendSkinToneOverrideLabel()
  return "Skin Override ( " .. (self.skin:getBlend()[6] + 1) .. " / " .. 46 .. " )"
end

function SkinEditor:getBlendFaceMixLabel()
  return "Face Mix ( " .. (self.skin:getBlendFaceMix()) .. " / " .. 1.0 .. " )"
end

function SkinEditor:getBlendSkinMixLabel()
  return "Skin Mix ( " .. (self.skin:getBlendSkinMix()) .. " / " .. 1.0 .. " )"
end

function SkinEditor:getBlendOverrideMixLabel()
  return "Override Mix ( " .. (self.skin:getBlendOverrideMix()) .. " / " .. 1.0 .. " )"
end

function SkinEditor:getComponentDrawableLabel(componentId)
  return "Model ( " .. (self.skin:getComponent(componentId)[1] + 1) .. " / " .. GetNumberOfPedDrawableVariations(GetPlayerPed(-1), componentId) .. " )"
end

function SkinEditor:getComponentTextureLabel(componentId)
  return "Variant ( " .. (self.skin:getComponent(componentId)[2] + 1) .. " / " .. GetNumberOfPedTextureVariations(GetPlayerPed(-1), componentId, self.skin:getComponent(componentId)[1]) .. " )"
end

function SkinEditor:getHairColor1Label()
  return "Color 1 ( " .. (self.skin:getHairColor()[1] + 1) .. " / " .. GetNumHairColors() .. " )"
end

function SkinEditor:getHairColor2Label()
  return "Color 2 ( " .. (self.skin:getHairColor()[2] + 1) .. " / " .. GetNumHairColors() .. " )"
end

-- TODO: refactor this so split into either a different class or another file
function SkinEditor:openComponentMenu(comp)

  self:ensurePed()

  local cfg = Config.componentsConfig[comp]

  self.cam:setRadius(cfg.radius)
  
  self.cam:pointToBone(cfg.bone, cfg.offset)

  local items = {}
  local label = cfg.label

  items[#items + 1] = {
    name  = 'drawable',
    label = self:getComponentDrawableLabel(comp),
    type  = 'slider',
    min   = 0,
    max   = GetNumberOfPedDrawableVariations(self._ped, comp) - 1,
    value = self.skin:getComponent(comp)[1],
  }

  items[#items + 1] = {
    name  = 'texture',
    label = self:getComponentTextureLabel(comp),
    type  = 'slider',
    min   = 0,
    max   = GetNumberOfPedTextureVariations(self._ped, comp, self.skin:getComponent(comp)[1]) - 1,
    value = self.skin:getComponent(comp)[2],
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
        self.skin:setComponentDrawable(comp, val)
        self.skin:setComponentTexture(comp, 0)

        byName['drawable'].label = self:getComponentDrawableLabel(comp, val)
        byName['texture'].max    = GetNumberOfPedTextureVariations(self._ped, comp, val)
        byName['texture'].value  = 0

      elseif item.name == 'texture' then
        self.skin:setComponentTexture(comp, val)
      end

      byName['texture'].label = self:getComponentTextureLabel(comp)

      self.skin:commit()
    end

  end)

  menu:on('item.click', function(item, index)
    
    if item.name == 'submit' then
      
      menu:destroy()
      
      self.currentMenu = self.mainMenu

      self.mainMenu:focus()
      self:mainCameraScene()
    end

  end)

end

-- TODO: refactor this so split into either a different class or another file
function SkinEditor:openHairMenu(comp)

  self:ensurePed()

  self.cam:setRadius(1.25)
  
  self.cam:pointToBone(SKEL_Head, vector3(0.0,0.0,0.0))

  local items = {}

  items[#items + 1] = {
    name  = 'drawable',
    label = self:getComponentDrawableLabel(PV_COMP_HAIR),
    type  = 'slider',
    min   = 0,
    max   = GetNumberOfPedDrawableVariations(self._ped, PV_COMP_HAIR) - 1,
    value = self.skin:getComponent(comp)[1],
  }

  items[#items + 1] = {
    name  = 'hair_color_1',
    label = self:getHairColor1Label(),
    type  = 'slider',
    min   = 0,
    max   = GetNumHairColors(),
    value = self.skin:getHairColor()[1],
  }

  items[#items + 1] = {
    name  = 'hair_color_2',
    label = self:getHairColor2Label(),
    type  = 'slider',
    min   = 0,
    max   = GetNumHairColors(),
    value = self.skin:getHairColor()[2],
  }

  items[#items + 1] = {name = 'submit', label = '>> apply <<', type = 'button'}
  
  if self.mainMenu.visible then
    self.mainMenu:hide()
  end

  local menu = Menu('skin.hair', {
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
        self.skin:setComponentDrawable(comp, val)

        byName['drawable'].label = self:getComponentDrawableLabel(comp, val)

      elseif item.name == 'hair_color_1' then
        self.skin:setHairColor1(val)
        byName['hair_color_1'].label = self:getHairColor1Label()
      elseif item.name == 'hair_color_2' then
        self.skin:setHairColor2(val)
        byName['hair_color_2'].label = self:getHairColor2Label()
      end

      self.skin:commit()
    end

  end)

  menu:on('item.click', function(item, index)
    
    if item.name == 'submit' then
      
      menu:destroy()
      
      self.currentMenu = self.mainMenu

      self.mainMenu:focus()
      self:mainCameraScene()
    end

  end)

end

-- TODO: refactor this so split into either a different class or another file
function SkinEditor:openSkintoneMenu(comp)

  self:ensurePed()

  self.cam:setRadius(1.25)
  
  self.cam:pointToBone(SKEL_Head, vector3(0.0,0.0,0.0))

  local items = {}

  items[#items + 1] = {type= 'slider', name = 'blend.face.father',   max   = 45,  value = self.skin:getBlend()[1],         label = self:getBlendFaceFatherLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.face.mother',   max   = 45,  value = self.skin:getBlend()[2],         label = self:getBlendFaceMotherLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.face.override', max   = 45,  value = self.skin:getBlend()[3],         label = self:getBlendFaceOverrideLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.skin.father',   max   = 45,  value = self.skin:getBlend()[4],         label = self:getBlendSkinToneFatherLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.skin.mother',   max   = 45,  value = self.skin:getBlend()[5],         label = self:getBlendSkinToneMotherLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.skin.override', max   = 45,  value = self.skin:getBlend()[6],         label = self:getBlendSkinToneOverrideLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.face.mix',      max   = 100, value = self.skin:getBlendFaceMix(),     label = self:getBlendFaceMixLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.skin.mix',      max   = 100, value = self.skin:getBlendSkinMix(),     label = self:getBlendSkinMixLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.override.mix',  max   = 100, value = self.skin:getBlendOverrideMix(), label = self:getBlendOverrideMixLabel()}

  items[#items + 1] = {name = 'submit', label = '>> apply <<', type = 'button'}
  
  if self.mainMenu.visible then
    self.mainMenu:hide()
  end

  local menu = Menu('skin.skintone', {
    title = "Skin Tone / Face",
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

      if item.name == 'blend.face.father' then

        self.skin:setFaceFather(val)

        item.label = self:getBlendFaceFatherLabel()

      elseif item.name == 'blend.face.mother' then

        self.skin:setFaceMother(val)

        item.label = self:getBlendFaceMotherLabel()

      elseif item.name == 'blend.face.override' then

        self.skin:setFaceOverride(val)

        item.label = self:getBlendFaceOverrideLabel()
        
      elseif item.name == 'blend.skin.father' then

        self.skin:setSkinToneFather(val)

        item.label = self:getBlendSkinToneFatherLabel()

      elseif item.name == 'blend.skin.mother' then

        self.skin:setSkinToneMother(val)

        item.label = self:getBlendSkinToneMotherLabel()

      elseif item.name == 'blend.skin.override' then

        self.skin:setSkinToneOverride(val)

        item.label = self:getBlendSkinToneOverrideLabel()

      elseif item.name == 'blend.face.mix' then

        self.skin:setFaceMix(val)

        item.label = self:getBlendFaceMixLabel()

      elseif item.name == 'blend.skin.mix' then

        self.skin:setSkinMix(val)

        item.label = self:getBlendSkinMixLabel()

      elseif item.name == 'blend.override.mix' then

        self.skin:setOverrideMix(val)

        item.label = self:getBlendOverrideMixLabel()

      end

      self.skin:commit()
    end

  end)

  menu:on('item.click', function(item, index)
    
    if item.name == 'submit' then
      
      menu:destroy()
      
      self.currentMenu = self.mainMenu

      self.mainMenu:focus()
      self:mainCameraScene()
    end

  end)

end

function SkinEditor:mainCameraScene()
  local ped       = GetPlayerPed(-1)
  local pedCoords = GetEntityCoords(ped)
  local forward   = GetEntityForwardVector(ped)

  self.cam:setRadius(1.25)
  self.cam:setCoords(pedCoords + forward * 1.25)
  self.cam:setPolarAzimuthAngle(utils.math.world3DtoPolar3D(pedCoords, pedCoords + forward * 1.25))

  self.cam:pointToBone(SKEL_ROOT, vector3(0.0,0.0,0.0))
end

function SkinEditor:getModelLabelByIndex(value)
  return 'Model (' .. PED_MODELS_BY_HASH[self.models[value + 1]] .. ')'
end

function SkinEditor:save()
  request('skin:save', function()
    self:destructor()
  end, self.skin:serialize())
end

function SkinEditor:destroyMenu()
  self.mainMenu:destroy()
  self.mainMenu = nil
end

module.init = function()
  -- check if the player already has a skin
  request("skin:getIdentitySkin", function(skinContent)
    if skinContent == nil then
      module.askOpenEditor()
    else
      module.loadPlayerSkin(skinContent)
    end
  end)
end

module.loadPlayerSkin = function(skinContent)
  local skin = Skin(skinContent)
  skin:applyAll()
end

module.askOpenEditor = function(skinContent)
  local editor = SkinEditor(skinContent)

  editor:start()
end