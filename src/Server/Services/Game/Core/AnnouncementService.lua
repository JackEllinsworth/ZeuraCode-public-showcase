-- Announcement Service
-- Jack_AviationRBX
-- August 10, 2022

local EVENT_ANNOUNCEMENT = "Announcement"
local TextService = game:GetService("TextService")


local AnnouncementService = {Client = {}}


function AnnouncementService:Init()
    self:RegisterClientEvent(EVENT_ANNOUNCEMENT)
end


function AnnouncementService:IssueAnnouncement(message, sender, important)
    if important then
        self:FireAllClients(EVENT_ANNOUNCEMENT, "ANN.IMP", message, sender)
    else
        self:FireAllClients(EVENT_ANNOUNCEMENT, "ANN.NORM", message, sender)
    end
end


function AnnouncementService:IssueATCAnnouncement(headtag, sender, message)
    self:FireAllClients(EVENT_ANNOUNCEMENT, message, headtag, sender)
end


function AnnouncementService:IssueEventNotification(player, message)
    self:FireClient(EVENT_ANNOUNCEMENT, player, "NOTIF", message)
end


return AnnouncementService