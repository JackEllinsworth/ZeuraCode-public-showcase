-- Cache Service
-- Jack_AviationRBX
-- August 8, 2021

--[[

CacheService provides server-only access to limited-use data, which can be retrieved and modified in any way.

Store Directory Layout:
[StoreName] = {
    ["defaults"] = {Configuration}
    ["LocatorKey"] = {
        ["IndividualRow"] = IndividualValue,
        ["IndividualRow"] = {IndividualTable}
    }
}

Configuration = {
    ["RowSettings"] = {
        ["IndividualRow"] = {},
        ["IndividualRow"] = ""
    },
    ["ListenerActive"] = true
}

(Sets default value on creation of dataset)

The wildcard "_" before an individual row key name prevents alerts setting off for any changes in the data.
However, this is only if the listener is active.

--]]


local Stores = {}
local EVENT_CACHE = "Cache"


local CacheService = {Client = {}}


function CacheService:Init()
    self:RegisterEvent(EVENT_CACHE)
end


function CacheService.createStore(storeName, configuration)
    if not Stores[storeName] then
        Stores[storeName] = {
            ["defaults"] = configuration
        }
        warn("[CacheService] -> Store Created: "..storeName)
    end
end


function CacheService.clearStore(storeName)
    Stores[storeName] = {["defaults"] = Stores[storeName]["defaults"]}
end


function CacheService._fetchConfiguration(storeName)
    return Stores[storeName]["defaults"]
end


function CacheService:AlertChange(storeName, locatorID, changeType, changeKey)
    local ListenerMode = self._fetchConfiguration(storeName)["ListenerActive"]
    if ListenerMode then
        if string.sub(changeKey, 1, 1) ~= "_" then
            self:Fire(EVENT_CACHE, storeName, locatorID, changeType, changeKey)
        end
    end
end


function CacheService:CreateLocator(storeName, locatorID)
    Stores[storeName][locatorID] = {}

    for keyName,keyDefault in pairs(self._fetchConfiguration(storeName)["RowSettings"]) do
        Stores[storeName][locatorID][keyName] = keyDefault
    end
end


function CacheService:GetLocatorRows(storeName, locatorID)
    if self:LocatorExists(storeName, locatorID) then
        return Stores[storeName][locatorID]
    end
end


function CacheService:GetAllLocators(storeName)
    return Stores[storeName]
end


function CacheService:GetRow(storeName, locatorID, keyName)
    if self:LocatorExists(storeName, locatorID) then
        return Stores[storeName][locatorID][keyName]
    end
end


function CacheService:LocatorExists(storeName, locatorID)
    if Stores[storeName][locatorID] ~= nil then
        return true
    end
end


function CacheService:ReplaceRow(storeName, locatorID, keyName, keyValue)
    if self:LocatorExists(storeName, locatorID) then
        Stores[storeName][locatorID][keyName] = keyValue
        self:AlertChange(storeName, locatorID, "Replacement", keyName)
    end
end


function CacheService:InsertRow(storeName, locatorID, keyName, insertionValue)
    if self:LocatorExists(storeName, locatorID) then
        table.insert(Stores[storeName][locatorID][keyName], insertionValue)
        self:AlertChange(storeName, locatorID, "Insertion", keyName)
    end
end


function CacheService:RemoveRow(storeName, locatorID, keyName, removalIndex)
    if self:LocatorExists(storeName, locatorID) then
        table.remove(Stores[storeName][locatorID][keyName], removalIndex)
        self:AlertChange(storeName, locatorID, "Removal", keyName)
    end
end


return CacheService