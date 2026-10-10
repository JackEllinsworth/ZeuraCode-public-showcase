-- Power Point Controller
-- Jack_AviationRBX
-- July 29, 2024


local PowerPoints = game.Workspace.Infrastructure:FindFirstChild("PowerPoints")
local ConfigArea = PowerPoints.Config
local PowerPointController = {}
local GUI

function PowerPointController:Activate(Gui)
    GUI = Gui

    for _,role in pairs(ConfigArea:GetChildren()) do
        -- Create roles initially
        local Temp = GUI.Selection.ScrollOptions.Template
        local New = Temp:Clone()
        New.Parent = Temp.Parent
        New.Name = role.Name
        New.TextButton.Text = role.Name
        New.Visible = true
        self:MonitorSelectionButton(New.TextButton)
    end

    GUI.Change.Return.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.PowerPointService:Clear(GUI.Attachment.Value)
    end)

    if PowerPoints then
        for _,powerpoint in pairs(PowerPoints:GetChildren()) do
            if powerpoint:IsA("Model") then
                powerpoint.Monitor.ClickDetector.MouseClick:Connect(function()
                    self.Services.Game.Infrastructure.PowerPointService:ClickedDetector(powerpoint.Name)
                end)
                self:MonitorPreviousForwardBtns(powerpoint)
            end
        end
    end
end


function PowerPointController:MonitorPreviousForwardBtns(powerpoint)

    GUI.Change.Back.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.PowerPointService:GoBack(powerpoint.Name)
    end)

    GUI.Change.Forward.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.PowerPointService:GoForward(powerpoint.Name)
    end)
end

function PowerPointController:MonitorSelectionButton(btn)
    btn.MouseButton1Click:Connect(function()
        self.Services.Game.Infrastructure.PowerPointService:RequestSelection(tostring(btn.Parent.Parent.Parent.Parent.Attachment.Value), btn.Parent.Name)
    end)
end



return PowerPointController