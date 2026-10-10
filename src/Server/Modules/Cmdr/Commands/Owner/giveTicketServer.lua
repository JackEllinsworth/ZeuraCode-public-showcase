return function (context, player, className, amount)
    local Aero = _G.Aero

    local Success = Aero.Services.Data.ClassService:UpdateTempTicketAmount(player, className, amount)

    if Success then
        context:Reply("Successfully gave "..player.Name.." "..className.." (x"..tostring(amount)..")")
    else
        context:Reply("An error occured, the server may be down.")
    end
end