-- Miles Service
-- Jack_AviationRBX
-- August 7, 2023

--[[

This service grants miles to profiles running on the server. 
This is used as a currency to gain access to some exclusive purchases.

--]]

local EVENT_MILES = "Miles"
local BASE_MILES_PER_FLIGHT = 200
local FLIGHT_DURATION_MINS = 100
local AUTO_SAVE = true
local SAVES_PER_MINUTE = 10
local COOLDOWN_MULTIPLIER = 3

local UsersMonitoring = {}
local SavingQueue = {}
local PlayersLeftBreak = {}

local MilesPerMinute = BASE_MILES_PER_FLIGHT / FLIGHT_DURATION_MINS
local MilesIntervalMinutes = 1 -- Adds miles to account every _ minutes.
local SavingIntervalMinutes = 10 -- Adds user to saving queue each _ minutes (Auto-save)


local MilesService = {Client = {}}


function MilesService:Init()
    self:RegisterClientEvent(EVENT_MILES)
end


function MilesService:Start()
    self:MonitorAutoSaving()
end


function MilesService:MonitorAutoSaving()
    local TimePerSave = 60 / SAVES_PER_MINUTE

    warn("[MilesService] Saving rate: 1 profile per "..tostring(TimePerSave).. "s in save queue. Save queue entry per " .. tostring(SavingIntervalMinutes).. "m")

    while AUTO_SAVE do
        task.wait(TimePerSave * COOLDOWN_MULTIPLIER)

        for _, userId in ipairs(SavingQueue) do
            local Success = self.Services.Data.ProfileService:Save(userId)

            if Success then
                table.remove(SavingQueue, 1)
            end

            task.wait(TimePerSave)
        end

    end
end


function MilesService:AddToSaveQueue(userId)
    local Break = false
    for _,v in ipairs(SavingQueue) do
        if v == userId then
            Break = true
            break
        end
    end

    if not Break then
        SavingQueue[#SavingQueue+1] = userId
    end
end


function MilesService:GetMultiplier(player, permissionName)
    local PermissionMultiplier = self.Modules.Config.Permissions[permissionName].milesMultiplier
    local HighestPermClass = self.Services.Data.ClassService:GetHighestPermClass(player)
    local HighestPermClassMultiplier = 1
    if HighestPermClassMultiplier and self.Modules.Config.Classes[HighestPermClass] then
        HighestPermClassMultiplier = self.Modules.Config.Classes[HighestPermClass].milesMultiplier
    end

    if PermissionMultiplier >= HighestPermClassMultiplier then
        return PermissionMultiplier
    else
        return HighestPermClassMultiplier
    end
end


function MilesService:UpdateClient(player)
    self:FireClient(EVENT_MILES, player, self.Services.Data.ProfileService:GetAsync(player.UserId, "miles"))
end


function MilesService:AttachProfile(player)

    self:FireClient(EVENT_MILES, player, self.Services.Data.ProfileService:GetAsync(player.UserId, "miles"))

    while PlayersLeftBreak[player.UserId] do
        task.wait((MilesIntervalMinutes * 60) + 1) 
    end

    local UserPermissionName = self.Services.Data.PermissionService:FetchPlayersPermissionName(player)

    -- Return if user is already getting miles
    if UsersMonitoring[player.UserId] then
        return
    else
        UsersMonitoring[player.UserId] = true
    end

    local MinutesProcessed = 0

    while player and UsersMonitoring[player.UserId] do
        task.wait(MilesIntervalMinutes * 60)

        if PlayersLeftBreak[player.UserId] then
            PlayersLeftBreak[player.UserId] = false
            break
        end

        if not player or not UsersMonitoring[player.UserId] then
            break
        end

        local Multiplier = self:GetMultiplier(player, UserPermissionName)
        local MilesToGive = math.round(((MilesPerMinute * MilesIntervalMinutes) * Multiplier)*10)/10

        self.Services.Data.ProfileService:IncrementAsync(player.UserId, "miles", MilesToGive)

        self:UpdateClient(player)
        
        MinutesProcessed += MilesIntervalMinutes
    
        if MinutesProcessed >= SavingIntervalMinutes then
            MinutesProcessed = 0
            self:AddToSaveQueue(player.UserId)
        end

    end
end


function MilesService:DetatchProfile(userId)
    if UsersMonitoring[userId] then
        PlayersLeftBreak[userId] = true
        UsersMonitoring[userId] = nil
    end
end

	
return MilesService