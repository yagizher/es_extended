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

local Input = M('input')

Input.On('pressed', 1, 74, function(lastPressed)

  if Input.IsControlPressed(1, 21) then

    module.voice.current = (module.voice.current + 1) % 3

    if module.voice.current == 0 then
      NetworkSetTalkerProximity(module.voice.default)
      module.voice.level = _U('voice:normal')
    elseif module.voice.current == 1 then
      NetworkSetTalkerProximity(module.voice.shout)
      module.voice.level = _U('voice:shout')
    elseif module.voice.current == 2 then
      NetworkSetTalkerProximity(module.voice.whisper)
      module.voice.level = _U('voice:whisper')
    end
  end
end)
