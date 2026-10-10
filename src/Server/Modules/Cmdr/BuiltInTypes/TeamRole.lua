local TeamRoles = {"Captain", "First Officer", "Airport Operations", "Customer Liaison", "Passenger"}

return function (cmdr)
	cmdr:RegisterType("teamRole", cmdr.Cmdr.Util.MakeEnumType("teamRole", TeamRoles))
end