-- Announcement Controller
-- Jack_AviationRBX
-- August 10, 2022

--[[

Sends announcements and events to local player(s). Manages animations and interface visual effects.

--]]


local GUI
local AnnouncementInProgress = false
local NotificationInProgress = false
local EVENT_LENGTH = 3.5


local AnnouncementController = {}


function AnnouncementController:Activate(Gui)
    GUI = Gui

    self:MonitorAnnouncements()
end


function AnnouncementController:RoundTime(toRound)
    local divided = toRound / 5
    local rounded = 5 * math.floor(divided)
    return rounded
end


function AnnouncementController:SendEventNotification(msg)
    if NotificationInProgress then
        return
    end

    NotificationInProgress = true
    GUI.Action.Background.TextLabel.Text = msg

    GUI.Action:TweenPosition(UDim2.new(0.903, 0,0.878, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.5)
    task.wait(EVENT_LENGTH)
    GUI.Action:TweenPosition(UDim2.new(1.1, 0,0.878, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.5)
    task.wait(0.5)
    NotificationInProgress = false
end


function AnnouncementController:SendAnnouncement(msg, sender, important)
    if AnnouncementInProgress then
        return false
    end

    AnnouncementInProgress = true

    GUI.Announcement.Background.TextLabel.Text = msg
    GUI.Announcement.Background.AnnouncementType.Text = "Server Announcement"
    if sender then
        GUI.Announcement.Background.AnnouncementType.Text = "Server Announcement (Sent by "..sender..")"
    end

    local WaitTime = math.abs((#string.split(msg, " ")) / 2)
    if WaitTime < 3 then
        WaitTime = 3
    end

    if important then
        WaitTime += 5
        GUI.Announcement.BackgroundColor3 = Color3.fromRGB(226, 124, 123)
        GUI.Announcement.Background.Important.Visible = true
    else
        GUI.Announcement.BackgroundColor3 = Color3.fromRGB(221, 226, 228)
        GUI.Announcement.Background.Important.Visible = false
    end

    GUI.Announcement:TweenPosition(UDim2.new(0.25, 0,0.008, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 1)
    task.wait(WaitTime)
    GUI.Announcement:TweenPosition(UDim2.new(0.25, 0,-0.2, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 1)
    task.wait(2)
    AnnouncementInProgress = false
end


function AnnouncementController:SendATCMessage(msg, headtag, sender)
    if AnnouncementInProgress then
        return false
    end

    AnnouncementInProgress = true

    GUI.ATCAnnouncement.Background.TextLabel.Text = msg
    GUI.ATCAnnouncement.Background.Headtag.Headtag.Text = headtag
    
    if not sender then
        GUI.ATCAnnouncement.Background.USER.Text = ""
    else
        GUI.ATCAnnouncement.Background.USER.Text = sender
    end

    GUI.ATCAnnouncement:TweenPosition(UDim2.new(0.25, 0,0.008, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 1)

    local WaitTime = math.abs((#string.split(msg, " ")) / 2) + 2.5
    if WaitTime < 3 then
        WaitTime = 3
    end

    task.wait(WaitTime)

    GUI.ATCAnnouncement:TweenPosition(UDim2.new(0.25, 0,-0.2, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 1)
    task.wait(1)
    AnnouncementInProgress = false
end


function AnnouncementController:MonitorAnnouncements()
    self.Services.Game.Core.AnnouncementService.Announcement:Connect(function(eventType, msg, sender)
        if eventType == "ANN.NORM" then
            self:SendAnnouncement(msg, sender, false)
        elseif eventType == "ANN.IMP" then
            self:SendAnnouncement(msg, sender, true)
        elseif eventType == "NOTIF" then
            self:SendEventNotification(msg)
        else
            self:SendATCMessage(msg, eventType, sender)
        end
    end)
end


return AnnouncementController