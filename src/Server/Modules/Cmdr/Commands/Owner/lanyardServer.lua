return function (context)
    if not context.Executor.Character:FindFirstChild("Lanyard") then
        local Aero = _G.Aero
        Aero.Services.Game.Staff.LanyardService:IssueLanyard(context.Executor)
        context:Reply("Given lanyard successfully.")
    else
        context:Reply("You already have a lanyard.")
    end
end