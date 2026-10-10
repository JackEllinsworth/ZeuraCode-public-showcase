-- Miles Controller
-- Jack_AviationRBX
-- August 7, 2023

--[[

Controls the miles system on the client. Displays appropriate data on screens.

--]]


local MilesController = {}


function MilesController:Start()
    self.Services.Data.MilesService.Miles:Connect(function(miles)
        local Miles = tostring(math.round(miles*10)/10)
        game.Players.LocalPlayer.PlayerGui:WaitForChild("ButtonBar").Miles.MilesOutput.Text = "zMiles: "..Miles
        game.Players.LocalPlayer.PlayerGui:WaitForChild("SCIPanel").Back.Frames.ClassSelection.Miles.Text = "zMiles: "..Miles
    end)
end


return MilesController