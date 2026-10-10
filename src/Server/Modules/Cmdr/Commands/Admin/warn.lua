return {
	Name = "warn";
	Aliases = {};
	Description = "Warns the specified user.";
	Group = "Admin";
	Args = {
		{
			Type = "playerId";
			Name = "Player";
			Description = "The player to warn.";
		},
        {
            Type = "string";
			Name = "Reason";
			Description = "The reason for the warning.";
        }
	};
}