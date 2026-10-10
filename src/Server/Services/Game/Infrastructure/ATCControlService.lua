-- ATC Control Service
-- Jack_AviationRBX
-- August 5, 2023

local EVENT_NAME = "ATCStaffUpdate"


local ATCControlService = {Client = {}}

function ATCControlService:Init()
    self:RegisterClientEvent(EVENT_NAME)
end

function ATCControlService:OpenClose(player)
    self:FireClient(EVENT_NAME, player, "OpenClosePanel")
end


function ATCControlService.Client:GetFlightNumber()
    local Data = self.Server.Services.Game.Core.FlightService:GetCurrentFlight()
    if Data then
        return Data.FlightNumber
    else
        return false
    end
end


function ATCControlService.Client:RequestATCAnnouncement(player, message, channel, flightNumber)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        local Headtag = ""
        if channel == "FlightDeck" then
            Headtag = flightNumber
        elseif channel == "ArrivalATC" then
            Headtag = self.Server.Modules.Config.Arrival .. " ATC"
        else
            Headtag = self.Server.Modules.Config.Departure .. " ATC"
        end

        self.Server.Services.Game.Core.AnnouncementService:IssueATCAnnouncement(message, player.Name, Headtag)
    end
end



return ATCControlService