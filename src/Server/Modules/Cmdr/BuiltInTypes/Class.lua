local Classes = {"Executive", "Premium", "Standard+", "Standard"}

return function (cmdr)
	cmdr:RegisterType("class", cmdr.Cmdr.Util.MakeEnumType("Class", Classes))
end