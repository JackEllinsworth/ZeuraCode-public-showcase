return function (context, userId, reason)
    local Aero = _G.Aero
    local Success,_ = Aero.Services.Data.ModerationService:IssueInfraction(
        userId, "Warn", reason, context.Executor.UserId)

    if Success then
        context:Reply("Successfully warned! If the server isn't online, this users warning won't stay on their record.")
    end
end