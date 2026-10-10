-- ATC Controller
-- Jack_AviationRBX
-- August 5, 2023

--[[

Sends an ATC announcement to all other clients, given that correct permissions are given.
Manages all ATC interactions for staff members.

--]]

local GUI
local PresetSelected = ""
local ChannelSelected = ""
local FlightNumber = ""

local Presets = {
    ["Pushback"] = "push and start approved, tail left/right. Expect Runway X at taxiway X.",
    ["Taxi"] = "taxi to holding point on runway X via X.",
    ["LineUp"] = "line up and wait, runway X.",
    ["Clearance"] = "this is X tower. Maintain your ILS for Runway X, speed X knots. Wind is at X degrees.",
    ["Landing"] = "cleared to land, runway X. Wind is at X degrees.",
    ["Return"] = "taxi to gate X via X."
}


local ATCController = {}


function ATCController:Activate(Gui)
    GUI = Gui

    self:MonitorClosure()
    self:MonitorStaffEvents()
    self:MonitorPresetSelection()
    self:MonitorChannelSelection()
    self:MonitorSending()
end


function ATCController:MonitorSending()
    GUI.Frame.Send.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.ATCControlService:RequestATCAnnouncement(
            GUI.Frame.InputFrame.ControlInput.Text,
            ChannelSelected,
            FlightNumber
        )
    end)
end

function ATCController:MonitorClosure()
    GUI.Frame.Exit.MouseButton1Click:Connect(function()
        GUI.Enabled = false
    end)
end


function ATCController:MonitorStaffEvents()
    self.Services.Game.Infrastructure.ATCControlService.ATCStaffUpdate:Connect(function(action, tbl)
        if action == "OpenClosePanel" then
            if GUI.Enabled then
                GUI.Enabled = false
            else
                GUI.Enabled = true
            end
        end
    end)
end


function ATCController:FormTemplateMessage()
    FlightNumber = self.Services.Game.Infrastructure.ATCControlService:GetFlightNumber()
    local StartMessage = ""

    if FlightNumber then
        StartMessage = StartMessage .. FlightNumber
    end

    if ChannelSelected ~= "FlightDeck" and PresetSelected ~= "" then
        StartMessage = StartMessage .. ", "
        StartMessage = StartMessage .. Presets[PresetSelected]
    end

    GUI.Frame.InputFrame.ControlInput.Text = StartMessage
end


function ATCController:MonitorChannelSelection()
    for _, button in pairs(GUI.Frame.Channels:GetChildren()) do
        button.MouseButton1Click:Connect(function()
            ChannelSelected = button.Name

            if ChannelSelected == "FlightDeck" then
                for _,preset in pairs(GUI.Frame.Presets:GetChildren()) do
                    preset.Visible = false
                end
                GUI.Frame.Titles.Preset.Visible = false
            else
                for _,preset in pairs(GUI.Frame.Presets:GetChildren()) do
                    preset.Visible = true
                end
                GUI.Frame.Titles.Preset.Visible = true
            end

            self:FormTemplateMessage()
        end)
    end
end


function ATCController:MonitorPresetSelection()
    for _, button in pairs(GUI.Frame.Presets:GetChildren()) do
        button.MouseButton1Click:Connect(function()
            PresetSelected = button.Name
            self:FormTemplateMessage()
        end)
    end
end


return ATCController