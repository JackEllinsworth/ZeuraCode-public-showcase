-- Music Service
-- Jack_AviationRBX
-- July 21, 2022


local AUDIO = game.Workspace.Infrastructure.Audio
local AUTO_PLAY_ON_JOIN = true
local EVENT_MUSIC = "Music"

local TweenService = game:GetService("TweenService")

local AutoPlayEnabled = false
local MusicInstance

local MusicList = {}
local CurrentQueue = {}
local CurrentlyPlaying = false


local MusicService = {Client = {}}


function MusicService:Init()
    self:RegisterClientEvent(EVENT_MUSIC)
end


function MusicService:Start()
    -- Fetch music list
    MusicList = self.Modules.MusicList

    -- Create audio channels
    MusicInstance = Instance.new("Sound", AUDIO)
    MusicInstance.Volume = 0.5
    MusicInstance.Name = "CoreMusic"

    -- Fetch additional music from external sources... (discord)

    -- Start auto play
    if AUTO_PLAY_ON_JOIN then
        self:AutoPlay()
    end
end


function MusicService:AutoPlay()
    AutoPlayEnabled = true
    CurrentQueue = {}

    while AutoPlayEnabled do
        CurrentlyPlaying = true

        local MusicToPlay = self.Shared.TableUtil.Copy(MusicList)
        for _,_ in pairs(MusicToPlay) do
            local RandomItem = MusicToPlay[math.random(1, #MusicToPlay)]
            table.remove(MusicToPlay, table.find(MusicToPlay, RandomItem))
            table.insert(MusicToPlay, 1, RandomItem)
        end

        CurrentQueue = MusicToPlay
        self:PlayQueue(true)
        
    end
end


function MusicService:IsAutoPlaying()
    return AutoPlayEnabled
end

function MusicService:StopAutoPlay()
    AutoPlayEnabled = false
    MusicInstance:Destroy()

    MusicInstance = Instance.new("Sound", AUDIO)
    MusicInstance.Name = "CoreMusic"

    self:ClearQueue()

    self:FireAllClients(EVENT_MUSIC, "AutoPlayDisabled")
    self:FireAllClients(EVENT_MUSIC, "Paused")
    CurrentlyPlaying = false
end


function MusicService:PlayQueue(autoMode)
    CurrentlyPlaying = true

    while true do
        if #CurrentQueue > 0 then
            if autoMode then
                self:FireAllClients(EVENT_MUSIC, "AutoPlayEnabled")
            end

			MusicInstance.TimePosition = 0
			local track = CurrentQueue[1]

            MusicInstance.SoundId = "rbxassetid://"..tostring(track.ID)

            if not MusicInstance.Loaded then
				MusicInstance.Loaded:Wait()
			end

            MusicInstance.PlaybackSpeed = MusicInstance.Pitch
            CurrentlyPlaying = true

            print("[MusicService] Now playing "..CurrentQueue[1]["Name"])
            self:FireAllClients(EVENT_MUSIC, "Resumed")

            table.remove(CurrentQueue, 1)
            self:FireAllClients(EVENT_MUSIC, "Queue", CurrentQueue)

			MusicInstance:Play()
			MusicInstance.Ended:Wait()

            if autoMode and not AutoPlayEnabled then
                CurrentlyPlaying = false
                self:FireAllClients(EVENT_MUSIC, "Paused")
                break
            end
        else
            CurrentlyPlaying = false
            self:FireAllClients(EVENT_MUSIC, "Queue", CurrentQueue)
            self:FireAllClients(EVENT_MUSIC, "Paused")
            break
        end
    end
end


function MusicService:GetQueue()
    return CurrentQueue
end


function MusicService:GetAllSongs()
    return MusicList
end


function MusicService:SkipCurrentSong(cancel)
    MusicInstance.TimePosition = MusicInstance.TimeLength

    if not cancel then
        self:FireAllClients(EVENT_MUSIC, "Queue", CurrentQueue)
    end
end


function MusicService:ClearQueue()
    CurrentQueue = {}
	self:FireAllClients(EVENT_MUSIC, "Queue", CurrentQueue)
end


function MusicService:AddToQueue(id)
    local Track = MusicList[id]
    if Track then
        table.insert(CurrentQueue, Track)
        self:FireAllClients(EVENT_MUSIC, "Queue", CurrentQueue)
    end
end

function MusicService:IsPaused()
	if MusicInstance.IsPaused then
		return true
	else
		return false
	end
end

function MusicService:RemoveFromQueue(id)
    table.remove(CurrentQueue, id)
    self:FireAllClients(EVENT_MUSIC, "Queue", CurrentQueue)
end


function MusicService:Pause()
    if not self:IsPaused() then
        local Tween = TweenService:Create(MusicInstance,TweenInfo.new(2),{Volume = 0})
        Tween:Play()
        Tween.Completed:Connect(function(playbackState)
            MusicInstance:Pause()
            MusicInstance.Volume = 0.5
            self:FireAllClients(EVENT_MUSIC, "Music paused")
        end)
    end
end


function MusicService:Resume()
    if self:IsPaused() then
        if not AutoPlayEnabled and not CurrentlyPlaying then
            self:PlayQueue()
        end

        MusicInstance.Volume = 0
        MusicInstance:Resume()
        
        local Tween = TweenService:Create(MusicInstance,TweenInfo.new(2),{Volume = 0.5})
        Tween:Play()

        Tween.Completed:Connect(function(playbackState)
            self:FireAllClients(EVENT_MUSIC, "Resumed")
        end)
    end
end


return MusicService