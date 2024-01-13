RegisterNetEvent("fuel:pay", function(amount)
    local src = source
    local player = NDCore.getPlayer(src)
    local success = player.deductMoney("cash", math.floor(amount), "Fuel from gas station")

    if success then
        -- Trigger a success notification directly on the server side
        player.notify({
            title = "Payment Successful",
            description = "Paid: $" .. string.format("%.2f", amount) .. " for gas.",
            type = "success",
            duration = 8000,
            position = "bottom"
        })
    else
        -- Trigger an error notification directly on the server side
        player.notify({
            title = "Insufficient Funds",
            description = "Get a job you cant even afford",
            type = "error",
            duration = 8000,
            position = "bottom"
        })
    end
end)


--- This code, below, is meant to handle the dynamic fuel prices. 

--[[local function UpdateFuelPrices()
    for fuelType, info in pairs(Config.FuelTypes) do
        local minPrice = info.minPrice
        local maxPrice = info.maxPrice
        Config.FuelTypes[fuelType].currentPrice = math.random(minPrice, maxPrice)
    end

    TriggerClientEvent('fuel:updatePrices', -1, Config.FuelTypes)
end

Citizen.CreateThread(function()
    UpdateFuelPrices()
    while true do
        Citizen.Wait(600000)
        UpdateFuelPrices()
    end
end)--]]