return {
	Name = "setFlight";
	Aliases = {"activateFlight", "enableFlight"};
	Description = "Sets the current flight in the game.";
	Group = "Admin";
	Args = {
		{
			Type = "string";
			Name = "Flight Number";
			Description = "The flight number linked to the flight.";
		}
	};
}