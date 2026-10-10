-- Arrivals Screen Service
-- Jack_AviationRBX
-- June 24, 2024

local SCREENS = game.Workspace.Infrastructure.Screens:FindFirstChild("Arrivals")

local ArrivalsScreenService = {}


function ArrivalsScreenService:UpdateEvent()

    self:ClearEvent()
    
    local ZeuraFlight, Data = self.Services.Game.Infrastructure.Screens.ScreenService:GetZeuraFlight()
    local TimeInSeconds
    if Data.ArrivalTime ~= nil and Data.ArrivalTime ~= "" then
        local SplitTime = string.split(Data.ArrivalTime, " ")[1]
        local HoursMinsTable = string.split(SplitTime, ":")
        TimeInSeconds = (tonumber(HoursMinsTable[1]) * 3600) + (tonumber(HoursMinsTable[2]) * 60)
    else
        TimeInSeconds = 0
    end

    local RandomFlights = self.Services.Game.Infrastructure.Screens.ScreenService:GenerateRandomFlights(20, TimeInSeconds)

    for _,screen in pairs(SCREENS:GetChildren()) do
        local ColourSwitch = false
        local Order = 1
        if screen.Name == "Primary" then
            local Template = screen.screen.Arrival.Background.Flights.F_1
            local Clone = Template:Clone()
            Clone.Parent = Template.Parent
            Clone.LayoutOrder = Order
            Clone.Airport.Text = Data["Airport"]
            Clone.Time.Text = Data.ArrivalTime
            Clone.ImageLabel.Image = "rbxassetid://"..ZeuraFlight.Id
            Clone.Visible = true
            Order += 1
            ColourSwitch = true
            Clone.Name = "0"

            for i = 1, 10 do
                local flight = RandomFlights[i]
                local Template
                if not ColourSwitch then
                    Template = screen.screen.Arrival.Background.Flights.F_1
                    ColourSwitch = true
                else
                    Template = screen.screen.Arrival.Background.Flights.F_2
                    ColourSwitch = false
                end
                local Clone = Template:Clone()
                Clone.Parent = Template.Parent
                Clone.LayoutOrder = Order
                Clone.Name = tostring(i)
                Clone.Airport.Text = flight.Destination
                Clone.ImageLabel.Image = "rbxassetid://"..flight.Id
                Clone.Time.Text = flight.TimeFormatted
                Order += 1
                Clone.Visible = true

                if i == 10 then
                    break;
                end
            end
        elseif screen.Name == "Secondary" then
            for i = 11, 20 do
                local flight = RandomFlights[i]
                local Template
                if not ColourSwitch then
                    Template = screen.screen.Arrival.Background.Flights.F_1
                    ColourSwitch = true
                else
                    Template = screen.screen.Arrival.Background.Flights.F_2
                    ColourSwitch = false
                end
                local Clone = Template:Clone()
                Clone.Parent = Template.Parent
                Clone.LayoutOrder = Order
                Clone.Name = tostring(i)
                Clone.Airport.Text = flight.Destination
                Clone.ImageLabel.Image = "rbxassetid://"..flight.Id
                Clone.Time.Text = flight.TimeFormatted
                Order += 1
                Clone.Visible = true
            end
        end
    end
end


function ArrivalsScreenService:ClearEvent()
    for _,screen in pairs(SCREENS:GetChildren()) do
        for _,frame in pairs(screen.screen.Arrival.Background.Flights:GetChildren()) do
            if frame.Name ~= "F_1" and frame.Name ~= "F_2" and frame:IsA("Frame") then
                frame:Destroy()
            end
        end
    end
end


return ArrivalsScreenService