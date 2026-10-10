-- PlayerController Service
-- Jack_AviationRBX
-- September 5, 2021

--[[

FreezeService allows the communication between the client controller with the server.
More freeze options may be added in the future.

--]]


local EVENT_MOVEMENT = "Movement"


local PlayerControlService = {Client = {}}


function PlayerControlService:Init()
    self:RegisterClientEvent(EVENT_MOVEMENT)
end


function PlayerControlService:DisableMovement(player)
    self:FireClient(EVENT_MOVEMENT, player, false)
end


function PlayerControlService:EnableMovement(player)
    self:FireClient(EVENT_MOVEMENT, player, true)
end


return PlayerControlService