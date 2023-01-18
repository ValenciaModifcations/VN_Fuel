local NDCore = exports["ND_Core"]:GetCoreObject()

RegisterNetEvent("VN_Fuel:pay", function(amount)
    local player = source
    NDCore.Functions.DeductMoney(math.floor(amount), player, "cash")
    TriggerClientEvent("chat:addMessage", player, {
        color = {211,211,211},
        args = {"Pump", "Paid: $" .. string.format("%.2f", amount) .. " for gas."}
    })
end)



