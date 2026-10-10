-- Moderation Service
-- Jack_AviationRBX
-- August 29, 2021

--[[

Moderation Service allows simplicity in managing players in the game.
This module provides the ability to ban (for a set time), kick and warn players.
Infractions can also be viewed and removed, using external API's.

--]]


local Players = game:GetService("Players")
local COLOURS = {
	["Ban"] = tonumber(0xFF8383),
	["Kick"] = tonumber(0xFF9C59),
	["Warn"] = tonumber(0xFFF279),
	["Removal"] = tonumber(0x97FF6E),
}


local ModerationService = {}


function ModerationService:IsBanned(userId)
	local Infractions = self:GetInfractions(userId)

	if Infractions and #Infractions >= 1 then
		local Bans = ModerationService:SortInfractionsByType(Infractions, "Ban")
		
		for _,infraction in ipairs(Bans) do
			if infraction.duration == "perm" then
				return true, infraction
			else
				if (tonumber(infraction.given) + tonumber(infraction.duration)) > os.time() then
					return true, infraction
				end
			end
		end
	end
end


function ModerationService:SortInfractionsByType(infractions, _type)
	local Sorted = {}

	for _, v in pairs(infractions) do
		if v["type"] == _type then
			table.insert(Sorted, v)
		end
	end
	
	return Sorted
end


function ModerationService:IssueInfraction(userId, _type, reason, moderatorId, timePeriod)
	local Infraction = {
		["type"] = _type,
		["given"] = os.time(),
		["reason"] = reason,
		["moderator"] = moderatorId,
	}
	local DaysDisplay = ""
	local ModeratorName = moderatorId

	if tonumber(moderatorId) then
		ModeratorName = Players:GetNameFromUserIdAsync(moderatorId)
	end

	if _type == "Ban" then
		local SecondsInDay = 86400

		local duration
		if timePeriod == "perm" then
			duration = "perm"
			DaysDisplay = "(Permanent)"
		else
			if tonumber(timePeriod) then
				duration = tonumber(timePeriod) * SecondsInDay
				DaysDisplay = "("..tostring(timePeriod).. " day(s)"..")"
			else
				return
			end
		end
		
		Infraction["duration"] = duration
	end
	
	local CurrentInfractions = self.Shared.TableUtil.Copy(self:GetInfractions(userId))
	table.insert(CurrentInfractions, Infraction)

	self.Services.Data.ProfileService:UpdateAsync(userId, "infractions", CurrentInfractions)

	local Player = Players:GetPlayerByUserId(userId)
	local Username

	if Player then
		Username = Player.Name

		if _type == "Ban" then
			local DisplayedDuration
			if timePeriod == "perm" then
				DisplayedDuration = "Permanent"
			else
				DisplayedDuration = tostring(timePeriod).. " day(s)"
			end

			Player:Kick("[ModerationService] ->\nYou're currently banned from Zeura's games.\nDuration: "..tostring(DisplayedDuration).."\nReason: "..reason)
		elseif _type == "Kick" then
			Player:Kick("[ModerationService] ->\nYou've been kicked from Zeura's games.\nReason: "..reason)
		elseif _type == "Warn" then
			task.spawn(function()
				Player.PlayerGui["Warning"].InnerFrame.Reason.Text = reason
				Player.PlayerGui["Warning"].Enabled = true
				self.Services.Game.Moderation.PlayerControlService:DisableMovement(Player)
				wait(20)
				Player.PlayerGui["Warning"].Enabled = false
				self.Services.Game.Moderation.PlayerControlService:EnableMovement(Player)
			end)
		end
	else
		Username = Players:GetNameFromUserIdAsync(userId)
	end
	
	self.Services.Data.DataService:SendWebhook("New Infraction", "", COLOURS[_type], {
		{"Username", Username},
		{"UserId", userId},
		{"Action", _type.." "..DaysDisplay},
		{"Reason", reason},
		{"Moderator", ModeratorName}
	}, "Moderation", false)
	
	return true, Infraction
end


function ModerationService:GetInfractions(userId)
	local Success,_ = self.Services.Data.ProfileService:LoadAsync(userId)
	local Infractions
	if Success then
		Infractions = self.Services.Data.ProfileService:GetAsync(userId, "infractions")
	else
		Infractions = {}
	end

	return Infractions
end


function ModerationService:RevokeInfraction(userId, index)
	local CurrentInfractions = ModerationService:GetInfractions(userId)

	local FormattedReplacement = {}
	local RemovalInfraction

	for i,v in ipairs(CurrentInfractions) do
		if i ~= index then
			table.insert(FormattedReplacement, v)
		else
			RemovalInfraction = v
		end
	end
	
	self.Services.Data.ProfileService:UpdateAsync(userId, "infractions", FormattedReplacement)
	local Success = self.Services.Data.ProfileService:Save(userId)

	local ModeratorName = RemovalInfraction["moderator"]

	if tonumber(ModeratorName) then
		ModeratorName = Players:GetNameFromUserIdAsync(ModeratorName)
	end

	if Success then
		self.Services.Data.DataService:SendWebhook("Infraction Removed", "", COLOURS["Removal"], {
			{"Username", Players:GetNameFromUserIdAsync(userId)},
			{"UserId", userId},
			{"Action", RemovalInfraction["type"].. " Removal"},
			{"Reason", RemovalInfraction["reason"]},
			{"Moderator", ModeratorName}
		}, "Moderation", false)
	
		return true
	end
end


return ModerationService