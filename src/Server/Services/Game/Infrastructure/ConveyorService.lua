-- Conveyor Service
-- Jack_AviationRBX
-- August 2, 2022

local CURRENT_ACTIVE_CONVEYOR = 0
local MAX_BAGS = 20
local BAGS_OUT = 0
local Disabled = true
local Players = game:GetService("Players")
local BagsComplete = false
local EVENT_CONVEYOR = "Baggage"
local Testing = true


local ConveyorService = {Client = {}}


function ConveyorService:Init()
    self:RegisterClientEvent(EVENT_CONVEYOR)
end


function ConveyorService:DisableActiveConveyor()
    if CURRENT_ACTIVE_CONVEYOR ~= 0 then
        Disabled = true
        local Conveyor = game.Workspace.Infrastructure.Conveyors[CURRENT_ACTIVE_CONVEYOR]
        for _,v in pairs(Conveyor.Conveyors:GetChildren()) do
            v.Velocity = Vector3.new(0, 0, 0)
        end
        self:UpdateScreens()
    end
end


function ConveyorService:EnableActiveConveyor()
    if CURRENT_ACTIVE_CONVEYOR ~= 0 then
        Disabled = false
        BagsComplete = false
        BAGS_OUT = 0

        self:UpdateScreens()

        local Conveyor = game.Workspace.Infrastructure.Conveyors[CURRENT_ACTIVE_CONVEYOR].Conveyors
        Conveyor.One.Velocity = Vector3.new(0, 0, -3)
        Conveyor.Two.Velocity = Vector3.new(0, 0, 3)
        Conveyor.Three.Velocity = Vector3.new(-3, 0, 0)
        Conveyor.Four.Velocity = Vector3.new(3, 0, 0)
        Conveyor.Five.Velocity = Vector3.new(0, 0, 5)

        local BaggageToUnload = self.Shared.TableUtil.Copy(self.Services.Data.SuitcaseService:GetLuggageStore())

        while true do
            
            if #BaggageToUnload <= 0 then
                break
            end

            if BAGS_OUT < MAX_BAGS then
                for index,tbl in ipairs(BaggageToUnload) do
                    if not Disabled and BAGS_OUT < MAX_BAGS and tbl then
                        local CustomerPlayer = Players:GetPlayerByUserId(tbl.UserId)
                        if CustomerPlayer or Testing then
                            -- Duplicate / get model
                            local BagLocation = Conveyor.Parent.Suitcases
                            local BagTemplateLocation = Conveyor.Parent.SuitcaseStart.Position
                            local Bag = game.ServerStorage.Models["Suitcase_Placed"]:Clone()
                        
                            local rotation = CFrame.Angles(0, 0, math.rad(Conveyor.Parent.SuitcaseStart.BaggageRotation.Value))
                            local modelCFrame = Bag:GetPrimaryPartCFrame()
                            Bag:SetPrimaryPartCFrame( modelCFrame * rotation )
                            
                            BagLocation.Parent.Conveyors.Switch.CanCollide = true
        
                            task.wait(1)
        
                            -- Update model tag
                            Bag.Parent = BagLocation
                            Bag.Tagged.Transparency = 0
                            Bag.Tag.Transparency = 0
                            Bag.Tag.Tag.Enabled = true
                            Bag.Name = tostring(tbl["UserId"])
                            
                            if not tbl["DestCode"] then
                                tbl["DestCode"] = "N/A"
                            end
        
                            if not tbl["FlightNumber"] then
                                tbl["FlightNumber"] = "N/A"
                            end
                        
                            local Tag = Bag.Tag.Tag.ImageLabel
                            Tag.Destination.Text = tbl.DestCode
                            Tag.FlightNumber.Text = tbl.FlightNumber
                            Tag.PassengerName.Text = tbl.Username
                            Tag.ShortCode.Text = tbl.SmallCode
                            Tag.Weight.Text = tostring(tbl.Weight).."kg"
                            
                            if CustomerPlayer then
                                self:FireClient(EVENT_CONVEYOR, CustomerPlayer, "BagCreated", Bag)
                                self.Services.Data.SuitcaseService:CustomiseSuitcase(CustomerPlayer, Bag)
                            end

                            self.Services.Game.Moderation.TeleportationService:MoveModelToPosition(Bag, BagTemplateLocation)
                            BAGS_OUT += 1
                            
                            table.remove(BaggageToUnload, index)
    
                            task.wait(2)
                            BagLocation.Parent.Conveyors.Switch.CanCollide = false
                            task.wait(2)
                        end
                    end
                end
            end
            task.wait(5)
        end

        BagsComplete = true
        self:UpdateScreens()
    end
end


function ConveyorService:SetActiveConveyor(conveyorNum)
    if game.Workspace.Infrastructure.Conveyors:FindFirstChild(tostring(conveyorNum)) then
        CURRENT_ACTIVE_CONVEYOR = conveyorNum
        self:UpdateScreens()
    end
end

function ConveyorService:SelectRandomConveyor(exclude)
    local Conveyors = game.Workspace.Infrastructure.Conveyors:GetChildren()
    local ConveyorNames = {}
    for i,v in pairs(Conveyors) do
        table.insert(ConveyorNames, v.Name)
    end
    local selected = false
    local randomNum

    while not selected do
        randomNum = math.random(1, #ConveyorNames)
        if ConveyorNames[randomNum] ~= exclude or #ConveyorNames == 1 then
            selected = true
        end
    end

    return ConveyorNames[randomNum]
end


function ConveyorService:UpdateScreens()
    
    local FlightData = self.Services.Game.Core.FlightService:GetCurrentFlight()

    self.Services.Game.Infrastructure.Screens.Types.BaggageArrivalScreenService:UpdateEvent(CURRENT_ACTIVE_CONVEYOR)

    -- Baggage status display
    local function resetStatusDisplays()
        for _,v in pairs(game.Workspace.Infrastructure.Conveyors:GetChildren()) do
            for _,b in pairs(v.BaggageStatusDisplay:GetDescendants()) do
                if b:IsA("TextBox") and b.Parent.Parent.Parent.Name ~= "Model" then
                    b.Text = " "
                end
            end
        end
    end

    resetStatusDisplays()

    local function writeOnBlocks(message, parent)
        for i, v in ipairs(message:split("")) do
            if not parent:FindFirstChild(i) then
                break
            end
            parent:FindFirstChild(tostring(i)).SurfaceGui.TextBox.Text = v
        end
    end

    if game.Workspace.Infrastructure.Conveyors[tostring(CURRENT_ACTIVE_CONVEYOR)] then
        for _,title in pairs(game.Workspace.Infrastructure.Conveyors[CURRENT_ACTIVE_CONVEYOR].BaggageStatusDisplay:GetChildren()) do
            if title.Name == "Status" then
                if Disabled then
                    writeOnBlocks("ARRIVING", title)
                elseif not BagsComplete then
                    writeOnBlocks("ON BELT", title)
                else
                    writeOnBlocks("DELIVERED", title)
                end
            elseif title.Name == "DeptCode" then
                writeOnBlocks(self.Modules.Config.AirportCode, title)
            elseif title.Name == "FlightNum" then
                if FlightData then
                    writeOnBlocks(FlightData.FlightNumber, title)
                end
            end
        end
    end
end


function ConveyorService.Client:RequestBagPickup(player)
    if game.Workspace.Infrastructure.Conveyors[CURRENT_ACTIVE_CONVEYOR] then
        local Location = game.Workspace.Infrastructure.Conveyors[CURRENT_ACTIVE_CONVEYOR]
        if Location.Suitcases:FindFirstChild(tostring(player.UserId)) then
            self.Server.Services.Data.SuitcaseService:GiveArrivalSuitcase(player)
            Location.Suitcases:FindFirstChild(tostring(player.UserId)):Destroy()

            BAGS_OUT -= 1
            self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Bag retrieved!")
        end
    end
end


return ConveyorService