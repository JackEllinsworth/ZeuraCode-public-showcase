-- Data Service
-- Jack_AviationRBX
-- August 7, 2021

--[[

DataService provides a very simplified way of communicating with the servers specified in the configuration module.
This is necessary for player data retrival and any data which needs to be saved externally, allowing a multi-game configuration.

--]]


local HttpService = game:GetService("HttpService")


local DataService = {Client = {}}


function DataService:_formatUrl(data_type, action_type, arguments)
    local ServerConfig = self.Modules.Config.DataServers
	local ConfigLocation = ServerConfig[data_type]
	local FormattedUrl = ConfigLocation["url"]..ConfigLocation["apiKey"].."/"..action_type.."/"

	for _,v in ipairs(arguments) do
		FormattedUrl = FormattedUrl..tostring(v).."/"
	end
	
	return FormattedUrl
end


function DataService.post(data_type, action_type, arguments, post_data)
	local FormattedUrl = DataService:_formatUrl(data_type, action_type, arguments)
	
	local success,_ = pcall(function()
		local encoded_data = HttpService:JSONEncode(post_data)

		HttpService:PostAsync(FormattedUrl, encoded_data)
	end)
	
	local ArgumentFormatted = table.concat(arguments, ",")
	
	if success then
		warn("[DataService] -> Posted type: "..data_type..", with action: "..action_type..". Url Arguments: "..ArgumentFormatted)

		return true
	else
		warn("[DataService] [ERR] -> Couldn't post type: "..data_type..", with action: "..action_type..". Url Arguments: "..ArgumentFormatted)
		return false
	end
end


function DataService.get(data_type, action_type, arguments, bypass_decode)
	local FormattedUrl = DataService:_formatUrl(data_type, action_type, arguments)

	local data
	local decoded_data
	
	local success,_= pcall(function()
		data = HttpService:GetAsync(FormattedUrl)
		if not bypass_decode then
			decoded_data = HttpService:JSONDecode(data)
		end
	end)

	local ArgumentFormatted = table.concat(arguments, ",")

	if success then
		warn("[DataService] -> Got type: "..data_type..", with action: "..action_type..". Url Arguments: "..ArgumentFormatted)
		
		if bypass_decode then
			return true
		else
			return decoded_data
		end
	else
		warn("[DataService] [ERR] -> Couldn't get type: "..data_type..", with action: "..action_type..". Url Arguments: "..ArgumentFormatted)
		return false
	end
end


function DataService:SendWebhook(title, description, colour, fields, webhookLocator, inline)
	local FieldsFormatting = {}
	local WebhookUrl = self.Modules.Config["Webhooks"][webhookLocator]

	--// Implement fields
	for _,v in ipairs(fields) do
		table.insert(FieldsFormatting, {
			["name"] = v[1],
			["value"] = v[2],
			["inline"] = inline
		})
	end

	--// Layout table
	local DiscordWebhook = {
		["content"] = "",
		["embeds"] = {{
			["title"] = title,
			["description"] = description,
			["type"] = "rich",
			["color"] = colour,
			["fields"] = FieldsFormatting
		}}
	}

	local success,_ = pcall(function()
		local encoded_data = HttpService:JSONEncode(DiscordWebhook)

		HttpService:PostAsync(WebhookUrl, encoded_data)
	end)

	if not success then
		warn("[DataService] [ERR] -> Error posting to webhook '"..webhookLocator.."'. Table:", DiscordWebhook)
	end
end



return DataService