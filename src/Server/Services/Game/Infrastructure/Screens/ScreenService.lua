-- Screen Service
-- Jack_AviationRBX
-- June 24, 2024


local ScreenService = {Client = {}}


function ScreenService:Start()
    local Directory = self.Services.Game.Infrastructure.Screens.Types

    -- Monitor new flight info
    self.Services.Game.Core.FlightService:ConnectEvent("Flight", function(action, tbl)
        if action == "CurrentSet" or action == "CurrentUpdate" then
            Directory.ArrivalsScreenService:UpdateEvent(tbl)
            Directory.DepartureScreenService:UpdateEvent(tbl)
            Directory.InfoScreenService:UpdateEvent(tbl)
        elseif action == "CurrentRemoval" then
            Directory.ArrivalsScreenService:ClearEvent()
            Directory.DepartureScreenService:ClearEvent()
            Directory.InfoScreenService:ClearEvent()
        end
    end)

end


function ScreenService:GenerateRandomTime(minTimeInSeconds, incrementTimeMinsRange)

    function Format(Int)
        return string.format("%02i", Int)
    end

    local NewTimeInSeconds = minTimeInSeconds + math.random(1, incrementTimeMinsRange * 60)
	local Minutes = (NewTimeInSeconds - NewTimeInSeconds%60)/60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60

	return Format(Hours)..":"..Format(Minutes), NewTimeInSeconds
end


function ScreenService:GenerateRandomFlights(amount, minTime)
    local GhostFlightsList = self.Modules.GhostFlights
    local AmountSelected = 0
    local SelectedNumbers = {}
    
    while AmountSelected < amount and amount < #GhostFlightsList do
        local RandomDigit = math.random(1, #GhostFlightsList)

        if not table.find(SelectedNumbers, RandomDigit) then
            table.insert(SelectedNumbers, RandomDigit)
            AmountSelected += 1
        end
    end

    local SelectedFlights = {}
    local NewTimeInSeconds = minTime
    for _, index in pairs(SelectedNumbers) do
        if minTime then
            local newTimeFormat, timeSec = self:GenerateRandomTime(NewTimeInSeconds, 40)
            NewTimeInSeconds = timeSec
            GhostFlightsList[index]["TimeFormatted"] = newTimeFormat
        end
        table.insert(SelectedFlights, GhostFlightsList[index])
    end

    return SelectedFlights
end


function ScreenService:GetZeuraFlight()
    local Flight = self.Services.Game.Core.FlightService:GetCurrentFlight()
    if Flight then
        return {
            Airline = "Zeura",
            Callsign = Flight.FlightNumber,
            Destination = Flight.Airport,
            Id = "18218482569"
        }, Flight
    end
end


return ScreenService