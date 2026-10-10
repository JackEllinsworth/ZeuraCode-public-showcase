return function (context, player)
    local Aero = _G.Aero
    local UserId = player.UserId
    local AvailableClasses = Aero.Services.Data.CacheService:GetRow("ClassStore", UserId, "availableClasses")
    
    --> Classes
    local FormattedString = "<- Available Classes ->"
    
    if AvailableClasses then
        for _,v in ipairs(AvailableClasses) do
            FormattedString = FormattedString.."\n"..v["className"].." (Amount: "..tostring(v["amount"])..")"
        end
    end

    --> Permissions
    local CalcPermissionLevel = Aero.Services.Data.CacheService:GetRow("PermissionStore", UserId, "permission")
    local CalcPermissionName = "N/A"

    if CalcPermissionLevel and CalcPermissionLevel >= 1 then
        CalcPermissionName = Aero.Services.Data.PermissionService:GetNameByLevel(CalcPermissionLevel)
    else
        CalcPermissionLevel = 0
    end

    local IsBeta = tostring(Aero.Services.Data.CacheService:GetRow("PermissionStore", UserId, "beta"))

    FormattedString = FormattedString.."\n\n<- Permissions ->"
    FormattedString = FormattedString.."\nCalculated Permission Level: "..tostring(CalcPermissionLevel)
    FormattedString = FormattedString.."\nAssigned Permission Name: "..tostring(CalcPermissionName)
    FormattedString = FormattedString.."\nBeta Status: "..IsBeta

    --> Player Data
    local PlayerData = Aero.Services.Data.ProfileService:GetProfileAsync(UserId)
    local AcceptedDisplays = {"rankId", "miles"}

    if PlayerData then
        
        FormattedString = FormattedString.."\n\n<- Player Data ->"
        for _,v in pairs(AcceptedDisplays) do
            FormattedString = FormattedString.."\n"..v..": "..tostring(PlayerData[v])
        end
    end

    FormattedString = FormattedString.."\n\n<- Game Data ->"
    local BookedClass = Aero.Services.Data.ClassService:GetBookedClass(UserId)
    if not BookedClass then
        BookedClass = "N/A"
    end

    FormattedString = FormattedString.."\nBooked class: "..BookedClass

    local TeamName = Aero.Services.Game.Core.LeaderboardService:GetPlayerTeam(player)
    FormattedString = FormattedString.."\nSet team: "..TeamName
    

    context:Reply(FormattedString)
    
end