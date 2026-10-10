-- MCI Staff Controller
-- Jack_AviationRBX
-- July 29, 2022

--[[

This code controls the core functionality of the HR Panel, accessible to high ranks only.

--]]


local GUI
local ClassOptions
local Players = game:GetService("Players")


local MCIStaffController = {}


function MCIStaffController:Activate(Gui)
    GUI = Gui
    ClassOptions = self.Services.Game.Infrastructure.ManualCheckInService:GetClassOptions()

    self:CreateClassOptions(ClassOptions)
    self:MonitorUpdates()
    self:MonitorPlayerControlButtons()

    self:ManageBackButtons()
    self:MonitorMainFrame()
    self:MonitorOpenClose()
    self:EnableDisable()
    self:ScreenOnOff()
    self:MonitorStatuses()
    self:MonitorClassRestrictions()
end


function MCIStaffController:MonitorUpdates()
    self.Services.Game.Infrastructure.ManualCheckInService.ManualCheckIn:Connect(function(event, tbl)
        if event == "StaffUpdate" then
            if tbl["AmountInQueue"] then
                GUI.CurrentlyInQueue.InQueue.Text = tostring(tbl["AmountInQueue"]).." Players currently in the queue"
            end
            if tbl["Position"] then
                GUI.Pos.Pos.Text = "Position "..tostring(tbl["Position"])
            end
            if tbl["CurrentlyServing"] ~= 0 and tbl["CurrentlyServing"] ~= nil then
                local Player = Players:GetPlayerByUserId(tbl["CurrentlyServing"])
                if Player then
                    GUI.Serving.Serving.Text = "Serving "..Player.Name
                end
                GUI.NextPlayerButton.Visible = false
                GUI.SendAwayButton.Visible = true
            else
                GUI.Serving.Serving.Text = "Serving N/A"
                GUI.NextPlayerButton.Visible = true
                GUI.SendAwayButton.Visible = false
            end
        elseif event == "ClassScreen" then
            if tbl[1] then
                GUI:FindFirstChild("ClassGive").Visible = true
            else
                GUI:FindFirstChild("ClassGive").Visible = false
            end
        elseif event == "UpdateCustomer" then
            self:UpdateAllowedClasses(tbl)
            self.Controllers.LeaderboardController:ForceClose()
        end
    end)
end


function MCIStaffController:MonitorPlayerControlButtons()
    local Debounce = false
    GUI.NextPlayerButton.TextButton.MouseButton1Click:Connect(function()
        if not Debounce then
            Debounce = true
            self.Services.Game.Infrastructure.ManualCheckInService:RequestNextPlayer()
            task.wait(2.5)
            Debounce = false
        end
    end)

    local DebounceTwo = false
    GUI.SendAwayButton.TextButton.MouseButton1Click:Connect(function()
        if not DebounceTwo then
            DebounceTwo = true
            self.Services.Game.Infrastructure.ManualCheckInService:SendPlayerBack()
            task.wait(2.5)
            DebounceTwo = false
        end
    end)
end


function MCIStaffController:CreateClassOptions(classTbl)
    local Template = GUI.ClassGive.ScrollClasses.ScrollingFrame.Template
    local Buttons = {}
    
    for _,v in ipairs(classTbl) do
        local New = Template:Clone()
        New.Parent = Template.Parent
        New.Name = v
        New.Class.Text = v
        New.Visible = true

        Buttons[#Buttons+1] = New.Give
        Buttons[#Buttons+1] = New.Prompt
    end
    
    self:MonitorClassButtons(Buttons)
end


function MCIStaffController:UpdateAllowedClasses(classTbl)
    -- Reset
    for _,v in ipairs(GUI.ClassGive.ScrollClasses.ScrollingFrame:GetChildren()) do
        if v:IsA("Frame") then
            v.Give.Visible = false
            v.Prompt.Visible = true
        end
    end

    for _,v in ipairs(classTbl) do
        local Sector = GUI.ClassGive.ScrollClasses.ScrollingFrame:FindFirstChild(v)
        Sector.Give.Visible = true
        Sector.Prompt.Visible = false
    end
end


function MCIStaffController:MonitorClassButtons(Buttons)
    for _,v in pairs(Buttons) do
        v.MouseButton1Click:Connect(function()
            local ClassName = v.Parent.Name
            local Option = v.Name

            local Success = self.Services.Game.Infrastructure.ManualCheckInService:ExecuteClassSelection(ClassName, Option)

            if Success then
                self.Controllers.AnnouncementController:SendEventNotification("Booked Player Successfully!")
                GUI.ClassGive.Visible = false
                self.Controllers.LeaderboardController:ForceOpen()
            end
        end)
    end
end


-- MCI Board

function MCIStaffController:MonitorOpenClose()
    local SwitchedOn = false
    GUI.MCIPanelButton.TextButton.MouseButton1Click:Connect(function()
        if not SwitchedOn then
            SwitchedOn = true
            GUI.MCIPanel.Main.Visible = true
        else
            GUI.MCIPanel.Main.Visible = false
            GUI.MCIPanel.QueueConfig.Visible = false
            GUI.MCIPanel.Status.Visible = false
            SwitchedOn = false
        end
    end)
end


function MCIStaffController:MonitorMainFrame()
    for _,v in ipairs(GUI.MCIPanel.Main:GetChildren()) do
        if v.Name ~= "Exit" and v:IsA("ImageLabel") then
            v.TextButton.MouseButton1Click:Connect(function()
                if v.Visible == true then
                    GUI.MCIPanel[v.Name].Visible = true
                    GUI.MCIPanel.Main.Visible = false
                end
            end)
        end
    end
end


function MCIStaffController:ManageBackButtons()
    for _,v in ipairs(GUI.MCIPanel:GetChildren()) do
        if v:IsA("ImageLabel") then
            if v:FindFirstChild("Back") then
                v.Back.TextButton.MouseButton1Click:Connect(function()
                    GUI.MCIPanel.QueueConfig.Visible = false
                    GUI.MCIPanel.Status.Visible = false
                    GUI.MCIPanel.Main.Visible = true
                end)
            end
        end
    end
end


function MCIStaffController:EnableDisable()
    local Enable = GUI.MCIPanel.QueueConfig.Enable.TextButton
    local Disable = GUI.MCIPanel.QueueConfig.Disable.TextButton

    Enable.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.ManualCheckInService:EnableDisable(true)
    end)

    Disable.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.ManualCheckInService:EnableDisable(false)
    end)
end


function MCIStaffController:MonitorClassRestrictions()
    for _,v in ipairs(GUI.MCIPanel.QueueConfig:GetChildren()) do
        if v:IsA("ImageLabel") and v.Name ~= "Exit" and v.Name ~= "Back" and v.Name ~= "Enable" and v.Name ~= "Disable" then
            v.TextButton.MouseButton1Click:Connect(function()
                self.Controllers.AnnouncementController:SendEventNotification("Class Restriction Updated!")
                self.Services.Game.Infrastructure.ManualCheckInService:SetClassRestriction(v.Name)
            end)
        end
    end
end


function MCIStaffController:ScreenOnOff()
    local ScreenOn = GUI.MCIPanel.Status.On.TextButton
    local ScreenOff = GUI.MCIPanel.Status.Off.TextButton
    ScreenOn.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.ManualCheckInService:ScreenOnOff(true)
    end)
    ScreenOff.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.ManualCheckInService:ScreenOnOff(false)
    end)
end


function MCIStaffController:MonitorStatuses()
    for _,v in ipairs(GUI.MCIPanel.Status:GetChildren()) do
        if v:IsA("ImageLabel") and v.Name ~= "Off" and v.Name ~= "Back" and v.Name ~= "Exit" then
            v.TextButton.MouseButton1Click:Connect(function()
                self.Services.Game.Infrastructure.ManualCheckInService:UpdateScreenStatus(v.Name)
            end)
        end
    end
end


return MCIStaffController