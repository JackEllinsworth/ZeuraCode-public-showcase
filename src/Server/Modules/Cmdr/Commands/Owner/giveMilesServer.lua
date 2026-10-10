return function (context, player, amount)
    local Aero = _G.Aero
    Aero.Services.Data.ProfileService:IncrementAsync(player.UserId, "miles", amount)
    Aero.Services.Data.MilesService:UpdateClient(player)

    context:Reply("Successfully gave "..player.Name.." "..tostring(amount).." miles.")
end