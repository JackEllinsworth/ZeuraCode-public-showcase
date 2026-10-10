return {
	Name = "permBan";
	Aliases = {"pban"};
	Description = "Bans the user forever.";
	Group = "Admin";
	Args = {
		{
			Type = "playerId";
			Name = "Player";
			Description = "The player to ban";
		},
        {
            Type = "string";
			Name = "Reason";
			Description = "The reason for the ban";
        }
	};
}