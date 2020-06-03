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


module.onNuiReady = function()
    module.menu = Menu('test_menu', {
        title = 'Test menu',
        float = 'top|left', -- not needed, default value
        items = {
            {
                name = 'a',
                label = 'Slide me, indeed, I\'m a slider',
                type = 'slider'
            },
            {name = 'b', label = 'Ready to check this one ?', type = 'check'},
            {
                name = 'c',
                label = 'It could be a super long text, maybe',
                type = 'text'
            }, {name = 'd', label = 'What\'s my type'}, -- type will be default
            {name = 'e', label = 'What fancy color ?', type = 'color'},
            {name = 'f', label = '>> Submit <<', type = 'button'}
        }
    })

    -- Menu events
    module.menu:on('ready', module.onMenuReady)
    module.menu:on('item.change', module.onItemChanged)
    module.menu:on('item.click', module.onItemClicked)
end

module.onMenuReady = function()
  module.menu.items[1].label = 'TEST'; -- data binding with the DOM
end

module.onItemChanged = function(item, prop, val, index)

    if (item.name == 'a') and (prop == 'value') then

        item.label = 'Dynamic label ' .. tostring(val);

    end

    if (item.name == 'b') and (prop == 'value') then

        local c = table.find(menu.items, function(e) return e.name == 'c' end)

        c.value = 'Dynamic text ' .. tostring(val);

    end

end

module.onItemClicked = function(item, index)
  print('index', index)
end
