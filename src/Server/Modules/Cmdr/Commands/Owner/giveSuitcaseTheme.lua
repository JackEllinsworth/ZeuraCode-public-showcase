return {
	Name = "giveSuitcaseTheme";
	Aliases = {};
	Description = "Gives a user a suitcase theme";
	Group = "Owner";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player to give the theme to.";
		},
        {
            Type = "suitcaseTheme";
			Name = "Theme";
			Description = "The suitcase theme to give";
        }
	};
}