-- Movement Controller
-- Jack_AviationRBX
-- September 4, 2021

--[[

MovementController manages player control over their character. This is useful in scenario's such as freeze commands,
as well as system's like Queues.

--]]


local MovementController = {}


function MovementController:Start()
    self.Services.Game.Moderation.PlayerControlService.Movement:Connect(function(setting)
        if setting then
            self:Enable()
        else
            self:Disable()
        end
    end)
end


function MovementController:Enable()
    --ContextActionService:UnbindAction(FROZEN_ACTION_KEY)
    local controls = require(game:GetService("Players").LocalPlayer.PlayerScripts.PlayerModule):GetControls()
    controls:Enable()
end


function MovementController:Disable()
    local controls = require(game:GetService("Players").LocalPlayer.PlayerScripts.PlayerModule):GetControls()
    controls:Disable()
end


return MovementController