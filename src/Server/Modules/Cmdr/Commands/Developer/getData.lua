return {
	Name = "getData";
	Aliases = {"devData"};
	Description = "Returns the target player's assigned data.";
	Group = "Developer";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player's username to fetch data from.";
		}
	};
}