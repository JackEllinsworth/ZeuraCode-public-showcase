-- Queue Controller
-- Jack_AviationRBX
-- 29 July, 2022

--[[

Manages queue popups.

--]]


local GUI

local QueueController = {}


function QueueController:Activate(Gui)
    GUI = Gui
    self:ManagePopup()
end


function QueueController:ManagePopup()
    local PopupButton = GUI.ButtonFrame.InnerFrame.TextButton
    
    local function activateResponse()
        local PopupText = PopupButton.Text
        self.Services.Game.Infrastructure.Queue.QueueService:PopupActivated(PopupText)
    end

    PopupButton.MouseButton1Click:Connect(function()
        GUI.Enabled = false
        activateResponse()
    end)

    self.Services.Game.Infrastructure.Queue.QueueService.Queue:Connect(function(event, args)
        if event == "PopupSet" then
            PopupButton.Text = args[1]
            GUI.Enabled = true
        elseif event == "PopupCancel" then
            GUI.Enabled = false
            PopupButton.Text = ""
        end
    end)
end


return QueueController

