-- Secrets.example.lua
-- Copy this file to src/Server/Modules/Secrets.lua and fill in real values.
-- src/Server/Modules/Secrets.lua is listed in .gitignore and must never be committed.

return {
	-- Base URL of the external data API. Must end with a trailing slash.
	-- Endpoints used: <base>playerdata/, <base>moderation/, <base>flights/
	DataServerBaseUrl = "https://your-api.example.com/api/zeura/",

	ApiKeys = {
		player_data = "REPLACE_ME",
		moderation_data = "REPLACE_ME",
		flight_data = "REPLACE_ME",
	},

	-- Discord webhook URLs (or a proxy that forwards to Discord, since Roblox blocks discord.com directly)
	Webhooks = {
		Moderation = "https://your-webhook-proxy.example.com/api/webhooks/ID/TOKEN",
		Logs = "https://your-webhook-proxy.example.com/api/webhooks/ID/TOKEN",
	},
}
