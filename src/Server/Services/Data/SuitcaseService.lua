-- Suitcase Service
-- Jack_AviationRBX
-- March 13, 2022

--[[

SuitcaseService allows tags to be created for customers luggage, which also saves to enable the same tags to appear
at luggage collection.

--]]


local LuggageStore = {}
local Defaults = {
    ["MinWeight"] = 5,
    ["MaxWeight"] = 30
}
local SuitcaseCooldown = {}
local EVENT_SUITCASE = "Suitcase"
local DEFAULT_BAG_NAME = "Default"


local SuitcaseService = {Client = {}}


function SuitcaseService:Init()
    SuitcaseService:RegisterClientEvent(EVENT_SUITCASE)
end


function SuitcaseService:Start()
    -- Monitor purchases
    local AssetLocators = {}
    for theme, id in pairs(self.Modules.Config.SuitcaseThemes) do
        AssetLocators[id] = theme
    end

    self.Services.Data.PurchaseService:SetPurchaseMonitor("SuitcaseTheme", AssetLocators, false, false, function(player, _, themeName)
        local Success = self:GrantUserTheme(player, themeName)
        if Success then
            spawn(self:SetEnabledTheme(player, themeName))
        end
        return Success
    end)

end


function SuitcaseService:GrantUserTheme(player, themeName)
    local UniqueData = self.Services.Data.ProfileService:GetAsync(player.UserId, "uniqueData")
    local UpdateData = self.Shared.TableUtil.Copy(UniqueData)

    if UniqueData["SuitcaseThemes"] then
        if table.find(UniqueData["SuitcaseThemes"]["Purchases"], themeName) then
            return true
        end
    end

    if not self.Modules.Config.SuitcaseThemes[themeName] then
        return false
    end

    if themeName ~= DEFAULT_BAG_NAME then
        if UniqueData["SuitcaseThemes"] then
            if not table.find(UniqueData["SuitcaseThemes"]["Purchases"], themeName) then
                table.insert(UpdateData["SuitcaseThemes"]["Purchases"], themeName)
                self.Services.Data.ProfileService:UpdateAsync(player.UserId, "uniqueData", UpdateData)
            end
        else
            UpdateData["SuitcaseThemes"] = {
                ["EnabledTheme"] = "",
                ["Purchases"] = {
                    themeName
                }
            }
            self.Services.Data.ProfileService:UpdateAsync(player.UserId, "uniqueData", UpdateData)
        end

        -- dupe purchases for some reason??
        local Success = self.Services.Data.ProfileService:Save(player.UserId)

        if not Success then
            -- Revert to old update status
            self.Services.Data.ProfileService:UpdateAsync(player.UserId, "uniqueData", UniqueData)
            return false
        else
            self:FireClient(EVENT_SUITCASE, player, "NewTheme", themeName)
            return true
        end
    end
end


function SuitcaseService:GenerateCode(option)
    local Numbers = {}
    local Code = nil
    if option == "small" then
        for _ = 1, 6 do
            table.insert(Numbers, tostring(math.random(1, 9)))
        end

        Code = table.concat(Numbers, " ")
        Code = Code.." - Z A"
    elseif option == "large" then
        for _ = 1, 13 do
            table.insert(Numbers, tostring(math.random(1, 9)))
        end
    
        Code = table.concat(Numbers, "")
    end

    return Code
end


function SuitcaseService:SetDefaults(_type, data)
    Defaults[_type] = data
end


function SuitcaseService:SaveLuggageData(player)
    local userId = player.UserId
    local weight = math.random(Defaults.MinWeight, Defaults.MaxWeight)
    local username = player.Name
    local smallCode = SuitcaseService:GenerateCode("small")
    local largeCode = SuitcaseService:GenerateCode("large")
    local destCode = self.Services.Data.CacheService:GetRow("FlightStore", "_currentFlight", "DestinationCode")
    local flightNumber = self.Services.Data.CacheService:GetRow("FlightStore", "_currentFlight", "FlightNumber")
    
    local Table = {
        UserId = userId,
        Weight = weight,
        Username = username,
        SmallCode = smallCode,
        LargeCode = largeCode,
        DestCode = destCode,
        FlightNumber = flightNumber
    }
    table.insert(LuggageStore, Table)

    return Table
end


function SuitcaseService:GetLuggageStore()
    return LuggageStore
end


function SuitcaseService:LuggageExists(userId)
    for i,v in pairs(LuggageStore) do
        if v["UserId"] == userId then
            return true, v
        end
    end
end


function SuitcaseService:CustomiseSuitcase(player, tool)
    -- Customize tool
    local UniqueData = self.Services.Data.ProfileService:GetAsync(player.UserId, "uniqueData")
    local Theme = DEFAULT_BAG_NAME

    if UniqueData and UniqueData["SuitcaseThemes"] then
        if UniqueData["SuitcaseThemes"]["EnabledTheme"] ~= "" then
            Theme = UniqueData["SuitcaseThemes"]["EnabledTheme"]
        end
    end

    -- Delete previous textures
    for _,v in pairs(tool.Colour:GetChildren()) do -- index nil with colour?
        if v:IsA("Texture") then
            v:Destroy()
        end
    end

    if not game.ServerStorage.Models.SuitcaseCustomisation:FindFirstChild(Theme) then
        Theme = DEFAULT_BAG_NAME
    end

    -- Fetch theme textures
    local Textures = game.ServerStorage.Models.SuitcaseCustomisation[Theme]:GetChildren()
    for _,texture in pairs(Textures) do
        if texture:IsA("Texture") then
            texture:Clone().Parent = tool.Colour
        end
    end

    tool.Colour.Color = game.ServerStorage.Models.SuitcaseCustomisation[Theme]["Colour"].Value

    return true
end


function SuitcaseService:GiveSuitcase(player, force)
    if not self:LuggageExists(player.UserId) or force then
        local HasTool, Tool = self.Services.Game.Core.ToolService:PlayerHasToolObject(player, "Suitcase")

        if HasTool and Tool then
            return self:CustomiseSuitcase(player, Tool)
        end

        local Success, Tool = self.Services.Game.Core.ToolService:IssueTool(player, "Suitcase")
        
        if Success and Tool then
            return self:CustomiseSuitcase(player, Tool)
        end
    end
end


function SuitcaseService:GiveArrivalSuitcase(player)
    local Exists, tbl = self:LuggageExists(player.UserId)
    if Exists then
        local Success, Tool = self.Services.Game.Core.ToolService:IssueTool(player, "Suitcase ")
        
        if Success and Tool then

            local Tag = Tool.Tag.Tag.ImageLabel
            Tag.Destination.Text = tbl.DestCode
            Tag.FlightNumber.Text = tbl.FlightNumber
            Tag.PassengerName.Text = tbl.Username
            Tag.ShortCode.Text = tbl.SmallCode
            Tag.Weight.Text = tostring(tbl.Weight).."kg"

            return self:CustomiseSuitcase(player, Tool)
        end
    end
end


function SuitcaseService:SetEnabledTheme(player, newTheme)
    local UpdateData = self.Shared.TableUtil.Copy(self.Services.Data.ProfileService:GetAsync(player.UserId, "uniqueData"))

    if game.ServerStorage.Models.SuitcaseCustomisation[newTheme] then
        -- Check if has purchases, if so, allow theme change.
        local ChangeMade = false

        if UpdateData["SuitcaseThemes"] then
            if table.find(UpdateData["SuitcaseThemes"]["Purchases"], newTheme) or newTheme == DEFAULT_BAG_NAME then
                if UpdateData["SuitcaseThemes"]["EnabledTheme"] ~= newTheme then
                    UpdateData["SuitcaseThemes"]["EnabledTheme"] = newTheme

                    self.Services.Data.ProfileService:UpdateAsync(player.UserId, "uniqueData", UpdateData)
                    ChangeMade = true
                end
            end
        end

        if ChangeMade then
            -- Update suitcase tool model for player if in inventory.
            local Success, Tool = self.Services.Game.Core.ToolService:PlayerHasToolObject(player, "Suitcase")
            if Success and Tool then
                self:CustomiseSuitcase(player, Tool)
            end

            self.Services.Game.Core.AnnouncementService:IssueEventNotification(player, "Suitcase Theme Updated!")

            self:FireClient(EVENT_SUITCASE, player, "ThemeEnabled", newTheme)
            return true
        end
    else
        return
    end
end


function SuitcaseService.Client:RequestClientThemes(player)
    local UniqueData = self.Server.Shared.TableUtil.Copy(self.Server.Services.Data.ProfileService:GetAsync(player.UserId, "uniqueData"))
    local Themes = {
        ["Themes"] = {DEFAULT_BAG_NAME},
        ["Enabled"] = ""
    }

    if UniqueData["SuitcaseThemes"] then
        if UniqueData["SuitcaseThemes"]["EnabledTheme"] ~= "" then
            Themes["Enabled"] = UniqueData["SuitcaseThemes"]["EnabledTheme"]
        else
            Themes["Enabled"] = DEFAULT_BAG_NAME
        end
        if #UniqueData["SuitcaseThemes"]["Purchases"] >= 1 then
            for _,v in pairs(UniqueData["SuitcaseThemes"]["Purchases"]) do
                table.insert(Themes["Themes"], v)
            end
        end
    end

    return Themes["Themes"], Themes["Enabled"]
end


function SuitcaseService.Client:RequestClientThemeChange(player, themeName)
    if not SuitcaseCooldown[player.UserId] then
        SuitcaseCooldown[player.UserId] = true
        self.Server.Services.Data.SuitcaseService:SetEnabledTheme(player, themeName)
        task.wait(1.5)
        SuitcaseCooldown[player.UserId] = false
    end
end


return SuitcaseService