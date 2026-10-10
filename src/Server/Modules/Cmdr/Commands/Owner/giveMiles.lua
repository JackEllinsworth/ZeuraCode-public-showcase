return {
	Name = "giveMiles";
	Aliases = {};
	Description = "Gives/removes the user a 1-time ticket. (negative numbers supported)";
	Group = "Owner";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player to give the miles to.";
		},
        {
            Type = "integer";
			Name = "Amount";
			Description = "The amount of miles to give. (+ or -)";
        }
	};
}