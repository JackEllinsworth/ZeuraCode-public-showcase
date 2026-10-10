-- HRPanelController
-- Jack_AviationRBX
-- July 20, 2022

--[[

This code controls the core functionality of the HR Panel, accessible to high ranks only.

--]]


local Players = game:GetService("Players")


-- Flight System
local GUI
local CurrentFlight = {}

-- Moderation system
local CurrentUserId = 0

-- Music system
local Songs = {}

-- Announcement Audio
local ClassBoarding = ""
local AM_PM = ""


local HRPanelController = {}


function HRPanelController:Activate(Gui)
    GUI = Gui
    self:MonitorCoreFrames()
    self:MonitorHREvents()
    self:ManageTeleportationSystem()
    self:ManageFlightSystem()
    self:ManageStaffLockSystem()
    self:ManageModerationSystem()
    self:ManageWeatherSystem()
    self:MonitorMusicSystem()
    self:ManageSpawningSystem()
    self:MonitorConveyorSystem()
    self:ManageAudioAnnouncementSystem()
end


function HRPanelController:MonitorCoreFrames()
    -- Monitor frames
    for _,v in pairs(GUI.MainFrame.ScrollOptions:GetChildren()) do
        local MainFrameName = v.Name
        local Buttons = {}
        
        for _,b in pairs(v:GetDescendants()) do
            if b:IsA("TextButton") then
                table.insert(Buttons, b)
            end
        end
        
        for _,b in pairs(Buttons) do
            b.MouseButton1Click:Connect(function()
                GUI.MainFrame.Visible = false
                GUI.FrameOptions[MainFrameName].Visible = true
                
                if #Buttons > 1 then
                    local InnerFrameName = b.Parent.Name
                    GUI.FrameOptions[MainFrameName][InnerFrameName].Visible = true
                end
            end)
        end
    end

    -- Back buttons
    local function manageBackBtn(btn)
        btn.MouseButton1Click:Connect(function()
            if btn.Parent.Parent.Parent.Parent.Name == "FrameOptions" then
                for _,v in pairs(btn.Parent.Parent.Parent:GetChildren()) do
                    if v:IsA("Frame") then
                        v.Visible = false
                    end
                end
            end
    
            for _,v in pairs(GUI.FrameOptions:GetChildren()) do
                v.Visible = false
            end
            
            GUI.MainFrame.Visible = true
        end)
    end

    for _,v in pairs(GUI.FrameOptions:GetChildren()) do
        if v:FindFirstChild("Back") then
            manageBackBtn(v["Back"].TextButton)
        else
            for _,b in pairs(v:GetChildren()) do
                if b:FindFirstChild("Back") then
                    manageBackBtn(b["Back"].TextButton)
                end
            end
        end
    end

    -- Monitor button bar
    game.Players.LocalPlayer.PlayerGui:WaitForChild("ButtonBar").Frame.HRPanel.Visible = true
    game.Players.LocalPlayer.PlayerGui:WaitForChild("ButtonBar").Frame.HRPanel.Frame.ImageButton.MouseButton1Click:Connect(function()
        if GUI.Enabled then
            GUI.Enabled = false
        else
            GUI.Enabled = true
        end
    end)
end


function HRPanelController:MonitorHREvents()

    self.Services.Game.Moderation.HRPanelService.HRUpdate:Connect(function(action, tbl)
        -- Flights
        local FlightFrame = GUI.FrameOptions["Flights"]
        if action == "SetCurrent" or action == "FlightUpdated" then
            if tbl then
                CurrentFlight = tbl
                
                for _,v in pairs(FlightFrame["UpdateFlight"].ScrollOptions:GetChildren()) do
                    if v.Name ~= "Template" and v:IsA("Frame") then
                        v:Destroy()
                    end
                end
                
                local Template = FlightFrame["UpdateFlight"].ScrollOptions.Template
                for i,v in pairs(tbl) do
                    --// FlightNumber and Aircraft can effect the overall seating system and flight number.
                    --// Therefore, it cant be edited/modified.
                    if i ~= "FlightNumber" and i ~= "Aircraft" and i ~= "Roles" and i ~= "_classesBooked" then
                        local New = Template:Clone()
                        New.Parent = Template.Parent
                        New.Option.Text = "Option: "..i
                        New.Name = i
                        New.Response.InputBox.Text = v
                        New.Visible = true
                    end
                end
                
                FlightFrame["UpdateFlight"].AdditionalInfo.Text = "Flight Number: "..tbl["FlightNumber"].."\nAircraft: "..tbl["Aircraft"]
                
                if FlightFrame["CreateFlight"].Visible == true or FlightFrame["PlannedFlights"].Visible == true then
                    FlightFrame["CreateFlight"].Visible = false
                    FlightFrame["PlannedFlights"].Visible = false
                    FlightFrame["UpdateFlight"].Visible = true
                end
                
                FlightFrame.Parent.Parent.MainFrame.ScrollOptions.Flights.Inner.PlannedFlights.Visible = false
                FlightFrame.Parent.Parent.MainFrame.ScrollOptions.Flights.Inner.UpdateFlight.Visible = true
                FlightFrame.Parent.Parent.MainFrame.ScrollOptions.Flights.Inner.CreateFlight.Visible = false
            end
        elseif action == "NewTempFlight" then
            local Template = FlightFrame.PlannedFlights.ScrollOptions.Template
            local New = Template:Clone()
            New.Parent = Template.Parent
            New.Name = tbl["FlightNumber"]
            New.DateTimeHost.Text = "Date: "..tbl["Date"].." | Time: "..tbl["Time"].." | Host: "..tbl["Host"]
            New.FlightNumber.Text = tbl["FlightNumber"]
            New.Visible = true
            
            New.Detector.MouseButton1Click:Connect(function()
                FlightFrame["PlannedFlights"].CurrentSelected.Text = New.Detector.Parent.Name
            end)
        elseif action == "FlightDeactivated" then
            FlightFrame["CreateFlight"].Visible = false
            FlightFrame["PlannedFlights"].Visible = false
            
            if FlightFrame["UpdateFlight"].Visible == true then
                FlightFrame.Parent.Parent.MainFrame.Visible = true
            end
            
            FlightFrame["UpdateFlight"].Visible = false
            FlightFrame.Visible = false
            
            FlightFrame.Parent.Parent.MainFrame.ScrollOptions.Flights.Inner.PlannedFlights.Visible = true
            FlightFrame.Parent.Parent.MainFrame.ScrollOptions.Flights.Inner.UpdateFlight.Visible = false
            FlightFrame.Parent.Parent.MainFrame.ScrollOptions.Flights.Inner.CreateFlight.Visible = true
        -- Stafflock system
        elseif action == "StaffLockChange" then
            for _,v in pairs(GUI.FrameOptions["StaffLock"].WhitelistOptions:GetChildren()) do
                v.SelectedStatus.Visible = false
            end	
            
            GUI.FrameOptions["StaffLock"].WhitelistOptions[tbl[1]].SelectedStatus.Visible = true
        -- Moderation system
        elseif action == "UpdateInfractionList" then
            self:UpdateInfractionListModerationSystem(tbl[1], tbl[2])
        elseif action == "WeatherFieldUpdate" then
            local Frame = GUI.FrameOptions["Weather"]
	        for i,v in pairs(tbl) do
		        if Frame.Rain:FindFirstChild(i) then
			        Frame["Rain"][i].InputBox.Text = v
		        end
	        end
        elseif action == "OpenClosePanel" then
            if GUI.Enabled then
                GUI.Enabled = false
            else
                GUI.Enabled = true
            end
        end
    end)
end


function HRPanelController:ManageAudioAnnouncementSystem()
    local Frame = GUI.FrameOptions["AudioAnnouncements"]

    for _,v in pairs(Frame.Options:GetChildren()) do
		v.TextButton.MouseButton1Click:Connect(function()
            if v.Name == "Boarding" and ClassBoarding ~= "" then
                self.Services.Game.Moderation.HRPanelService:RequestAudioAnnouncement(v.Name, ClassBoarding)
            elseif v.Name == "Arrival" then
                
                local TimeEntry = Frame.TimeOptionsArrival.TimeEntry.InputBox.Text
                if tonumber(TimeEntry) and tonumber(TimeEntry) >= 0 and tonumber(TimeEntry) <= 12 and AM_PM ~= "" then
                    self.Services.Game.Moderation.HRPanelService:RequestAudioAnnouncement(v.Name, {
                        ["Time"] = tonumber(TimeEntry),
                        ["AM_PM"] = AM_PM
                    })
                end
            elseif v.Name ~= "Boarding" then
                self.Services.Game.Moderation.HRPanelService:RequestAudioAnnouncement(v.Name)
            end
		end)
	end

    Frame.TimeOptionsArrival.AM.TextButton.MouseButton1Click:Connect(function()
        AM_PM = "AM"
        Frame.TimeOptionsArrival.AM.SelectedStatus.Visible = true
        Frame.TimeOptionsArrival.PM.SelectedStatus.Visible = false
    end)

    Frame.TimeOptionsArrival.PM.TextButton.MouseButton1Click:Connect(function()
        AM_PM = "PM"
        Frame.TimeOptionsArrival.PM.SelectedStatus.Visible = true
        Frame.TimeOptionsArrival.AM.SelectedStatus.Visible = false
    end)

    for _,v in pairs(Frame.ClassOptionsBoarding:GetChildren()) do
        v.TextButton.MouseButton1Click:Connect(function()
            ClassBoarding = v.Name

            for _,p in pairs(Frame.ClassOptionsBoarding:GetChildren()) do
                p.SelectedStatus.Visible = false
            end
            
            v.SelectedStatus.Visible = true
        end)
    end
end


function HRPanelController:ManageFlightSystem()
    self.Services.Game.Moderation.HRPanelService:RequestCurrentFlight()

    local Frame = GUI.FrameOptions["Flights"]
    local CreationOptions = {"FlightNumber", "Status", "Host", "Date", "Time", "Airport", "Aircraft", "Gate", "Destination", "DestinationCode", "BoardingTime", "DepartureTime", "ArrivalTime"}
    local PossibleAircrafts = self.Services.Game.Moderation.HRPanelService:GetPossibleAircrafts()

    local Text = "<b>Formatting Notice:</b> Aircraft names are <b>case sensitive</b>, make sure every character is correct! To be able to sync the configuration automatically, this must be correct or the flight will not be added.<br /><b>Possible aircraft names:</b><br />"

    for i,v in ipairs(PossibleAircrafts) do
        if i ~= #PossibleAircrafts then
            Text = Text..v..", "
        else
            Text = Text..v.."."
        end
    end

    Frame.CreateFlight.Notice.Text = Text

    -- Setup default flights
    local temp = Frame.PlannedFlights.ScrollOptions.Template
	local Flights = self.Services.Game.Moderation.HRPanelService:GetDefaultFlights()

	for _,flight in pairs(Flights) do
		local New = temp:Clone()
		New.Parent = temp.Parent
		New.Name = flight["FlightNumber"]
		New.DateTimeHost.Text = "Date: "..flight["Date"].." | Time: "..flight["Time"].." | Host: "..flight["Host"]
		New.FlightNumber.Text = flight["FlightNumber"]
		New.Visible = true
		
        New.Detector.MouseButton1Click:Connect(function()
            Frame["PlannedFlights"].CurrentSelected.Text = New.Detector.Parent.Name
        end)
	end

    -- Setup default input options
    local clone = Frame.CreateFlight.ScrollOptions.Template
	for _,v in pairs(CreationOptions) do
		local New = clone:Clone()
		New.Parent = clone.Parent
		New.Name = v
		New.Option.Text = "Option: "..v
		New.Visible = true
	end

    -- Create new flight
    Frame.CreateFlight.ActivateFlight.TextButton.MouseButton1Click:Connect(function()
        local Data = {}

        for _,v in pairs(Frame.CreateFlight.ScrollOptions:GetChildren()) do
            if v:IsA("Frame") and v.Name ~= "Template" then
                Data[v.Name] = v.Box.InputBox.Text
            end
        end

        self.Services.Game.Moderation.HRPanelService:CreateNewFlight(Data)
        
        Frame.CreateFlight.Visible = false
        Frame.PlannedFlights.Visible = true
    end)

    -- Deactivate current flight
    Frame["UpdateFlight"].DeactivateFlight.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:DeactivateFlight()
    end)

    -- Set current flight
    Frame["PlannedFlights"].ActivateFlight.TextButton.MouseButton1Click:Connect(function()
        local FlightNumber = Frame["PlannedFlights"].CurrentSelected.Text

        if #FlightNumber >= 1 and FlightNumber ~= "None Selected" then
			self.Services.Game.Moderation.HRPanelService:SetCurrentFlight(FlightNumber)
		end
    end)

    -- Detect flight update
    Frame["UpdateFlight"].UpdateConfig.TextButton.MouseButton1Click:Connect(function()
        for _,v in pairs(Frame["UpdateFlight"].ScrollOptions:GetChildren()) do
			if v.Name ~= "Template" and v:IsA("Frame") then
				CurrentFlight[v.Name] = v.Response.InputBox.Text
			end
		end
		self.Services.Game.Moderation.HRPanelService:UpdateFlight(CurrentFlight)
    end)
end


function HRPanelController:ManageTeleportationSystem()
    local Frame = GUI.FrameOptions["Teleportation"]
    
    local function detectTeleportButton(btn)
        btn.MouseButton1Click:Connect(function()
            self.Services.Game.Moderation.TeleportationService:TransportPlayerToZone(btn.Parent.Parent.Parent.Name)
        end)
    end

    local LocationsAllowed = self.Services.Game.Moderation.TeleportationService:GetZoneNames()
	local Template = Frame.ScrollOptions.Template

	for _,v in pairs(LocationsAllowed) do
		local New = Template:Clone()
		New.Name = v
		New.Parent = Template.Parent
		New.Title.Text = v
		New.Visible = true
		detectTeleportButton(New.Inner.Teleport.TextButton)
	end
end


function HRPanelController:ManageStaffLockSystem()
    local Frame = GUI.FrameOptions["StaffLock"]
    local CurrentMode = self.Services.Game.Moderation.StaffLockService:GetCurrentMode()

    Frame.WhitelistOptions[CurrentMode].SelectedStatus.Visible = true

    Frame.ServerOptions.KickNonStaff.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:KickNonStaff()
    end)
    Frame.ServerOptions.ServerShutdown.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:ShutdownServer()
    end)

    for _,v in pairs(Frame.WhitelistOptions:GetChildren()) do
		v.TextButton.MouseButton1Click:Connect(function()
			self.Services.Game.Moderation.HRPanelService:ChangeStaffLockMode(v.Name)
		end)
	end
end


function HRPanelController:ManageModerationSystem()
    local Frame = GUI.FrameOptions["Moderation"]
    local CurrentModerationType = ""

    local function updatePlayerList()
        for _,v in pairs(Frame.SearchPlayerByGame.PlayerList:GetChildren()) do
            if v:IsA("Frame") and v.Name ~= "Template" then
                v:Destroy()
            end
        end
    
        local Template = Frame.SearchPlayerByGame.PlayerList.Template
        for _,v in pairs(Players:GetChildren()) do
            local New = Template:Clone()
            New.Parent = Template.Parent
            New.Name = v.Name
            New.Username.Text = v.Name
            New.UserId.Value = v.UserId
            New.Visible = true
        end
    end


    local function changeCurrentUserDisplay(userId)
        local PlayerName = Players:GetNameFromUserIdAsync(userId)
        local Player = Players:GetPlayerByUserId(userId)
    
        if Player then
            Frame.SelectedUser.Text = "Selected User: "..PlayerName.." | Account Age: "..tostring(Player.AccountAge)
        else
            Frame.SelectedUser.Text = "Selected User: "..PlayerName.." | Account Age: User offline"
        end
    end


    -- Update player list on every menu click
	Frame.Parent.Parent.MainFrame.ScrollOptions.Moderation.Inner.OpenPanel.TextButton.MouseButton1Click:Connect(function()
		updatePlayerList()
	end)
	
    -- Execution button control
    Frame.InnerInfractionGive.Execute.TextButton.MouseButton1Click:Connect(function()
		local CurrentUser = CurrentUserId
		local InfractionType = CurrentModerationType
		local Reason = Frame.InnerInfractionGive.Reason.InputBox.Text
		local Duration = nil
		
		local AllClear = false
		
		if InfractionType == "Ban" then
			Duration = Frame.InnerInfractionGive.Duration.InputBox.Text
			
			if Duration == "perm" or tonumber(Duration) then
				AllClear = true
			end
		else
			AllClear = true
		end

		if AllClear then
            self.Services.Game.Moderation.HRPanelService:ForwardInfractionRequest(CurrentUser, InfractionType, Reason, Duration)
			Frame.InnerInfractionGive.Visible = false
			Frame.InnerInfractionGive.Duration.InputBox.Text = ""
			Frame.InnerInfractionGive.Reason.InputBox.Text = ""
		end
	end)


    -- Monitor custom username input
    local LastUserSearch = ""
    local DebounceSearch = false
    Frame.SearchPlayerByName.SearchPlayerBtn.TextButton.MouseButton1Click:Connect(function()
        if DebounceSearch == false then
            if LastUserSearch ~= Frame.SearchPlayerByName.SearchPlayer.InputBox.Text then
                DebounceSearch = true
                local UserId = nil
                pcall(function()
                    UserId = Players:GetUserIdFromNameAsync(Frame.SearchPlayerByName.SearchPlayer.InputBox.Text)
                end)
                if UserId then
                    if UserId ~= CurrentUserId then
                        CurrentUserId = UserId
                        changeCurrentUserDisplay(UserId)
                        local InfractionsFetched = self.Services.Game.Moderation.HRPanelService:ForwardInfractionRetrival(CurrentUserId)
                        self:UpdateInfractionListModerationSystem(InfractionsFetched, UserId)
                    end
                end
                wait(6)
                DebounceSearch = false
            end
        end
    end)

    -- Selection buttons
    for _,v in pairs(Frame.SelectionButtons:GetChildren()) do
		v.TextButton.MouseButton1Click:Connect(function()
			if CurrentUserId > 1 then
				if Frame.InnerInfractionGive.Visible then
					Frame.InnerInfractionGive.Visible = false
				else
					Frame.InnerInfractionGive.Visible = true
					
					if v.Name == "Ban" then
						Frame.InnerInfractionGive.DurationTitle.Visible = true
						Frame.InnerInfractionGive.DurationNotice.Visible = true
						Frame.InnerInfractionGive.Duration.Visible = true
					else
						Frame.InnerInfractionGive.DurationTitle.Visible = false
						Frame.InnerInfractionGive.DurationNotice.Visible = false
						Frame.InnerInfractionGive.Duration.Visible = false
					end

					CurrentModerationType = v.Name
				end
			end
		end)
	end

    Frame.InnerInfractionGive.ExitPage.MouseButton1Click:Connect(function()
		Frame.InnerInfractionGive.Visible = false
	end)


    -- Game player input
    local DebounceGame = false

	Frame.SearchPlayerByGame.PlayerList.ChildAdded:Connect(function(child)
		child.Detector.MouseButton1Click:Connect(function()
			if DebounceGame == false then
				if child.UserId.Value ~= CurrentUserId then
					DebounceGame = true
					CurrentUserId = child.UserId.Value
					
					changeCurrentUserDisplay(CurrentUserId)

                    local InfractionsFetched = self.Services.Game.Moderation.HRPanelService:ForwardInfractionRetrival(CurrentUserId)
                    self:UpdateInfractionListModerationSystem(InfractionsFetched, CurrentUserId)
				end
				wait(6)
				DebounceGame = false
			end
		end)
	end)


    -- Online / offline switch
    local function changeGameList(bool)
		if bool == true then
			updatePlayerList()
		end
		for _,v in pairs(Frame.SearchPlayerByGame:GetChildren()) do
			v.Visible = bool
		end
	end

	local function changePlayerList(bool)
		for _,v in pairs(Frame.SearchPlayerByName:GetChildren()) do
			v.Visible = bool
		end
	end

	Frame.OfflinePlayers.TextButton.MouseButton1Click:Connect(function()
		changePlayerList(true)
		changeGameList(false)
	end)

	Frame.OnlinePlayers.TextButton.MouseButton1Click:Connect(function()
		changePlayerList(false)
		changeGameList(true)
	end)

end


function HRPanelController:UpdateInfractionListModerationSystem(infractions, userId)
    local Colours = {
        Warn = Color3.fromRGB(190, 199, 102),
        Kick = Color3.fromRGB(213, 178, 107),
        Ban = Color3.fromRGB(213, 121, 104)
    }
    local Frame = GUI.FrameOptions["Moderation"]

    if CurrentUserId == userId then

        --// Reset previous
        for _,v in pairs(Frame.ViewInfractions.InfractionList:GetChildren()) do
            if v.Name ~= "Template" and v:IsA("Frame") then
                v:Destroy()
            end
        end

        local Template = Frame.ViewInfractions.InfractionList.Template

        --// Update new infraction list
        local Index = 0
        for _,v in ipairs(infractions) do
            local ModeratorName = nil
            if tonumber(v["moderator"]) then
                ModeratorName = Players:GetNameFromUserIdAsync(v["moderator"])
            else
                ModeratorName = v["moderator"]
            end

            local New = Template:Clone()
            New.Parent = Template.Parent
            New.Name = tostring(Index)
            New.InfractionType.Text = string.upper(v["type"])
            New.InfractionType.BackgroundColor3 = Colours[v["type"]]
            New.ModeratorName.Text = ModeratorName
            New.Reason.Text = v["reason"]
            New.Visible = true

            Index = Index + 1

            local Clicked = false
            New.RemoveBtn.MouseButton1Click:Connect(function()
                if Clicked == false then
                    Clicked = true

                    self.Services.Game.Moderation.HRPanelService:ForwardInfractionRemoval(CurrentUserId, New.RemoveBtn.Parent.Name)
                end
            end)
        end
    end
end


function HRPanelController:ManageWeatherSystem()

    self.Services.Game.Moderation.HRPanelService:GetCurrentRainStats()

    local Frame = GUI.FrameOptions["Weather"]

    local function sendEvent(trueOrfalse)
		local Config = {
			["enabled"] = trueOrfalse,
			["Intensity"] = tonumber(Frame["Rain"].Intensity.InputBox.Text),
			["LightEmission"] = tonumber(Frame["Rain"].LightEmission.InputBox.Text),
			["LightInfluence"] = tonumber(Frame["Rain"].LightInfluence.InputBox.Text),
			["Speed"] = tonumber(Frame["Rain"].Speed.InputBox.Text),
			["Transparency"] = tonumber(Frame["Rain"].Transparency.InputBox.Text)
		}
		
        self.Services.Game.Moderation.HRPanelService:UpdateRainRequest(Config)
	end
	
	Frame.Rain.RainEnable.TextButton.MouseButton1Click:Connect(function()
		sendEvent(true)
	end)
	
	Frame.Rain.RainDisable.TextButton.MouseButton1Click:Connect(function()
		sendEvent(false)
	end)
end


function HRPanelController:MonitorMusicSystem()
    local Frame = GUI.FrameOptions["Music"]

    -- On initiation pause/play setup
    if self.Services.Game.Moderation.HRPanelService:IsPaused() then
        Frame.MusicControl.Play.Visible = true
        Frame.MusicControl.Pause.Visible = false
    else
        Frame.MusicControl.Play.Visible = false
        Frame.MusicControl.Pause.Visible = true
    end

    -- On initiation, get auto play status
    if self.Services.Game.Moderation.HRPanelService:IsAutoPlaying() then
        Frame.AutoplayDisable.Visible = true
        Frame.AutoplayEnable.Visible = false
    else
        Frame.AutoplayDisable.Visible = false
        Frame.AutoplayEnable.Visible = true
    end

    -- Pause / play / skip buttons
    for _,v in ipairs(Frame.MusicControl:GetChildren()) do
		v.MouseButton1Click:Connect(function()
			if v.Name == "Pause" or v.Name == "Play" then
				self.Services.Game.Moderation.HRPanelService:MusicPlayPauseSwitch()
			else
				self.Services.Game.Moderation.HRPanelService:SkipMusicTrack()
			end
		end)
	end

    -- Update queue
    local function updateQueue(queue, fetchQueue)
        if fetchQueue then
            queue = self.Services.Game.Moderation.HRPanelService:FetchQueue()
        end

        local QueueTemplate = Frame.CurrentPlaylist.Template

        for _,v in pairs(Frame.CurrentPlaylist:GetChildren()) do
            if v.Name ~= "Template" and not v:IsA('UIGridLayout') then
                v:Destroy()
            end
        end

        if queue then
            for i,v in ipairs(queue) do
                local New = QueueTemplate:Clone()
                New.Parent = QueueTemplate.Parent
                New.Name = tostring(i)
                New.SongNameArtistName.Text = v.Name.." | "..v.Artist
                New.Visible = true

                local Debounce = false
                New.RemoveBtn.MouseButton1Click:Connect(function()
                    if not Debounce then
                        self.Services.Game.Moderation.HRPanelService:RemoveTrack(tonumber(New.RemoveBtn.Parent.Name))
                        Debounce = true
                    end
                end)
            end
        end
    end

    updateQueue({}, true)

    -- Setup songs
    local function setupSongs()
        local Fetched_Songs = self.Services.Game.Moderation.HRPanelService:GetAllSongs()
        local SongsTemplate = Frame.MusicList.Template
        
        Songs = Fetched_Songs
        for i,v in ipairs(Fetched_Songs) do
            local New = SongsTemplate:Clone()
            New.Parent = SongsTemplate.Parent
            New.Name = tostring(i)
            New.SongName.Text = v.Name
            New.ArtistGenre.Text = tostring(v.Artist)
            New.Visible = true
            
            New.Detector.MouseButton1Click:Connect(function()
                if not Frame.CurrentPlaylist:FindFirstChild(New.Detector.Parent.Name) then
                    for a,_ in ipairs(Songs) do
                        if a == tonumber(New.Detector.Parent.Name) then
                            self.Services.Game.Moderation.HRPanelService:AddToQueue(a)
                            break
                        end
                    end
                end
            end)
        end
    end

    setupSongs()

    -- Monitor music events
    self.Services.Game.Auditory.MusicService.Music:Connect(function(action, data)
        if action == "Paused" then
            Frame.MusicControl.Play.Visible = true
            Frame.MusicControl.Pause.Visible = false
        elseif action == "Resumed" then
            Frame.MusicControl.Pause.Visible = true
            Frame.MusicControl.Play.Visible = false
        elseif action == "Queue" then
            updateQueue(data)
        elseif action == "AutoPlayEnabled" then
            Frame.AutoplayDisable.Visible = true
            Frame.AutoplayEnable.Visible = false
        elseif action == "AutoPlayDisabled" then
            Frame.AutoplayDisable.Visible = false
            Frame.AutoplayEnable.Visible = true
        end
    end)

    -- Manage autoplay enable / disable buttons
    Frame.AutoplayDisable.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:StopAutoPlay()
    end)

    Frame.AutoplayEnable.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:AutoPlay()
    end)

    -- Manage song search
    Frame.SearchSong.InputBox.Changed:Connect(function()
		local InputText = string.upper(Frame.SearchSong.InputBox.Text)
		for _,song in pairs(Frame.MusicList:GetChildren())do
			if song:IsA("Frame") then
				if InputText==""or string.find(string.upper(song.SongName.Text),InputText)~=nil then
					song.Visible=true
					Frame.MusicList:FindFirstChild("Template").Visible = false
				else
					song.Visible=false
				end
			end
		end
	end)
end


function HRPanelController:ManageSpawningSystem()
    local Frame = GUI.FrameOptions["Spawning"]
    local Aircrafts = self.Services.Game.Moderation.HRPanelService:GetPossibleAircrafts()

    for _,v in pairs(Aircrafts) do
        local Template = Frame.ScrollOptions.Template
        local New = Template:Clone()
        New.Parent = Template.Parent
        New.Name = v
        New.Title.Text = v
        New.Visible = true

        local Debounce = false
        New.Inner.Spawn.TextButton.MouseButton1Click:Connect(function()
            if not Debounce then
                Debounce = true
                self.Services.Game.Moderation.HRPanelService:RequestAircraft(New.Name)
                wait(8)
                Debounce = false
            end
        end)
    end

    Frame.DespawnAll.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:RequestDespawn()
    end)
end


function HRPanelController:MonitorConveyorSystem()
    local Frame = GUI.FrameOptions["Conveyor"]

    Frame.Disable.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:DisableConveyor()
    end)

    Frame.Enable.TextButton.MouseButton1Click:Connect(function()
        self.Services.Game.Moderation.HRPanelService:EnableConveyor()
    end)

    Frame.Set.TextButton.MouseButton1Click:Connect(function()
        local ConveyorNum = Frame.ConveyorNumEntry.InputBox.Text
        if ConveyorNum and tonumber(ConveyorNum) then
            self.Services.Game.Moderation.HRPanelService:SetConveyor(ConveyorNum)
        end
    end)
end


return HRPanelController