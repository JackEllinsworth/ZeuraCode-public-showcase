return function (context)
    local Aero = _G.Aero
    Aero.Modules.Config.BetaDefaultPermission = "Admin"

    for _,v in pairs(game.Players:GetChildren()) do
        Aero.Services.Data.PermissionService:CalculatePermissions(v)
        Aero.Services.Game.Core.GuiService:LoadGUIs(v)
    end

    context:Reply("Success")
end