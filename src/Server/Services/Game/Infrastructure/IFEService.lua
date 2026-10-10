
-- IFE Service
-- Jack_AviationRBX
-- July 24, 2022


local Debounce = {}


local IFEService = {Client = {}}
local EVENT_IFE = "IFEUpdate"


function IFEService:Init()
    self:RegisterClientEvent(EVENT_IFE)
end


function IFEService:Start()
    self:MonitorExternalEvents()
end


function IFEService:MonitorExternalEvents()
    self.Services.Game.Core.FlightService:ConnectEvent("Flight", function(action, tbl)
        if action == "CurrentSet" or action == "CurrentUpdate" then
            self:FireAllClients(EVENT_IFE, "UpdateFlight", tbl)
        end
    end)
end


function IFEService.Client:GetCurrentFlight()
    local Data = self.Server.Services.Game.Core.FlightService:GetCurrentFlight()
    return Data
end



function IFEService.Client:GetAllSongs(player)
    local Music = self.Server.Services.Game.Auditory.MusicService
    return Music:GetAllSongs()
end


function IFEService.Client:RequestGame(player, gameName)
    if game.ServerStorage.Tools.Games:FindFirstChild(gameName) then
        self.Server.Services.Game.Core.ToolService:IssueTool(player, gameName)
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Game issued!")
    end
end


function IFEService:MonitorIFEButtons(IFEModelLocation)
    for _,v in pairs(IFEModelLocation:GetDescendants()) do
        if v:IsA("Part") and v.Name == "Clicker" then
            local Instance = Instance.new("ClickDetector", v)
            Instance.MaxActivationDistance = 20
            Instance.MouseClick:Connect(function(playerWhoClicked)
                if playerWhoClicked.PlayerGui:FindFirstChild("IFE") then
                    playerWhoClicked.PlayerGui.IFE.Enabled = true
                    playerWhoClicked.PlayerGui.IFE.IFELocation.Value = IFEModelLocation
                    self:FireClient(EVENT_IFE, playerWhoClicked, "UpdateFlightData")
                end
            end)
        end
    end
end


return IFEService