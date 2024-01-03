fx_version 'bodacious'
game 'gta5'

author 'Valencia Modifcations'
description 'Legacy Fuel for ND_Core'
version '2'
lua54 "yes"

-- Source https://github.com/ValenciaModifcations/VN_Fuel

client_scripts {
	'config.lua',
	'functions/functions_client.lua',
	'source/fuel_client.lua'
}

server_scripts {
	'config.lua',
	'source/fuel_server.lua'
}

shared_scripts {
	"@ND_Core/init.lua",
	"config.lua",
	"@ox_lib/init.lua"
}

exports {
	'GetFuel',
	'SetFuel'
}
