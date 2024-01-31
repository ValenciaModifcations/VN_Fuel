Config = {}

-- What should the price of jerry cans be?
Config.JerryCanCost = 100
Config.RefillCost = 50 -- If it is missing half of it capacity, this amount will be divided in half, and so on.

-- Display Refuel Info For 3 Seconds After Done
Config.WaitTimeAfterRefuel = 3000

-- Fuel decor - No need to change this, just leave it.
Config.FuelDecor = "_FUEL_LEVEL"

-- What keys are disabled while you're fueling.
Config.DisableKeys = {0, 22, 23, 24, 29, 30, 31, 37, 44, 56, 82, 140, 166, 167, 168, 170, 288, 289, 311, 323}

-- Want to use the HUD? Turn this to true.
Config.EnableHUD = true

-- Configure blips here. Turn both to false to disable blips all together.
Config.ShowNearestGasStationOnly = false
Config.ShowAllGasStations = true

Config.Strings = {
	ExitVehicle = "Exit the vehicle to refuel",
	EToRefuel = "Press ~g~E ~w~to refuel vehicle",
	JerryCanEmpty = "Jerry can is empty",
	FullTank = "Tank is full",
	PurchaseJerryCan = "You purchased a jerry can for ~g~$" .. Config.JerryCanCost,
	CancelFuelingPump = "Press ~g~E ~w~to cancel the fueling",
	CancelFuelingJerryCan = "Press ~g~E ~w~to cancel the fueling",
	NotEnoughCash = "~r~Not enough cash",
	RefillJerryCan = "You refilled the jerry can for ",
	NotEnoughCashJerryCan = "~r~Not enough cash to refill jerry can",
	JerryCanFull = "~g~Jerry can is full",
	TotalCost = "Cost",
}

if not Config.UseESX then
	Config.Strings.PurchaseJerryCan = "You purchased a jerry can"
	Config.Strings.RefillJerryCan = "You refilled the jerry can"
end

-- Blacklist certain vehicles. Use names or hashes. https://wiki.gtanet.work/index.php?title=Vehicle_Models
Config.Blacklist = {
	--"Adder",
	--276773164
	"as350"
}

Config.FuelTypes = {
    [87] = { currentPrice = 1.50 },
    [89] = { currentPrice = 1.70 },
    [91] = { currentPrice = 1.90 },
}

Config.gasPumpModels = {
	"prop_gas_pump_1d",
	"prop_gas_pump_1a",
	"prop_gas_pump_1b",
	"prop_gas_pump_1c",
	"prop_vintage_pump",
	"prop_gas_pump_old2",
	"prop_gas_pump_old3"
}

-- Do you want the HUD removed from showing in blacklisted vehicles?
Config.RemoveHUDForBlacklistedVehicle = true

-- Class multipliers. Adjust these to change fuel consumption for different vehicle classes.
Config.Classes = {
	[0] = 0.8, -- Compacts
	[1] = 1.1, -- Sedans
	[2] = 1.5, -- SUVs 
	[3] = 0.9, -- Coupes
	[4] = 1.5, -- Muscle 
	[5] = 1.2, -- Sports Classics
	[6] = 1.3, -- Sports
	[7] = 1.4, -- Super
	[8] = 1.8, -- Motorcycles
	[9] = 1.3, -- Off-road 
	[10] = 1.9, -- Industrial
	[11] = 1.5, -- Utility
	[12] = 1.4, -- Vans
	[13] = 0.0, -- Cycles 
	[14] = 1.0, -- Boats
	[15] = 1.0, -- Helicopters
	[16] = 1.0, -- Planes
	[17] = 1.0, -- Service
	[18] = 0.6, -- Emergency
	[19] = 1.0, -- Military
	[20] = 1.0, -- Commercial
	[21] = 1.0, -- Trains
}

-- Fuel usage based on RPM percentages. Adjust as needed.
Config.FuelUsage = {
	[1.0] = 1.2, -- 100% RPM
	[0.9] = 1.0, -- 90% RPM
	[0.8] = 0.8, -- 80% RPM
	[0.7] = 0.7, -- 70% RPM
	[0.6] = 0.6, -- 60% RPM
	[0.5] = 0.5, -- 50% RPM
	[0.4] = 0.4, -- 40% RPM
	[0.3] = 0.3, -- 30% RPM
	[0.2] = 0.2, -- 20% RPM
	[0.1] = 0.2, -- 10% RPM
	[0.0] = 0.01, -- Idle (No fuel consumption)
}

Config.GasStations = {
	vector3(49.4187, 2778.793, 58.043),
	vector3(263.894, 2606.463, 44.983),
	vector3(1039.958, 2671.134, 39.550),
	vector3(1207.260, 2660.175, 37.899),
	vector3(2539.685, 2594.192, 37.944),
	vector3(2679.858, 3263.946, 55.240),
	vector3(2005.055, 3773.887, 32.403),
	vector3(1687.156, 4929.392, 42.078),
	vector3(1701.314, 6416.028, 32.763),
	vector3(179.857, 6602.839, 31.868),
	vector3(-94.4619, 6419.594, 31.489),
	vector3(-2554.996, 2334.40, 33.078),
	vector3(-1800.375, 803.661, 138.651),
	vector3(-1437.622, -276.747, 46.207),
	vector3(-2096.243, -320.286, 13.168),
	vector3(-724.619, -935.1631, 19.213),
	vector3(-526.019, -1211.003, 18.184),
	vector3(-70.2148, -1761.792, 29.534),
	vector3(265.648, -1261.309, 29.292),
	vector3(819.653, -1028.846, 26.403),
	vector3(1208.951, -1402.567,35.224),
	vector3(1181.381, -330.847, 69.316),
	vector3(620.843, 269.100, 103.089),
	vector3(2581.321, 362.039, 108.468),
	vector3(176.631, -1562.025, 29.263),
	vector3(176.631, -1562.025, 29.263),
	vector3(-319.292, -1471.715, 30.549),
	vector3(1784.324, 3330.55, 41.253),
	vector3(-1232.51, 6927.99, 25.21) -- Custom Gas Station
}
