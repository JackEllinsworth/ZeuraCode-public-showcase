-- Scanners Service
-- Jack_AviationRBX
-- July 27, 2022


local TweenService = game:GetService("TweenService")
local STAFF_ACCESS_TOOL_NAME = "Staff Access"

local ScannersService = {Client = {}}


function ScannersService:Start()
    for _,v in pairs(game.Workspace.Infrastructure.Scanners:GetChildren()) do
        for _,b in pairs(v:GetChildren()) do
            if b.Name == "Scanner" then
                self:ManageScanner(b)
            end
        end
    end

    for _,gate in pairs(game.Workspace.Infrastructure.Scanners.BoardingTicket.Gates:GetChildren()) do
        for _,scanner in pairs(gate:GetChildren()) do
            self:ManageScanner(scanner)
        end
    end

    warn("[ScannersService] All scanners are now activated & being monitored.")
end


function ScannersService:ResolveAccessBool(player, config, toolName)
    -- Staff access
    if toolName == STAFF_ACCESS_TOOL_NAME then
        if self.Services.Data.PermissionService:HasPermission(player.UserId, "Staff") then
            return true
        end
    end
    -- Booked access (allows booked class level only)
    if config:FindFirstChild("ClassRestrictionBooked") then
        if config.ClassRestrictionBooked.Value == "None" or config.ClassRestrictionBooked.Value == nil then
            return false
        else
            local ClassBookedLevel = self.Services.Data.ClassService:GetBookedLevel(player.UserId)
            local ClassRequiredLevel = self.Services.Data.ClassService:GetClassLevelByName(config["ClassRestrictionBooked"].Value)

            if ClassBookedLevel >= ClassRequiredLevel then
                return true
            end
        end
    -- Obtained classes only (high perm class level and below + booked class level and below)
    elseif config:FindFirstChild("ClassRestrictionObtained") then
        local ClassesObtained = self.Services.Data.ClassService:GetClassAccessabilities(player)

        if table.find(ClassesObtained, config["ClassRestrictionObtained"].Value) then
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


function ScannersService:MoveGate(door)
    local TweenTable = {Position = door.Parent.Parent.OpenPos.Position}

    local function getTween(tweenTbl, enum)
        local Tween = TweenService:Create(
            door,
            TweenInfo.new(1, Enum.EasingStyle.Sine, enum),
            tweenTbl
        )
        return Tween
    end

    getTween(TweenTable, Enum.EasingDirection.Out):Play()

    task.wait(1)

    TweenTable = {Position = door.Parent.Parent.ClosedPos.Position}

    getTween(TweenTable, Enum.EasingDirection.In):Play()
end



function ScannersService:ManageScanner(scanner)

    -- ClassRestrictionObtained includes all perm tickets and the current booked ticket.
    -- This is for general lounge access

    -- ClassRestrictionBooked is for the scanners at the gate - only allows people in with that booked ticket.
    
    local occupant = nil
    local debounce = false
    local Config = scanner.Configuration
    local AllowedIn = true
    local active = false
    if scanner.Model:FindFirstChild("Reset") then
        scanner.Model.Reset.ClickDetector.MouseClick:Connect(function(player)
            if self.Services.Data.PermissionService:HasPermission(player.UserId, "Admin") then
                occupant = nil
                AllowedIn = true
                scanner.Model.signalFRONT.control.main.open.Visible = true
                scanner.Model.signalFRONT.control.main.closed.Visible = false
            end
        end)
    end

    if scanner.Model:FindFirstChild("PlayerDetection") then
        scanner.Model.PlayerDetection.Touched:Connect(function(hit)
            if AllowedIn and occupant then
                AllowedIn = true
                occupant = false
            end

            local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent.Parent)
            if player then
                occupant = player
            end
        end)
    end

    if scanner.Model:FindFirstChild("scanBlock") then
        
        scanner.Model.scanBlock.Touched:Connect(function(hit)
            if self.Modules.Config.Classes[hit.Parent.Name] or hit.Parent.Name == STAFF_ACCESS_TOOL_NAME then
                local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent.Parent)
                if not debounce and player then
                    debounce = true
                    local Allowed = self:ResolveAccessBool(player, Config, hit.Parent.Name)
    
                    if Allowed and AllowedIn then
                        AllowedIn = false

                        task.spawn(function()
                            for _,v in pairs(scanner.Model.led:GetChildren()) do
                                v.Color = Color3.fromRGB(0, 255, 0)
                            end

                            task.wait(2)

                            scanner.Model.signalFRONT.control.main.open.Visible = false
                            scanner.Model.signalFRONT.control.main.closed.Visible = true
                            
                            for _,v in pairs(scanner.Model.led:GetChildren()) do
                                v.Color = Color3.fromRGB(255, 0, 0)
                            end
                        end)

                        task.spawn(function()
                            scanner.Model.door1.DOOR.METAL.Transparency = 1
                            self:MoveGate(scanner.Model.door1.DOOR.GLASS)
                            task.wait(1)
                            scanner.Model.door1.DOOR.METAL.Transparency = 0
                        end)

                        task.spawn(function()
                            scanner.Model.door2.DOOR.METAL.Transparency = 1
                            self:MoveGate(scanner.Model.door2.DOOR.GLASS)
                            task.wait(1)
                            scanner.Model.door2.DOOR.METAL.Transparency = 0
                        end)
                    end
    
                    task.wait(3)

                    if not scanner.Model:FindFirstChild("scanBlock2") or not occupant then
                        scanner.Model.signalFRONT.control.main.open.Visible = true
                        scanner.Model.signalFRONT.control.main.closed.Visible = false
                        AllowedIn = true
                    end

                    debounce = false
                end
            end
        end)
    end

    if scanner.Model:FindFirstChild("scanBlock2") then
        scanner.Model.scanBlock2.Touched:Connect(function(hit)
            if hit.Parent.Name == "Passport" then
                local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent.Parent)

                if not active then
                    active = true
                    -- Gui control
                    scanner.Model.Model.screen.SurfaceGui.Scanning.Visible = true
                    scanner.Model.Model.screen.SurfaceGui.FramePlace.Visible = false
                    scanner.Model.Model.screen.SurfaceGui.Proceed.Visible = false

                    local TweenInformation = TweenInfo.new(1.25,
                    Enum.EasingStyle.Linear);
                    local RotateArea = scanner.Model.Model.screen.SurfaceGui.Scanning.Icon
                    local Iterations = 0

                    local function allowLeave()
                        occupant = nil

                        scanner.Model.door3.D2.Motor.DesiredAngle = 1.6
                        scanner.Model.door4.D1.Motor.DesiredAngle = 1.6
    
                        task.wait(3)
    
                        scanner.Model.door3.D2.Motor.DesiredAngle = 0
                        scanner.Model.door4.D1.Motor.DesiredAngle = 0
                        
                        task.wait(1)
                        
                        AllowedIn = true

                        scanner.Model.signalFRONT.control.main.open.Visible = true
                        scanner.Model.signalFRONT.control.main.closed.Visible = false

                        scanner.Model.Model.screen.SurfaceGui.FramePlace.Visible = true
                        scanner.Model.Model.screen.SurfaceGui.Proceed.Visible = false
                        scanner.Model.Model.screen.SurfaceGui.Scanning.Visible = false
                        active = false
                    end

                    local function Tween()
                        if Iterations >= 3 then
                            scanner.Model.Model.screen.SurfaceGui.FramePlace.Visible = false
                            scanner.Model.Model.screen.SurfaceGui.Proceed.Visible = true
                            scanner.Model.Model.screen.SurfaceGui.Scanning.Visible = false

                            if player then
                                self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Authorised!")
                            end
                            allowLeave()
                            return
                        else
                            RotateArea.Rotation = 0;
                            Iterations = Iterations + 1
                            local Create = game:GetService("TweenService"):Create(RotateArea, TweenInformation, {Rotation = 359.9});
                            Create.Completed:Connect(Tween);
                            Create:Play();
                        end
                    end

                    Tween()
                end
            end
        end)
    end
end


return ScannersService