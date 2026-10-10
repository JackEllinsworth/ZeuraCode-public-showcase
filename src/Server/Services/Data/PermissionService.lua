-- Permission Service
-- Jack_AviationRBX
-- August 29, 2021

--[[

PermissionService allows simplified permissions in a centralized location, which can be used to access certain staff privilidges.
This is also necessary to ensure only HR-Restricted GUI's are only functional to HR's and not exploiters.

--]]


local STORE_NAME = "PermissionStore"
local EVENT_PERMISSION = "Permission"
local BETA_PERMISSION_NAME = "Beta"


local PermissionService = {Client = {}}


function PermissionService:Start()

	-- Create Cache Store
    self.Services.Data.CacheService.createStore(STORE_NAME, {
        ["RowSettings"] = {
            ["permission"] = 0,
			["beta"] = false
        },
        ["ListenerActive"] = false
    })

end


function PermissionService:Init()
	self:RegisterClientEvent(EVENT_PERMISSION)
end


function PermissionService:HasPermission(userId, permName)
	local RequiredPermLevel = self:GetLevelByName(permName)
	local CurrentPermLevel = self.Services.Data.CacheService:GetRow(STORE_NAME, userId, "permission")

	if CurrentPermLevel then
		if CurrentPermLevel >= RequiredPermLevel then
			return true
		else
			return false
		end
	end
end


function PermissionService:IsBeta(userId)
	local BetaStatus = self.Services.Data.CacheService:GetRow(STORE_NAME, userId, "beta")
	if BetaStatus then
		return true
	else
		return false
	end
end


function PermissionService:GetLevelByName(permName)
    return self.Modules.Config.Permissions[permName].permLevel
end


function PermissionService:GetNameByLevel(permLevel)
    for permName,tbl in pairs(self.Modules.Config.Permissions) do
        if tbl["permLevel"] == permLevel then
            return permName
        end
    end
end


function PermissionService:UpdatePermission(player, permName)
	if not self.Services.Data.CacheService:LocatorExists(STORE_NAME, player.UserId) then
        self.Services.Data.CacheService:CreateLocator(STORE_NAME, player.UserId)
    end
	
    self.Services.Data.CacheService:ReplaceRow(STORE_NAME, player.UserId, "permission", self:GetLevelByName(permName))
    self:FireClient(EVENT_PERMISSION, player, permName)
end


function PermissionService:GrantBetaStatus(player)
	if not self.Services.Data.CacheService:LocatorExists(STORE_NAME, player.UserId) then
        self.Services.Data.CacheService:CreateLocator(STORE_NAME, player.UserId)
    end
	
    self.Services.Data.CacheService:ReplaceRow(STORE_NAME, player.UserId, "beta", true)
end


function PermissionService:FetchPlayersPermissionName(player)
	local CurrentPermLevel = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "permission")
	return self:GetNameByLevel(CurrentPermLevel)
end


function PermissionService:CalculatePermissions(player)
    local CurrentPermission = self.Services.Data.ProfileService:GetAsync(player.UserId, "permission")
	local GroupRank = self.Services.Data.ProfileService:GetAsync(player.UserId, "rankId")
	local CurrentLevel = 0
	
	if CurrentPermission ~= "normal" and CurrentPermission ~= nil then
		if self.Modules.Config.Permissions[CurrentPermission] then
			CurrentLevel = self.Modules.Config.Permissions[CurrentPermission].permLevel
		elseif CurrentPermission  == BETA_PERMISSION_NAME then
			self:GrantBetaStatus(player)
			CurrentLevel = self.Modules.Config.Permissions[self.Modules.Config.BetaDefaultPermission].permLevel
		end
	end
	
	for _,tbl in pairs(self.Modules.Config.Permissions) do
		local GroupBounds = tbl.groupBounds
		
		for _,v in ipairs(GroupBounds) do
			local LowerBound = v[1]
			local UpperBound = v[2]
			
			if GroupRank >= LowerBound and GroupRank <= UpperBound then
				if tbl.permLevel > CurrentLevel then
					CurrentLevel = tbl.permLevel
				end
			end
		end
	end

	if CurrentLevel >= 0 then
		self:UpdatePermission(player, self:GetNameByLevel(CurrentLevel))
	end
end


return PermissionService