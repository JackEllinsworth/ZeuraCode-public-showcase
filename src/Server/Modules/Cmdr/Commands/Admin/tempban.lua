return {
	Name = "tempBan";
	Aliases = {"ban"};
	Description = "Bans the user for a set duration.";
	Group = "Admin";
	Args = {
		{
			Type = "playerId";
			Name = "Player";
			Description = "The player to ban";
		},
        {
            Type = "integer";
			Name = "Duration (days)";
			Description = "The time to ban the user";
        },
        {
            Type = "string";
			Name = "Reason";
			Description = "The reason for the ban";
        }
	};
}