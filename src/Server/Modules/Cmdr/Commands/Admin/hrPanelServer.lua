return function (context)
    local Aero = _G.Aero
    Aero.Services.Game.Moderation.HRPanelService:OpenClose(context.Executor)
    context:Reply("Opened/closed panel successfully.")
end