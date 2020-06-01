fx_version 'adamant'

game 'gta5'

description 'ESX'

version '2.0.1'

ui_page 'hud/index.html'

ui_page_preload 'yes'

dependencies {
  'yarn',
  'spawnmanager',
  'baseevents',
  'mysql-async',
  'async',
  'cron',
  'skinchanger'
}

server_scripts {
  'fxmanifest.workaround.js',
}
