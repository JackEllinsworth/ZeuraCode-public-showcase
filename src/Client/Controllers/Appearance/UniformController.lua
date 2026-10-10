-- Uniform Controller
-- Jack_AviationRBX
-- July 22, 2022

--[[

Manages uniform option changing for Cabin Crew and First Officer/Pilot roles.

--]]


local GUI
local CurrentOptions = {}
local CurrentRoleSelection = ""


local UniformController = {}


function UniformController:Activate(Gui)
    GUI = Gui
    self:MonitorButtons()
    self:MonitorRequests()
end


function UniformController:MonitorButtons()
    local function reset()
        CurrentOptions = {}
        CurrentRoleSelection = ""
        GUI.Enabled = false
    end

    GUI.Options.One.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Staff.UniformService:RequestUniformVariant(CurrentRoleSelection, CurrentOptions[1])
        reset()
    end)

    GUI.Options.Two.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Staff.UniformService:RequestUniformVariant(CurrentRoleSelection, CurrentOptions[2])
        reset()
    end)
end


function UniformController:MonitorRequests()
    self.Services.Game.Staff.UniformService.Uniform:Connect(function(roleName, optionsTbl)
        CurrentRoleSelection = roleName
        CurrentOptions = optionsTbl

        GUI.Options.One.TextButton.Text = optionsTbl[1]
        GUI.Options.Two.TextButton.Text = optionsTbl[2]
        GUI.Title.TextLabel.Text = "Select your uniform variant. [Role: "..roleName.."]"
        GUI.Enabled = true
    end)
end


return UniformController