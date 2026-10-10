-- Audio Announcement Service
-- Jack_AviationRBX
-- August 6, 2023

local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")


local AUDIO = game.Workspace.Infrastructure.Audio
local EVENT_AUDIO_ANNOUNCEMENTS = "AudioAnnouncement"
local AUDIO_INSTANCES = {
    ["Boarding"] = {
        ID = 13893914362,
        Timestamps = {
            ["Start"] = {0, 8.3},
            ["Numbers"] = {
                ["0"] = {8.4, 9.9},
                ["1"] = {10, 10.67},
                ["2"] = {10.8, 11.6},
                ["3"] = {11.65, 12.5},
                ["4"] = {12.65, 13.55},
                ["5"] = {14, 14.71},
                ["6"] = {14.72, 15.6},
                ["7"] = {16.1, 16.85},
                ["8"] = {16.95, 17.78},
                ["9"] = {17.9, 18.6}
            },
            ["To"] = {18.65, 19.8},
            ["Destination"] = {
                ["Barcelona"] = {20, 21},
                ["Newcastle"] = {21, 22.9},
                ["Nice"] = {23, 23.8},
                ["Rhodes"] = {24, 24.93},
            },
            ["IsNowBoarding"] = {25, 27.7},
            ["Classes"] = {
                ["Executive"] = {27.7, 28.9},
                ["Premium"] = {29.5, 30.9},
                ["Standard+"] = {31, 32.1},
                ["Standard"] = {33, 33.88}
            },
            ["TicketHolders"] = {34, 38.9},
            ["ForBoarding"] = {39, 43.7}
        }
    },
    ["Cruising"] = {
        ID = 13893913895
    },
    ["Emergency"] = {
        ID = 13893913605
    },
    ["Final Boarding"] = {
        ID = 13893913189,
        Timestamps = {
            ["Start"] = {0, 9.5},
            ["Numbers"] = {
                ["0"] = {9.6, 11.2},
                ["1"] = {11.2, 11.87},
                ["2"] = {11.87, 12.8},
                ["3"] = {12.8, 13.7},
                ["4"] = {13.7, 14.75},
                ["5"] = {14.75, 15.91},
                ["6"] = {15.91, 16.8},
                ["7"] = {16.8, 18},
                ["8"] = {18.05, 18.98},
                ["9"] = {18.98, 19.8}
            },
            ["To"] = {19.8, 20.8},
            ["Destination"] = {
                ["Barcelona"] = {21, 22},
                ["Newcastle"] = {22, 23.9},
                ["Nice"] = {24, 24.8},
                ["Rhodes"] = {25, 26},
            },
            ["PleaseMayRemainingPassengers"] = {26.5, 30.7},
            ["ForBoarding"] = {31, 37.7}
        }
    },
    ["Landing"] = {
        ID = 13893912899
    },
    ["Server Locking"] = {
        ID = 13893912725
    },
    ["Server Locked"] = {
        ID = 13893912474
    },
    ["Pre-Boarding"] = {
        ID = 13893912191,
        Timestamps = {
            ["Start"] = {0, 8.6},
            ["Numbers"] = {
                ["0"] = {8.7, 10},
                ["1"] = {10.1, 10.77},
                ["2"] = {10.9, 11.7},
                ["3"] = {11.75, 12.6},
                ["4"] = {12.75, 13.65},
                ["5"] = {14.1, 14.81},
                ["6"] = {14.82, 15.7},
                ["7"] = {16.1, 17.88},
                ["8"] = {18, 17.78},
                ["9"] = {17.9, 18.7}
            },
            ["To"] = {18.7, 19.7},
            ["Destination"] = {
                ["Barcelona"] = {19.9, 20.9},
                ["Newcastle"] = {21, 22.9},
                ["Nice"] = {23, 23.8},
                ["Rhodes"] = {24, 25},
            },
            ["ShortlyBoardAtGate"] = {25, 29.1},
            ["FollowOn"] = {29, 41.8}
        }
    },
    ["Safety Audio"] = {
        ID = 13893911004,
        ["Timestamps"] = {
            ["Start"] = {0, 12.379},
            ["AircraftTitle"] = {
                ["737 Max 8"] = {13, 16.637},
                ["737-800"] = {17, 20.637},
                ["777-300ER"] = {21, 24.637},
                ["787 Dreamliner"] = {25, 26.637},
                ["A220-300"] = {29, 32.637},
                ["A320"] = {33, 36.637},
                ["A321"] = {37, 40.637},
                ["A330"] = {41, 44.637},
                ["A350-1000"] = {45, 48.637}
            },
            ["HeadphoneRemoval"] = {49, 53},
            ["AircraftExits"] = {
                ["737 Max 8"] = {71, 88.741},
                ["737-800"] = {71, 88.741},
                ["777-300ER"] = {89, 106.741},
                ["787 Dreamliner"] = {125, 142.741},
                ["A220-300"] = {53, 70.741},
                ["A320"] = {71, 88.741},
                ["A321"] = {107, 124.741},
                ["A330"] = {125, 142.741},
                ["A350-1000"] = {125, 142.741}
            },
            ["Ending"] = {143, 307}
        }
    },
    ["Arrival"] = {
        ID = 13893879404,
        ["Timestamps"] = {
            ["Start"] = {0, 15.63},
            ["Destination"] = {
                ["Barcelona"] = {15.64, 17.3},
                ["Newcastle"] = {17.5, 18.9},
                ["Nice"] = {19, 20.05},
                ["Rhodes"] = {20.1, 21.1},
            },
            ["TheLocalTimeIsCurrently"] = {22, 24},
            ["Numbers"] = {
                ["0"] = {24, 25},
                ["1"] = {25, 26},
                ["2"] = {26, 26.65},
                ["3"] = {27, 27.81},
                ["4"] = {28, 28.833},
                ["5"] = {29, 29.95},
                ["6"] = {30, 30.967},
                ["7"] = {31, 32},
                ["8"] = {32, 33},
                ["9"] = {33, 33.65},
                ["10"] = {34, 35},
                ["11"] = {35, 36},
                ["12"] = {36, 37}
            },
            ["AM"] = {37, 38},
            ["PM"] = {38, 39.25},
            ["RemainSeated"] = {40, 60.5}

        }
    },
}


local AudioAnnouncementService = {Client = {}}


function AudioAnnouncementService:Init()
    self:RegisterClientEvent(EVENT_AUDIO_ANNOUNCEMENTS)
end


function AudioAnnouncementService:Start()
    local AssetsToLoad = {}
    for name, tbl in pairs(AUDIO_INSTANCES) do
        local AudioInstance = Instance.new("Sound", AUDIO)
        AudioInstance.Name = name
        AudioInstance.SoundId = "rbxassetid://" .. tostring(tbl.ID)
        table.insert(AssetsToLoad, AudioInstance)
    end
  
    local startTime = os.clock()
    ContentProvider:PreloadAsync(AssetsToLoad)
    local deltaTime = os.clock() - startTime

    warn(("[AudioAnnouncementService] Preloading complete took %.2f seconds"):format(deltaTime))
end


function AudioAnnouncementService:ParseTimestamps(AudioName, config)
    local Timestamps = {}

    local function getNumbersFromString(stringOption)
        local Numbers = string.gsub(stringOption, "%D", "")
        return Numbers
    end

    local FlightData = self.Services.Game.Core.FlightService:GetCurrentFlight()

    if not FlightData then
        return {}
    end

    if AudioName == "Boarding" then
        local Boarding = AUDIO_INSTANCES["Boarding"].Timestamps
        Timestamps[#Timestamps+1] = Boarding["Start"]
    
        for number in (getNumbersFromString(FlightData["FlightNumber"])):gmatch(".") do
            Timestamps[#Timestamps+1] = Boarding["Numbers"][number]
        end

        Timestamps[#Timestamps+1] = Boarding["To"]

        for dest, timestamp in pairs(Boarding["Destination"]) do
            if string.lower(FlightData["Destination"]) == string.lower(dest) then
                Timestamps[#Timestamps+1] = timestamp
                break
            end
        end

        Timestamps[#Timestamps+1] = Boarding["IsNowBoarding"]

        if config["BoardingClass"] then
            Timestamps[#Timestamps+1] = Boarding["Classes"][config["BoardingClass"]]
        end

        Timestamps[#Timestamps+1] = Boarding["TicketHolders"]

        for number in (getNumbersFromString(FlightData["Gate"])):gmatch(".") do
            Timestamps[#Timestamps+1] = Boarding["Numbers"][number]
        end

        Timestamps[#Timestamps+1] = Boarding["ForBoarding"]

    elseif AudioName == "Final Boarding" then
        local FinalBoarding = AUDIO_INSTANCES["Final Boarding"].Timestamps
        Timestamps[#Timestamps+1] = FinalBoarding["Start"]

        for number in (getNumbersFromString(FlightData["FlightNumber"])):gmatch(".") do
            Timestamps[#Timestamps+1] = FinalBoarding["Numbers"][number]
        end

        Timestamps[#Timestamps+1] = FinalBoarding["To"]

        for dest, timestamp in pairs(FinalBoarding["Destination"]) do
            if string.lower(FlightData["Destination"]) == string.lower(dest) then
                Timestamps[#Timestamps+1] = timestamp
                break
            end
        end

        Timestamps[#Timestamps+1] = FinalBoarding["PleaseMayRemainingPassengers"]

        for number in (getNumbersFromString(FlightData["Gate"])):gmatch(".") do
            Timestamps[#Timestamps+1] = FinalBoarding["Numbers"][number]
        end

        Timestamps[#Timestamps+1] = FinalBoarding["ForBoarding"]
    elseif AudioName == "Pre-Boarding" then
        local Preboarding = AUDIO_INSTANCES["Pre-Boarding"].Timestamps
        Timestamps[#Timestamps+1] = Preboarding["Start"]
    
        for number in (getNumbersFromString(FlightData["FlightNumber"])):gmatch(".") do
            Timestamps[#Timestamps+1] = Preboarding["Numbers"][number]
        end

        Timestamps[#Timestamps+1] = Preboarding["To"]

        for dest, timestamp in pairs(Preboarding["Destination"]) do
            if string.lower(FlightData["Destination"]) == string.lower(dest) then
                Timestamps[#Timestamps+1] = timestamp
                break
            end
        end

        Timestamps[#Timestamps+1] = Preboarding["ShortlyBoardAtGate"]

        for number in (getNumbersFromString(FlightData["Gate"])):gmatch(".") do
            Timestamps[#Timestamps+1] = Preboarding["Numbers"][number]
        end

        Timestamps[#Timestamps+1] = Preboarding["FollowOn"]
    elseif AudioName == "Safety Audio" then
        local SafetyAudio = AUDIO_INSTANCES["Safety Audio"].Timestamps
        Timestamps[#Timestamps+1] = SafetyAudio["Start"]

        if SafetyAudio["AircraftTitle"][FlightData["Aircraft"]] then
            Timestamps[#Timestamps+1] = SafetyAudio["AircraftTitle"][FlightData["Aircraft"]]
        end

        Timestamps[#Timestamps+1] = SafetyAudio["HeadphoneRemoval"]

        if SafetyAudio["AircraftTitle"][FlightData["Aircraft"]] then
            Timestamps[#Timestamps+1] = SafetyAudio["AircraftExits"][FlightData["Aircraft"]]
        end

        Timestamps[#Timestamps+1] = SafetyAudio["Ending"]
    elseif AudioName == "Arrival" then
        local Arrival = AUDIO_INSTANCES["Arrival"].Timestamps
        Timestamps[#Timestamps+1] = Arrival["Start"]

        for dest, timestamp in pairs(Arrival["Destination"]) do
            if string.lower(FlightData["Destination"]) == string.lower(dest) then
                Timestamps[#Timestamps+1] = timestamp
                break
            end
        end

        Timestamps[#Timestamps+1] = Arrival["TheLocalTimeIsCurrently"]

        local TimeSelected = tostring(config["Time"])
        if Arrival["Numbers"][TimeSelected] then
            Timestamps[#Timestamps+1] = Arrival["Numbers"][TimeSelected]
        end

        if Arrival[config["AM_PM"]] then
            Timestamps[#Timestamps+1] = Arrival[config["AM_PM"]]
        end

        Timestamps[#Timestamps+1] = Arrival["RemainSeated"]
    end

    return Timestamps
end


function AudioAnnouncementService:PlayAudio(AudioName, config)
    local MusicInstance = AUDIO[AudioName]

    if not MusicInstance.Loaded then
        MusicInstance.Loaded:Wait()
    end

    MusicInstance.TimePosition = 0
    MusicInstance.Volume = 0
    MusicInstance:Play()

    local Tween = TweenService:Create(MusicInstance,TweenInfo.new(1),{Volume = 1})
    Tween:Play()

    self.Services.Game.Auditory.MusicService:Pause()

    if AUDIO_INSTANCES[AudioName]["Timestamps"] then
        local ParsedTimestamps = self:ParseTimestamps(AudioName, config)
    
        if #ParsedTimestamps == 0 then
            
            return MusicInstance:Pause()
        end

        local Tween = TweenService:Create(MusicInstance,TweenInfo.new(1),{Volume = 1})
        Tween:Play()

        local Index = 1

        local function monitorNextTimestamp()
            local Timestamp = ParsedTimestamps[Index]

            MusicInstance.TimePosition = Timestamp[1]

            while MusicInstance.TimePosition <= Timestamp[2] do
                task.wait(0.01)
            end

            Index += 1

            if ParsedTimestamps[Index] then
                monitorNextTimestamp()
            end
        end

        monitorNextTimestamp()
        self.Services.Game.Auditory.MusicService:Resume()
    else
        MusicInstance.Ended:Wait()
        self.Services.Game.Auditory.MusicService:Resume()
    end

end


return AudioAnnouncementService