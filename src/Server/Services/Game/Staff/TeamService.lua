-- Team Service
-- Jack_AviationRBX
-- September 11, 2021

--[[

TeamService automatically links the flight attendence list and in-game players, or joining players.
When a player joins, and a flight is active, they are assigned to a team role automatically, similar to current game players.

--]]


local FlightRoles = {}
local FlightActive = false
local Players = game:GetService("Players")

local TeamService = {Client = {}}


function TeamService:Start()
    self:MonitorFlightChanges()
end


function TeamService:MonitorFlightChanges()
    self.Services.Game.Core.FlightService:ConnectEvent("Flight", function(_type, tbl)
        if _type == "CurrentSet" then
            if tbl["Roles"] then
                FlightActive = true
                self:UpdateAssignedRoles(tbl["Roles"])
            end
        elseif _type == "CurrentRemoval" then
            FlightActive = false
        end
    end)
end


function TeamService:AssignCheck(player)
    if FlightActive then
        if FlightRoles[player.Name] then
            self.Services.Game.Core.LeaderboardService:SetPlayerTeam(player, FlightRoles[player.Name])
            self.Services.Game.Staff.UniformService:IssueUniform(player, FlightRoles[player.Name])
            self.Services.Game.Core.ToolService:IssueTool(player, "Staff Access")
            self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Set Team: "..FlightRoles[player.Name])
        end
    end
end


function TeamService:UpdateAssignedRoles(roleTbl)
    FlightRoles = {}

    for i,v in pairs(roleTbl) do
        --// Go through roles
        local RoleName = i:gsub("(%l)(%u)", "%1 %2")
        if RoleName then
            --// Set each player in-game to that team.
            for _,username in pairs(v) do
                if not FlightRoles[username] then
                    FlightRoles[username] = RoleName

                    local User = Players:FindFirstChild(username)
                    if User then
                        self.Services.Game.Core.LeaderboardService:SetPlayerTeam(User, RoleName)
                        self.Services.Game.Staff.UniformService:IssueUniform(User, RoleName)
                        self.Services.Game.Core.ToolService:IssueTool(User, "Staff Access")
                        self.Services.Game.Core.AnnouncementService:IssueEventNotification(User, "Set Team: "..RoleName)
                    end
                end
            end
        end
    end
end


return TeamService