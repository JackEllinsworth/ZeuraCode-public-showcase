return {
	Name = "announce";
	Aliases = {"m"};
	Description = "Makes a server-wide announcement.";
	Group = "Admin";
	Args = {
        {
            Type = "boolean",
            Name = "important",
            Description = "Importance of the announcement true/false"
        },
		{
			Type = "string";
			Name = "text";
			Description = "The announcement text.";
		},
	};
}