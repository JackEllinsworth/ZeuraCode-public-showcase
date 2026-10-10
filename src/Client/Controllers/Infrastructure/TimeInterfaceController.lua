-- Time Interface Controller
-- Jack_AviationRBX
-- July 21, 2022

--[[

This code controls the interfaces in the game, via the client, showing the exact time locally.

--]]


local Infrastrucutre = game.Workspace.Infrastructure
local GateScreens = Infrastrucutre.GateScreens
local Queues = Infrastrucutre.Queues


local TimeInterfaceController = {}


function TimeInterfaceController:Start()
	local function getTime()
		local date = os.date("*t") 
		return ("%02d:%02d:%02d"):format(date.hour, date.min, date.sec)
	end

	while true do
		wait(1)
	
		local c_time = getTime()
	
		-- Gate screens
		for _,v in ipairs(GateScreens:GetChildren()) do
			for _,b in ipairs(v:GetChildren()) do
				b.Screen.On.TopBar.Time.Text = c_time
			end
		end

		-- MCI System
		for _,v in ipairs(game.Workspace.Infrastructure.Queues.ManualCheckIn:GetChildren()) do
			for _,b in pairs(v.Models:GetChildren()) do
				local Location = b.Overhead["Check-In Screen"].Screen.SurfaceGui["On_1"]
				Location.Time.Text = c_time
			end
		end
	
		-- Identification screens
		for _,v in pairs(game.Workspace.Infrastructure.Screens.DepartureScreens:GetChildren()) do
			if v.Name == "Primary_Horizontal" then
				v.screen.Departures.Background.TopBar.CurrentTime.Text = c_time
			end
		end

		-- IFE System
		local IFE = game.Players.LocalPlayer.PlayerGui:FindFirstChild("IFE")
		if IFE then
			IFE.Background.Time.Inner.Time.Text = c_time
		end
	end
end


return TimeInterfaceController