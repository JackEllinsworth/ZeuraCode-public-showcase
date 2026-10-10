return {
	Name = "kick";
	Aliases = {};
	Description = "Kicks the user from the game.";
	Group = "Admin";
	Args = {
		{
			Type = "playerId";
			Name = "Player";
			Description = "The player to kick";
		},
        {
            Type = "string";
			Name = "Reason";
			Description = "The reason for the kick";
        }
	};
}