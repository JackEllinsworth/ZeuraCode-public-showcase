-- Info Screen Service
-- Jack_AviationRBX
-- June 24, 2024


local SCREENS = game.Workspace.Infrastructure.Screens:FindFirstChild("InfoScreens")


local InfoScreenService = {}


function InfoScreenService:UpdateEvent()

    self:ClearEvent()
    
    local ZeuraFlight, Data = self.Services.Game.Infrastructure.Screens.ScreenService:GetZeuraFlight()

    for _,screen in pairs(SCREENS:GetChildren()) do
        local location = screen.screen.Info.Background.Info
        location.Aircraft.Aircraft.Text = Data.Aircraft
        location.BoardingTime.BoardingTime.Text = Data.BoardingTime
        location.DepartureGate.Gate.Text = Data.Gate
        location.FlightNumber.FlightNumber.Text = Data.FlightNumber
        location.Status.Status.Text = Data.Status
    end
end


function InfoScreenService:ClearEvent()
    for _,screen in pairs(SCREENS:GetChildren()) do
        local location = screen.screen.Info.Background.Info
        location.Aircraft.Aircraft.Text = "N/A"
        location.BoardingTime.BoardingTime.Text = "N/A"
        location.DepartureGate.Gate.Text = "N/A"
        location.FlightNumber.FlightNumber.Text = "ZEUXXXX"
        location.Status.Status.Text = "N/A"
    end
end



return InfoScreenService