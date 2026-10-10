return function (context, player, teamName)
    local Aero = _G.Aero
    local Success,_ = Aero.Services.Game.Core.LeaderboardService:SetPlayerTeam(player, teamName)

    if teamName ~= "Passenger" then
        Aero.Services.Game.Staff.UniformService:IssueUniform(player, teamName)
        Aero.Services.Game.Core.ToolService:IssueTool(player, "Staff Access")
    else
        Aero.Services.Game.Core.ToolService:RevokeTool(player, "Staff Access")
    end

    if Success then
        context:Reply("Successfully updated team!")
    end
end