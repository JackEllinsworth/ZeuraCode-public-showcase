-- Boarding Controller
-- Jack_AviationRBX
-- August 9, 2022

--[[

Controls the staff-held system which manages access through the scanners in boarding systems.

--]]


local GUI
local ClassOptions


local BoardingController = {}


function BoardingController:Activate(Gui)
    GUI = Gui
    ClassOptions = self.Services.Game.Infrastructure.BoardingService:GetClassOptions()

    self:CreateClassOptions(ClassOptions)

    self.Services.Game.Infrastructure.BoardingService.Boarding:Connect(function(event, setting)
        if event == "OpenStatus" then
            if setting then
                GUI.Enabled = true
            end
        end
    end)

    GUI.Frame.Exit.MouseButton1Click:Connect(function()
        GUI.Enabled = false
    end)
end


function BoardingController:CreateClassOptions(classTbl)
    local Template = GUI.Frame.ScrollingFrame.Template
    local Buttons = {}
    
    for i,v in ipairs(classTbl) do
        local New = Template:Clone()
        New.Parent = Template.Parent
        New.Name = v
        New.TextLabel.Text = v
        New.Visible = true
        New.LayoutOrder = i

        Buttons[#Buttons+1] = New.TextButton
    end
    
    self:MonitorClassButtons(Buttons)
end


function BoardingController:MonitorClassButtons(buttons)

    for _,v in pairs(buttons) do
        v.MouseButton1Click:Connect(function()
            local ClassName = v.Parent.Name
            if v.Text == "DISABLE" then
                v.Text = "ENABLE"
                v.BackgroundColor3 = Color3.fromRGB(96, 153, 102)
                self.Services.Game.Infrastructure.BoardingService:SetBoardingMode(false)
            elseif v.Text == "ENABLE" then
                for _,b in pairs(v.Parent.Parent:GetChildren()) do
                    if b:IsA("Frame") then
                        b.TextButton.Text = "ENABLE"
                        b.TextButton.BackgroundColor3 = Color3.fromRGB(96, 153, 102)
                    end
                end
                v.Text = "DISABLE"
                v.BackgroundColor3 = Color3.fromRGB(158, 89, 87)
                self.Services.Game.Infrastructure.BoardingService:SetBoardingMode(true, ClassName)
            end
        end)
    end
end


return BoardingController