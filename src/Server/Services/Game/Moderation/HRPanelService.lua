-- HR Panel Service
-- Jack_AviationRBX
-- July 20, 2022


local EVENT_NAME = "HRUpdate"
local RainConfiguration = {
    ["enabled"] = false,
    ["Intensity"] = "",
    ["LightEmission"] = "",
    ["LightInfluence"] = "",
    ["Speed"] = "",
    ["Transparency"] = ""
}


local HRPanelService = {Client = {}}


function HRPanelService:Init()
    self:RegisterClientEvent(EVENT_NAME)
end


function HRPanelService:Start()
    self:MonitorEvents()
end


function HRPanelService:OpenClose(player)
    self:FireClient(EVENT_NAME, player, "OpenClosePanel")
end


-- Flight functions
function HRPanelService:SendEventToHRs(...)
    for _,v in pairs(game:GetService("Players"):GetChildren()) do
        if self.Services.Data.PermissionService:HasPermission(v.UserId, "Admin") then
            self:FireClient(EVENT_NAME, v, ...)
        end
    end
end


function HRPanelService.Client:CreateNewFlight(player, flight_data)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Core.FlightService:CreateFlight(flight_data)
    end
end


function HRPanelService.Client:UpdateFlight(player, flight_data)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Core.FlightService:UpdateCurrentFlight(flight_data)
    end
end


function HRPanelService.Client:GetPossibleAircrafts(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        return self.Server.Services.Game.Core.SpawningService:GetPossibleAircrafts()
    end
end


function HRPanelService.Client:SetCurrentFlight(player, flight_number)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Core.FlightService:SetCurrentFlight(flight_number)
    end
end


function HRPanelService.Client:DeactivateFlight(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Core.FlightService:SetCurrentFlight(false)
    end
end


function HRPanelService.Client:GetDefaultFlights(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        return self.Server.Services.Game.Core.FlightService:GetAllFlights()
    end
end


function HRPanelService.Client:RequestCurrentFlight(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        return self.Server.Services.Game.Moderation.HRPanelService:FireClient(EVENT_NAME, player, "CurrentSet", self.Server.Services.Game.Core.FlightService:GetCurrentFlight())
    end
end


function HRPanelService:MonitorEvents()
    self.Services.Game.Core.FlightService:ConnectEvent("Flight", function(action, tbl)
        if action == "Creation" then
            self:SendEventToHRs("NewTempFlight", tbl)
        elseif action == "CurrentSet" then
            self:SendEventToHRs("SetCurrent", tbl)
        elseif action == "CurrentRemoval" then
            self:SendEventToHRs("FlightDeactivated", nil)
        elseif action == "CurrentUpdate" then
            self:SendEventToHRs("FlightUpdated", tbl)
        elseif action == "DefaultFlights" then
            self:SendEventToHRs("UpdateDefaultFlights", tbl)
        end
    end)

    self.Services.Game.Moderation.StaffLockService:ConnectEvent("StaffLock", function(mode)
        self:SendEventToHRs("StaffLockChange", {mode})
    end)
end


-- ServerLock Functions
function HRPanelService.Client:ChangeStaffLockMode(player, mode)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Updated StaffLock Mode")
        return self.Server.Services.Game.Moderation.StaffLockService:SetMode(mode)
    end
end


function HRPanelService.Client:KickNonStaff(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Kicking Non-Staff!")
        return self.Server.Services.Game.Moderation.StaffLockService:KickNonStaff()
    end
end


function HRPanelService.Client:ShutdownServer(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        return self.Server.Services.Game.Moderation.StaffLockService:ShutdownServer()
    end
end


-- Moderation functions

function HRPanelService.Client:ForwardInfractionRequest(player, userId, infracType, reason, duration)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Success = self.Server.Services.Data.ModerationService:IssueInfraction(userId, infracType, reason, player.UserId, duration)
        
        if Success then
            local NewInfractions = self.Server.Services.Data.ModerationService:GetInfractions(userId)
            self.Server.Services.Game.Moderation.HRPanelService:SendEventToHRs("UpdateInfractionList", {NewInfractions, userId})
            self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Infraction Issued!")
        end
    end
end


function HRPanelService.Client:ForwardInfractionRetrival(player, userId)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Infractions = self.Server.Services.Data.ModerationService:GetInfractions(userId)
        return Infractions
    end
end


function HRPanelService.Client:ForwardInfractionRemoval(player, userId, index)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Success = self.Server.Services.Data.ModerationService:RevokeInfraction(userId, index+1)

        if Success then
            local NewInfractions = self.Server.Services.Data.ModerationService:GetInfractions(userId)
            self.Server.Services.Game.Moderation.HRPanelService:SendEventToHRs("UpdateInfractionList", {NewInfractions, userId})
            self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Removed Infraction")
        end
    end
end


-- Rain functions
function HRPanelService.Client:UpdateRainRequest(player, config)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        RainConfiguration = config
        self.Server.Services.Game.Moderation.HRPanelService:FireAllClients(EVENT_NAME, "SetRainMode", config)
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Rain Settings Updated")
        self.Server.Services.Game.Moderation.HRPanelService:SendEventToHRs("WeatherFieldUpdate", RainConfiguration)
    end
end


function HRPanelService.Client:GetCurrentRainStats(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Moderation.HRPanelService:FireClient(EVENT_NAME, player, "WeatherFieldUpdate", RainConfiguration)
    end
end


function HRPanelService.Client:UpdateRainClient(player)
    -- debounce??
    self.Server.Services.Game.Moderation.HRPanelService:FireClient(EVENT_NAME, player, "SetRainMode", RainConfiguration)
end


-- Music system
function HRPanelService.Client:MusicPlayPauseSwitch(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        if Music:IsPaused() then
            Music:Resume()
            self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Music Resumed!")
        else
            Music:Pause()
            self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Music Paused!")
        end
    end
end


function HRPanelService.Client:IsPaused(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        return Music:IsPaused()
    end
end


function HRPanelService.Client:SkipMusicTrack(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Music Skipped!")
        Music:SkipCurrentSong()
    end
end


function HRPanelService.Client:RemoveTrack(player, id)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        Music:RemoveFromQueue(id)
    end
end


function HRPanelService.Client:FetchQueue(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        return Music:GetQueue()
    end
end


function HRPanelService.Client:AddToQueue(player, id)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        return Music:AddToQueue(id)
    end
end


function HRPanelService.Client:GetAllSongs(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        return Music:GetAllSongs()
    end
end


function HRPanelService.Client:IsAutoPlaying(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        return Music:IsAutoPlaying()
    end
end


function HRPanelService.Client:AutoPlay(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "AutoPlay Enabled!")
        Music:AutoPlay()
    end
end


function HRPanelService.Client:StopAutoPlay(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Music = self.Server.Services.Game.Auditory.MusicService
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "AutoPlay Disabled!")
        Music:StopAutoPlay()
    end
end


-- Spawning

function HRPanelService.Client:RequestAircraft(player, aircraftName)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Spawning = self.Server.Services.Game.Core.SpawningService
        local Position = game.Workspace.Infrastructure.Spawning.Aircraft.Position
        Spawning:SpawnAircraft(aircraftName, Position)
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Spawned "..aircraftName.."")
    end
end


function HRPanelService.Client:RequestDespawn(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Spawning = self.Server.Services.Game.Core.SpawningService
        Spawning:DespawnAircrafts()
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Despawned Aircrafts!")
    end
end


-- Conveyor

function HRPanelService.Client:SetConveyor(player, conveyorNumber)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Conveyor = self.Server.Services.Game.Infrastructure.ConveyorService
        Conveyor:SetActiveConveyor(conveyorNumber)
    end
end


function HRPanelService.Client:EnableConveyor(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Conveyor = self.Server.Services.Game.Infrastructure.ConveyorService
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Conveyor Enabled!")
        Conveyor:EnableActiveConveyor()
    end
end


function HRPanelService.Client:DisableConveyor(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        local Conveyor = self.Server.Services.Game.Infrastructure.ConveyorService
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Conveyor Disabled!")
        Conveyor:DisableActiveConveyor()
    end
end


-- Audio Announcements

function HRPanelService.Client:RequestAudioAnnouncement(player, announcementType, data)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Playing audio!")
        if announcementType == "Boarding" then
            self.Server.Services.Game.Auditory.AudioAnnouncementService:PlayAudio(announcementType, {["BoardingClass"] = data})
        elseif announcementType == "Arrival" then
            self.Server.Services.Game.Auditory.AudioAnnouncementService:PlayAudio(announcementType, {["Time"] = data["Time"], ["AM_PM"] = data["AM_PM"]})
        else
            self.Server.Services.Game.Auditory.AudioAnnouncementService:PlayAudio(announcementType)
        end
    end
end



return HRPanelService