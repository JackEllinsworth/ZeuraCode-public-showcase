return function (context, userId, reason)
    local Aero = _G.Aero
    local Success,_ = Aero.Services.Data.ModerationService:IssueInfraction(
        userId, "Ban", reason, context.Executor.UserId, "perm")

    if Success then
        context:Reply("Successfully perm-banned! If the server isn't online, this users ban won't take effect in new servers.")
    end
end