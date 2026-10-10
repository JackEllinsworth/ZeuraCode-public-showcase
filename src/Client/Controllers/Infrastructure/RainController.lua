
-- Rain Controller
-- Jack_AviationRBX
-- 21 July, 2022

--[[

Manages the virtual rain in the game
Add ability to turn off in the future (client only) to stop lag

--]]


local RainController = {}


function RainController:Start()
    self.Services.Game.Moderation.HRPanelService:UpdateRainClient()

    self.Services.Game.Moderation.HRPanelService.HRUpdate:Connect(function(action, tbl)
        local Rain = self.Modules.Aesthetics.Rain
        if action == "SetRainMode" then
            if tbl["enabled"] then
                Rain:Enable()
            else
                Rain:Disable()
            end

            Rain:SetTransparency(tbl.Transparency)
            Rain:SetSpeedRatio(tbl.Speed)
            Rain:SetIntensityRatio(tbl.Intensity)
            Rain:SetLightEmission(tbl.LightEmission)
            Rain:SetLightInfluence(tbl.LightInfluence)
        end
    end)
end


return RainController

