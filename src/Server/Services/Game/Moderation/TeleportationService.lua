-- Teleportation Service
-- Jack_AviationRBX
-- August 31, 2021

--[[

TeleportationService allows players and parts to be moved to different locations on the map.
This is useful for game moderation, and for systems which require movement, such as the luggage system.

--]]

local RESTRICTION_REQUIREMENT = "Admin"
local TELEPORTATION_ZONES = game.Workspace:WaitForChild("Infrastructure")["Teleportation"]


local TeleportationService = {Client = {}}


function TeleportationService:MovePlayerToPart(player, part)
	if player.Character:FindFirstChild("HumanoidRootPart") then
		local offset = CFrame.new(0,2.5,0)
		player.Character.HumanoidRootPart.CFrame = part.CFrame * offset
		return true
	end
end


function TeleportationService.Client:TransportPlayerToZone(player, partName)
	if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, RESTRICTION_REQUIREMENT) then
		if player.Character:FindFirstChild("HumanoidRootPart") then
			local part = TELEPORTATION_ZONES[partName]
			local offset = CFrame.new(0,2.5,0)
			player.Character.HumanoidRootPart.CFrame = part.CFrame * offset
			return true
		end
	else
		self.Server.Services.Data.ModerationService:IssueInfraction(player.UserId, "Ban", "Teleportation event manipulation", "ZeuraCore Auto", "perm")
	end
end


function TeleportationService.Client:GetZoneNames(player)
	if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, RESTRICTION_REQUIREMENT) then
		local Names = {}
		for _,v in pairs(game.Workspace.Infrastructure.Teleportation:GetChildren()) do
			table.insert(Names, v.Name)
		end
		return Names
	end
end


function TeleportationService:MoveModelToPosition(model, location)
	model:MoveTo(location)
end


return TeleportationService