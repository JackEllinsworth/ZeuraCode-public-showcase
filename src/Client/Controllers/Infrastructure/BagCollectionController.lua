-- Bag Collection Controller
-- Jack_AviationRBX
-- August 3, 2022

--[[

Controls the bag pickup system.

--]]


local Players = game:GetService("Players")


local BagCollectionController = {}


function BagCollectionController:Start()
    local Debounce = false
    self.Services.Game.Infrastructure.ConveyorService.Baggage:Connect(function(event, model)
        if event == "BagCreated" then
            
            model.Location.Collect.Enabled = true
            local Instance = Instance.new("ClickDetector", model.Location)
            Instance.MaxActivationDistance = model.Location.Collect.MaxDistance
            Instance.MouseClick:Connect(function()
                if not Debounce then
                    Debounce = true
                    self.Services.Game.Infrastructure.ConveyorService:RequestBagPickup()
                    task.wait(2)
                    Debounce = false
                end
            end)
        end
    end)
end


return BagCollectionController