-- Profile Service
-- Jack_AviationRBX
-- October 10, 2021

--[[

Profile Service provides a very user friendly way of dealing with players data.
The functions compatible with this module are:

UpdateAsync(userId, key, value)
GetAsync(userId, key)
IncrementAsync(userId, key, amount)
SetMetaDataAsync(userId, metaDataChanges)
GetMetaDataAsync(userId, metaDataType)
LoadAsync(userId)
Save(userId)

If setup in the preferable way, this module will only make 2 requests per user,
unless manual saves are put into place (rarely).

The times these requests occur is on player join, and player leave (or on server close.)
--]]

local Players = game:GetService("Players")

local MAX_LOAD_ATTEMPTS = 2
local MAX_SAVE_ATTEMPTS = 2
local KICK_ON_LOAD_FAIL = false
local KICK_MESSAGE = "[ProfileService] ZeuraCore couldn't resolve your data. Please try again later."

local ProfileMetaData = {}
local Profiles = {}
local SavesInProgress = {}

local StoreTypes = {}
local SavingStores = {}

local AutomaticKeys = {}

local SaveOnServerClose = false
local SaveOnPlayerLeave = false
local SavingEnabled = true

local ServerIsClosing = false


local ProfileService = {Client = {}}


function ProfileService:UpdateAsync(userId, key, value)
    if Profiles[userId] then
        if self:GetMetaDataAsync(userId, "_can_modify") then
            Profiles[userId][key] = value
        end
    end
end


function ProfileService:GetAsync(userId, key)
    if Profiles[userId] then
        return Profiles[userId][key]
    end
end


function ProfileService:GetProfileAsync(userId)
    if Profiles[userId] then
        return Profiles[userId]
    end
end

function ProfileService:CreateProfileAsync(userId, profile)
    Profiles[userId] = profile
end


function ProfileService:IncrementAsync(userId, key, value)
    if Profiles[userId] and tonumber(value) then
        if self:GetMetaDataAsync(userId, "_can_modify") then
            Profiles[userId][key] += value
        end
    end
end


function ProfileService:_GetStoresAsync(userId, stores)
    local DataInStores = {}

    for storeName, storeTbl in pairs(StoreTypes) do
        if table.find(stores, storeName) then
            for key,_ in pairs(storeTbl) do
                DataInStores[key] = self:GetAsync(userId, key)
            end
        end
    end

    return DataInStores
end


function ProfileService:SetMetaDataAsync(userId, changes)
    if not ProfileMetaData[userId] then
        ProfileMetaData[userId] = {}
    end

    for key, value in pairs(changes) do
        ProfileMetaData[userId][key] = value
    end
end


function ProfileService:GetMetaDataAsync(userId, key)
    if ProfileMetaData[userId] then
        return ProfileMetaData[userId][key]
    end
end


function ProfileService:SetStoreTypes(storeTypes)
    StoreTypes = storeTypes
end


function ProfileService:SetSaveStores(stores)
    SavingStores = stores
end


function ProfileService:SetAutomaticKeys(keyTbl)
    AutomaticKeys = keyTbl
end


function ProfileService:SaveOnServerClose(bool)
    SaveOnServerClose = bool
end


function ProfileService:SaveOnPlayerLeave(bool)
    SaveOnPlayerLeave = bool
end


function ProfileService:_ParseProfileTable(userId, profileTbl)
    for key, value in pairs(AutomaticKeys) do
        if profileTbl[key] then
            if value == "group_rank" then
                local Player = Players:GetPlayerByUserId(userId)
                if Player then
                    profileTbl[key] = Player:GetRankInGroup(self.Modules.Config.GroupInfo.GroupId)
                end
            elseif value == "user_id" then
                profileTbl[key] = userId
            end
        end
    end

    return profileTbl
end


function ProfileService:_GetDefaultKeys()
    local Keys = {}

    for _, storeTbl in pairs(StoreTypes) do
        for key, value in pairs(storeTbl) do
            Keys[key] = value
        end
    end

    return Keys
end


function ProfileService:LoadAsync(userId)
    local ExistingProfileFailed = self:GetMetaDataAsync(userId, "_failed")
    local Profile
    local LoadedSafely = false
    local ProfileCreationRequired = true

    if not Profiles[userId] or ExistingProfileFailed then
        Profile = self:_GetDefaultKeys()

        local FailedAttempts = 0

        while FailedAttempts < MAX_LOAD_ATTEMPTS and not LoadedSafely do
            local UserData = self.Services.Data.DataService.get("player_data", "retrieve", {userId})
            
            if UserData then
                for key,value in pairs(UserData) do
                    
                    if Profile[key] then
                        Profile[key] = value
                    end
                end

                LoadedSafely = true
            else
                FailedAttempts += 1
            end
        end
    else
        ProfileCreationRequired = false
        Profile = Profiles[userId]
        LoadedSafely = true
    end

    Profile = self:_ParseProfileTable(userId, Profile)

    if KICK_ON_LOAD_FAIL and not LoadedSafely then
        local Player = Players:GetPlayerByUserId(userId)
        if Player then
            Player:Kick(KICK_MESSAGE)
        end
        return false, LoadedSafely
    else
        if ProfileCreationRequired then
            self:CreateProfileAsync(userId, Profile)
            self:SetMetaDataAsync(userId, {
                ["_failed"] = not LoadedSafely,
                ["_last_save"] = self:_GetStoresAsync(userId, SavingStores),
                ["_can_modify"] = LoadedSafely
            })
        end

        return true, LoadedSafely
    end
end


function ProfileService:Save(userId)
    if not SavesInProgress[userId] then
        SavesInProgress[userId] = true
        if not self:GetMetaDataAsync(userId, "_failed") and SavingEnabled then
            local DifferentTables, KeysChanged = self:_DifferentTables(
                self:_GetStoresAsync(userId, SavingStores),
                self:GetMetaDataAsync(userId, "_last_save")
            )

            if DifferentTables then
                local UpdatesTable = {}
                for _, key in pairs(KeysChanged) do
                    UpdatesTable[key] = self:GetAsync(userId, key)
                end

                local FailedAttempts = 0
                local Success = false

                while FailedAttempts < MAX_SAVE_ATTEMPTS and not Success do
                    local Updated = self.Services.Data.DataService.post("player_data", "update", {userId}, {Data = UpdatesTable})
                    if Updated then
                        Success = true
                    else
                        FailedAttempts += 1
                    end
                end
                
                if Success then
                    self:SetMetaDataAsync(userId, {
                        ["_last_save"] = self:_GetStoresAsync(userId, SavingStores)
                    })
                    SavesInProgress[userId] = false
                    return true
                else
                    SavesInProgress[userId] = false

                    return false
                end
            else
                SavesInProgress[userId] = false
                return false
            end
        else
            SavesInProgress[userId] = false
            return false
        end
    end
end


function ProfileService:_DifferentTables(table1, table2)
    local Difference = false
    local DifferenceKeys = {}

    local function AddDifferenceKey(key)
        Difference = true
        if not table.find(DifferenceKeys, key) then
            table.insert(DifferenceKeys, key)
        end
    end

    local function SearchLinearTableArray(tbl1, tbl2)
        if #tbl1 ~= #tbl2 then
            return true
        else
            for i,v in ipairs(tbl1) do
                for innerKey, innerValue in pairs(v) do
                    if innerValue ~= tbl2[i][innerKey] then
                        return true
                    end
                end
            end
        end
    end

    for rootKey, rootValue in pairs(table1) do
        if typeof(rootValue) == "string" or typeof(rootValue) == "number" then
            if rootValue ~= table2[rootKey] then
                AddDifferenceKey(rootKey)
            end
        elseif typeof(rootValue) == "table" then
            local Different = SearchLinearTableArray(rootValue, table2[rootKey])
            if Different then
                AddDifferenceKey(rootKey)
            end
        end
    end

    -- Iterate through unique data - checking differences
    local function isUniqueDataDifference(tbl1, tbl2)
        if typeof(tbl1) == "table" and #tbl1 ~= #tbl2 then
            return true
        else
            for rootKey,data in pairs(tbl1) do
                if not tbl2[rootKey] then
                    return true
                else
                    if typeof(tbl2[rootKey]) == "string" then
                        if tbl2[rootKey] ~= data then
                            return true
                        end
                    elseif typeof(tbl2[rootKey]) == "table" then
                        local IsDifferent = isUniqueDataDifference(data, tbl2[rootKey])
                        if IsDifferent then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    local UniqueDifference = isUniqueDataDifference(table1["uniqueData"], table2["uniqueData"])
    if UniqueDifference then
        Difference = true
        table.insert(DifferenceKeys, "uniqueData")
    end
    
    return Difference, DifferenceKeys
end


function ProfileService:Start()
    self:MonitorFunctionalityEvents()
end


function ProfileService:MonitorFunctionalityEvents()
    game:BindToClose(function()
        ServerIsClosing = true
        warn("[ProfileService] Server closing, saving profiles.")
        if SaveOnServerClose then
            for userId,_  in pairs(Profiles) do
                self:Save(userId)
                print("[ProfileService] Saved", userId)
            end
        end
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        wait(0.5)
        if SaveOnPlayerLeave and not ServerIsClosing then
            warn("[ProfileService] Player left, saving profile.")
            self:Save(player.UserId)
        end
    end)

end


return ProfileService