-- Lanyard Service
-- Jack_AviationRBX
-- July 22, 2022

--[[

Lanyard Service ensures all staff members get a personalised lanyard to themselves - showing identification.

--]]

-- Proper name modifications
local RoleAppearenceChanges = {
    ["Group Holder"] = "Chief Executive Officer",
}
local CustomColours = {
    [171789275] = {
        [1] = Color3.fromRGB(108, 196, 157),
        [2] = Color3.fromRGB(73, 115, 138),
        [3] = Color3.fromRGB(145,73,147),
        ["Tag"] = "Lead Programmer"
    }
}

local Players = game:GetService("Players")


local LanyardService = {Client = {}}


function LanyardService:IssueLanyard(player)

    if player.Character:FindFirstChild("Lanyard") then
        return
    end

    -- Lanyard clone
    local Lanyard = game.ServerStorage.Models.Lanyard:Clone()
    local LanyardInterface = Lanyard.Info.SurfaceGui.Frame

    -- Image retrival
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local imageLabel, isReady = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)

    -- Update Name & Role
    LanyardInterface.Username.Text = player.Name

    -- Fetch role
    local RoleName = player:GetRoleInGroup(self.Modules.Config.GroupInfo.GroupId)
    if RoleAppearenceChanges[RoleName] then
        RoleName = RoleAppearenceChanges[RoleName]
    end

    LanyardInterface.Role.Text = RoleName

    -- Update image
    if isReady and imageLabel then
        LanyardInterface.ImageLabel.Image = imageLabel
    end

    if CustomColours[player.UserId] then
        LanyardInterface.UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,CustomColours[player.UserId][1]),
            ColorSequenceKeypoint.new(0.5,CustomColours[player.UserId][2]),
            ColorSequenceKeypoint.new(1,CustomColours[player.UserId][3])
        }
        LanyardInterface.AdditionalRole.Text = CustomColours[player.UserId]["Tag"]
        LanyardInterface.AdditionalRole.Visible = true
    end

    player.Character:WaitForChild("Humanoid",5):AddAccessory(Lanyard)
end


return LanyardService