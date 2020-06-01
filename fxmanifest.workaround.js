// Copyright (c) Jérémie N'gadi
//
// All rights reserved.
//
// Even if 'All rights reserved' is very clear :
//
//   You shall not use any piece of this software in a commercial product / service
//   You shall not resell this software
//   You shall not provide any facility to install this particular software in a commercial product / service
//   If you redistribute this software, you must link to ORIGINAL repository at https://github.com/ESX-Org/es_extended
//   This copyright should appear in every part of the project code

const fs   = require('fs');
const glob = require('glob');

const cwd = process.cwd();

// CHANGE ME IF NEEDED
const RESOURCE_PATH = 'resources';
const RESOURCE_NAME = 'es_extended';

// DON'T TOUCH BELOW
const root         = path.resolve(path.join(cwd, RESOURCE_PATH)).replace('\\', '/');
const files        = glob.sync('**/' + RESOURCE_NAME + '/fxmanifest*.lua', {cwd: root, nodir: true});
const MANIFEST     = path.resolve(path.join(root, files.find(e => e.endsWith('fxmanifest.lua'))));
const MANIFEST_TPL = path.resolve(path.join(root, files.find(e => e.endsWith('fxmanifest.tpl.lua'))));
const ESX_DIR      = path.dirname(MANIFEST);
const TPL_DATA     = fs.readFileSync(MANIFEST_TPL).toString();

// fengari
const fengari                                          = require('fengari');
const { luaopen_js, tojs }                             = require('fengari-interop');
const lua                                              = fengari.lua;
const lauxlib                                          = fengari.lauxlib;
const lualib                                           = fengari.lualib;
const { to_luastring, to_jsstring }                    = fengari;
const { lua_pop, lua_getglobal, lua_tostring, LUA_OK } = lua;
const { luaL_requiref }                                = lauxlib;

const CFX_MANIFEST_LOADER = `
CFX_METADATA_KEYS = {}
CFX_METADATA      = {}

local addMetaData = function(k, v)

  if CFX_METADATA[k] == nil then
    CFX_METADATA_KEYS[#CFX_METADATA_KEYS + 1] = k
  end

  CFX_METADATA[k] = CFX_METADATA[k] or {}

  if type(v) == 'table' then
    for i=1, #v, 1 do
      table.insert(CFX_METADATA[k], v[i])
    end
  else
    table.insert(CFX_METADATA[k], v)
  end

end

local mt = {
  __index = function(t, k)

    local raw = rawget(t, k)

    if raw then
      return raw
    end

    return function(value)
      local newK = k

      if type(value) == 'table' then
        -- remove any 's' at the end (client_scripts, ...)
        if k:sub(-1) == 's' then
          newK = k:sub(1, -2)
        end

        -- add metadata for each table entry
        for _, v in ipairs(value) do
          addMetaData(newK, v)
        end
      else
        addMetaData(k, value)
      end

      -- for compatibility with legacy things
      return function(v2)
        addMetaData(newK .. '_extra', json.encode(v2))
      end
    end
  end
}

_ENV = setmetatable(_G, mt)
`;

const parseManifest = function(data) {

  const L = lauxlib.luaL_newstate();

  luaL_requiref(L, to_luastring('js'), luaopen_js, 1);
  lua_pop(L, 1);

  lualib.luaL_openlibs(L);

  lauxlib.luaL_loadstring(L, to_luastring(CFX_MANIFEST_LOADER));

  result = lua.lua_pcall(L, 0, -1, 0);

  if(result !== LUA_OK) {
    const s = lua_tostring(L, -1);
    if(s)
      throw new Error(to_jsstring(s))
  }

  lauxlib.luaL_loadstring(L, to_luastring(data));

  result = lua.lua_pcall(L, 0, -1, 0);

  if(result !== LUA_OK) {
    const s = lua_tostring(L, -1);
    if(s)
      throw new Error(to_jsstring(s))
  }

  lua_getglobal(L, 'CFX_METADATA_KEYS')

  const keys      = [];
  const keysProxy = tojs(L, 1);

  let i = 1;

  while(keysProxy.has(i))
    keys.push(keysProxy.get(i++));

  lua_pop(L, 1)

  lua_getglobal(L, 'CFX_METADATA')

  const metadata      = {};
  const metadataProxy = tojs(L, 1);

  for(let i=0; i<keys.length; i++) {

    const key   = keys[i];
    const ref   = metadataProxy.get(key);
    const entry = [];

    let j = 1;

    while(ref.has(j))
      entry.push(ref.get(j++));

    metadata[key] = entry;
  }

  lua_pop(L, 1)

  return metadata;

}

const buildManifest = function(data) {

  data.fx_version = data.fx_version || ['bodacious'];
  data.game       = data.game       || ['gta5'];

  let manifest = '';

  for(let k in data) {

    const entry = data[k];

    if(entry.length === 1)
      manifest += `${k} '${entry[0]}'\n\n`;
    else
      manifest += `${k}s {\n${entry.map(e => '  \'' + e + '\'').join(',\n')}\n}\n\n`;

  }

  return manifest;

}

const expand = function(entry) {
  return glob.sync(entry, {cwd: ESX_DIR, nodir: true});
}

const init = () => {

  console.log('^7[^4esx^7] checking manifest');

  const oldManifest    = parseManifest(TPL_DATA);
  const newManifest    = JSON.parse(JSON.stringify(oldManifest));
  const oldManifestLua = fs.readFileSync(MANIFEST).toString();

  ['file', 'shared_script', 'client_script', 'server_script'].forEach(k => {

    newManifest[k] = [];
    const entry    = newManifest[k];
    const oldEntry = oldManifest[k] || [];

    for(let i=0; i<oldEntry.length; i++) {

      const line = oldEntry[i];

      if(line[0] == '@') {
        entry.push(line);
        continue;
      }

      const expanded = expand(line);

      for(let j=0; j<expanded.length; j++)
        entry.push(expanded[j]);
    }

  });

  const newManifestLua = buildManifest(newManifest);

  if(newManifestLua === oldManifestLua) {

    console.log('^7[^4esx^7] ^2no changes required in fxmanifest.lua^7');

    process.nextTick(() => {
      emit('esx:manifest:check:pass');
    });

  } else {

    console.log('^7[^4esx^7] ^1fxmanifest.lua has changed, you MUST type ^4ensure es_extended^1 in the console^7');

    fs.writeFileSync(MANIFEST, newManifestLua);

    ExecuteCommand('refresh');
  }

}

init();
