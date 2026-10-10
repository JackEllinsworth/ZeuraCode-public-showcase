-- MCI Controller
-- Jack_AviationRBX
-- 30 July, 2022

--[[

Manages the Manual Check-In system locally.

--]]


local GUI


local MCIController = {}


function MCIController:Activate(Gui)
    GUI = Gui
    self:ManagePopup()
end


function MCIController:ManagePopup()
    local PopupButton = GUI.ButtonFrame.InnerFrame.TextButton
    
    local function activateResponse()
        local PopupText = PopupButton.Text
        self.Services.Game.Infrastructure.ManualCheckInService:PopupActivated(PopupText)
    end

    PopupButton.MouseButton1Click:Connect(function()
        GUI.Enabled = false
        activateResponse()
    end)

    self.Services.Game.Infrastructure.ManualCheckInService.ManualCheckIn:Connect(function(event, args)
        if event == "PopupSet" then
            PopupButton.Text = args[1]
            GUI.Enabled = true
        elseif event == "PopupCancel" then
            GUI.Enabled = false
            PopupButton.Text = ""
        end
    end)
end


return MCIController

