-- Tool Service
-- Jack_AviationRBX
-- March 13, 2022


--[[
    Saves the tools issued to a player, allows for re-joining players to collect their previous tools.
--]]


local ToolStore = {}


local ToolService = {Client = {}}


function ToolService:FindTool(toolName)
    for _,v in pairs(game.ServerStorage.Tools:GetDescendants()) do
        if v:IsA("Tool") then
            if v.Name == toolName then
                return v
            end
        end
    end
end


function ToolService:IssueTool(player, toolName)
    if not ToolStore[player.UserId] then
        ToolStore[player.UserId] = {}
    end

    if not table.find(ToolStore[player.UserId], toolName) then

        local Tool = self:FindTool(toolName)
        if Tool then
            local NewTool = Tool:Clone()
            NewTool.Parent = player.Backpack
            table.insert(ToolStore[player.UserId], toolName)
            
            return true, NewTool
        end
    end
end


function ToolService:PlayerHasToolObject(player, toolName)
    local Backpack = player:WaitForChild("Backpack")
    local Character = player.Character
    local Tool

    local function checkExistance(model_location)
        Tool = model_location:FindFirstChild(toolName)
        if Tool and Tool:IsA("Tool") then
            return true
        else
            return false
        end
    end

    if checkExistance(Backpack) or checkExistance(Character) then
        return true, Tool
    end
end


function ToolService:RevokeTool(player, toolName)
    if ToolStore[player.UserId] then
        local Index = table.find(ToolStore[player.UserId], toolName)
        if Index then
            table.remove(ToolStore[player.UserId], Index)
        end
    end

    if self:PlayerHasToolObject(player, toolName) then
        local Backpack = player:WaitForChild("Backpack")
        local Character = player.Character

        if Backpack:FindFirstChild(toolName) then
            Backpack[toolName]:Destroy()
        elseif Character:FindFirstChild("Suitcase") then
            Character[toolName]:Destroy()
        end
    end
end


function ToolService:ReobtainTools(player)
    if not ToolStore[player.UserId] then
        return
    end
    for _, tool in ipairs(ToolStore[player.UserId]) do
        local ToolObject = self:FindTool(tool)
        if not self:PlayerHasToolObject(player, tool) then
            local NewTool = ToolObject:Clone()
            NewTool.Parent = player.Backpack
        end
    end
end


return ToolService