-- Baggage Arrival Screen Service
-- Jack_AviationRBX
-- June 24, 2024

local SCREENS = game.Workspace.Infrastructure.Screens:FindFirstChild("BaggageArrival")

local BaggageArrivalScreenService = {}


function BaggageArrivalScreenService:UpdateEvent(conveyor)

    self:ClearEvent()
    
    local ZeuraFlight, Data = self.Services.Game.Infrastructure.Screens.ScreenService:GetZeuraFlight()
    local RandomFlights = self.Services.Game.Infrastructure.Screens.ScreenService:GenerateRandomFlights(10, false)

    for _,screen in pairs(SCREENS:GetChildren()) do
        local ColourSwitch = true
        local Order = 1

        local Template = screen.screen.Baggage.Background.Flights.F_1
        local Clone = Template:Clone()
        Clone.Parent = Template.Parent
        Clone.LayoutOrder = Order
        Clone.From.Text = Data["Airport"]
        Clone.Carousel.Text = tostring(conveyor)
        Clone.ImageLabel.Image = "rbxassetid://"..ZeuraFlight.Id
        Clone.Visible = true
        Order += 1
        Clone.Name = "0"

        for i = 1, 10 do
            local flight = RandomFlights[i]
            local Template
            if not ColourSwitch then
                Template = screen.screen.Baggage.Background.Flights.F_1
                ColourSwitch = true
            else
                Template = screen.screen.Baggage.Background.Flights.F_2
                ColourSwitch = false
            end
            local Clone = Template:Clone()
            Clone.Parent = Template.Parent
            Clone.LayoutOrder = Order
            Clone.Name = tostring(i)
            Clone.ImageLabel.Image = "rbxassetid://"..flight.Id
            Clone.From.Text = flight.Destination
            Clone.Carousel.Text = self.Services.Game.Infrastructure.ConveyorService:SelectRandomConveyor(tostring(conveyor))
            Order += 1
            Clone.Visible = true
        end
    end
end


function BaggageArrivalScreenService:ClearEvent()
    for _,screen in pairs(SCREENS:GetChildren()) do
        for _,frame in pairs(screen.screen.Baggage.Background.Flights:GetChildren()) do
            if frame.Name ~= "F_1" and frame.Name ~= "F_2" and frame:IsA("Frame") then
                frame:Destroy()
            end
        end
    end
end


return BaggageArrivalScreenService