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

  self.model = config and config.model or "mp_m_freemode_01"
  self.components = config and config.components or self:getDefaultComponents()
  self.blend = config and config.blend or self:getDefaultBlend()
  self.hairColor = config and config.hair_color or self:getDefaultHairColor()
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

function Skin:getDefaultHairColor()
  return Config.defaultHairColor
end

function Skin:getComponent(idOrName)
  if (type(idOrName) == "number") then
    return self.components[idOrName]
  else
    return self.components[getComponentNumberFromIdentifier(idOrName)]
  end
end

function Skin:getBlend()
  return self.blend
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
end

function Skin:setComponentTexture(componentIdOrName, textureId)
  local component = self:getComponent(componentIdOrName)
  component[2] = textureId
end

function Skin:setSkinTone(skinTone)
  self.blend[2] = skinTone
end

function Skin:setFace(face)
  self.blend[1] = face
end

function Skin:setHairColor1(hairColor1)
  self.hairColor[1] = hairColor1
end

function Skin:setHairColor2(hairColor2)
  self.hairColor[2] = hairColor2
end

function Skin:setModel(model)
  self.model = model
  return self
end

function Skin:apply()
  local modelHash = GetHashKey(self:getModel())
  
  utils.game.requestModel(modelHash, function()
    SetPlayerModel(PlayerId(), modelHash)

    local ped = GetPlayerPed(-1)

    local blend = self:getBlend()
    SetPedHeadBlendData(ped, blend[1], blend[1], blend[1], blend[2], blend[2], blend[2], 1.0, 1.0, 1.0, true)

    for componentId,component in pairs(self.components) do
      SetPedComponentVariation(ped, componentId, component[1], component[2], 1)
    end

    local hairColor = self:getHairColor()
    SetPedHairColor(ped, hairColor[1], hairColor[2])

    SetModelAsNoLongerNeeded(modelHash)
  end)
  
end

function Skin:serialize()
  return {
    components = self.components,
    blend = self.blend,
    hair_color = self.hairColor
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
  self.timestamp = utils.time.timestamp()
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

  self:unbindEvents()
  self.cam:disable()
  self.mainMenu:destroy()

  -- TODO : Fix this, field super is nil ?
  -- self.super:destructor()
end

function SkinEditor:start()
  self.cam:start()
  self:openMenu()

  self.cam:pointToBone(SKEL_ROOT)

  self.skin:apply()

  self:emit('start')
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
      error('Editing other player is forbidden')
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
    {name = 'enforce', label = 'Enforce compatible elements (WIP)', type = 'check',  value = false,            visible = self.canEnforceComponents},
  }

  items[#items + 1] = {type= 'slider', name = 'blend.face', max   = 45, value = self.skin:getBlend()[1], label = self:getBlendFaceLabel()}
  items[#items + 1] = {type= 'slider', name = 'blend.skin', max   = 45, value = self.skin:getBlend()[2], label = self:getBlendSkinToneLabel()}

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

      item.label = self:getModelLabelByIndex(val)
      -- Ensure not spamming model changes
      if self.modelTimeout ~= nil then
        ESX.ClearTimeout(self.modelTimeout)
      end

      self.modelTimeout = ESX.SetTimeout(250, function()

        local model  = self.models[val + 1]
        local ped    = self:getPed()

        utils.game.requestModel(model, function()

          local byName = self.mainMenu:by('name')

          self.skin:setModel(PED_MODELS_BY_HASH[self.models[val + 1]]):apply()
          local modelLabel = self:getModelLabelByIndex(val)

          ped = self:getPed()

          byName['enforce'].visible = self.isPedFreemode

          SetPedDefaultComponentVariation(ped)
          SetModelAsNoLongerNeeded(model)

          self.cam:pointToBone(SKEL_ROOT)
  
        end)

      end)

    elseif item.name == 'ensure' then
    
      self.canEnforceComponents = val

    elseif item.name == 'blend.face' then

      self.skin:setFace(val)
      self.skin:apply()

      item.label = self:getBlendFaceLabel()
      
    elseif item.name == 'blend.skin' then

      self.skin:setSkinTone(val)
      self.skin:apply()

      item.label = self:getBlendSkinToneLabel()

    end
  
  end

end

function SkinEditor:getBlendFaceLabel()
  return "Face ( " .. self.skin:getBlend()[1] .. " / " .. 45 .. " )"
end

function SkinEditor:getBlendSkinToneLabel()
  return "Skin Tone ( " .. self.skin:getBlend()[2] .. " / " .. 45 .. " )"
end

function SkinEditor:getComponentDrawableLabel(componentId)
  return "Model ( " .. (self.skin:getComponent(componentId)[1] + 1) .. " / " .. GetNumberOfPedDrawableVariations(self._ped, componentId) .. " )"
end

function SkinEditor:getComponentTextureLabel(componentId)
  return "Variant ( " .. (self.skin:getComponent(componentId)[2] + 1) .. " / " .. GetNumberOfPedTextureVariations(self._ped, componentId, self.skin:getComponent(componentId)[1]) .. " )"
end

-- TODO: refactor this so split into either a different class or another file
function SkinEditor:openComponentMenu(comp)

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

      self.skin:apply()
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

      self.cam:setRadius(1.25)
      self.cam:setCoords(pedCoords + forward * 1.25)
      self.cam:setPolarAzimuthAngle(utils.math.world3DtoPolar3D(pedCoords, self.camCoords))

      self.cam:pointToBone(SKEL_ROOT)

    end

  end)

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
    if not(skin) then
      module.askOpenEditor()
    else
      module.loadPlayerSkin(skinContent)
    end
  end)
end

module.loadPlayerSkin = function(skinContent)
  local skin = Skin(skinContent)
  skin:apply()
end

module.askOpenEditor = function(skinContent)
  local editor = SkinEditor(skinContent)

  editor:start()
end