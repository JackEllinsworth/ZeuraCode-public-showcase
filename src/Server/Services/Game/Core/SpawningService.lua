-- Spawning Service
-- Jack_AviationRBX
-- July 24, 2022

--[[

Spawns an aircraft into the game at a certain location.

--]]


local InsertService =  game:GetService("InsertService")

local SpawningService = {Client = {}}


-- Aircrafts

function SpawningService:Start()
    self:MonitorExternalAircrafts()
end

function SpawningService:SpawnAircraft(aircraftName, position, forceModel)
    local NameOfPlane, RegCode, Summary = self:GetAircraftReg(aircraftName)
    
    local InsertId = self.Modules.Config.Aircrafts[aircraftName].InsertId

    local success, aircraft

    if not forceModel then
        success, aircraft = pcall(function()
            return InsertService:LoadAsset(InsertId)
        end)
    end

    if success or forceModel then

        if not forceModel then
            aircraft.Parent = game.Workspace.Infrastructure.Aircrafts
            aircraft.Name = aircraftName
            aircraft:MoveTo(position)
        else
            aircraft = forceModel
        end

        local function createData(parent)
            -- Insert data required for IFE
            local Folder = Instance.new("Folder", parent)
            Folder.Name = "GeneratedAircraftUtil"
            
            local SummaryValue = Instance.new("StringValue", Folder)
            SummaryValue.Name = "SummaryAbout"
            SummaryValue.Value = Summary

            local NameValue = Instance.new("StringValue", Folder)
            NameValue.Name = "AircraftName"
            NameValue.Value = NameOfPlane

            local RegValue = Instance.new("StringValue", Folder)
            RegValue.Name = "RegCode"
            RegValue.Value = RegCode
        end

        -- Place reg code onto aircraft
        local FoundAll = 0

        for _,v in ipairs(aircraft:GetDescendants()) do
            if v.Name == "RegPlate" then
                if aircraftName == "777-300ER" then
                    local SecondToLast = string.sub(RegCode, #RegCode-1,#RegCode-1)
                    local Last = string.sub(RegCode, #RegCode,#RegCode)
                    v.HALF_REG.SurfaceGui.TextBox.Text = SecondToLast..Last
                end
                for _,b in pairs(v:GetChildren()) do
                    if b.Name == "REG" then
                        b.SurfaceGui.TextLabel.Text = RegCode
                    elseif b.Name == "P_NAME" then
                        b.SurfaceGui.TextBox.Text = NameOfPlane
                    end
                end
                FoundAll += 0.5
            elseif v.Name == "IFEs" then
                createData(v)
                self.Services.Game.Infrastructure.IFEService:MonitorIFEButtons(v)
                FoundAll += 0.5
            end

            if FoundAll == 1 then
                warn("[SpawningService] Loaded plane reg + ife config")
                break
            end
        end
        
        return true, aircraft
    end
end


function SpawningService:GetAircraftReg(aircraftName)
    local Location = self.Modules.Config.Aircrafts[aircraftName]["Names"]
    local PossibleNames = #Location
    local SelectedName = Location[math.random(1, PossibleNames)]

    return SelectedName["Name"], SelectedName["RegCode"], SelectedName["Summary"]
end


function SpawningService:DespawnAircrafts()
    for _,v in pairs(game.Workspace.Infrastructure.Aircrafts:GetChildren()) do
        v:Destroy()
    end
end


function SpawningService:GetPossibleAircrafts()
    local Names = {}
    for name,_ in pairs(self.Modules.Config.Aircrafts) do
        table.insert(Names, name)
    end
    return Names
end

function SpawningService:MonitorExternalAircrafts()
    game.Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") and table.find(self:GetPossibleAircrafts(), child.Name) then
            self:SpawnAircraft(child.Name, false, child)
        end
    end)
end



return SpawningService