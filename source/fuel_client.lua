local isFueling, currentFuel, currentCost, fuelSynced, inBlacklisted, ShutOffPump = false, 0.0, 0.0, false, false, false
local target = exports.ox_target

function ManageFuelUsage(vehicle)
    local fuelLevel = DecorExistOn(vehicle, Config.FuelDecor) and GetFuel(vehicle) or math.random(200, 800) / 10
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

function IsValidFuelPumpModel(model)
    for _, validModel in pairs(Config.gasPumpModels) do
        if model == validModel or GetHashKey(model) == GetHashKey(validModel) then
            return true
        end
    end
    return false
end

local pumpObject = Config.gasPumpModels

for _, model in pairs(pumpObject) do
    if IsValidFuelPumpModel(model) then
        exports.ox_target:addModel(model, {
            label = 'Fuel Pump',
            icon = 'fa-solid fa-gas-pump',
            onSelect = function(data)
                lib.showContext('fuel_options')
            end
        })
    end
end

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

RegisterNetEvent('start_refueling')
AddEventHandler('start_refueling', function(args)
    local pumpObject = args.pumpObject
    local fuelType = args.fuelType
    local ped = PlayerPedId()
    local vehicle = GetPlayersLastVehicle()
    local maxFuel = 100.0

    -- Reset cancel to false before starting a new refueling operation
    local cancel = false

    if vehicle and DoesEntityExist(vehicle) then
        local vehicleCoords = GetEntityCoords(vehicle)
        local pedCoords = GetEntityCoords(ped)

        if GetDistanceBetweenCoords(pedCoords, vehicleCoords, true) < 2.5 then
            local currentFuel = GetVehicleFuelLevel(vehicle)
            local fuelRate = 1.50

            local player = NDCore.getPlayer()
            local playercash = player.cash
            local initialFuel = currentFuel

            local paymentThread = Citizen.CreateThread(function()
                while not cancel and currentFuel < maxFuel do
                    Citizen.Wait(0)
                    vehicleCoords = GetEntityCoords(vehicle)
                    DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 1.0, string.format("Fuel: %.1f%%", currentFuel))

                    if IsControlJustReleased(0, 38) then
                        cancel = true
                        local addedFuel = currentFuel - initialFuel
                        local extraCost = addedFuel * Config.FuelTypes[fuelType].currentPrice

                        if playercash < extraCost then
                            print("Not enough cash to refuel.")
                            return
                        end

                        TriggerServerEvent('fuel:pay', extraCost)

                        TriggerEvent('chat:addMessage', {
                            color = {31, 78, 47},
                            multiline = true,
                            args = {"Gas Station", "That's enough for you? Alrighty! Your tank is now " .. string.format("%.1f%% full.", currentFuel)}
                        })
                    end
                end
            end)

			while not cancel and currentFuel < maxFuel do
				Citizen.Wait(1000 / fuelRate)
			
				currentFuel = currentFuel + 1
				progress = math.floor((currentFuel / maxFuel) * 100)
			
				if currentFuel > maxFuel then
					currentFuel = maxFuel
				end
			
				SetFuel(vehicle, currentFuel)
			
				if fuelType == 87 then
					SetVehicleCheatPowerIncrease(vehicle, 1.0)
				elseif fuelType == 89 then
					SetVehicleCheatPowerIncrease(vehicle, 1.2)
				elseif fuelType == 91 then
					SetVehicleCheatPowerIncrease(vehicle, 1.3)
				end
			
				if currentFuel >= maxFuel then
					TriggerEvent('fuel:completeRefueling', vehicle, fuelType, initialFuel, maxFuel)
					return
				end
			end

            isFueling = false

            if paymentThread then
                Citizen.Wait(500)  -- Wait for a short time to ensure the payment thread completes
                Citizen.StopThread(paymentThread)
            end
        else
            TriggerEvent('chat:addMessage', {
                color = {31, 78, 47},
                multiline = true,
                args = {"Gas Station", "What am I supposed to be fueling here? Are you on crack?"}
            })
        end
    else
        TriggerEvent('chat:addMessage', {
            color = {31, 78, 47},
            multiline = true,
            args = {"Gas Station", "I don't see a car nearby. No soliciting!"}
        })
    end
end)

AddEventHandler('fuel:stopRefuelFromPump', function()
    if isFueling then
        ShutOffPump = true
    end
end)

RegisterNetEvent('fuel:completeRefueling')
AddEventHandler('fuel:completeRefueling', function(vehicle, fuelType, initialFuel, maxFuel)
    local addedFuel = GetVehicleFuelLevel(vehicle) - initialFuel
    local extraCost = addedFuel * Config.FuelTypes[fuelType].currentPrice

    local player = NDCore.getPlayer()
    local playercash = player.cash

    if playercash < extraCost then
        print("Not enough cash to refuel.")
        return
    end

    TriggerServerEvent('fuel:pay', extraCost)

    TriggerEvent('chat:addMessage', {
        color = {31, 78, 47},
        multiline = true,
        args = {"Gas Station", "That's enough for you? Alrighty! Your tank is now " .. string.format("%.1f%% full.", GetVehicleFuelLevel(vehicle))}
    })
end)

AddEventHandler('fuel:refuelFromPump', function(ped, vehicle)
    isFueling = true
    TriggerEvent('fuel:startFuelUpTick', true, ped, vehicle)
    local player = NDCore.getPlayer()
    local playercash = player.cash

    while isFueling do
        local vehicleCoords = GetEntityCoords(vehicle)
        local extraString = ""

        if playercash >= currentCost then
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
    local function DrawAdvancedText(x, y, w, h, sc, text, r, g, b, a, font, jus)
        SetTextFont(font)
        SetTextProportional(0)
        SetTextScale(sc, sc)
        N_0x4e096588b13ffeca(jus)
        SetTextColour(r, g, b, a)
        SetTextDropShadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x - 0.1 + w, y - 0.02 + h)
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
                local vehicle = GetVehiclePedIsIn(PlayerPedId())
                local speedMph = math.ceil(GetEntitySpeed(vehicle) * 2.236936)
                local speedKmh = math.ceil(speedMph * 1.60934)
                local fuelPercentage = math.ceil(GetVehicleFuelLevel(vehicle))

                DrawAdvancedText(0.130 - x, 0.77 - y, 0.005, 0.0028, 0.6, tostring(speedMph), 255, 255, 255, 255, 6, 1)
                DrawAdvancedText(0.174 - x, 0.77 - y, 0.005, 0.0028, 0.6, tostring(speedKmh), 255, 255, 255, 255, 6, 1)
                DrawAdvancedText(0.2195 - x, 0.77 - y, 0.005, 0.0028, 0.6, tostring(fuelPercentage), 255, 255, 255, 255, 6, 1)
                DrawAdvancedText(0.148 - x, 0.7765 - y, 0.005, 0.0028, 0.4, "mp/h              km/h              Fuel", 255, 255, 255, 255, 6, 1)
            else
                Citizen.Wait(750)
            end

            Citizen.Wait(0)
        end
    end)
end
