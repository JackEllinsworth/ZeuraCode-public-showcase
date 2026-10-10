-- Purchase Service
-- Jack_AviationRBX
-- September 13, 2021

--[[

PurchaseService handles all asset purchases in the game, which require to be monitored.
This module is very useful for the 1-time ticket system, so you know exactly when to update players data.

--]]


local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local EVENT_CLIENT = "PurchaseClient"
local EVENT_BINDABLE = "PurchaseBindable"
local MonitoringPurchases = {}
local ClientEventCategorys = {}
local ServerEventCategorys = {}
local CategoryCallbacks = {}
local ErrorPurchases = {}


local PurchaseService = {}


function PurchaseService:Start()
    self:MonitorPurchases()
end


function PurchaseService:Init()
    self:RegisterClientEvent("PurchaseClient")
    self:RegisterEvent("PurchaseBindable")
end


-- Make sure to send to webhook - anything it can try when everything is down.
-- Also send manually to a HR via a command that can be run.
function PurchaseService:GetFailedPurchases()
    return ErrorPurchases
end


-- locatableIDs = {assetId = key, assetId = key}
function PurchaseService:SetPurchaseMonitor(categoryName, locatableIDs, clientFire, serverFire, callback)
    MonitoringPurchases[categoryName] = locatableIDs

    if clientFire then
        table.insert(ClientEventCategorys, categoryName)
    end

    if serverFire then
        table.insert(ServerEventCategorys, categoryName)
    end

    if callback then
        CategoryCallbacks[categoryName] = callback
    end
end


function PurchaseService:GetAssetData(assetId)
    for i,v in pairs(MonitoringPurchases) do
        if v[assetId] then
            return i, v[assetId] -- catrgoryName, key
        end
    end
end


function PurchaseService:MonitorPurchases()
    local function processReceipt(receiptInfo, isDifferent)
        local Category, LocatorKey = self:GetAssetData(receiptInfo.ProductId)
        if Category and LocatorKey then
            -- Fetch player
            local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
            
            if not player and not isDifferent then
                table.insert(ErrorPurchases, receiptInfo)
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end

            -- Peform callback
            local CallbackFunction = CategoryCallbacks[Category]
            if CallbackFunction then
                local success, result = pcall(CallbackFunction, player, Category, LocatorKey, receiptInfo)
                if not success or not result then
                    if not isDifferent then
                        self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Purchase Error!")
                        warn("[PurchaseService] -> An error occured whilst executing a purchase handler. UserId: "..tostring(player.UserId)..", ProductId: "..tostring(receiptInfo.ProductId))
                        table.insert(ErrorPurchases, receiptInfo)
                        return Enum.ProductPurchaseDecision.NotProcessedYet
                    end
                else
                    -- Handle events
                    if table.find(ClientEventCategorys, Category) then
                        self:FireClient(EVENT_CLIENT, player, Category, LocatorKey)
                    end
                    if table.find(ServerEventCategorys, Category) then
                        self:Fire(EVENT_BINDABLE, player, Category, LocatorKey)
                    end

                    self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Purchase Success!")
                    warn("[PurchaseService] -> A successful purchase occured. UserId: "..tostring(player.UserId).." ProductId: "..tostring(receiptInfo.ProductId))
                    if not isDifferent then
                        return Enum.ProductPurchaseDecision.PurchaseGranted
                    end
                end
            end

            -- Purchase Error event: make it display gui to player after purchase.
            -- explain that the server couldn't handle the request, and to show a screenshot of this page, with a code generated randomly
            -- Show that we also keep error longs, so if you dont reciebe within 24hr do the above ^
        end
    end

    MarketplaceService.ProcessReceipt = processReceipt
    MarketplaceService.PromptPurchaseFinished:Connect(function(player, assetId, purchased)
        if purchased then
            processReceipt({["ProductId"] = assetId, ["PlayerId"] = player.UserId}, true)
        end
    end)
end


return PurchaseService