local ContentProvider = game:GetService("ContentProvider")
-- Cmdr Service
-- Jack_AviationRBX
-- September 5, 2021

--[[

CmdrService manages all administration systems implemented into the Cmdr module.
It also configured any hooks, to ensure the security of all commands.

--]]


local OWNER_PERMISSION = "Owner"


local CmdrService = {Client = {}}


function CmdrService:Start()
    self.Modules.Cmdr:RegisterDefaultCommands()
    self.Modules.Cmdr:RegisterCommandsIn(script.Parent.Parent.Parent.Parent.Modules.Cmdr.Commands)
    self:RegisterPermissions()
end


function CmdrService:RegisterPermissions()
    -- Manage server-sides permissions
    self.Modules.Cmdr.Registry:RegisterHook("BeforeRun", function(context)
        if not self.Services.Data.PermissionService:HasPermission(context.Executor.UserId, context.Group) then
            return "This command is restricted to permission level '"..context.Group.."'."
        end
    end)
end


return CmdrService