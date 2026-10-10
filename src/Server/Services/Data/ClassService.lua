-- Class Service
-- Jack_AviationRBX
-- August 8, 2021

--[[

ClassService provides an easy way to book a users class remotely from other scripts.
It also allows issuing or revoking 1-time tickets from players who are in the game.
Additionally, this system allows a vast amount of checks to be ran to check if a user owns a class;
Whether they have a greater class than the one they're booking, or if they have a group rank granting the class.

--]]

local Players = game:GetService("Players")

local MarketplaceService = game:GetService("MarketplaceService")
local PlayerOwnsAsset = MarketplaceService.PlayerOwnsAsset
local STORE_NAME = "ClassStore"
local HasRestored = false -- Only permits 1 restore period per server.
local ClassColours = {
    ["Executive"] = Color3.fromRGB(46, 82, 102),
    ["Premium"] = Color3.fromRGB(28, 114, 147),
    ["Standard+"] = Color3.fromRGB(152, 203, 180),
    ["Standard"] = Color3.fromRGB(152, 203, 180)
}

local ClassService = {Client = {}}


function ClassService:Start()

	-- Create Cache Store
    self.Services.Data.CacheService.createStore(STORE_NAME, {
        ["RowSettings"] = {
            ["bookedClass"] = "",
            ["availableClasses"] = {},
            ["tempTicketBackup"] = {}
        },
        ["ListenerActive"] = false
    })

    -- Set class purchase monitor
    for className, data in pairs(self.Modules.Config.Classes) do
        if data.shirtId ~= 0 then
            local AssetLocators = {}
            for ticketAmount, assetId in pairs(data.devProducts) do
                AssetLocators[assetId] = ticketAmount
            end

            AssetLocators[data.shirtId] = "perm"

            self.Services.Data.PurchaseService:SetPurchaseMonitor("Class"..className, AssetLocators, true, false, function(player, category, locatorKey)
                local ClassName = string.gsub(category, "Class", "")
                if locatorKey == "perm" then
                    self:CalculateOwnedClasses(player)
                    return true
                elseif tonumber(locatorKey) then
                    local CancelSave = false
                    if locatorKey <= 1 then
                        CancelSave = true
                    end

                    local Success = self.Services.Data.ClassService:UpdateTempTicketAmount(player, ClassName, locatorKey, CancelSave)
                    if not Success then
                        self.Services.Data.DataService:SendWebhook("Ticket Purchase Error", "Please restore this users ticket manually.", tonumber(0xFF8383), {
                            {"Username", player.Name},
                            {"UserId", player.UserId},
                            {"Ticket Name", ClassName},
                            {"Ticket Quantity", locatorKey}
                        }, "Logs", false)
                    else
                        return true
                    end
                end
            end)
        end
    end
    
end


-- Gets the classes that the user can pass for areas such as lounges.
-- Takes into account only perm tickets and currently booked tickets.
-- Basically does the same as getavaliableclasses, but also takes booked class into account.
function ClassService:GetClassAccessabilities(player)
    local ClassesAccessible = {}
    local HighestLevel = 0
    local AvailableClasses = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "availableClasses")

    for _,class in pairs(AvailableClasses) do
        if class["amount"] == "perm" then
            local ClassLevel = self:GetClassLevelByName(class["className"])
            if ClassLevel > HighestLevel then
                HighestLevel = ClassLevel
            end
        end
    end

    local IsBooked = self:IsBooked(player.UserId)

    -- Booked class takes priority - any classes <= are accessible, plus any higher perm classes.
    if IsBooked then
        local CurrentClassBooked = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "bookedClass")

        if CurrentClassBooked then
            local ClassLevelBooked = self:GetClassLevelByName(CurrentClassBooked)

            if ClassLevelBooked > HighestLevel then
                HighestLevel = ClassLevelBooked
            end
        end
    end

    for key,tbl in pairs(self.Modules.Config.Classes) do
        if tbl["classLevel"] <= HighestLevel then
            table.insert(ClassesAccessible, key)
        end
    end

    return ClassesAccessible
end


function ClassService:UpdateTempTicketAmount(player, className, amount, cancelSave)
    if amount == 0 then
        return true
    end

    -- Updates the users temp ticket amount, "amount" can be a negative or positive number
    local PreviousTickets = self.Services.Data.ProfileService:GetAsync(player.UserId, "boughtClasses")
    local NewTickets = self.Shared.TableUtil.Copy(PreviousTickets)
    local FoundAndUpdated = false

    local function Update(_amount)
        for _,tbl in pairs(NewTickets) do
            if tbl["className"] == className then
                tbl["amount"] = tbl["amount"] + _amount
                FoundAndUpdated = true
            end
        end
    
        if not FoundAndUpdated then
            table.insert(NewTickets, {
                ["className"] = className,
                ["amount"] = _amount
            })
        end
    end

    Update(amount)

    -- Update player data as new table
    self.Services.Data.ProfileService:UpdateAsync(player.UserId, "boughtClasses", NewTickets)

    -- Force-save (instantly) the new classes the user owns.
    local Success = false
    if not cancelSave then
        -- Currently not working, some yielding error, need to await response. Fix later (not a priority - manual save)
        Success = self.Services.Data.ProfileService:Save(player.UserId)
    else
        Success = true
    end

    if not Success then
        -- Restore to previous version
        self.Services.Data.ProfileService:UpdateAsync(player.UserId, "boughtClasses", PreviousTickets)

        warn("[ClassService] [ERR] -> An error occured whilst saving "..player.Name.."'s 1-time ticket for "..className..". [VIA ROBUX] The save has been restored.")
        return false
    else
        -- Update Cache & Re-calcuate current ownership of classes
        self:CalculateOwnedClasses(player)
        return true
    end
end


function ClassService:GetAvailableClasses(userId)
    local HighestClassLevel = 0
    local TempClasses = {}
    local AvailableClasses = self.Services.Data.CacheService:GetRow(STORE_NAME, userId, "availableClasses")

    for _,class in pairs(AvailableClasses) do
        local ClassLevel = self:GetClassLevelByName(class["className"])
        if class["amount"] == "perm" then
            if ClassLevel > HighestClassLevel then
                HighestClassLevel = ClassLevel
            end
        elseif class["amount"] >= 1 then
            table.insert(TempClasses, class["className"])
        end
    end

    local ClassNames = {}
    for i,v in pairs(self.Modules.Config.Classes) do
        if v["classLevel"] <= HighestClassLevel then
            table.insert(ClassNames, i)
        end
    end

    for _,v in pairs(TempClasses) do
        if not table.find(ClassNames, v) then
            table.insert(ClassNames, v)
        end
    end

    -- Remove classes unavaliable due to booking slots
    local FlightActive = self.Services.Game.Core.FlightService:GetCurrentFlight()

    if FlightActive then
        for i,v in pairs(ClassNames) do
            local Bookings = self.Services.Game.Core.FlightService:GetClassBookingsAvailable(v)
            if not Bookings or Bookings <= 0 then
                table.remove(ClassNames, i)
            end
        end
    end
    return ClassNames
end


function ClassService:HandleClassBooking(player, className)
    local RequestedClassLevel = self:GetClassLevelByName(className)

    local HighestPermClassLevel = 0
    local RequestedClassIsPerm = false
    local RequestedClassIsValid = false
    local AvailableClasses = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "availableClasses")

    for _,class in pairs(AvailableClasses) do
        if class["className"] == className then
            if class["amount"] == "perm" then
                RequestedClassIsPerm = true
            elseif class["amount"] >= 1 then
                RequestedClassIsValid = true
            end
        end

        local ClassLevel = self:GetClassLevelByName(class["className"])
        if ClassLevel > HighestPermClassLevel and class["amount"] == "perm" then
            HighestPermClassLevel = ClassLevel
        end
    end

    local Bookings = self.Services.Game.Core.FlightService:GetClassBookingsAvailable(className)

    --// User can book if their is no active flight or there is a flight and there is spare bookings.
    local FlightActive = self.Services.Game.Core.FlightService:GetCurrentFlight()
    local CanBook = true

    if FlightActive then
        CanBook = tonumber(Bookings) and Bookings >= 1
    end

    if CanBook then
        if RequestedClassLevel <= HighestPermClassLevel then
            -- Remove previous booking slot
            local IsBooked = self:IsBooked(player.UserId)
            if IsBooked then
                local CurrentClassBooked = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "bookedClass")
                self.Services.Game.Core.FlightService:ModifyClassBookings(CurrentClassBooked, 1)
            end

            -- No need to take temp class away
            self.Services.Game.Core.FlightService:ModifyClassBookings(className, -1)
            self:BookUserClass(player, className)
            
            return true
        elseif not RequestedClassIsPerm and RequestedClassIsValid then
            -- Must take temp class away
            self.Services.Game.Core.FlightService:ModifyClassBookings(className, -1)
            local Success = self.Services.Data.ClassService:UpdateTempTicketAmount(player, className, -1)
        
            if Success then
                local IsBooked = self:IsBooked(player.UserId)
                if IsBooked then
                    local CurrentClassBooked = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "bookedClass")
                    self.Services.Game.Core.FlightService:ModifyClassBookings(CurrentClassBooked, 1)
                end

                self.Services.Data.CacheService:InsertRow(STORE_NAME, player.UserId, "tempTicketBackup", className)
                self.Services.Data.ClassService:BookUserClass(player, className)
                return true
            end
        end
    end
end


function ClassService:RestoreBookedTickets()
    if not HasRestored then
        HasRestored = true
        for _,player in pairs(Players:GetChildren()) do
            local BackupStore = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "tempTicketBackup")
            if BackupStore and #BackupStore >= 1 then
                for i,v in pairs(BackupStore) do

                    local SuccessfulTicketReimburse = self:UpdateTempTicketAmount(player, v, 1, false)

                    if not SuccessfulTicketReimburse then
                        self.Services.Data.DataService:SendWebhook("[Zeura Backup] Data Restore Error", "Please return x1 of this users ticket manually.", tonumber(0xFF8383), {
                            {"Username", player.Name},
                            {"UserId", player.UserId},
                            {"Ticket Name", v}
                        }, "Logs", false)
                    end
                end
            end
        end

        return true
    end
end


function ClassService:GetClassLevelByName(className)
    local Class = self.Modules.Config.Classes[className]
    return Class["classLevel"]
end


function ClassService:IsBooked(userId)
    local CurrentBookedClass = self.Services.Data.CacheService:GetRow(STORE_NAME, userId, "bookedClass")
    if CurrentBookedClass and self.Modules.Config.Classes[CurrentBookedClass] then
        return true
    end
end


function ClassService:GetCurrentBookedClass(player)
    return self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "bookedClass")
end


function ClassService:GiveClassToolIfBooked(player)
    if self:IsBooked(player.UserId) then
        local CurrentBookedClass = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "bookedClass")

        self.Services.Game.Core.ToolService:RevokeTool(player, CurrentBookedClass)

        local ToolInstance = game.ServerStorage.Tools.Classes.ClassTicket:Clone()
        ToolInstance.Parent = player.Backpack
        ToolInstance.Name = CurrentBookedClass

        local Area = ToolInstance.Handle.SurfaceGui.Frame.TopBar
        local CurrentFlight = self.Services.Game.Core.FlightService:GetCurrentFlight()
        if CurrentFlight then
            Area.Date.Text = CurrentFlight["Date"]
            Area.Destination.Text = CurrentFlight["Destination"]
            Area.FlightNumber.Text = CurrentFlight["FlightNumber"]
            Area.Gate.Text = CurrentFlight["Gate"]
            Area.Airport.Text = CurrentFlight["Airport"]
            Area.Aircraft.Text = CurrentFlight["Aircraft"]
            Area.BoardingTime.Text = CurrentFlight["BoardingTime"]
        end

        Area.BarcodeTag.Text = "ZEU-X5MAXPGMQ9PCA_3VA"
        Area.Username.Text = player.Name

        if ClassColours[CurrentBookedClass] then
            Area.BackgroundColor3 = ClassColours[CurrentBookedClass]
            Area.Parent.BottomBar.BackgroundColor3 = ClassColours[CurrentBookedClass]
        end

        Area.ClassIdentifier.Text = string.upper(CurrentBookedClass)
    end
end


function ClassService:BookUserClass(player, className)
    if self:IsBooked(player.UserId) then
        local CurrentBookedClass = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "bookedClass")
        self.Services.Game.Core.ToolService:RevokeTool(player, CurrentBookedClass)
    end

    self.Services.Data.CacheService:ReplaceRow(STORE_NAME, player.UserId, "bookedClass", className)
    self:GiveClassToolIfBooked(player)
    self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Booked as "..className)

    warn("[ClassHandler] Booked player: "..player.Name.." as class "..className)
end


function ClassService:GetBookedLevel(userId)
    local BookedClass = self.Services.Data.CacheService:GetRow(STORE_NAME, userId, "bookedClass")
    if BookedClass then
        return self:GetClassLevelByName(BookedClass)
    end
end


function ClassService:GetBookedClass(userId)
    local BookedClass = self.Services.Data.CacheService:GetRow(STORE_NAME, userId, "bookedClass")
    if BookedClass then
        return BookedClass
    end
end


function ClassService:GetTempClasses(userId, exclusionList)
    local TempClasses = self.Services.Data.ProfileService:GetAsync(userId, "boughtClasses")
    if TempClasses then
        local PositiveTable = {}
        for _,tbl in pairs(TempClasses) do
            if tbl["amount"] >= 1 then
                if exclusionList then
                    if not table.find(exclusionList, tbl["className"]) then
                        table.insert(PositiveTable, tbl)
                    end
                else
                    table.insert(PositiveTable, tbl)
                end
            end
        end

        return PositiveTable
    end
end


function ClassService:GetPermClasses(player)
    local PermClasses = {}
    local GroupRank = self.Services.Data.ProfileService:GetAsync(player.UserId, "rankId")

    local function resolveIndividualClass(classTbl)
        if classTbl["shirtId"] == 0 then
            return true
        end
    
        if classTbl['groupRanks'] then
            for _,v in pairs(classTbl['groupRanks']) do
                if GroupRank == v then
                    return true
                end
            end
        end
    
        if not player then
            return
        end

        --// Check if user bought class shirt
        local success, doesPlayerOwnAsset = pcall(PlayerOwnsAsset, MarketplaceService, player, classTbl["shirtId"])
            
        if success then
            if doesPlayerOwnAsset then
                return true
            end
        else
            wait(0.5)
            warn("[ClassHandler] [ERR] -> Could not check asset ownership for "..player.Name.." with assetId: "..tostring(classTbl["shirtId"]))
        end
    end

    for className,classTbl in pairs(self.Modules.Config.Classes) do
        if resolveIndividualClass(classTbl) then
            table.insert(PermClasses, {
                ["className"] = className,
                ["amount"] = "perm"
            })
        end
    end

    return PermClasses
end


function ClassService:CalculateOwnedClasses(player)
    local PermClasses = self:GetPermClasses(player)
    local LinearClasses = {}

    for _,tbl in pairs(PermClasses) do
        table.insert(LinearClasses, tbl["className"])
    end

    local ExcludedTempList = self:GetTempClasses(player.UserId, LinearClasses)
    local MergedList = PermClasses

    for _,tbl in pairs(ExcludedTempList) do
        table.insert(MergedList, tbl)
    end

    if not self.Services.Data.CacheService:LocatorExists(STORE_NAME, player.UserId) then
        self.Services.Data.CacheService:CreateLocator(STORE_NAME, player.UserId)
    end

    self.Services.Data.CacheService:ReplaceRow(STORE_NAME, player.UserId, "availableClasses", MergedList)
end


function ClassService:GetHighestPermClass(player)
    local HighestLevel = 0
    local HighestLevelName = ""
    local AvailableClasses = self.Services.Data.CacheService:GetRow(STORE_NAME, player.UserId, "availableClasses")

    for _,class in pairs(AvailableClasses) do
        if class["amount"] == "perm" then
            local ClassLevel = self:GetClassLevelByName(class["className"])
            if ClassLevel > HighestLevel then
                HighestLevel = ClassLevel
                HighestLevelName = class["className"]
            end
        end
    end

    return HighestLevelName
end


return ClassService