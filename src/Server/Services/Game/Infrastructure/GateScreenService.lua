-- Gate Screen Service
-- Jack_AviationRBX
-- July 21, 2022


local GATE_SCREENS = game.Workspace.Infrastructure:WaitForChild("GateScreens")
local STATUS_COLOURS = {
	["On-Time"] = Color3.fromRGB(51, 156, 58),
	["Delayed"] = Color3.fromRGB(156, 108, 60),
	["Cancelled"] = Color3.fromRGB(156, 53, 53)
}


local GateScreenService = {Client = {}}


function GateScreenService:Start()
    -- Monitor new flight info
    self.Services.Game.Core.FlightService:ConnectEvent("Flight", function(action, tbl)
        if action == "CurrentSet" or action == "CurrentUpdate" then
            self:DisablePreviousSameFlights(tbl["FlightNumber"])
           
            if GATE_SCREENS:FindFirstChild(tbl["Gate"]) then
                local Screens = GATE_SCREENS:FindFirstChild(tbl["Gate"]):GetChildren()

                for _,v in ipairs(Screens) do
                    local Descendants = v:GetDescendants()

                    v.Screen.On.BackFrame.Visible = true
                    v.Screen.On.TopBar.Visible = true
                    v.Screen.Off.MainFrame.Visible = false

                    for a,b in ipairs(Descendants) do
                        if b:IsA("TextLabel") and b.Parent.Parent.Name == "On" then
                            local Value = tbl[b.Name]
                                
                            if b.Name ~= "Time" then
                                if b.Parent == "TopBar" then
                                    b.Text = Value
                                elseif b.Name == "Gate" then
                                    b.Text = "Gate "..Value
                                elseif b.Name == "BoardingTime" then
                                    b.Text = "Boarding Time: "..Value
                                elseif b.Name == "DepartureTime" then
                                    b.Text = "Departure Time: "..Value
                                elseif b.Name == "Aircraft" then
                                    b.Text = "Aircraft: "..Value
                                else
                                    b.Text = Value
                                end

                                if b.Name == "Status" then
                                    if STATUS_COLOURS[Value] then
                                        b.TextColor3 = STATUS_COLOURS[Value]
                                    else
                                        b.TextColor3 = STATUS_COLOURS["On-Time"]
                                    end
                                end
                            end
                        end
                    end
                end
            end
        elseif action == "CurrentRemoval" then
            if GATE_SCREENS:FindFirstChild(tbl["Gate"]) then
                local Screens = GATE_SCREENS:FindFirstChild(tbl["Gate"]):GetChildren()
        
                for _,v in ipairs(Screens) do
                    v.Screen.On.BackFrame.Visible = false
                    v.Screen.On.TopBar.Visible = false
                    v.Screen.Off.MainFrame.Visible = true
                end
        
                return true
            end
        end
    end)

end


function GateScreenService:DisablePreviousSameFlights(flightNumber)
    	--> Disable Previous Gates with same flight number
	for _,v in ipairs(GATE_SCREENS:GetChildren()) do
		for _,b in ipairs(v:GetChildren()) do
			if b.Screen.On.BackFrame.FlightNumber.Text == flightNumber then
				b.Screen.On.BackFrame.Visible = false
				b.Screen.On.TopBar.Visible = false
				b.Screen.Off.MainFrame.Visible = true
			end
		end
	end
end


return GateScreenService