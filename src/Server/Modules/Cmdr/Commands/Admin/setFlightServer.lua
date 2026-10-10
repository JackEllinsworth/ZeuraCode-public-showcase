return function (context, flightNumber)
    local Aero = _G.Aero
    local Success = Aero.Services.Game.Core.FlightService:SetCurrentFlight(flightNumber)
    
    if Success then
        context:Reply("Successfully activated flight "..flightNumber)
    else
        context:Reply("Error - does the flight exist?")
    end
end