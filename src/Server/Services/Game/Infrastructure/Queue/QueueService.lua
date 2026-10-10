-- Queue Service (Rewrite 4)
-- Jack_AviationRBX
-- July 29, 2022


local Players = game:GetService("Players")
local EVENT_QUEUE = "Queue"
local EVENT_QUEUE_SERVER = "QueueServer"


local Queues = {}


local QueueService = {Client = {}}


function QueueService:Init()
    self:RegisterClientEvent(EVENT_QUEUE)
    self:RegisterEvent(EVENT_QUEUE_SERVER)
end


function QueueService:Start()
    -- Activate all queues
    for _,group in pairs(game.Workspace.Infrastructure.Queues:GetChildren()) do
        for _,queue in pairs(group:GetChildren()) do
            self:MonitorQueue(queue, {group, queue:FindFirstChild("Configuration")})
        end
    end
end


function QueueService:MonitorQueue(queue, data)
    Queues[queue.Name] = {
        ["QueueObj"] = queue,
        ["Group"] = data[1],
        ["Config"] = data[2],
        ["PlayersInQueue"] = {},
        ["PlayersGrantedPopup"] = {},
        ["SkipPoints"] = self:GetSkipPoints(queue),
        ["QueuePositionCount"] = self:CountQueuePositions(queue),
        ["PossiblePositions"] = self:GetPossiblePositions(queue),
        ["JoinDebounce"] = false,
        ["GetPlayerDebounce"] = false
    }


    local ZonePart = queue.EntryZone
    local Zone = self.Shared.ZoneModule.new(ZonePart)

    Zone.playerEntered:Connect(function(player)
        -- Permission check
        if not self:ResolveEntryPermissions(player, queue.Name) then
            return
        end

        if #Queues[queue.Name]["PlayersInQueue"] < Queues[queue.Name]["QueuePositionCount"] then
            if not self:PlayerIsInQueue(player, queue.Name) then
                Queues[queue.Name]["PlayersGrantedPopup"][player.UserId] = true
                self:FireClient(EVENT_QUEUE, player, "PopupSet", {"Join Queue"})
            end
        end
    end)

    Zone.playerExited:Connect(function(player)
        Queues[queue.Name]["PlayersGrantedPopup"][player.UserId] = false
        self:FireClient(EVENT_QUEUE, player, "PopupCancel")
    end)
end


function QueueService:GetNextPlayer(queueName, config, callbackOnceMoved)
    if #Queues[queueName]["PlayersInQueue"] > 0 and not Queues[queueName]["GetPlayerDebounce"] then
        if Queues[queueName]["PlayersInQueue"][1].Stationary then
            local Player = Players:GetPlayerByUserId(Queues[queueName]["PlayersInQueue"][1]["UserId"])
            if Player then
                self:FireClient(EVENT_QUEUE, Player, "PopupCancel")

                Queues[queueName]["GetPlayerDebounce"] = true

                if config["TeleportEndPart"] then
                    self.Services.Game.Moderation.TeleportationService:MovePlayerToPart(Player, config["TeleportEndPart"])
                end
                
                -- Animated move-to end skip positions.
                local FinalPositionNum = Queues[queueName]["PossiblePositions"][#Queues[queueName]["PossiblePositions"]]
                if config["MoveEndCompletion"]["Enabled"] then
                    local AdditionalSkipMovements = {}
                    for _,v in pairs(Queues[queueName]["SkipPoints"]) do
                        if tonumber(v) > tonumber(FinalPositionNum) then
                            table.insert(AdditionalSkipMovements, tonumber(v))
                        end
                    end
                    table.sort(AdditionalSkipMovements)
        
                    local Positions = {}
                    for _,v in ipairs(AdditionalSkipMovements) do
                        table.insert(Positions, Queues[queueName]["QueueObj"]["Steps"][tostring(v)].Position)
                    end
                    
                    if config["MoveEndCompletion"]["Additional"] then
                        for _,v in pairs(config["MoveEndCompletion"]["Additional"]) do
                            table.insert(Positions, v)
                        end
                    end

                    task.spawn(function()
                        for _,v in ipairs(Positions) do
                            Player.Character.Humanoid:MoveTo(v)
                            Player.Character.Humanoid.MoveToFinished:Wait()
                        end

                        callbackOnceMoved(Player)
                        Queues[queueName]["GetPlayerDebounce"] = false
                    end)
                end

                -- Thaws if no config setting or set false.
                if not config["Freeze"] then
                    self.Server.Services.Game.Moderation.PlayerControlService:EnableMovement(Player)
                end

                self:RemovePlayerFromQueue(Player.UserId, queueName)
                self:RotateMovementPositions(queueName)

                return Player
            end
        end
    end
end


function QueueService:UpdateStaffInterfaces(queueName)
    self:Fire(EVENT_QUEUE_SERVER, "QueueUpdate", {
        ["QueueType"] = Queues[queueName]["QueueObj"].Parent.Name,
        ["QueueName"] = queueName,
        ["AmountInQueue"] = #Queues[queueName]["PlayersInQueue"]}
    )
end


function QueueService:GetAmountInQueue(queueName)
    return #Queues[queueName]["PlayersInQueue"]
end


function QueueService:GetMovementNodes(queue, currentPlayerPos, finalPlayerPos)
    local Nodes = {}

    local function GetPoints()
        for _,v in ipairs(queue.Steps:GetChildren()) do
            if v:FindFirstChild("Turn") then
                if tonumber(v.Name) > currentPlayerPos and tonumber(v.Name) <= tonumber(finalPlayerPos) then
                    if not Nodes[v.Name] then
                        table.insert(Nodes, tonumber(v.Name))
                    end
                end
            end
        end
    end

    GetPoints()
    table.sort(Nodes)
    
    if #Nodes >= 1 then
        if Nodes[#Nodes] < finalPlayerPos then
            table.insert(Nodes, finalPlayerPos)
        end
    else
        table.insert(Nodes, finalPlayerPos)
    end

    return Nodes
end


function QueueService:MoveCharacterPosition(Player, CurrentPosition, NewPosition)
    if Player then
        self:FireClient(EVENT_QUEUE, Player, "PopupSet", {"Leave Queue"})

        if tonumber(CurrentPosition) == tonumber(NewPosition) then
            return
        end

        local data, queueName, queueData = self:GetPlayerQueueData(Player)

        if not data or not queueName or not queueData then
            return
        end

        if not data["HasStartedQueue"] then
            self.Services.Game.Moderation.TeleportationService:MovePlayerToPart(Player, queueData["QueueObj"]["Start"])
            data["HasStartedQueue"] = true
        end

        data["Stationary"] = false

        local Nodes = self:GetMovementNodes(Queues[queueName]["QueueObj"], data["ActualPosition"], NewPosition)

        local function Move()
            Player.Character:WaitForChild("Humanoid"):MoveTo(Player.Character.PrimaryPart.Position)

            for _,v in ipairs(Nodes) do
                local Node = Queues[queueName]["QueueObj"].Steps:FindFirstChild(tostring(v))
                Player.Character.Humanoid:MoveTo(Node.Position)
                Player.Character.Humanoid.MoveToFinished:Wait()
            end

            if tonumber(NewPosition) == tonumber(queueData["PossiblePositions"][#queueData["PossiblePositions"]]) then
                if self:PlayerIsInQueue(Player, queueName) then
                    self.Services.Game.Moderation.TeleportationService:MovePlayerToPart(Player, Queues[queueName]["QueueObj"]["Steps"][Nodes[#Nodes]])
                end
            end

            data["Stationary"] = true
            data["ActualPosition"] = tonumber(Nodes[#Nodes])
        end
    
        Move()
    end
end


function QueueService:RotateMovementPositions(queueName)
    local QueueData = Queues[queueName]
    local Index = #QueueData["PossiblePositions"]

    -- Reorder all positions
    for _,user in ipairs(Queues[queueName]["PlayersInQueue"]) do
        local Player = Players:GetPlayerByUserId(user.UserId)
        if Player and self:PlayerIsInQueue(Player, queueName) then
            local CurrentPosition = user.Position
            if (QueueData["PossiblePositions"][#QueueData["PossiblePositions"]]) ~= CurrentPosition then
                local NewPosition = QueueData["PossiblePositions"][Index]
                
                if tonumber(NewPosition) ~= tonumber(CurrentPosition) then
                    user.Position = NewPosition
                    table.insert(user.AwaitingMovementTasks, {
                        ["Current"] = CurrentPosition,
                        ["New"] = NewPosition
                    })

                    if not user["MonitoringAdditionalWalk"] then
                        user["MonitoringAdditionalWalk"] = true
                        
                        task.spawn(function()
                            local MovementPaused = false
                            while not MovementPaused do
                                if #user.AwaitingMovementTasks < 1 or not self:PlayerIsInQueue(Player, queueName) then
                                    MovementPaused = true
                                    user["MonitoringAdditionalWalk"] = false
                                else
                                    self:MoveCharacterPosition(Player, user.AwaitingMovementTasks[1].Current, user.AwaitingMovementTasks[1].New)
                                    table.remove(user.AwaitingMovementTasks, 1)
                                end
                            end
                        end)
                    end
                end
            end
            Index -= 1
        else
            self:RemovePlayerFromQueue(user.UserId, queueName)
        end
    end

    self:UpdateStaffInterfaces(queueName)
end


function QueueService:GetPossiblePositions(queue)
    local Positions = {}
    for _,v in pairs(queue.Steps:GetChildren()) do
        if not v:FindFirstChild("QueueEnd") then
            table.insert(Positions, tonumber(v.Name))
        end
    end
    table.sort(Positions)

    return Positions
end


function QueueService:GetSkipPoints(queue)
    local Points = {}
    for _,v in pairs(queue.Steps:GetChildren()) do
        if v:FindFirstChild("QueueEnd") then
            table.insert(Points, v.Name)
        end
    end
    return Points
end


function QueueService.Client:PopupActivated(player, popupText)
    if popupText == "Join Queue" then
        local QueueServiceServer = self.Server.Services.Game.Infrastructure.Queue.QueueService
        local queueName, queueData = QueueServiceServer:GetPlayerJoinQueueData(player)
        if queueName and queueData and not queueData["JoinDebounce"] then
            queueData["JoinDebounce"] = true

            if queueData["PlayersGrantedPopup"][player.UserId] then
                if not QueueServiceServer:ResolveEntryPermissions(player, queueName) then
                    return
                end
                if #Queues[queueName]["PlayersInQueue"] < Queues[queueName]["QueuePositionCount"] then
                    Queues[queueName]["PlayersGrantedPopup"][player.UserId] = false
                    
                    -- Add to queue
                    local NewPlayer = {UserId = player.UserId, Position = 0, Stationary = true, HasStartedQueue = false, ActualPosition = 0, AwaitingMovementTasks = {}}
                    table.insert(Queues[queueName]["PlayersInQueue"], NewPlayer)

                    -- Freeze
                    self.Server.Services.Game.Moderation.PlayerControlService:DisableMovement(player)

                    -- Update Positions
                    self.Server.Services.Game.Infrastructure.Queue.QueueService:RotateMovementPositions(queueName)

                    task.wait(1)
                    queueData["JoinDebounce"] = false

                    self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Joined Queue!")
                end
            end
        end
    elseif popupText == "Leave Queue" then
        local data, queueName, queueData = self.Server.Services.Game.Infrastructure.Queue.QueueService:GetPlayerQueueData(player)
        if data and queueName and queueData then
            self.Server.Services.Game.Infrastructure.Queue.QueueService:RemovePlayerFromQueue(player.UserId, queueName)
            self.Server.Services.Game.Moderation.TeleportationService:MovePlayerToPart(player, Queues[queueName]["QueueObj"]["SendBack"])
            self.Server.Services.Game.Moderation.PlayerControlService:EnableMovement(player)
            self.Server.Services.Game.Infrastructure.Queue.QueueService:RotateMovementPositions(queueName)
        end

        self.Server.Services.Game.Infrastructure.Queue.QueueService:FireClient(EVENT_QUEUE, player, "PopupCancel")
        self.Server.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Left Queue!")
    end
end


function QueueService:RemovePlayerFromQueue(userId, queueName)
    for i,tbl in pairs(Queues[queueName]["PlayersInQueue"]) do
        if tbl.UserId == userId then
            table.remove(Queues[queueName]["PlayersInQueue"], i)
        end
    end
end


function QueueService:GetPlayerJoinQueueData(player)
    for queueName,tbl in pairs(Queues) do
        if tbl["PlayersGrantedPopup"][player.UserId] then
            return queueName, tbl
        end
    end
end


function QueueService:GetPlayerQueueData(player)
    for queueName,tbl in pairs(Queues) do
        for _,v in pairs(tbl["PlayersInQueue"]) do
            if v.UserId == player.UserId then
                -- Returns player data, queueName, queueData
                return v, queueName, tbl
            end
        end
    end
end


function QueueService:PlayerIsInQueue(player, queueNameOptional)
    local function iterateTable(tbl)
        for _,v in pairs(tbl) do
            if v.UserId == player.UserId then
                return true
            end
        end
    end

    if queueNameOptional then
        if Queues[queueNameOptional] then
            local result = iterateTable(Queues[queueNameOptional]["PlayersInQueue"])
            if result then
                return true
            end
        end
    else
        for _,tbl in pairs(Queues) do
            local result = iterateTable(tbl["PlayersInQueue"])
            if result then
                return true
            end
        end
    end
end


function QueueService:ResolveEntryPermissions(player, queueName)
    local Configuration = Queues[queueName]["Config"]

    if not Queues[queueName]["Config"]["Enabled"].Value then
        return false
    end

    -- Booked access (allows booked class level only)
    if Configuration:FindFirstChild("ClassRestrictionBooked") then
        if Configuration.ClassRestrictionBooked.Value == nil then
            return false
        else
            local ClassBookedLevel = self.Services.Data.ClassService:GetBookedLevel(player.UserId)
            local ClassRequiredLevel = self.Services.Data.ClassService:GetClassLevelByName(Configuration["ClassRestrictionBooked"].Value)

            if ClassBookedLevel == ClassRequiredLevel then
                return true
            end
        end
    -- Obtained classes only (high perm class level and below + booked class level and below)
    elseif Configuration:FindFirstChild("ClassRestrictionObtained") then
        local ClassesObtained = self.Services.Data.ClassService:GetClassAccessabilities(player)

        if table.find(ClassesObtained, Configuration["ClassRestrictionObtained"].Value) then
            return true
        end
    else
        -- If no settings and booked, let through
        local booked =  self.Services.Data.ClassService:IsBooked(player.UserId)
        if booked then
            return true
        end
    end
end


function QueueService:CountQueuePositions(queue)
    local Count = 0
    for _,v in pairs(queue.Steps:GetChildren()) do
        if not v:FindFirstChild("QueueEnd") then
            Count += 1
        end
    end
    return Count
end


return QueueService