-- IFEController
-- Jack_AviationRBX
-- July 24, 2022

--[[

This code controls the core functionality of the IFE.

--]]


local GUI
local Players = game:GetService("Players")
local CameraInit = false
local FromAirportCode = "BCN" -- Should be done automatically but will save time.
local Pages = {"Home", "Music", "News", "Games", "Info"}
local Games = {"Lunar Lander", "Adventure Island", "RoMaze"}
local RecentlyPlayedNumber = 1

-- Home frame
local ProgressParts = game.Workspace.Infrastructure.FlightProgressionBlocks -- Arrival, Origin

local IFEController = {}


function IFEController:Activate(Gui)
    GUI = Gui
    self:Sync()
    self:ManageGameFrame()
    self:ManageMusicFrame()
    self:ManageInfoFrame()
    self:MonitorCoreFrames()
    self:Update(self.Services.Game.Infrastructure.IFEService:GetCurrentFlight())
    self:ManageTracker()
end


function IFEController:Sync()
    self.Services.Game.Infrastructure.IFEService.IFEUpdate:Connect(function(action, tbl)
        if action == "UpdateFlight" or action == "SetFlight" then
            self:Update(tbl)
        elseif action == "UpdateFlightData" then
            local IFEConfigArea = GUI.IFELocation.Value
            local Frame = GUI.Background.Info

            GUI.Enabled = true

            Frame.AircraftNaming.Inner.NameOfPlane.Text = IFEConfigArea.GeneratedAircraftUtil.AircraftName.Value
            Frame.Data.Inner.Reg.Text = IFEConfigArea.GeneratedAircraftUtil.RegCode.Value
            Frame.AircraftNaming.Inner.History.Text = IFEConfigArea.GeneratedAircraftUtil.SummaryAbout.Value
            self:ManageCameraSystem()
        end
    end)
end


function IFEController:Update(tbl)
    if not tbl then
        return
    end
    
    GUI.WelcomePage.FlightNumber.Text = tbl["FlightNumber"]

    if not tbl["DestinationCode"] or #tbl["DestinationCode"] < 1 then
        tbl["DestinationCode"] = "?"
    end
    
    local DataLoc = GUI.Background.Info.Data.Inner

    DataLoc.FlightNumber.Text = tbl["FlightNumber"]

    if tbl["Roles"] then
        if tbl["Roles"]["FirstOfficer"] then
            if #tbl["Roles"]["FirstOfficer"] >= 1 then
                DataLoc.FirstOfficer.Text = tbl["Roles"]["FirstOfficer"][1]
            end
        end
        if tbl["Roles"]["Captain"] then
            if #tbl["Roles"]["Captain"] >= 1 then
                DataLoc.Captain.Text = tbl["Roles"]["Captain"][1]
            end
        end
    end

    DataLoc.Departure.Text = tbl["DepartureTime"]
    DataLoc.Tracker.FromCode.Text = FromAirportCode
    DataLoc.Tracker.FromName.Text = tbl["Airport"]
    DataLoc.Tracker.DestCode.Text = tbl["DestinationCode"]
    DataLoc.Tracker.DestName.Text = tbl["Destination"]

    GUI.Background.Tracker.Inner.FromCode.Text = FromAirportCode
    GUI.Background.Tracker.Inner.DestCode.Text = tbl["DestinationCode"]
end


function IFEController:MonitorCoreFrames()
    for _,v in pairs(GUI.Background.Home:GetChildren()) do
        v.Selection.MouseButton1Click:Connect(function()
            -- Close previous frames
            for _,b in pairs(GUI.Background:GetChildren()) do
                if table.find(Pages, b.Name) then
                    b.Visible = false
                end
            end

            GUI.Background[v.Name].Visible = true
        end)
    end

    -- Monitor welcome page access
    GUI.WelcomePage.Btn.Inner.TextButton.MouseButton1Click:Connect(function()
        GUI.WelcomePage.Visible = false
        GUI.Background.Visible = true
        GUI.Background.Home.Visible = true
    end)

    GUI.Background.ButtonHolder.Exit.MouseButton1Click:Connect(function()
        GUI.Enabled = false
    end)

    -- Expand / slide movement
    GUI.Expand.Btn.MouseButton1Click:Connect(function()
        GUI.Expand.Visible = false
        GUI.Background:TweenPosition(UDim2.new(0.5, 0,0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 1)
    end)

    GUI.Background.ButtonHolder.Slide.MouseButton1Click:Connect(function()
        GUI.Background:TweenPosition(UDim2.new(-0.8, 0,0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 1)
        GUI.Expand.Visible = true
    end)


    GUI.Background.ButtonHolder.Home.MouseButton1Click:Connect(function()
        for _,b in pairs(GUI.Background:GetChildren()) do
            if table.find(Pages, b.Name) then
                b.Visible = false
            end
        end
        GUI.Background.Home.Visible = true
    end)
end


function IFEController:ManageTracker()
    local Frame = GUI.Background.Tracker.Inner.Progression

    
    -- Flight progression update
    while true do
        wait(2.5)
        local StartPosition = ProgressParts.Arrival.Position
        local EndPosition = ProgressParts.Origin.Position
        local DifferenceBetweenLocations = math.abs((EndPosition-StartPosition).Magnitude)
        local PlayerPosition = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Position

        local PlayersDistanceToArrival = math.abs((EndPosition - PlayerPosition).Magnitude)
        local CompletionMultiplier = PlayersDistanceToArrival / DifferenceBetweenLocations

        if CompletionMultiplier > 1 then
            CompletionMultiplier = 1
        end

        local NewSize = CompletionMultiplier * 1 -- 1 is the size scale for the full slide

        task.spawn(function()
            GUI.Background.Info.Data.Inner.Tracker.Progression.Move:TweenSize(
                UDim2.new(NewSize, 0, GUI.Background.Info.Data.Inner.Tracker.Progression.Move.Size.Y.Scale, 0),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Linear,
                1.25,
                true
            )
        end)

        Frame.Move:TweenSize(
	        UDim2.new(NewSize, 0, Frame.Move.Size.Y.Scale, 0),
	        Enum.EasingDirection.In,
	        Enum.EasingStyle.Linear,
	        1.25,
	        true
        )
    end
end


function IFEController:ManageInfoFrame()
    local Frame = GUI.Background["Info"].Data.Inner

    -- Altitude / Speed
    game:GetService("RunService").Heartbeat:Connect(function()
        local Part = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart",2)
        if Part then
            Frame.Altitude.Text = tostring(math.floor(Part.Position.Y))
        end

        local Speed = (game.Players.LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
        Frame.Speed.Text = tostring(math.floor(math.abs(Speed)))
    end)
end


function IFEController:ManageMusicFrame()
    local Frame = GUI.Background["Music"]
    local SongList = self.Services.Game.Infrastructure.IFEService:GetAllSongs()
    local SongsTemplate = Frame.Selection.Inner.MusicList.Template
    local isPlaying = false
    local CurrentSong = nil

    game.Workspace.Infrastructure.Audio.ChildAdded:Connect(function(child)
        if child.Name == "CoreMusic" and isPlaying then
            child.Volume = 0 -- 0.5 = On
        end
    end)

    local function pause()
        if Players.LocalPlayer.PlayerGui:FindFirstChild("IFEMusic") then
            local Audio = Players.LocalPlayer.PlayerGui:FindFirstChild("IFEMusic")
            if not Audio.IsPaused then
                if CurrentSong then
                    Frame.MusicBar.Inner.Pause.Visible = false
                    Frame.MusicBar.Inner.Play.Visible = true
                else
                    Frame.MusicBar.Inner.Artist.Text = "N/A"
                    Frame.MusicBar.Inner.SongName.Text = "No Song Playing"
                end

                Audio:Pause()

                if game.Workspace.Infrastructure.Audio:FindFirstChild("CoreMusic") then
                    game.Workspace.Infrastructure.Audio.CoreMusic.Volume = 0.5
                end
            end
        end
    end

    local function resume(set)
        if isPlaying then

            if game.Workspace.Infrastructure.Audio:FindFirstChild("CoreMusic") then
                print("core music off")
                game.Workspace.Infrastructure.Audio.CoreMusic.Volume = 0
            end

            Frame.MusicBar.Inner.Pause.Visible = true
            Frame.MusicBar.Inner.Play.Visible = false
            if not set then
                if Players.LocalPlayer.PlayerGui:FindFirstChild("IFEMusic") then
                    print("resumed ife")
                    local Audio = Players.LocalPlayer.PlayerGui:FindFirstChild("IFEMusic")
                    Audio:Resume()

                    if CurrentSong then
                        Frame.MusicBar.Inner.SongName.Text = CurrentSong.Name
                    end
                end
            end
        end
    end

    local function playSong(track)
        local Audio = nil
        if Players.LocalPlayer.PlayerGui:FindFirstChild("IFEMusic") then
            Audio = Players.LocalPlayer.PlayerGui.IFEMusic
        else
            Audio = Instance.new("Sound", Players.LocalPlayer.PlayerGui)
            Audio.Name = "IFEMusic"
        end

        if game.Workspace.Infrastructure.Audio:FindFirstChild("CoreMusic") then
            game.Workspace.Infrastructure.Audio.CoreMusic.Volume = 0
        end

        Audio.TimePosition = 0

        Audio.SoundId = "rbxassetid://"..tostring(track.ID)

        if not Audio.Loaded then
            Audio.Loaded:Wait()
        end

        CurrentSong = track
        Frame.MusicBar.Inner.SongName.Text = track.Name
        Frame.MusicBar.Inner.Artist.Text = track.Artist

        Audio.PlaybackSpeed = Audio.Pitch

        isPlaying = true
        resume(true)
        task.spawn(function()
            self.Controllers.AnnouncementController:SendEventNotification("Playing Next Song...")
        end)
        Audio:Play()
        Audio.Ended:Wait()
        CurrentSong = nil
        pause()
    end

    if SongList then
        for i,v in ipairs(SongList) do
            local New = SongsTemplate:Clone()
            New.Parent = SongsTemplate.Parent
            New.Name = tostring(i)
            New.Inner.SongName.Text = v.Name
            New.Inner.Artist.Text = tostring(v.Artist)
            New.Visible = true
            
            New.Inner.Detector.MouseButton1Click:Connect(function()
                for a,v in ipairs(SongList) do
                    if a == tonumber(New.Name) then -- this line needs checking
                        local NewPreviousSongTemp = Frame.PreviouslyPlayed.Inner.MusicList.Template
                        local NewTemp = NewPreviousSongTemp:Clone()
                        NewTemp.Parent = NewPreviousSongTemp.Parent
                        NewTemp.Name = tostring(RecentlyPlayedNumber)
                        RecentlyPlayedNumber += 1
                        NewTemp.Inner.SongName.Text = v.Name
                        NewTemp.Inner.Artist.Text = tostring(v.Artist)
                        NewTemp.Visible = true
                        playSong(v)
                        break
                    end
                end
            end)
        end

        local CellSize = SongsTemplate.Parent.UIGridLayout.CellSize.Y.Offset
        local PaddingSize = SongsTemplate.Parent.UIGridLayout.CellPadding.Y.Offset
        local SeperationSize = CellSize + PaddingSize
        SongsTemplate.Parent.CanvasSize = UDim2.new(0, 0, 0, SeperationSize * (#SongList))
    end

    local function pausePlay(option)
        if option == "Play" then
            if Frame.CustomMusic.Inner.Input.InnerInput.Input.Text == "" or not tonumber(Frame.CustomMusic.Inner.Input.InnerInput.Input.Text) then
                resume()
            else
                local ID = Frame.CustomMusic.Inner.Input.InnerInput.Input.Text
                if tonumber(ID) then
                    Frame.CustomMusic.Inner.Input.InnerInput.Input.Text = "Insert Music ID..."
                    playSong({
                        Name = "Custom Song",
                        Artist = "N/A",
                        ID = tonumber(ID)
                    })
                end
            end
        else
            pause()
            task.spawn(function()
                self.Controllers.AnnouncementController:SendEventNotification("IFE Music Paused, Core Music Resumed")
            end)
        end
    end

    Frame.MusicBar.Inner.Pause.MouseButton1Click:Connect(function()
        pausePlay("Pause")
    end)
    Frame.MusicBar.Inner.Play.MouseButton1Click:Connect(function()
        pausePlay("Play")
    end)
end


function IFEController:ManageGameFrame()
    local Frame = GUI.Background["Games"]
    for _,v in pairs(Frame:GetChildren()) do
        if table.find(Games, v.Name) then
            local Debounce = false
            v.Inner.BtnDetection.MouseButton1Click:Connect(function()
                if not Debounce then
                    Debounce = true
                    self.Services.Game.Infrastructure.IFEService:RequestGame(v.Name)
                    task.wait(2)
                    Debounce = false
                end
            end)
        end
    end
end


function IFEController:ManageCameraSystem()
    local Frame = GUI.Background["Info"]
    local updateCamera

    if CameraInit then
        return
    end
    
    CameraInit = true


    -- fix so its not reinitialised every time ife opens
    -- only re-init
    GUI.CameraExit.Exit.MouseButton1Click:Connect(function()
        self.Controllers.InitializeController:PhotoMode(false)
        GUI.CameraExit.Visible = false
        GUI.Background.Visible = true

        updateCamera:Disconnect()

        local Camera = game.Workspace.CurrentCamera
		local humanoid = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			Camera.CameraSubject = humanoid
            Camera.CameraType = Enum.CameraType.Custom
		end
    end)

    local function setPlayerCamera(cam_name)
        local Camera = game.Workspace.CurrentCamera
        local FocusPart = GUI.IFELocation.Value.Cameras[cam_name]
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CameraSubject = FocusPart

        updateCamera = game:GetService("RunService").RenderStepped:Connect(function()
            Camera.CFrame = FocusPart.CFrame
        end)

        self.Controllers.InitializeController:PhotoMode(true)
        GUI.CameraExit.Visible = true
        GUI.Background.Visible = false
        GUI.Enabled = true
    end

    for _,v in pairs(Frame.Cameras.Inner:GetChildren()) do
        if v:IsA('Frame') then
            v.Inner.Button.MouseButton1Click:Connect(function()
                if GUI.IFELocation.Value.Cameras:FindFirstChild(v.Name) then
                    setPlayerCamera(v.Name)
                end
            end)
        end
    end
end


return IFEController