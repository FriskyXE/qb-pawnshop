local lastDoorState = nil

if Config.UseTimes then
    CreateThread(function()
        while true do
            local hour = GetClockHours()
            local isClosed = hour < Config.TimeOpen or hour >= Config.TimeClosed
            local newState = isClosed and 1 or 0 -- 1 = Locked, 0 = Unlocked

            if newState ~= lastDoorState then
                lastDoorState = newState
                TriggerServerEvent('qb-pawnshop:server:syncDoors', newState)
            end
            Wait(10000)
        end
    end)
end
