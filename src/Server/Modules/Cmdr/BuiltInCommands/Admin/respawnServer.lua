return function(_, players)
	for _, player in pairs(players) do
		if player.Character then
			player.Character:BreakJoints()
		end
	end

	return ("Respawned %d players."):format(#players)
end