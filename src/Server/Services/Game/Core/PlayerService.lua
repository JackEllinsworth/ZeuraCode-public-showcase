-- Player Service
-- Jack_AviationRBX
-- August 29, 2021

--[[

Player Service provides a way to manage the players data, as well as completing periodic auto-saving functions.
This service maintains all server-side apsects of a general players experience in the game, such as updating and modifying data when necessary.
Additionally, this is a completely necessary module for all systems to link together and work. This is because most modules require this module.

--]]


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


local PlayerService = {Client = {}}


function PlayerService:Start()
    self:SetProfileDefaults()
    self.Services.Game.Moderation.StaffLockService:Setup()

    -- Detect players
	Players.PlayerAdded:Connect(function(player)
        
        -- Check staff lock status
        if not RunService:IsStudio() and not self.Services.Game.Moderation.StaffLockService:IsAuthorised(player) and not self.Modules.Config.BetaOnlyAccess then
            return player:Kick("[StaffLockService] The game is currently locked, please try again another time!")
        end

        -- Load profile and profile-required services
        self.Services.Data.ProfileService:LoadAsync(player.UserId)
        self.Services.Data.ClassService:CalculateOwnedClasses(player)
        self.Services.Data.PermissionService:CalculatePermissions(player)

        -- Check beta status
        if not RunService:IsStudio() and self.Modules.Config.BetaOnlyAccess and not self.Services.Data.PermissionService:IsBeta(player.UserId) then
            if not self.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
                return player:Kick("This game is locked to beta only! Access is restricted.")
            end
        else
            warn("[PermissionService] "..player.Name.." ["..tostring(player.UserId).."] has beta access - granted entry.")
        end

        -- Handle infraction ban check
        local HasBanned = self:HandleBan(player)

        -- Handle game processes
        if not HasBanned then
            -- Initialize client GUI's and handlers
            self.Services.Game.Core.GuiService:LoadGUIs(player)

            -- Leaderboard & Team checks
            self.Services.Game.Core.LeaderboardService:SendUpdateSignal(player)
            self.Services.Game.Core.LeaderboardService:SetPlayerTeam(player, "Passenger")
            self.Services.Game.Staff.TeamService:AssignCheck(player)

            -- Issue Tools
            self:IssueTools(player)

            -- Mark as Loaded
            warn("[PlayerService] Fully loaded "..player.Name.."'s modules. Player Profile:",
            self.Services.Data.ProfileService:GetProfileAsync(player.UserId),
            "Classes:", self.Services.Data.CacheService:GetLocatorRows("ClassStore", player.UserId))
            self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Client Loaded!")

            -- Attach miles algorithm
            self.Services.Data.MilesService:AttachProfile(player)
        end

        player.CharacterAdded:Connect(function()
            self:IssueTools(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.Services.Data.MilesService:DetatchProfile(player)
        self.Services.Game.Core.LeaderboardService:RemovePlayer(player.UserId)
    end)
end


function PlayerService:IssueTools(player)
    self.Services.Game.Core.ToolService:ReobtainTools(player)
    self.Services.Data.SuitcaseService:GiveSuitcase(player)
    self.Services.Game.Core.ToolService:IssueTool(player, "Passport")
    self.Services.Data.ClassService:GiveClassToolIfBooked(player)
end


function PlayerService:SetProfileDefaults()
    local ProfileService = self.Services.Data.ProfileService
    ProfileService:SetAutomaticKeys({
        ["rankId"] = "group_rank",
        ["userId"] = "user_id"
    })

    ProfileService:SetSaveStores({"player", "moderation"})

    ProfileService:SaveOnServerClose(true)
    ProfileService:SaveOnPlayerLeave(true)

    ProfileService:SetStoreTypes({
        ["player"] = {
            ["userId"] = 0,
            ["permission"] = "normal",
            ["miles"] = 0,
            ["uniqueData"] = {},
            ["boughtClasses"] = {},
        },
        ["moderation"] = {
            ["infractions"] = {}
        },
        ["general"] = {
            ["rankId"] = 0
        }
    })
end


function PlayerService:HandleBan(player)
    -- Check ban status
    local Banned, Infraction = self.Services.Data.ModerationService:IsBanned(player.UserId)

    -- Evaluate and carry out ban
    if Banned then
		local TimeDateStr = ""
		
		if Infraction["duration"] == "perm" then
			TimeDateStr = "Permanent - Unlimited"
		else
			local TimeEnding = tonumber(Infraction["duration"]) + tonumber(Infraction["given"])
			TimeEnding = os.date("*t", TimeEnding)

			TimeDateStr = TimeEnding["day"].."/"..TimeEnding["month"].."/"..TimeEnding["year"].." - "..TimeEnding["hour"]..":"..TimeEnding["min"]..":"..TimeEnding["sec"]
		end
		
		player:Kick("[ModerationService] ->\nYou're currently banned from Zeura's games.\nTime/Date Ending: "..TimeDateStr.."\nReason: "..Infraction["reason"])
        return true
    end
end


return PlayerService