# ESX 2

### Sill looking for old version ? => https://github.com/ESX-Org/es_extended/tree/v1-final

# Table of Contents

1. [Installation](#install)
2. [Changelog](#changelog)
3. [Examples](#examples)
   1. [Menu](#examples-menu)
   2. [Datastore](#examples-datastore)
   3. [Declarative Table Schemas](#examples-declarative-schema)
   4. [Programmatically Extend xPlayer methods](#examples-extend-xplayer)

## Installation <a name="install"></a>

### Requirements :

- An installed MariaDB server (MySQL not supported for now).
- [Async script by ESX-Org](https://github.com/ESX-Org/async)
- [Cron script by ESX-Org](https://github.com/ESX-Org/cron)
- [SkinChanger script by ESX-Org](https://github.com/ESX-Org/skinchanger)
- [MySQL-Async by brouznouf](https://github.com/brouznouf/fivem-mysql-async)

### Server.cfg sample

```bash
# minimum resources and config to get it working

set mysql_connection_string "mysql://john:smith@localhost/es_extended?charset=utf8mb4"

stop webadmin

ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure hardcap
ensure rconlog
ensure baseevents

ensure yarn

ensure mysql-async
ensure cron

ensure es_extended # Will now auto-generate fxmanifest.lua to prevent platform-dependant behavior, will prompt you to type ensure es_extended in console when fxmanifest has changed. To save some typing, uncomment below lines

# stop es_extended
# start es_extended
```

## Changelog <a name="changelog"></a>

```
- Switched to a module-based single resource for ease of use and performance
- Performance improvements
- Split all base functionnalities into their own module
- Module can either encapsulate its own functionality or declare global stuff
- Loading modules via method M('themodule') ensure correct loading order of modules
- Automated database schema generation (RIP SQL files everywhere)
- Database schema can also be expanded by other modules
- Custom event system to avoid serialization of event data and cross-resource communication, that make it possible to pass metatables through these events (You can still use TriggerEvent and such to escape that thing)
- xPlayer fully customizable without rewriting core resources (Hello second job, faction system and such...)
- Added some modules to optimize common things like input, marker and static npc management
- Extend base lua functionnality when appropriate via module. example: table.indexOf
- OOP System based on http://lua-users.org/wiki/InheritanceTutorial and improved
- Neat menu API
- Open as many pages as you want in single NUI frame with Frame API
- EventEmitter class
- WIP rewrite of well-known datastore / inventory / account stuff
```

## Code examples <a name="examples"></a>

### How to create and use menus <a name="examples-menu"></a>

![Menu](https://i.snipboard.io/tF8AcT.jpg)

### How to store/retrieve datas <a name="examples-datastore"></a>

```lua
-- DataStore

M('datastore')

on('esx:db:ready', function()

  local ds = DataStore('test', true, {sample = 'data'}) -- name, shared, initial data

  ds:on('save', function()
    print(ds.name .. ' saved => ' .. json.encode(ds:get()))
  end)

  ds:on('ready', function()

    ds:set('foo', 'bar')

    ds:save(function()
      print('callbacks also')
    end)

  end)

end)
```

### Table schema declarations <a name="examples-declarative-schema"></a>

```lua
-- Here is how datastore schema is declared, no need to feed some SQL file

M('events')

on('esx:db:init', function(initTable, extendTable)

  initTable('datastores', 'name', {
    {name = 'name',  type = 'VARCHAR',  length = 255, default = nil,    extra = 'NOT NULL'},
    {name = 'owner', type = 'VARCHAR',  length = 64,  default = 'NULL', extra = nil},
    {name = 'data',  type = 'LONGTEXT', length = nil, default = nil,    extra = nil},
  })

end)
```

### Extending xPlayer method programmatically <a name="examples-extend-xplayer"></a>

```lua
-- Want to create faction system ?

M('player')

xPlayer.createDBAccessor('faction', {name = 'faction', type = 'VARCHAR', length = 64, default = 'gang.ballas', extra = nil})

-- Now any player (which is instance of xPlayer) have the following methods
-- Also user table has now a faction column added automatically

local player = xPlayer:fromId(2)

print(player:getFaction())

player:setFaction('another.faction')

player:save()
```

```lua
-- I want to store JSON :(
-- No problem

xPlayer.createDBAccessor('someData', {name = 'some_data', type = 'TEXT', length = nil, default = '{}', extra = nil}, json.encode, json.decode)
```

```lua
-- I want to store WHATEVER (comma-separated list for example) :(
-- No problem

M('string')

xPlayer.createDBAccessor(
  'someWeirdData',
  {name = 'some_weird_data', type = 'TEXT', length = nil, default = '1,2,3,4,5', extra = nil},
  function(x) -- encode
    return table.concat(x, ',')
  end,
  function(x) -- decode
    return string.split(x, ',')
  end
)
```
