local DataStoreService = game:GetService("DataStoreService")
-- Leaderboard Service
-- Jack_AviationRBX
-- September 7, 2021

--[[

Leaderboard Service provides functions which can modify all clients leaderboard behaviour.
This is a very useful part of the core GUI and also supports teams.

--]]


local EVENT_LEADERBOARD = "Leaderboard"
local CurrentLeaderboard = {}
local HasSetup = false
local TeamOrder = {}

local RankChanges = {
    ["Group Holder"] = "CEO",
    ["Chief Executive Officer"] = "CEO",
    ["Chief Operations Officer"] = "COO",
    ["General Manager"] = "GM",
    ["Event Manager"] = "EM",
    ["Head of Department"] = "HoD",
    ["Development Team"] = "Dev",
    ["Airport Operations"] = "AO",
    ["Customer Liaison"] = "Liaison",
    ["First Officer"] = "FO",
    ["Lead Programmer"] = "DEV",
    ["Lead Developer"] = "DEV"
}

local PassengerTeam = "Passenger"

local LeaderboardService = {Client = {}}


function LeaderboardService:Start()
    self:Setup()
end


function LeaderboardService:Init()
    self:RegisterClientEvent(EVENT_LEADERBOARD)
end


function LeaderboardService:SendUpdateSignal(_type, data)
    if HasSetup then
        if _type == "PlayerRemoved" then
            self:FireAllClients(EVENT_LEADERBOARD, "Remove", data, TeamOrder)
        elseif _type == "PlayerAdded" then
            self:FireAllClients(EVENT_LEADERBOARD, "Add", data, TeamOrder)
        else
            self:FireClient(EVENT_LEADERBOARD, _type, false, CurrentLeaderboard, TeamOrder)
        end
    end
end


function LeaderboardService:Setup()
    -- Create Team
    local Teams = {}
    for _,teamName in ipairs(self.Modules.Config.Teams) do
        table.insert(Teams, teamName)
    end

    self:CreateTeams(Teams)

    -- Send update to all clients
    HasSetup = true
end


function LeaderboardService:SetPlayerTeam(player, teamName)
    self:RemovePlayer(player, true)

    local TeamType
    
    if teamName == PassengerTeam then
        TeamType = "Passenger"
    else
        TeamType = "Staff"
    end

    local Role = player:GetRoleInGroup(self.Modules.Config.GroupInfo.GroupId)

    if RankChanges[Role] then
        Role = RankChanges[Role]
        if Role == "CEO" then
            local LogisticsRole = player:GetRoleInGroup(self.Modules.Config.GroupInfo.LogisticsGroupId)
            Role = Role .. " | " .. RankChanges[LogisticsRole]
        end
    elseif not Role then
        Role = "N/A"
    end

    local data = {
        ["userId"] = player.UserId,
        ["username"] = player.Name,
        ["groupRole"] = Role,
        ["teamType"] = TeamType
    }

    table.insert(CurrentLeaderboard[teamName], data)

    self:SendUpdateSignal("PlayerAdded", data)
end


function LeaderboardService:GetPlayerTeam(player)
    for i,v in pairs(CurrentLeaderboard) do
        for _, b in ipairs(v) do
            if b["userId"] == player.UserId then
                return i
            end
        end
    end
end


function LeaderboardService:RemovePlayer(userId, silent)
    for _,v in pairs(CurrentLeaderboard) do
        for index,b in ipairs(v) do
            if b["userId"] == userId then
                table.remove(v, index)
    
                if not silent then
                    self:SendUpdateSignal("PlayerRemoved", {["userId"] = userId})
                end
            end
        end
    end
end

function LeaderboardService:CreateTeams(teamNames)
    for _,v in ipairs(teamNames) do
        CurrentLeaderboard[v] = {}
        table.insert(TeamOrder, v)
    end
end


return LeaderboardService