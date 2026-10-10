-- StaffLockService Service
-- Jack_AviationRBX
-- July 19, 2022

--[[

Manages authorised access within the game.

--]]


local STAFF_MODE_NAME = "Staff"
local EVENT_STAFFLOCK = "StaffLock"


local CurrentLevelAllowence = 1 
local IsolatedAllowenceList = {}


local StaffLockService = {Client = {}}


function StaffLockService:Init()
    self:RegisterEvent(EVENT_STAFFLOCK)
end


function StaffLockService:Setup()
    CurrentLevelAllowence = self.Modules.Config.StaffLock.Modes[self.Modules.Config.StaffLock.DefaultMode].level
    warn("[StaffLockService] Initiated default settings.")
end


function StaffLockService:SetMode(level_name)
    if self.Modules.Config.StaffLock.Modes[level_name] then
        CurrentLevelAllowence = self.Modules.Config.StaffLock.Modes[level_name].level
        self:Fire(EVENT_STAFFLOCK, level_name)
    end
end


function StaffLockService:ShutdownServer()
    for _,v in pairs(game:GetService("Players"):GetChildren()) do
        v:Kick("The server has now closed. Thank you for attending, and we hope to see you again soon!")
    end
end


function StaffLockService.Client:GetCurrentMode(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        for name, tbl in pairs(self.Server.Modules.Config.StaffLock.Modes) do
            if tbl.level == CurrentLevelAllowence then
                return name
            end
        end
    end
end


function StaffLockService:KickNonStaff()
    for _,v in pairs(game:GetService("Players"):GetChildren()) do
        if not self.Services.Data.PermissionService:HasPermission(v.UserId, STAFF_MODE_NAME) then
            v:Kick("The server has now closed. Thank you for attending, and we hope to see you again soon!")
        end
    end
end


function StaffLockService:IsAuthorised(player)
    if IsolatedAllowenceList[player.UserId] then
        return true
    end

    local GroupRank = player:GetRankInGroup(self.Modules.Config.GroupInfo.GroupId)
    local CurrentPermissionLevel = 1

    for _,tbl in pairs(self.Modules.Config.StaffLock.Modes) do
        local GroupBounds = tbl.groupBounds
        
        for _,v in ipairs(GroupBounds) do
            local LowerBound = v[1]
            local UpperBound = v[2]
            
            if GroupRank >= LowerBound and GroupRank <= UpperBound then
                if tbl.level > CurrentPermissionLevel then
                    CurrentPermissionLevel = tbl.level
                end
            end
        end
    end

    if CurrentPermissionLevel >= CurrentLevelAllowence then
        warn("[StaffLockService] Granted " .. player.Name .. " [" .. tostring(player.UserId) .. "] to the server. Server level: " .. tostring(CurrentPermissionLevel))
        return true
    else
        return false
    end

end


return StaffLockService