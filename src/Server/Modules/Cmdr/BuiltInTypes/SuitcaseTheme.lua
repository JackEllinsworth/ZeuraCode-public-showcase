local SuitcaseThemes = {"Chequered-Striped", "Barbershop", "Brick", "Chequered", "Y-Design", "Wooden", "Triangles", "Roadways", "Arrows", "Hexagon", "Striped", "Split Stiped"}

return function (cmdr)
	cmdr:RegisterType("suitcaseTheme", cmdr.Cmdr.Util.MakeEnumType("SuitcaseTheme", SuitcaseThemes))
end