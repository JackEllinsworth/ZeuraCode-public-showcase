-- Leaderboard Controller
-- Jack_AviationRBX
-- September 7, 2021

--[[

Leaderboard Controller manages the local clients leaderboard using various functions, and making use of a client event to recieve updates.
Instead of checking for any changes, it completely re-creates the leaderboard on a player join/leave.
For efficiency, this could be updated in the future to prevent client memory being wasted.

--]]


local EXCLUSION_LIST = {"Staff", "Passenger", "UIGridLayout", "Template"}
local GUI 
local TWEEN_VISIBLE = UDim2.new(0.965, -185,0, 5)
local TWEEN_INVISIBLE = UDim2.new(0.978, 45,0, 5)
local IsOpen = true

local StaffIndex = 0
local PassengerIndex = 1

local LeaderboardController = {}


function LeaderboardController:Activate(Gui)
    GUI = Gui
end


function LeaderboardController:Start()
    self:MonitorChanges()
    self:MonitorUserInput()
end


function LeaderboardController:ForceClose()
    local SelectedPosition = TWEEN_INVISIBLE
    local EnumOption = Enum.EasingDirection.Out
    IsOpen = false
    GUI["Scroll"]:TweenPosition(
        SelectedPosition,
        EnumOption,
        Enum.EasingStyle.Linear,
        0.35,
        true
    )
end


function LeaderboardController:ForceOpen()
    local SelectedPosition = TWEEN_VISIBLE
    local EnumOption = Enum.EasingDirection.In
    IsOpen = true
    GUI["Scroll"]:TweenPosition(
        SelectedPosition,
        EnumOption,
        Enum.EasingStyle.Linear,
        0.35,
        true
    )
end


function LeaderboardController:MonitorUserInput()
    game:GetService("UserInputService").InputBegan:Connect(function(input, Processed)
        if input.KeyCode == Enum.KeyCode.Tab and not Processed then
            local SelectedPosition = nil
            local EnumOption = nil

            if IsOpen == true then
                SelectedPosition = TWEEN_INVISIBLE
                EnumOption = Enum.EasingDirection.Out
                IsOpen = false
            else
                SelectedPosition = TWEEN_VISIBLE
                EnumOption = Enum.EasingDirection.In
                IsOpen = true
            end

            GUI["Scroll"]:TweenPosition(
                SelectedPosition,
                EnumOption,
                Enum.EasingStyle.Linear,
                0.35,
                true
            )
        end
    end)
end

function LeaderboardController:MonitorChanges()
    self.Services.Game.Core.LeaderboardService.Leaderboard:Connect(function(_type, data, teamOrder)
        if GUI then
            if _type == "Add" then
                self:AddAndRemovePrevious(data, teamOrder)
            elseif _type == "Remove" then
                self:Remove(data, teamOrder)
            else
                self:Reset(data, teamOrder)
            end
        end
    end)
end


function LeaderboardController:Remove(data)
    local IndexRemoved = 0

    for _,v in pairs(GUI.Scroll:GetChildren()) do
        if v.Name == tostring(data["userId"]) then
            IndexRemoved = v.LayoutOrder
            v:Destroy()
        end
    end

    if IndexRemoved > 0 then
        if IndexRemoved > StaffIndex then
            PassengerIndex -= 1
        else
            StaffIndex -= 1
        end

        for _,v in pairs(GUI.Scroll:GetChildren()) do
            if v:IsA("Frame") then
                if v.LayoutOrder > IndexRemoved then
                    v.LayoutOrder = v.LayoutOrder - 1
                end
            end
        end
    end
end


function LeaderboardController:AddAndRemovePrevious(data, teamOrder)
    -- Remove previous if it exists

    self:Remove({
        ["userId"] = data["userId"]
    })

    if data["teamType"] == "Passenger" then
        PassengerIndex += 1
        local AddedPlayer = GUI.Scroll.Template:Clone()
        AddedPlayer.Parent = GUI.Scroll.Template.Parent
        AddedPlayer.Name = tostring(data["userId"])
        AddedPlayer.Username.TextLabel.Text = data["username"]
        AddedPlayer.Role.TextLabel.Text = data["groupRole"]
        AddedPlayer.Visible = true
        AddedPlayer.LayoutOrder = PassengerIndex
    elseif data["teamType"] == "Staff" then
        -- Move passengers up by 1 index.
        for _,v in pairs(GUI.Scroll:GetChildren()) do
            if v:IsA("Frame") and v.LayoutOrder > StaffIndex then
                v.LayoutOrder = v.LayoutOrder + 1
            end
        end
        PassengerIndex += 1

        -- Insert staff into created spot
        StaffIndex += 1
        local AddedPlayer = GUI.Scroll.Template:Clone()
        AddedPlayer.Parent = GUI.Scroll.Template.Parent
        AddedPlayer.Name = tostring(data["userId"])
        AddedPlayer.Username.TextLabel.Text = data["username"]
        AddedPlayer.Role.TextLabel.Text = data["groupRole"]
        AddedPlayer.Visible = true
        AddedPlayer.LayoutOrder = StaffIndex
    end

    local CellSize = GUI.Scroll.UIGridLayout.CellSize.Y.Offset  -- Including padding
    local PaddingSize = GUI.Scroll.UIGridLayout.CellPadding.Y.Offset
    local SeperationSize = CellSize + PaddingSize
    GUI.Scroll.CanvasSize = UDim2.new(0, 0, 0, SeperationSize * (PassengerIndex + #teamOrder))
end


function LeaderboardController:Reset(newLeaderboard, teamOrder)
    GUI.Enabled = true

    -- Remove current frames
    for _,v in pairs(GUI.Scroll:GetChildren()) do
        if not table.find(EXCLUSION_LIST, v.Name) and v:IsA("Frame") then
            v:Destroy()
        end
    end

    -- Add new frames from full leaderboard list
    local TopAmount = 1
    local TeamAmount = #teamOrder

    -- Complete staff search
    for _,v in ipairs(teamOrder) do
        TopAmount += 1

        for _,b in ipairs(newLeaderboard[v]) do
            if b.teamType == "Staff" then
                local AddedPlayer = GUI.Scroll.Template:Clone()
                AddedPlayer.Parent = GUI.Scroll.Template.Parent
                AddedPlayer.Name = tostring(b["userId"])
                AddedPlayer.Username.TextLabel.Text = b["username"]
                AddedPlayer.Role.TextLabel.Text = b["groupRole"]
                AddedPlayer.Visible = true
                AddedPlayer.LayoutOrder = TopAmount
            end
        end
    end

    StaffIndex = TopAmount

    TopAmount += 1
    GUI.Scroll.Passenger.LayoutOrder = TopAmount

    -- Add passengers
    for _,v in ipairs(teamOrder) do
        TopAmount += 1

        for _,b in ipairs(newLeaderboard[v]) do
            if b.teamType == "Passenger" then
                local AddedPlayer = GUI.Scroll.Template:Clone()
                AddedPlayer.Parent = GUI.Scroll.Template.Parent
                AddedPlayer.Name = tostring(b["userId"])
                AddedPlayer.Username.TextLabel.Text = b["username"]
                AddedPlayer.Role.TextLabel.Text = b["groupRole"]
                AddedPlayer.Visible = true
                AddedPlayer.LayoutOrder = TopAmount
            end
        end
    end


    PassengerIndex = TopAmount

    local CellSize = GUI.Scroll.UIGridLayout.CellSize.Y.Offset  -- Including padding
    local PaddingSize = GUI.Scroll.UIGridLayout.CellPadding.Y.Offset
    local SeperationSize = CellSize + PaddingSize
    GUI.Scroll.CanvasSize = UDim2.new(0, 0, 0, SeperationSize * (TopAmount + TeamAmount))
end


return LeaderboardController