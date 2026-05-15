fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'QB Pawnshop - ox_lib UI'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/locale.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_stocks.lua',
    'server/sv_utils.lua',
    'server/sv_main.lua'
}

client_scripts {
    'client/cl_main.lua',
    'client/cl_menu.lua',
    'client/cl_time.lua'
}

ui_page 'web/dist/index.html'

files {
  'locales/*.json',
  'web/dist/index.html',
  'web/dist/**/*'
}