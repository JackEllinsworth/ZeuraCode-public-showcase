local GuiService = game:GetService("GuiService")
-- Power Point Service
-- Jack_AviationRBX
-- July 27, 2022


local PowerPoints = game.Workspace.Infrastructure:FindFirstChild("PowerPoints")
local PowerPointService = {Client = {}}


function PowerPointService:Start()
    warn("[PowerPointService] All powerpoints are now activated & being monitored.")
end


function PowerPointService.Client:Clear(player, powerpoint)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        local Powerpoint = PowerPoints:FindFirstChild(tostring(powerpoint))
        Powerpoint.CurrentRole.Value = ""
        Powerpoint.CurrentSlide.Value = 0
        Powerpoint.Screen.SCREEN.Decal.Transparency = 1
        player.PlayerGui:FindFirstChild("PowerPoint").Selection.Visible = true
        player.PlayerGui:FindFirstChild("PowerPoint").Change.Visible = false
    end
end



function PowerPointService.Client:GoBack(player, powerpoint)
    print("bac")
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        local Powerpoint = PowerPoints:FindFirstChild(tostring(powerpoint))
        if Powerpoint.Parent.Config[Powerpoint.CurrentRole.Value]:FindFirstChild(tostring(Powerpoint.CurrentSlide.Value - 1)) then
            Powerpoint.CurrentSlide.Value = Powerpoint.CurrentSlide.Value - 1
            Powerpoint.Screen.SCREEN.Decal.Texture = "rbxassetid://"..Powerpoint.Parent.Config[Powerpoint.CurrentRole.Value][tostring(Powerpoint.CurrentSlide.Value)].Value
            Powerpoint.Screen.SCREEN.Decal.Transparency = 0
        end
    end
end

function PowerPointService.Client:GoForward(player, powerpoint)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        local Powerpoint = PowerPoints:FindFirstChild(tostring(powerpoint))
        local Role = Powerpoint.CurrentRole.Value
        if Powerpoint.Parent.Config[Role]:FindFirstChild(tostring(Powerpoint.CurrentSlide.Value + 1)) then
            Powerpoint.CurrentSlide.Value = Powerpoint.CurrentSlide.Value + 1
            Powerpoint.Screen.SCREEN.Decal.Texture = "rbxassetid://"..Powerpoint.Parent.Config[Powerpoint.CurrentRole.Value][tostring(Powerpoint.CurrentSlide.Value)].Value
            Powerpoint.Screen.SCREEN.Decal.Transparency = 0
        end
    end
end

function PowerPointService.Client:RequestSelection(player, powerpoint, role)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        local Powerpoint = PowerPoints:FindFirstChild(powerpoint)
        Powerpoint.CurrentRole.Value = role
        Powerpoint.CurrentSlide.Value = 1
        player.PlayerGui:FindFirstChild("PowerPoint").Change.Visible = true
        player.PlayerGui:FindFirstChild("PowerPoint").Selection.Visible = false
        player.PlayerGui:FindFirstChild("PowerPoint").Attachment.Value = powerpoint
        Powerpoint.Screen.SCREEN.Decal.Texture = "rbxassetid://"..Powerpoint.Parent.Config[role][tostring(Powerpoint.CurrentSlide.Value)].Value
        Powerpoint.Screen.SCREEN.Decal.Transparency = 0
    end
end


function PowerPointService.Client:ClickedDetector(player, powerpoint)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        if player.PlayerGui:FindFirstChild("PowerPoint").Attachment.Value == 0 then
            player.PlayerGui:FindFirstChild("PowerPoint").Enabled = true
            player.PlayerGui:FindFirstChild("PowerPoint").Selection.Visible = true
            player.PlayerGui:FindFirstChild("PowerPoint").Change.Visible = false
            player.PlayerGui:FindFirstChild("PowerPoint").Attachment.Value = tonumber(powerpoint)
        else
            player.PlayerGui:FindFirstChild("PowerPoint").Attachment.Value = 0
            player.PlayerGui:FindFirstChild("PowerPoint").Enabled = false
            player.PlayerGui:FindFirstChild("PowerPoint").Selection.Visible = false
            player.PlayerGui:FindFirstChild("PowerPoint").Change.Visible = false
        end
    end
end



return PowerPointService