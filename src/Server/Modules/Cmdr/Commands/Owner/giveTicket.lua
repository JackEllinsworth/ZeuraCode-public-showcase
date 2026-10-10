return {
	Name = "giveTicket";
	Aliases = {};
	Description = "Gives/removes the user a 1-time ticket. (negative numbers supported)";
	Group = "Owner";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player to give the ticket too.";
		},
        {
            Type = "class";
			Name = "Class Name";
			Description = "The class name of the ticket to give.";
        },
        {
            Type = "integer";
			Name = "Amount";
			Description = "The amount of the tickets to give. (+ or -)";
        }
	};
}