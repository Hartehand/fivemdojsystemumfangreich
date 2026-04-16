fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'doj_casehub'
author 'Codex'
description 'DOJ CaseHub for ESX + oxmysql with optional wasabi_mdt/vms_cityhall integrations'
version '2.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/tablet.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/permissions.lua',
    'server/integrations.lua',
    'server/templates.lua',
    'server/signatures.lua',
    'server/calendar.lua',
    'server/cases.lua',
    'server/evidence.lua',
    'server/documents.lua',
    'server/hearings.lua',
    'server/export.lua',
    'server/main.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/print.css',
    'web/app.js'
}

dependencies {
    'es_extended',
    'oxmysql'
}
