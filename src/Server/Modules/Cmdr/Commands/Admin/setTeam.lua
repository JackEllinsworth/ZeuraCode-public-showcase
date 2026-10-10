return {
	Name = "setTeam";
	Aliases = {"changeTeam"};
	Description = "Sets the specified users team";
	Group = "Admin";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player";
		},
        {
            Type = "teamRole";
			Name = "Role";
			Description = "The role to set the player to";
        }
	};
}