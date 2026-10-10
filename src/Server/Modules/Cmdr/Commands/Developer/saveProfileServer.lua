return function (context, player)
    local Aero = _G.Aero

    local Success = Aero.Services.Data.ProfileService:Save(player.UserId)

    if Success then
        context:Reply("Save successful!")
    else
        context:Reply("Save unsuccessful: server may be down or no data changes requiring saving.")
    end
end