-- Server stub.
-- You don't strictly need a server file for the overlay itself,
-- but it's useful if later you want:
-- - synced “per-part damage” systems
-- - storing damage states
-- - permissions / jobs
-- - logging

RegisterNetEvent('my_vehicle_inspect:server:forceStop', function(targetId)
    -- Example: server can tell a player to stop inspecting (optional)
    if type(targetId) ~= 'number' then return end
    TriggerClientEvent('my_vehicle_inspect:client:stop', targetId)
end)