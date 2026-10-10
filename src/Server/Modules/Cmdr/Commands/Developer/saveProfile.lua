return {
	Name = "saveProfile";
	Aliases = {"save"};
	Description = "Saves specified users profile.";
	Group = "Developer";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player's account to save";
		}
	};
}