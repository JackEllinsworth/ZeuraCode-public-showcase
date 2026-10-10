return function (context, important, announcement)
    local Aero = _G.Aero
    Aero.Services.Game.Core.AnnouncementService:IssueAnnouncement(announcement, context.Executor.Name, important)
end