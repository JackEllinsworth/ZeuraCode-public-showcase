return function (context)
    local Aero = _G.Aero
    context:Reply("WARNING: [ THIS COMMAND IS NOT FULLY FUNCTIONAL. PLEASE SCREENSHOT ANY FAILED ATTEMPTS ]")
    context:Reply("Executing class backup check... (please wait, this may take a while)")
    local Success = Aero.Services.Data.ClassService:RestoreBookedTickets()
    
    if Success then
        context:Reply("Successfully attempted to restore all current players tickets. Any failed attempts have been logged externally.")
    else
        context:Reply("You can only restore tickets once per server.")
    end
end