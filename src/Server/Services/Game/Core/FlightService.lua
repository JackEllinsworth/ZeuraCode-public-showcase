-- Flight Service
-- Jack_AviationRBX
-- August 8, 2021

--[[

FlightService allows you to manage and maintain current flights in the game.
It also allows you to modify class bookings via various ways, to ensure everything links together properly.
Event objects are also created to ensure server-server communication is used, for updating infrastructure around the airport.

--]]


local STORE_NAME = "FlightStore"
local MODIFICATION_PERMISSION = "Admin"
local EVENT_FLIGHT = "Flight"


local FlightService = {Client = {}}


function FlightService:Start()

	-- Create Cache Store
    self.Services.Data.CacheService.createStore(STORE_NAME, {
        ["RowSettings"] = {
            ["FlightNumber"] = "",
            ["Status"] = "",
            ["Host"] = "",
            ["Date"] = "",
            ["Time"] = "",
            ["Airport"] = "",
            ["Aircraft"] = "",
            ["Gate"] = "",
            ["Destination"] = "",
            ["DestinationCode"] = "",
            ["BoardingTime"] = "",
            ["DepartureTime"] = "",
            ["ArrivalTime"] = "",
            ["Roles"] = {},
            ["_classesBooked"] = {}
        },
        ["ListenerActive"] = false
    })

    -- Parse external flights into cache
    local Flights = self.Services.Data.DataService.get("flight_data", "retrieve", {})
    if Flights then
        for _,flight in pairs(Flights) do
            self:CreateFlight(flight)
        end
    end
end


function FlightService:Init()
    self:RegisterEvent(EVENT_FLIGHT)
end


function FlightService:GetCurrentFlightClasses()
    local Current = self.Services.Data.CacheService:GetRow(STORE_NAME, "_currentFlight", "_classesBooked")
    if Current then
        local ClassNames = {}
        for className,_ in pairs(Current) do
            if self:GetClassBookingsAvailable(className) >= 1 then
                table.insert(ClassNames, className)
            end
        end
        return ClassNames
    else
        return {}
    end
end


function FlightService:ModifyClassBookings(className, amount)
    local Current = self.Services.Data.CacheService:GetRow(STORE_NAME, "_currentFlight", "_classesBooked")
    if Current then
        if not Current[className] then
            Current[className] = 0
        end
        Current[className] = Current[className] + amount
        self.Services.Data.CacheService:ReplaceRow(STORE_NAME, "_currentFlight", "_classesBooked", Current)
    end
end


function FlightService:GetClassBookingsAvailable(className)
    local Current = self.Services.Data.CacheService:GetRow(STORE_NAME, "_currentFlight", "_classesBooked")

    if Current then
        return Current[className]
    end
end


function FlightService:GetCurrentFlight()
    return self.Services.Data.CacheService:GetLocatorRows(STORE_NAME, "_currentFlight")
end


function FlightService:GetAllFlights()
    local Flights = self.Shared.TableUtil.Copy(self.Services.Data.CacheService:GetAllLocators(STORE_NAME))
    if Flights["_currentFlight"] then
        Flights["_currentFlight"] = nil
    end
    Flights["defaults"] = nil
    return Flights
end


function FlightService:SetCurrentFlight(flightNumber)
    if flightNumber then
        local FlightData = self.Services.Data.CacheService:GetLocatorRows(STORE_NAME, flightNumber)

        if FlightData then
            self.Services.Data.CacheService:CreateLocator(STORE_NAME, "_currentFlight")

            for key,value in pairs(FlightData) do
                self.Services.Data.CacheService:ReplaceRow(STORE_NAME, "_currentFlight", key, value)
            end

            self.Services.Game.Core.FlightService:Fire(EVENT_FLIGHT, "CurrentSet", FlightData)
            return true
        end
    else
        -- Reset current flight, set data as nil
        local FlightData = self.Services.Data.CacheService:GetLocatorRows(STORE_NAME, "_currentFlight")

        self.Services.Data.CacheService:CreateLocator(STORE_NAME, "_currentFlight")
        self.Services.Game.Core.FlightService:Fire(EVENT_FLIGHT, "CurrentRemoval", FlightData)
    end
end


function FlightService:UpdateCurrentFlight(tbl)
    if self.Services.Data.CacheService:LocatorExists(STORE_NAME, "_currentFlight") then
        for key,value in pairs(tbl) do
            self.Services.Data.CacheService:ReplaceRow(STORE_NAME, "_currentFlight", key, value)
        end
        self.Services.Game.Core.FlightService:Fire(EVENT_FLIGHT, "CurrentUpdate", self.Services.Data.CacheService:GetLocatorRows(STORE_NAME, "_currentFlight"))
        return true
    end
end


function FlightService:CreateFlight(tbl)
    local Aircraft = tbl["Aircraft"]
    if not self.Services.Data.CacheService:LocatorExists(STORE_NAME, tbl["FlightNumber"]) then
        if self.Modules.Config.Aircrafts[Aircraft] then
            local ClassesBooked = self.Modules.Config.Aircrafts[Aircraft].Classes

            self.Services.Data.CacheService:CreateLocator(STORE_NAME, tbl["FlightNumber"])
            self.Services.Data.CacheService:ReplaceRow(STORE_NAME, tbl["FlightNumber"], "_classesBooked", ClassesBooked)
    
            for key,value in pairs(tbl) do
                self.Services.Data.CacheService:ReplaceRow(STORE_NAME, tbl["FlightNumber"], key, value)
            end

            self.Services.Game.Core.FlightService:Fire(EVENT_FLIGHT, "Creation", tbl)
        end
    end
end


return FlightService