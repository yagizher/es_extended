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

function SkinEditor:constructor(ped)

  self.super:ctor()

  self.tick            = nil
  self.cam             = nil
  self.menu            = nil
  self.ped             = ped
  self.camIsActive     = false
  self.camRadius       = 1.5
  self.camCoords       = vector3(0.0, 0.0, 0.0)
  self.camPolarAngle   = 0.0
  self.camAzimuthAngle = 0.0
  self.menu            = nil
  self.timestamp       = utils.time.timestamp()

end

function SkinEditor:getPed()
  return type(self.ped) == 'function' and self.ped() or self.ped
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
  self.menu:destroy()
  self.menu = nil
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
  offset = offset or vector3(0.0, 0.0, 0.0)
  PointCamAtPedBone(self.cam, self:getPed(), boneIndex, offset.x, offset.y, offset.z, 0)
end

function SkinEditor:openMenu()

  self.menu = Menu('test_menu', {
    title = 'Test menu',
    float = 'top|left', -- not needed, default value
    items = {
      {name = 'superSlider', label = 'Slide me, indeed, I\'m a slider', type = 'slider'},
      {name = 'superChecker', label = 'Ready to check this one ?', type = 'check'},
      {name = 'superText', label = 'It could be a super long text, maybe', type = 'text'},
      {name = 'superSecretBind', label = 'I\'m changing if you type upper and check the box', type = 'text'},
      {name = 'superDefaultType', label = 'What\'s my type'}, -- type will be default
      {name = 'superColor', label = 'What fancy color ?', type = 'color'},
      {name = 'superSumbitButton', label = '>> Submit <<', type = 'button'}
    }
  })

  self.menu:on('mouse:move:offset', function(offsetX, offsetY, data)

    if not self.menu.mouseIn then -- not self.menu.mouseIn => Mouse not inside menu
      
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

on('esx:ready', function()

  local editor = SkinEditor(PlayerPedId)
  local model  = GetHashKey('mp_m_freemode_01')

  utils.game.requestModel(model, function()

    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(model)

    editor:start()

  end)

end)

