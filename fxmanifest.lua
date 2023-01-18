fx_version 'bodacious'
game 'gta5'

author 'Valencia Modifcations'
description 'Legacy Fuel for ND_Core'
version '1.3'

-- What to run
client_scripts {
	'config.lua',
	'functions/functions_client.lua',
	'source/fuel_client.lua'
}

server_scripts {
	'config.lua',
	'source/fuel_server.lua'
}

exports {
	'GetFuel',
	'SetFuel'
}
