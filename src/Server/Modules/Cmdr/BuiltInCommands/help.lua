return {
	Name = "help";
	Description = "Displays a list of all commands, or inspects one command.";
	Group = "Moderator";
	Args = {
		{
			Type = "command";
			Name = "Command";
			Description = "The command to view information on";
			Optional = true;
		},
	};
}
