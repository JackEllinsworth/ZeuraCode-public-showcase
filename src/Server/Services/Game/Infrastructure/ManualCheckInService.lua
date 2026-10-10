-- Manual Check In Service
-- Jack_AviationRBX
-- July 29, 2022

local EVENT_MCI = "ManualCheckIn"
local Players = game:GetService("Players")
local QueueStaff = {}
local MarketplaceService = game:GetService("MarketplaceService")


local ManualCheckInService = {Client = {}}


function ManualCheckInService:Init()
    self:RegisterClientEvent(EVENT_MCI)
end


function ManualCheckInService:Start()
    -- Monitor Flight Settings
    self.Services.Game.Core.FlightService:ConnectEvent("Flight", function(action, tbl)
        if action == "CurrentSet" or action == "CurrentUpdate" then
            for _,v in pairs(game.Workspace.Infrastructure.Queues.ManualCheckIn:GetChildren()) do
                for _,b in pairs(v.Models:GetChildren()) do
                    local Location = b.Overhead["Check-In Screen"].Screen.SurfaceGui["On_1"]
                    Location.Destination.Text = tbl.Destination
                    Location.FlightNumber.Text = tbl.FlightNumber
                end
            end
        end
    end)

    local function resetGui(player)
        player.PlayerGui.ManualCheckIn.Enabled = false
        player.PlayerGui.ManualCheckIn.ClassGive.Visible = false
        player.PlayerGui.ManualCheckIn.MCIPanel.Main.Visible = false
        player.PlayerGui.ManualCheckIn.MCIPanel.QueueConfig.Visible = false
        player.PlayerGui.ManualCheckIn.MCIPanel.Status.Visible = false
    end

    -- Monitor new staff
    for _,queue in pairs(game.Workspace.Infrastructure.Queues.ManualCheckIn:GetChildren()) do
        for _,controller in pairs(queue.Control:GetChildren()) do
            queue.Models[controller.Name].Overhead["Desk Number"].Number.SurfaceGui.TextBox.Text = controller.Name
            controller.Button.ClickDetector.MouseClick:Connect(function(player)
                if self.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
                    local StaffExists, Index, _ = self:StaffExists(player.UserId)
                    -- Revoke access if already-staff member clicks (disable technique)
                    if StaffExists then
                        table.remove(QueueStaff, Index)
                        if player.PlayerGui:FindFirstChild("ManualCheckIn") then
                            resetGui(player)
                        end
                        self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Disabled MCI System")
                    -- Approve access if no current staff member or current staff member not in game.
                    else
                        local Authorised = false
                        local CurrentlyServingUpdate = nil
                        local Found, UserId = self:GetStaffByQueueAndController(queue.Name, controller.Name)
                        if Found then
                            local StaffPlayer = Players:GetPlayerByUserId(UserId)
                            if not StaffPlayer then
                                table.remove(QueueStaff, Index)
                                Authorised = true
                            end
                        else
                            Authorised = true
                        end

                        if Authorised then
                            resetGui(player)
                            player.PlayerGui:FindFirstChild("ManualCheckIn").Enabled = true

                            if controller.Master.Value then
                                player.PlayerGui.ManualCheckIn.MCIPanel.Main.QueueConfig.Visible = true
                            else
                                player.PlayerGui.ManualCheckIn.MCIPanel.Main.QueueConfig.Visible = false
                            end

                            if controller.CustomerId.Value ~= 0 then
                                if Players:GetPlayerByUserId(controller.CustomerId.Value) then
                                    CurrentlyServingUpdate = controller.CustomerId.Value
                                end
                            end

                            table.insert(QueueStaff, {
                                ["UserId"] = player.UserId,
                                ["Queue"] = queue.Name,
                                ["Controller"] = controller.Name,
                                ["CurrentlyServing"] = CurrentlyServingUpdate,
                            })

                            local TableToSendStaff = {
                                ["AmountInQueue"] = self.Services.Game.Infrastructure.Queue.QueueService:GetAmountInQueue(queue.Name),
                                ["Position"] = tostring(controller.Name),
                                ["CurrentlyServing"] = CurrentlyServingUpdate
                            }

                            if CurrentlyServingUpdate then
                                player.PlayerGui.ManualCheckIn.NextPlayerButton.Visible = false
                                player.PlayerGui.ManualCheckIn.SendAwayButton.Visible = true
                                
                                self:StartPlayerSession(queue.Name, controller.Name)
                            end

                            self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Enabled MCI System")

                            self:FireClient(EVENT_MCI, player, "StaffUpdate", TableToSendStaff)
                        end
                    end
                end
            end)
        end
    end

    -- Update queue count / positon
    self.Services.Game.Infrastructure.Queue.QueueService:ConnectEvent("QueueServer", function(action, tbl)
        if action == "QueueUpdate" and tbl["QueueType"] == "ManualCheckIn" then
            for _,v in pairs(QueueStaff) do
                if v.Queue == tbl["QueueName"] then
                    local Player = Players:GetPlayerByUserId(v.UserId)
                    if Player then
                        self:FireClient(EVENT_MCI, Player, "StaffUpdate", {
                            ["AmountInQueue"] = tbl["AmountInQueue"],
                            ["Position"] = tostring(v.Controller),
                            ["CurrentlyServing"] = v.CurrentlyServing
                        })
                    end
                end
            end
        end
    end)
end


function ManualCheckInService:GetStaffByQueueAndController(queueName, controller)
    for _,v in pairs(QueueStaff) do
        if v.Queue == queueName and v.Controller == controller then
            return true, v.UserId, v
        end
    end
end


function ManualCheckInService:StaffExists(userId)
    for i,v in pairs(QueueStaff) do
        if v.UserId == userId then
            return true, i, v
        end
    end
end


function ManualCheckInService:CustomerExists(userId)
    for _,v in pairs(QueueStaff) do
        if v["CurrentlyServing"] == userId then
            return true, v
        end
    end
end


function ManualCheckInService.Client:RequestNextPlayer(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        for _,v in pairs(QueueStaff) do
            if v.UserId == player.UserId then

                if v.CurrentlyServing then
                    local ServingPlayer = Players:GetPlayerByUserId(v.CurrentlyServing)
                    if ServingPlayer then
                        return
                    end
                end

                local FinalTeleportNodes = {}
                for _,b in pairs(game.Workspace.Infrastructure.Queues.ManualCheckIn[v.Queue]["Control"][v.Controller].Nodes:GetChildren()) do
                    table.insert(FinalTeleportNodes, tonumber(b.Name))
                end
                table.sort(FinalTeleportNodes)
    
                local MovementToFinal = {}
                for _,b in pairs(FinalTeleportNodes) do
                    table.insert(MovementToFinal, game.Workspace.Infrastructure.Queues.ManualCheckIn[v.Queue]["Control"][v.Controller].Nodes[tostring(b)].Position)
                end
                
                table.insert(MovementToFinal, game.Workspace.Infrastructure.Queues.ManualCheckIn[v.Queue]["Control"][v.Controller].MovePosition.Position)
    

                self.Server.Services.Game.Infrastructure.Queue.QueueService:GetNextPlayer(v.Queue, {
                    MoveEndCompletion = {
                        ["Enabled"] = true,
                        ["Additional"] = MovementToFinal
                    },
                    Freeze = true
                }, function(newPlayer)
                    if newPlayer then
                        -- Fire event to staff member, initiate serving
                        v.CurrentlyServing = newPlayer.UserId
                        game.Workspace.Infrastructure.Queues.ManualCheckIn[v.Queue]["Control"][v.Controller].CustomerId.Value = newPlayer.UserId
                        self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, player, "StaffUpdate", {
                            ["CurrentlyServing"] = newPlayer.UserId,
                        })
                        self.Server.Services.Game.Infrastructure.ManualCheckInService:StartPlayerSession(v.Queue, v.Controller)
                    end
                end)
            end
        end
    end
end


function ManualCheckInService.Client:SendPlayerBack(player)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        for _,v in pairs(QueueStaff) do
            if v.UserId == player.UserId then
                if v.CurrentlyServing then
                    local Customer = Players:GetPlayerByUserId(v.CurrentlyServing)
                    local BackPart = game.Workspace.Infrastructure.Queues.ManualCheckIn[v.Queue]["SendBack"]

                    if Customer then
                        self.Server.Services.Game.Moderation.TeleportationService:MovePlayerToPart(Customer, BackPart)
                        self.Server.Services.Game.Moderation.PlayerControlService:EnableMovement(Customer)
                    end

                    v.CurrentlyServing = 0
                    game.Workspace.Infrastructure.Queues.ManualCheckIn[v.Queue]["Control"][v.Controller].CustomerId.Value = nil

                    self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, player, "StaffUpdate", {
                        ["CurrentlyServing"] = nil,
                    })

                    self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, player, "ClassScreen", {false})
                end
            end
        end
    end
end


function ManualCheckInService.Client:GetClassOptions()
    local Classes = {}
    for i,_ in pairs(self.Server.Modules.Config.Classes) do
        table.insert(Classes, i)
    end
    return Classes
end


function ManualCheckInService.Client:EnableDisable(staffPlayer, _option)
    local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(staffPlayer.UserId)

    if StaffExists and self.Server.Services.Data.PermissionService:HasPermission(staffPlayer.UserId, "Staff") then
        local QueueIdentifier = Tbl["Queue"]
        game.Workspace.Infrastructure.Queues.ManualCheckIn[QueueIdentifier].Configuration.Enabled.Value = _option
    end
end


function ManualCheckInService.Client:UpdateScreenStatus(staffPlayer, status)
    local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(staffPlayer.UserId)

    if StaffExists and self.Server.Services.Data.PermissionService:HasPermission(staffPlayer.UserId, "Staff") then
        local QueueIdentifier = Tbl["Queue"]
        local Controller = Tbl["Controller"]
        local ScreenGui = game.Workspace.Infrastructure.Queues.ManualCheckIn[QueueIdentifier].Models[Controller].Overhead["Check-In Screen"].Screen.SurfaceGui
        ScreenGui["On_1"].Status.Text = status

        local Location = ScreenGui["On_1"].Status
        if status == "Position Opening Soon" or status == "Open" then
            Location.BackgroundColor3 = Color3.fromRGB(51, 156, 58)
        elseif status == "Position Closing Soon" then
            Location.BackgroundColor3 = Color3.fromRGB(156, 108, 60)
        elseif status == "Final Call" or status == "Last Minute" or status == "Cancelled" then
            Location.BackgroundColor3 = Color3.fromRGB(156, 53, 53)
        end
    end
end


function ManualCheckInService.Client:ScreenOnOff(staffPlayer, _option)
    local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(staffPlayer.UserId)

    if StaffExists and self.Server.Services.Data.PermissionService:HasPermission(staffPlayer.UserId, "Staff") then
        local QueueIdentifier = Tbl["Queue"]
        local Controller = Tbl["Controller"]
        local ScreenGui = game.Workspace.Infrastructure.Queues.ManualCheckIn[QueueIdentifier].Models[Controller].Overhead["Check-In Screen"].Screen.SurfaceGui
        if _option then
            ScreenGui["On_1"].Visible = true
            ScreenGui["Off"].Visible = false
        else
            ScreenGui["Off"].Visible = true
            ScreenGui["On_1"].Visible = false
            ScreenGui["On_2"].Visible = false
        end
    end
end


function ManualCheckInService:StartPlayerSession(queueName, controller)
    local Found, StaffUserId, FullTbl = self:GetStaffByQueueAndController(queueName, controller)
    
    local StaffPlayer
    if Found and StaffUserId then
        StaffPlayer = Players:GetPlayerByUserId(StaffUserId)
    else
        return
    end

    if StaffPlayer then
        local CustomerPlayer
        if FullTbl["CurrentlyServing"] ~= nil then
            CustomerPlayer = Players:GetPlayerByUserId(FullTbl["CurrentlyServing"])
        end

        if not CustomerPlayer then
            return
        end

        -- Reset conveyor
        local BagLocation = game.Workspace.Infrastructure.Queues.ManualCheckIn[queueName].Models[controller].Baggage
        BagLocation.Conveyor.Velocity = Vector3.new(0, 0, 0)

        task.wait(1.5)

        -- Request baggage
        self:FireClient(EVENT_MCI, StaffPlayer, "PopupSet", {"Request Baggage"})
    end
end


function ManualCheckInService:PlaceBag(Tbl)
    local Queues = game.Workspace.Infrastructure.Queues.ManualCheckIn
	local Queue = Tbl["Queue"]
	local Controller = Tbl["Controller"]
	local BagLocation = Queues[Queue].Models[Controller].Baggage
	
    local CustomerPlayer = Players:GetPlayerByUserId(Tbl["CurrentlyServing"])

    BagLocation.Conveyor.Velocity = Vector3.new(-1, 0, 0) * 2.2  --// 0,0,-1 for other side

	if BagLocation:FindFirstChild("Suitcase_Placed") then
		BagLocation["Suitcase_Placed"]:Destroy()
	end
	
	local BagTemplateLocation = BagLocation.SuitcaseArea.Position
	local Bag = game.ServerStorage.Models["Suitcase_Placed"]:Clone()

    self.Services.Data.SuitcaseService:CustomiseSuitcase(CustomerPlayer, Bag)

    if CustomerPlayer then
        self.Services.Game.Core.ToolService:RevokeTool(CustomerPlayer, "Suitcase")
    end

    local rotation = CFrame.Angles(0, 0, math.rad(Queues[Queue].Configuration.BaggageRotation.Value))
    local modelCFrame = Bag:GetPrimaryPartCFrame()
    Bag:SetPrimaryPartCFrame( modelCFrame * rotation )

	Bag.Parent = BagLocation
    
    self.Services.Game.Moderation.TeleportationService:MoveModelToPosition(Bag, BagTemplateLocation)
end


function ManualCheckInService.Client:PopupActivated(player, popupText)
    
    if popupText == "Request Baggage" then
        local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(player.UserId)
        if StaffExists and self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
            -- Add player accept gui
            local Customer = Players:GetPlayerByUserId(Tbl["CurrentlyServing"])
            if Customer then
                self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, Customer, "PopupSet", {"Place Baggage"})
            end
        end
    elseif popupText == "Place Baggage" then
        local CustomerExists, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:CustomerExists(player.UserId)
        if CustomerExists then
            -- Add Baggage to conveyor
            self.Server.Services.Game.Infrastructure.ManualCheckInService:PlaceBag(Tbl)

            -- Give staff "print tag" GUI
            local StaffPlayer = Players:GetPlayerByUserId(Tbl["UserId"])
            if StaffPlayer then
                self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, StaffPlayer, "PopupSet", {"Print Tag"})
            end
        end
    elseif popupText == "Print Tag" then
        local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(player.UserId)
        if StaffExists and self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
            local CustomerPlayer = Players:GetPlayerByUserId(Tbl["CurrentlyServing"])
            if CustomerPlayer then
                -- Print the tag for the bag on the conveyor
                local PrintedTag = self.Server.Services.Data.SuitcaseService:SaveLuggageData(CustomerPlayer)

                local Bag = game.Workspace.Infrastructure.Queues.ManualCheckIn[Tbl["Queue"]].Models[Tbl["Controller"]].Baggage:FindFirstChild("Suitcase_Placed")
                if Bag then
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
                end

                self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, player, "PopupSet", {"Activate Conveyor"})

                -- Issue class-give screen
                local ClassesOwned = self.Server.Services.Data.ClassService:GetAvailableClasses(CustomerPlayer.UserId)

                -- Issue class-giving controls
                self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, player, "ClassScreen", {true})
                self.Server.Services.Game.Infrastructure.ManualCheckInService:FireClient(EVENT_MCI, player, "UpdateCustomer", ClassesOwned)
            end
        end
    elseif popupText == "Activate Conveyor" then
        local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(player.UserId)
        if StaffExists and self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
            local BagLocation = game.Workspace.Infrastructure.Queues.ManualCheckIn[Tbl["Queue"]].Models[Tbl["Controller"]].Baggage

            if BagLocation then
                local Area = BagLocation.Release
    
                task.wait(0.1)
                Area.CanCollide = false
                task.wait(4.5)
                Area.CanCollide = true
                BagLocation.Conveyor.Velocity = Vector3.new(0, 0, 0)
    
                if Area.Parent:FindFirstChild("Suitcase_Placed") then
                    Area.Parent:FindFirstChild("Suitcase_Placed"):Destroy()
                end
            end
        end
    end
end


function ManualCheckInService.Client:SetClassRestriction(staffPlayer, classRestriction)
    if self.Server.Services.Data.PermissionService:HasPermission(staffPlayer.UserId, "Staff") then
        local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(staffPlayer.UserId)
        if not StaffExists or not Tbl then
            return
        end

        local Queue = Tbl["Queue"]
        game.Workspace.Infrastructure.Queues.ManualCheckIn[Queue]["Configuration"]["ClassRestrictionObtained"].Value = classRestriction

        for _,v in pairs(game.Workspace.Infrastructure.Queues.ManualCheckIn[Queue].Models:GetChildren()) do
            v.Overhead["Check-In Screen"].Screen.SurfaceGui["On_1"].ClassServing.Text = classRestriction
        end
    end
end


function ManualCheckInService.Client:ExecuteClassSelection(player, ClassName, Option)
    local StaffExists, _, Tbl = self.Server.Services.Game.Infrastructure.ManualCheckInService:StaffExists(player.UserId)
    if StaffExists and self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
        local Customer = Tbl["CurrentlyServing"]
        local CustomerPlayer = Players:GetPlayerByUserId(Customer)

        if CustomerPlayer then
            if Option == "Prompt" then
                local ShirtId = self.Server.Modules.Config.Classes[ClassName].ShirtId
                if ShirtId ~= 0 then
                    MarketplaceService:PromptPurchase(CustomerPlayer, self.Server.Modules.Config.Classes[ClassName].shirtId)
                end
            elseif Option == "Give" then
                local Success = self.Server.Services.Data.ClassService:HandleClassBooking(CustomerPlayer, ClassName)

                if Success then
                    return "Close"
                end
            end
        end
    end
end


return ManualCheckInService