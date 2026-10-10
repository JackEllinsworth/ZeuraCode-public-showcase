-- Self Check In Service
-- Jack_AviationRBX
-- October 11, 2021

local EVENT_SCI = "SCI"
local Players = game:GetService("Players")


local SelfCheckInService = {Client = {}}

function SelfCheckInService:Start()
    local SCILocation = game.Workspace:FindFirstChild("Infrastructure"):FindFirstChild("SCIs")
    for _,v in pairs(SCILocation:GetChildren()) do
        local AlreadyWaiting = false
        local ChangesMade = 0

        v.SelectionPart.ClickDetector.MouseClick:Connect(function(player)
            local function allow()
                v.UsedById.Value = player.UserId
                ChangesMade += 1
                player.PlayerGui:FindFirstChild("SCIPanel").Enabled = true
                player.PlayerGui:FindFirstChild("SCIPanel").Area.Value = v
            end

            if v.UsedById.Value == 0 then
                allow()
            else
                local oldPlayer = game:GetService("Players"):GetPlayerByUserId(v.UsedById.Value)
                if not oldPlayer then
                    allow()
                else
                    if not AlreadyWaiting then
                        local Before = ChangesMade
                        AlreadyWaiting = true
                        task.wait(35)
                        if ChangesMade == Before then
                            warn("[SelfCheckInService] Client timed out ("..tostring(v.UsedById.Value)..").")
                            v.UsedById.Value = 0
                        end
                        ChangesMade = 0
                        AlreadyWaiting = false
                    end
                end
            end
        end)
    end
end


function SelfCheckInService.Client:SendBaggage(player)
    local IsBooked = self.Server.Services.Data.ClassService:IsBooked(player.UserId)
    local HasLuggage = self.Server.Services.Data.SuitcaseService:LuggageExists(player.UserId)
    if IsBooked and not HasLuggage then
        coroutine.wrap(function()
            local PrintedTag = self.Server.Services.Data.SuitcaseService:SaveLuggageData(player)
            local BagLocation = player.PlayerGui:FindFirstChild("SCIPanel"):FindFirstChild("Area").Value.Luggage
        
            if BagLocation:FindFirstChild("Suitcase_Placed_SCI") then
                BagLocation["Suitcase_Placed_SCI"]:Destroy()
            end
            
            local BagTemplateLocation = BagLocation.SuitcaseArea.Position
            local Bag = game.ServerStorage.Models["Suitcase_Placed_SCI"]:Clone()
        
            self.Server.Services.Data.SuitcaseService:CustomiseSuitcase(player, Bag)
            self.Server.Services.Game.Core.ToolService:RevokeTool(player, "Suitcase")
            
            Bag.Tagged.Transparency = 0
            Bag.Tag.Transparency = 0
            Bag.Tag.Tag.Enabled = true

            if not PrintedTag["DestCode"] then
                PrintedTag["DestCode"] = "N/A"
            end

            if not PrintedTag["FlightNumber"] then
                PrintedTag["FlightNumber"] = "N/A"
            end
            
            local Tag = Bag.Tag.Tag.ImageLabel
            Tag.Destination.Text = PrintedTag.DestCode
            Tag.FlightNumber.Text = PrintedTag.FlightNumber
            Tag.PassengerName.Text = PrintedTag.Username
            Tag.ShortCode.Text = PrintedTag.SmallCode
            Tag.Weight.Text = tostring(PrintedTag.Weight).."kg"

            Bag.Parent = BagLocation
            local rotation = CFrame.Angles(0, 0, math.rad(BagLocation.Parent.BaggageRotation.Value))
            local modelCFrame = Bag:GetPrimaryPartCFrame()
            Bag:SetPrimaryPartCFrame( modelCFrame * rotation )

            self.Server.Services.Game.Moderation.TeleportationService:MoveModelToPosition(Bag, BagTemplateLocation)

            task.wait(6.5)
    
            if BagLocation:FindFirstChild("Suitcase_Placed_SCI") then
                BagLocation:FindFirstChild("Suitcase_Placed_SCI"):Destroy()
            end

            player.PlayerGui:FindFirstChild("SCIPanel"):FindFirstChild("Area").Value.UsedById.Value = 0
        end)()
        return true
    else
        return false
    end
end


function SelfCheckInService.Client:RequestClosure(player)
    player.PlayerGui:FindFirstChild("SCIPanel"):FindFirstChild("Area").Value.UsedById.Value = 0
    player.PlayerGui:FindFirstChild("SCIPanel").Enabled = false
    return true
end


function SelfCheckInService.Client:GetStartingData(player)
    local FlightService = self.Server.Services.Game.Core.FlightService
    local FlightsClasses = FlightService:GetCurrentFlightClasses()
    local CurrentFlight = FlightService:GetCurrentFlight()
    local AvailableClasses = self.Server.Services.Data.ClassService:GetAvailableClasses(player.UserId)

    if FlightsClasses and CurrentFlight and AvailableClasses then
        return {
            ["classes"] = FlightsClasses,
            ["classesOwned"] = AvailableClasses,
            ["flightInfo"] = {
                ["boardingGate"] = CurrentFlight["Gate"],
                ["boardingTime"] = CurrentFlight["BoardingTime"],
                ["aircraft"] = CurrentFlight["Aircraft"]
            }
        }
    end
end


function SelfCheckInService.Client:RequestMilesPurchase(player, className, amount)
    local Classes = self.Server.Modules.Config.Classes

    if Classes[className] and amount > 0 then
        local UsersCurrentMiles = self.Server.Services.Data.ProfileService:GetAsync(player.UserId, "miles")
        if UsersCurrentMiles >= (Classes[className].milesPrice * amount) then
            self.Server.Services.Data.ProfileService:IncrementAsync(player.UserId, "miles", -(Classes[className].milesPrice * amount))

            local Success = self.Server.Services.Data.ClassService:UpdateTempTicketAmount(player, className, amount)

            if Success then
                self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Purchase Success!")
                warn("[ClassService] -> A successful purchase occured, a 1-time ticket via miles by "..player.Name.." for "..className..". Amount: ".. tostring(amount)..". x1 Has been used for booking.")
                self.Server.Services.Data.MilesService:UpdateClient(player)
                return true, className
            else
                self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Purchase Error!")
                self.Server.Services.Data.ProfileService:IncrementAsync(player.UserId, "miles", (Classes[className].milesPrice) * amount)
                self.Server.Services.Data.MilesService:UpdateClient(player)
                warn("[ClassService] [ERR] -> An error occured whilst saving "..player.Name.."'s 1-time ticket for "..className.." [VIA MILES]. The save has been restored. Amount: "..tostring(amount))
                return false
            end
        end
    end
end


function SelfCheckInService.Client:IssuePurchasePrompt(player, className, amount)
    local Classes = self.Server.Modules.Config.Classes
    local PurchaseId = 0
    local IsProduct = false

    if Classes[className] then
        if amount == "perm" then
            IsProduct = false
            PurchaseId = Classes[className]["shirtId"]
        else
            if Classes[className]["devProducts"][amount] then
                IsProduct = true
                PurchaseId = Classes[className]["devProducts"][amount]
            end
        end
    end

    if PurchaseId ~= 0 then
        if IsProduct then
            game:GetService("MarketplaceService"):PromptProductPurchase(player, PurchaseId)
        else
            game:GetService("MarketplaceService"):PromptPurchase(player, PurchaseId)
        end
        return true
    end
end


function SelfCheckInService.Client:RequestBooking(player, className)
    local Success = self.Server.Services.Data.ClassService:HandleClassBooking(player, className)
    return Success
end


return SelfCheckInService