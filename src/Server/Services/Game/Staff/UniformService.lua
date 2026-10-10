-- Uniform Service
-- Jack_AviationRBX
-- July 22, 2022

--[[

Sets the appropriate uniform to certain staff roles. Exclusions are possible for certain ranks (e.g HR) via commands.

--]]

local EVENT_UNIFORM = "Uniform"
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")


local UniformService = {Client = {}}


function UniformService:Init()
    self:RegisterClientEvent(EVENT_UNIFORM)
end


function UniformService:Start()
    local ToLoad = {}
    for _,v in pairs(self.Modules.Config.Uniform) do
        if v["Variant"] then
            table.insert(ToLoad, "http://www.roblox.com/asset/?id="..tostring(v["Variant"]["ShirtId"]))
            table.insert(ToLoad, "http://www.roblox.com/asset/?id="..tostring(v["Variant"]["PantsId"]))
        elseif v["Variants"] then
            for _,b in pairs(v["Variants"]) do
                table.insert(ToLoad, "http://www.roblox.com/asset/?id="..tostring(b["ShirtId"]))
                table.insert(ToLoad, "http://www.roblox.com/asset/?id="..tostring(b["PantsId"]))
            end
        end
    end

    ContentProvider:PreloadAsync(ToLoad)
end


function UniformService:IssueUniform(player, roleName)
    self.Services.Game.Staff.LanyardService:IssueLanyard(player)
    
    local RoleConfig = self.Modules.Config.Uniform
    if not RoleConfig[roleName] then
        return
    else
        RoleConfig = RoleConfig[roleName]
    end

    if RoleConfig["Singular"] then
        local Ids = RoleConfig["Variant"]
        self:SetClothing(player, Ids["ShirtId"], Ids["PantsId"])
    else
        local Variants = {}
        for i,_ in pairs(RoleConfig.Variants) do
            table.insert(Variants, i)
        end

        self:FireClient(EVENT_UNIFORM, player, roleName, Variants)
    end
end


function UniformService:SetClothing(player, shirtId, pantsId)
    local ShirtArea = player.Character:FindFirstChild("Shirt")
    local PantsArea = player.Character:FindFirstChild("Pants")
    ShirtArea.ShirtTemplate = "http://www.roblox.com/asset/?id="..tostring(shirtId)
    PantsArea.PantsTemplate = "http://www.roblox.com/asset/?id="..tostring(pantsId)
end


function UniformService.Client:RequestUniformVariant(player, roleName, optionSelected)
    if self.Server.Services.Data.PermissionService:HasPermission(player.UserId, "Trainee") then
        if player.Character:FindFirstChild("Humanoid") then
            local Variant = self.Server.Modules.Config.Uniform[roleName]["Variants"][optionSelected]
            self.Server.Services.Game.Staff.UniformService:SetClothing(player, Variant["ShirtId"], Variant["PantsId"])
        end
    end
end




return UniformService