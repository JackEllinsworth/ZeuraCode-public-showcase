-- Departure Screen Service
-- Jack_AviationRBX
-- June 24, 2024


local SCREENS = game.Workspace.Infrastructure.Screens:FindFirstChild("DepartureScreens")
local RemarkTable = {
    [1] = {
        Name = "FINAL CALL",
        Colour = Color3.fromRGB(255, 124, 123)
    },
    [2] = {
        Name = "Boarding",
        Colour = Color3.fromRGB(112, 228, 112)
    },
    [3] = {
        Name = "DELAYED",
        Colour = Color3.fromRGB(255, 255, 112)
    },
    [4] = {
        Name = "CANCELLED",
        Colour = Color3.fromRGB(255, 124, 123)
    },
    [5] = {
        Name = "Gate Announced",
        Colour = Color3.fromRGB(255, 255, 255)
    }
}

local DepartureScreenService = {}


function DepartureScreenService:UpdateEvent()

    self:ClearEvent()
    
    local ZeuraFlight, Data = self.Services.Game.Infrastructure.Screens.ScreenService:GetZeuraFlight()
    local TimeInSeconds
    local SplitTime
    if Data.DepartureTime ~= nil and Data.DepartureTime ~= "" then
        SplitTime = string.split(Data.DepartureTime, " ")[1]
        local HoursMinsTable = string.split(SplitTime, ":")
        TimeInSeconds = (tonumber(HoursMinsTable[1]) * 3600) + (tonumber(HoursMinsTable[2]) * 60)
    else
        TimeInSeconds = 0
        SplitTime = "00:00"
    end

    local RandomFlights = self.Services.Game.Infrastructure.Screens.ScreenService:GenerateRandomFlights(20, TimeInSeconds)

    for _,screen in pairs(SCREENS:GetChildren()) do
        local ColourSwitch = false
        local Order = 1
        if screen.Name == "Primary" or screen.Name == "Primary_Horizontal" then
            local Template = screen.screen.Departures.Background.Flights.F_1
            local Clone = Template:Clone()
            Clone.Parent = Template.Parent
            Clone.LayoutOrder = Order
            Clone.Airport.Text = Data.Destination
            Clone.Time.Text = SplitTime
            Clone.Gate.Text = Data.Gate
            Clone.ImageLabel.Image = "rbxassetid://"..ZeuraFlight.Id

            if screen.Name == "Primary_Horizontal" then
                local found = false
                for _,v in pairs(RemarkTable) do
                    if string.lower(v.Name) == string.lower(Data.Status) then
                        Clone.Remark.Text = v.Name
                        Clone.Remark.TextColor3 = v.Colour
                        found = true
                        break
                    end
                end

                if not found then
                    Clone.Remark.Text = Data.Status
                    Clone.Remark.TextColor3 = Color3.new(255, 255, 255)
                end

                Clone.Flight.Text = Data.FlightNumber
            end

            Clone.Visible = true
            Order += 1
            ColourSwitch = true
            Clone.Name = "0"

            for i = 1, 10 do
                local flight = RandomFlights[i]
                local Template
                if not ColourSwitch then
                    Template = screen.screen.Departures.Background.Flights.F_1
                    ColourSwitch = true
                else
                    Template = screen.screen.Departures.Background.Flights.F_2
                    ColourSwitch = false
                end
                local Clone = Template:Clone()
                Clone.Parent = Template.Parent
                Clone.LayoutOrder = Order
                Clone.Name = tostring(i)
                Clone.Airport.Text = flight.Destination
                Clone.ImageLabel.Image = "rbxassetid://"..flight.Id
                Clone.Time.Text = flight.TimeFormatted

                if screen.Name == "Primary_Horizontal" then
                    local Remark = self:GenerateRandomRemark()
                    Clone.Remark.Text = Remark.Name
                    Clone.Remark.TextColor3 = Remark.Colour
                    Clone.Flight.Text = flight.Callsign
                end
                
                Clone.Gate.Text = self.Services.Game.Infrastructure.ConveyorService:SelectRandomConveyor(tostring(Data.Gate))
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
                    Template = screen.screen.Departures.Background.Flights.F_1
                    ColourSwitch = true
                else
                    Template = screen.screen.Departures.Background.Flights.F_2
                    ColourSwitch = false
                end
                local Clone = Template:Clone()
                Clone.Parent = Template.Parent
                Clone.LayoutOrder = Order
                Clone.Name = tostring(i)
                Clone.Airport.Text = flight.Destination
                Clone.ImageLabel.Image = "rbxassetid://"..flight.Id
                Clone.Time.Text = flight.TimeFormatted
                Clone.Gate.Text = self.Services.Game.Infrastructure.ConveyorService:SelectRandomConveyor(tostring(Data.Gate))
                Order += 1
                Clone.Visible = true
            end
        end
    end
end


function DepartureScreenService:ClearEvent()
    for _,screen in pairs(SCREENS:GetChildren()) do
        for _,frame in pairs(screen.screen.Departures.Background.Flights:GetChildren()) do
            if frame.Name ~= "F_1" and frame.Name ~= "F_2" and frame:IsA("Frame") then
                frame:Destroy()
            end
        end
    end
end


function DepartureScreenService:GenerateRandomRemark()
    return RemarkTable[math.random(1, #RemarkTable)]
end


return DepartureScreenService