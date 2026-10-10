-- Initialize Controller
-- Jack_AviationRBX
-- September 5, 2021

--[[

InitializeController activates all necessary controllers on the local player's client.
This is generally used via the GuiService event, so only certain controllers are activated,
hence saving game resources and allowing a faster loading time.

--]]

local GUIEnabledLog = {}
local PhotoModeEnabled = false

local LoadedControllers = {}


local InitializeController = {Client = {}}


function InitializeController:Start()
    --> Initialize GUI Controllers
    self.Services.Game.Core.GuiService.GuiControllerLoad:Connect(function(controller, guiObject)
        if not table.find(LoadedControllers, controller) then
            table.insert(LoadedControllers, controller)
            local Controller = self:GetController(controller)
            if Controller then
                warn("[InitializeController] -> Activated GUI Controller:", controller)
                Controller:Activate(guiObject)
            end
        end
    end)

    --> Initialize Cmdr Client
    self:StartCmdr()

    --> Set CoreGUI Defaults
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end


function InitializeController:PhotoMode(setting)
    if setting then
        PhotoModeEnabled = true
        GUIEnabledLog = {}
        for _,v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if v.Enabled then
                v.Enabled = false
                table.insert(GUIEnabledLog, v.Name)
            end
        end
    else
        if GUIEnabledLog then
            for _,v in pairs(GUIEnabledLog) do
                if game.Players.LocalPlayer.PlayerGui:FindFirstChild(v) then
                    game.Players.LocalPlayer.PlayerGui[v].Enabled = true
                end
            end
            PhotoModeEnabled = false
        end
    end
end


function InitializeController:StartCmdr()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))

    -- Configurable, and you can choose multiple keys
    Cmdr:SetActivationKeys({Enum.KeyCode.Semicolon})
end


function InitializeController:GetController(controllerName)
    local Controller

    local function SearchDirectory(directory)
        for index,value in pairs(directory) do
            if index == controllerName then
                Controller = directory[index]
                return
            elseif typeof(value) == "table" then
                SearchDirectory(value)
            end
        end
    end

    SearchDirectory(self.Controllers)
    
    return Controller
end


return InitializeController