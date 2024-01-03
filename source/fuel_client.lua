local isFueling, currentFuel, currentCost, fuelSynced, inBlacklisted, ShutOffPump = false, 0.0, 0.0, false, false, false
local target = exports.ox_target

function ManageFuelUsage(vehicle)
    local fuelLevel = DecorExistOn(vehicle, Config.FuelDecor) and GetFuel(vehicle) or math.random(20, 80) / 10
    SetFuel(vehicle, fuelLevel)
    fuelSynced = DecorExistOn(vehicle, Config.FuelDecor)

    if IsVehicleEngineOn(vehicle) then
        local rpm = GetVehicleCurrentRpm(vehicle)
        local usage = Config.FuelUsage[Round(rpm, 1)] * (Config.Classes[GetVehicleClass(vehicle)] or 1.0) / 10
        SetFuel(vehicle, GetVehicleFuelLevel(vehicle) - usage)
    end
end

Citizen.CreateThread(function()
    DecorRegister(Config.FuelDecor, 1)
    for _, v in ipairs(Config.Blacklist) do
        Config.Blacklist[type(v) == 'string' and GetHashKey(v) or v] = true
    end

    while true do
        Citizen.Wait(1000)
        local ped, vehicle = PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false)
        inBlacklisted = vehicle and Config.Blacklist[GetEntityModel(vehicle)] or false

        if not inBlacklisted and vehicle and GetPedInVehicleSeat(vehicle, -1) == ped then
            ManageFuelUsage(vehicle)
        end
    end
end)

function FindNearestFuelPump()
    local playerCoords, shortestDistance = GetEntityCoords(PlayerPedId()), math.huge
    local nearestPumpObject, nearestPumpCoords

    for _, model in pairs(Config.gasPumpModels) do
        local hash = GetHashKey(model)
        local pump = GetClosestObjectOfType(playerCoords, 10.0, hash, false, false, false)
        if pump then
            local pumpCoords = GetEntityCoords(pump)
            local distance = #(playerCoords - pumpCoords)
            if distance < shortestDistance then
                shortestDistance, nearestPumpObject, nearestPumpCoords = distance, pump, pumpCoords
            end
        end
    end
    return nearestPumpObject, nearestPumpCoords
end

local performanceBoost = {
    [87] = { fieldName = 'fInitialDriveForce', value = 1.0 },
    [89] = { fieldName = 'fInitialDriveForce', value = 2.05 },
    [91] = { fieldName = 'fInitialDriveForce', value = 3.1 }
}

target:addGlobalObject({
    entity = pumpObject,
    label = 'Fuel Pump',
    icon = 'fa-solid fa-gas-pump',
    command = 'fueltest'
})

lib.registerContext({
    id = 'fuel_options',
    title = 'Fuel Type',
    canClose = true,
    options = {
        { title = 'Refuel with 87 - $1.50 per unit', event = 'start_refueling', args = { pumpObject = pumpObject, fuelType = 87 } },
        { title = 'Refuel with 89 - $1.70 per unit', event = 'start_refueling', args = { pumpObject = pumpObject, fuelType = 89 } },
        { title = 'Refuel with 91 - $1.90 per unit', event = 'start_refueling', args = { pumpObject = pumpObject, fuelType = 91 } }
    }
})

RegisterCommand('fueltest', function(source)
    lib.showContext('fuel_options')
end)

RegisterNetEvent('start_refueling')
AddEventHandler('start_refueling', function(args)
    local pumpObject = args.pumpObject
    local fuelType = args.fuelType
    local ped = PlayerPedId()
    local vehicle = GetPlayersLastVehicle()
    local maxFuel = 100.0

    if vehicle and DoesEntityExist(vehicle) then
        local vehicleCoords = GetEntityCoords(vehicle)
        local pedCoords = GetEntityCoords(ped)
        if GetDistanceBetweenCoords(pedCoords, vehicleCoords, true) < 2.5 then
            local currentFuel = GetVehicleFuelLevel(vehicle)
            local fuelNeeded = maxFuel - currentFuel
            local fuelRate = 1.50
            local duration = fuelNeeded / fuelRate * 1000

            local player = NDCore.getPlayer()
            local playerPossibleCash = player.cash
            local extraCost = fuelNeeded / 10 * Config.FuelTypes[fuelType].currentPrice

            if playerPossibleCash < extraCost then
                print("Not enough cash to refuel.")
                return
            end

            local cancel = false
            local progress = 0

            Citizen.CreateThread(function()
                if lib.progressBar({
                    duration = duration,
                    label = string.format('Refueling...'),
                    canCancel = true,
                    disable = {
                        move = true,
                        car = true,
                        combat = true,
                    }
                }) then
                    print('Refueling complete')
                else
                    print('Refueling cancelled')
                    cancel = true
                end
            end)

            while not cancel and currentFuel < maxFuel do
                Citizen.Wait(1000 / fuelRate)
                if IsControlJustReleased(0, 38) then
                    cancel = true
                    break
                end
                currentFuel = currentFuel + 1
                progress = math.floor((currentFuel / maxFuel) * 100)
                if currentFuel > maxFuel then
                    currentFuel = maxFuel
                end
                SetFuel(vehicle, currentFuel)
            end

			if not cancel then
				TriggerServerEvent('fuel:pay', extraCost)
			
				local boost = performanceBoost[fuelType]
				if boost then
					SetVehicleHandlingFloat(vehicle, 'CHandlingData', boost.fieldName, boost.value)
					print(string.format("Vehicle received a performance boost with fuel type %d", fuelType))
					print("New " .. boost.fieldName .. " value: " .. GetVehicleHandlingFloat(vehicle, 'CHandlingData', boost.fieldName))
				end
			end
		
            isFueling = false
            currentCost = 0.0
        else
            print("Player is not near the vehicle or vehicle not found for refueling.")
        end
    else
        print("No vehicle found for refueling.")
    end
end)

AddEventHandler('fuel:stopRefuelFromPump', function()
	if isFueling then
		ShutOffPump = true
	end
end)

AddEventHandler('fuel:refuelFromPump', function(ped, vehicle)
    isFueling = true
    TriggerEvent('fuel:startFuelUpTick', true, ped, vehicle)
    local player = NDCore.getPlayer()
    local playerPossibleCash = player.cash

    while isFueling do
        local vehicleCoords = GetEntityCoords(vehicle)
        local extraString = ""

        if playerPossibleCash >= currentCost then
            SetFuel(vehicle, currentFuel)
            extraString = "\n" .. Config.Strings.TotalCost .. ": ~g~$" .. Round(currentCost, 1)
        end

        Citizen.Wait(0)
    end
end)

AddEventHandler('fuel:refuelFromJerryCan', function(ped, vehicle)
	TaskTurnPedToFaceEntity(ped, vehicle, 1000)
	Citizen.Wait(1000)
	SetCurrentPedWeapon(ped, -1569615261, true)
	isFueling = true
	LoadAnimDict("timetable@gardener@filling_can")
	TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)

	TriggerEvent('fuel:startFuelUpTick', false, ped, vehicle)

	while isFueling do
		for _, controlIndex in pairs(Config.DisableKeys) do
			DisableControlAction(0, controlIndex)
		end

		local vehicleCoords = GetEntityCoords(vehicle)
		DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5, Config.Strings.CancelFuelingJerryCan .. "\nGas can: ~g~" .. Round(GetAmmoInPedWeapon(ped, 883325847) / 4500 * 100, 1) .. "% | Vehicle: " .. Round(currentFuel, 1) .. "%")

		if not IsEntityPlayingAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3) then
			TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
		end

		if IsControlJustReleased(0, 38) or DoesEntityExist(GetPedInVehicleSeat(vehicle, -1)) then
			isFueling = false
		end

		Citizen.Wait(0)
	end

	ClearPedTasks(ped)
	RemoveAnimDict("timetable@gardener@filling_can")
end)

--[[AddEventHandler('fuel:requestJerryCanPurchase', function()
	if Config.UseESX then
		currentCash = ESX.GetPlayerData().money
	end
	if currentCash >= Config.JerryCanCost then
		local ped = PlayerPedId()
		if not HasPedGotWeapon(ped, 883325847) then
			ShowNotification(Config.Strings.PurchaseJerryCan)
			GiveWeaponToPed(ped, 883325847, 4500, false, true)
			TriggerServerEvent('fuel:pay', Config.JerryCanCost)
		else
			if Config.UseESX then
				local refillCost = Round(Config.RefillCost * (1 - GetAmmoInPedWeapon(ped, 883325847) / 4500))

				if refillCost > 0 then
					if currentCash >= refillCost then
						ShowNotification(Config.Strings.RefillJerryCan .. "~g~$" .. refillCost)
						TriggerServerEvent('fuel:pay', refillCost)
						SetPedAmmo(ped, 883325847, 4500)
					else
						ShowNotification(Config.Strings.NotEnoughCashJerryCan)
					end
				else
					ShowNotification(Config.Strings.JerryCanFull)
				end
			else
				ShowNotification(Config.Strings.RefillJerryCan)
				SetPedAmmo(ped, 883325847, 4500)
			end
		end
	else
		ShowNotification(Config.Strings.NotEnoughCash)
	end
end)]]--

if Config.ShowNearestGasStationOnly then
	Citizen.CreateThread(function()
		local currentGasBlip = 0

		while true do
			local coords = GetEntityCoords(PlayerPedId())
			local closest = 1000
			local closestCoords

			for _, gasStationCoords in pairs(Config.GasStations) do
				local dstcheck = GetDistanceBetweenCoords(coords, gasStationCoords)

				if dstcheck < closest then
					closest = dstcheck
					closestCoords = gasStationCoords
				end
			end

			if DoesBlipExist(currentGasBlip) then
				RemoveBlip(currentGasBlip)
			end

			currentGasBlip = CreateBlip(closestCoords)

			Citizen.Wait(10000)
		end
	end)
elseif Config.ShowAllGasStations then
	Citizen.CreateThread(function()
		for _, gasStationCoords in pairs(Config.GasStations) do
			CreateBlip(gasStationCoords)
		end
	end)
end

if Config.EnableHUD then
	local function DrawAdvancedText(x,y ,w,h,sc, text, r,g,b,a,font,jus)
		SetTextFont(font)
		SetTextProportional(0)
		SetTextScale(sc, sc)
		N_0x4e096588b13ffeca(jus)
		SetTextColour(r, g, b, a)
		SetTextDropShadow(0, 0, 0, 0,255)
		SetTextEdge(1, 0, 0, 0, 255)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		AddTextComponentString(text)
		DrawText(x - 0.1+w, y - 0.02+h)
	end
	local mph = 0
	local kmh = 0
	local fuel = 0
	local displayHud = false

	local x = 0.01135
	local y = -0.019420

	Citizen.CreateThread(function()
		while true do
			local ped = PlayerPedId()

			if IsPedInAnyVehicle(ped) and not (Config.RemoveHUDForBlacklistedVehicle and inBlacklisted) then
				local vehicle = GetVehiclePedIsIn(ped)
				local speed = GetEntitySpeed(vehicle)

				mph = tostring(math.ceil(speed * 2.236936))
				kmh = tostring(math.ceil(speed * 3.6))
				fuel = tostring(math.ceil(GetVehicleFuelLevel(vehicle)))

				displayHud = true
			else
				displayHud = false

				Citizen.Wait(500)
			end

			Citizen.Wait(50)
		end
	end)

	Citizen.CreateThread(function()
		while true do
			if displayHud then
				DrawAdvancedText(0.130 - x, 0.77 - y, 0.005, 0.0028, 0.6, mph, 255, 255, 255, 255, 6, 1)
				DrawAdvancedText(0.174 - x, 0.77 - y, 0.005, 0.0028, 0.6, kmh, 255, 255, 255, 255, 6, 1)
				DrawAdvancedText(0.2195 - x, 0.77 - y, 0.005, 0.0028, 0.6, fuel, 255, 255, 255, 255, 6, 1)
				DrawAdvancedText(0.148 - x, 0.7765 - y, 0.005, 0.0028, 0.4, "mp/h              km/h              Fuel", 255, 255, 255, 255, 6, 1)
			else
				Citizen.Wait(750)
			end

			Citizen.Wait(0)
		end
	end)
end
