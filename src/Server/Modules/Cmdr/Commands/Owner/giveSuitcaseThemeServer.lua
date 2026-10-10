return function (context, player, themeName)
    local Aero = _G.Aero
    local Success = Aero.Services.Data.SuitcaseService:GrantUserTheme(player, themeName)

    if Success then
        context:Reply("Successfully gave "..player.Name.." theme: "..themeName)
    else
        context:Reply("An error occured.")
    end
end