return function (context, userId, reason)
    local Aero = _G.Aero
    local Success,_ = Aero.Services.Data.ModerationService:IssueInfraction(
        userId, "Kick", reason, context.Executor.UserId)

    if Success then
        context:Reply("Successfully kicked! If the server isn't online, this won't stay on their record.")
    end
end