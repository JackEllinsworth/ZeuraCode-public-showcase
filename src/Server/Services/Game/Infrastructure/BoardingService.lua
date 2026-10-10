-- Boarding Service
-- Jack_AviationRBX
-- August 9, 2022


local Players = game:GetService("Players")
local SCANNERS_BOARDING = game.Workspace.Infrastructure.Scanners.BoardingTicket
local EVENT_BOARDING = "Boarding"


local BoardingService = {Client = {}}


function BoardingService:Init()
    self:RegisterClientEvent(EVENT_BOARDING)
end


function BoardingService:Start()
    for _,v in pairs(SCANNERS_BOARDING.Gates:GetChildren()) do
        local Gate = v.Name
        SCANNERS_BOARDING.Controllers[Gate].ClickDetector.MouseClick:Connect(function(player)
            if self.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
                player.PlayerGui.BoardingSystem.Gate.Value = Gate
                self:FireClient(EVENT_BOARDING, player, "OpenStatus", true)
            end
        end)
    end
end


function BoardingService.Client:GetClassOptions()
    local Classes = {}
    for i,_ in pairs(self.Server.Modules.Config.Classes) do
        table.insert(Classes, i)
    end
    return Classes
end


function BoardingService.Client:SetBoardingMode(player, status, className)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        local Gate = player.PlayerGui.BoardingSystem.Gate.Value

        for _,v in pairs(SCANNERS_BOARDING.Gates[Gate]:GetChildren()) do
            if status then
                v.Configuration.ClassRestrictionBooked.Value = className
            else
                v.Configuration.ClassRestrictionBooked.Value = "None"
            end
        end

        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Boarding Mode Updated!")
    end
end


return BoardingService