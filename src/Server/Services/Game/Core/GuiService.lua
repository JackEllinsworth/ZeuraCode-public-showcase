-- Gui Service
-- Jack_AviationRBX
-- September 5, 2021

--[[

GuiService is intended to make GUI's load to certain player's player guis on join.
This ensures only the required GUI's are loaded for the particular player.

--]]


local EVENT_GUI = "GuiControllerLoad"


local GuiService = {Client = {}}


function GuiService:Init()
    self:RegisterClientEvent(EVENT_GUI)
end


function GuiService:IssueGui(player, guiObject)
    local NewGui = guiObject:Clone()

    if not player.PlayerGui:FindFirstChild(guiObject.Name) then
        NewGui.Parent = player.PlayerGui
    end

    if NewGui:FindFirstChild("Controller") then
        local ControllerName = NewGui["Controller"].Value
        self:FireClient(EVENT_GUI, player, ControllerName, NewGui)
    end
end


function GuiService:LoadGUIs(player)
    local GUIs = game.ServerStorage:FindFirstChild("GUIs")

    for _, permissionFolder in ipairs(GUIs:GetChildren()) do
        local PermissionName = permissionFolder.Name
        local HasPermission = false

        if not self.Modules.Config.Permissions[PermissionName] then
            HasPermission = true
        else
            HasPermission = self.Services.Data.PermissionService:HasPermission(player.UserId, PermissionName)
        end

        if HasPermission then
            for _,categoryFolder in ipairs(permissionFolder:GetChildren()) do
                for _,gui in ipairs(categoryFolder:GetChildren()) do
                    self:IssueGui(player, gui, categoryFolder.Name)
                end
            end
        end
    end
end


return GuiService