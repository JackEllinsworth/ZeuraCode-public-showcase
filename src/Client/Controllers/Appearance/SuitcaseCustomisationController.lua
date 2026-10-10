-- Suitcase Customisation Controller
-- Jack_AviationRBX
-- July 26, 2022

--[[

Controls the suitcase customisation system.

--]]


local GUI

local SuitcaseCustomisationController = {}


function SuitcaseCustomisationController:Activate(Gui)
    GUI = Gui
    self:SetupThemes()

    -- Button bar
    game.Players.LocalPlayer.PlayerGui:WaitForChild("ButtonBar").Frame.SuitcaseCustomisation.Frame.ImageButton.MouseButton1Click:Connect(function()
        if GUI.Enabled then
            GUI.Enabled = false
        else
            GUI.Enabled = true
        end
    end)

    -- Monitor newly bought themes / enable changes
    self.Services.Data.SuitcaseService.Suitcase:Connect(function(action, themeName)
        if action == "ThemeEnabled" or action == "NewTheme" then
            self:SetupThemes()
        end
    end)
end


function SuitcaseCustomisationController:MonitorButton(btn)
    btn.MouseButton1Click:Connect(function()
        if btn.Text == "ENABLE" then
            self.Services.Data.SuitcaseService:RequestClientThemeChange(btn.Parent.Name)
        end
    end)
end


function SuitcaseCustomisationController:SetupThemes()
    local Themes, EnabledTheme = self.Services.Data.SuitcaseService:RequestClientThemes()
    
    for _,v in pairs(GUI.BackLayout.ScrollingFrame:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "Template" then
            v:Destroy()
        end
    end

    if #Themes <= 1 then
        GUI.BackLayout.NoThemes.Visible = true
    else
        GUI.BackLayout.NoThemes.Visible = false
        GUI.BackLayout.NoThemes.Visible = false
        for _,v in ipairs(Themes) do
            local NewInstance = GUI.BackLayout.ScrollingFrame.Template:Clone()
            NewInstance.Parent = GUI.BackLayout.ScrollingFrame
            NewInstance.Name = v
            NewInstance.Visible = true
            NewInstance.ThemeName.Text = v
            self:MonitorButton(NewInstance.Enable)
        end
    
        GUI.BackLayout.ScrollingFrame[EnabledTheme].Enable.Text = "ACTIVE"
        GUI.BackLayout.ScrollingFrame[EnabledTheme].Enable.BackgroundColor3 = Color3.fromRGB(248, 92, 85)
       
        local CellSize = GUI.BackLayout.ScrollingFrame.UIGridLayout.CellSize.Y.Offset
        local PaddingSize = GUI.BackLayout.ScrollingFrame.UIGridLayout.CellPadding.Y.Offset
        local SeperationSize = CellSize + PaddingSize

        GUI.BackLayout.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, SeperationSize * (#Themes))
    end
end


return SuitcaseCustomisationController