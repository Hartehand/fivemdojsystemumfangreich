DojPermissions = {}

function DojPermissions.GetRole(xPlayer)
    local job = xPlayer and xPlayer.getJob and xPlayer.getJob() or nil
    if not job then return nil end
    return Config.Permissions.jobRoleMap[job.name]
end

function DojPermissions.GetRolePermissions(role)
    return Config.Permissions.roles[role] or {}
end

local function hasWasabiPermission(identifier, permission)
    local cfg = Config.Integrations.wasabi
    if not cfg.enabled or not cfg.useOfficerChecks then return false end
    if GetResourceState(cfg.resource) ~= 'started' then return false end

    local ok, result = pcall(function()
        return exports[cfg.resource]:HasPermission(identifier, permission)
    end)
    return ok and result == true
end

function DojPermissions.Has(xPlayer, permission)
    local role = DojPermissions.GetRole(xPlayer)
    if role then
        local rolePermissions = DojPermissions.GetRolePermissions(role)
        if rolePermissions[permission] == true then return true end
    end

    local identifier = DojUtils.GetPreferredIdentifier(xPlayer and xPlayer.source or nil, xPlayer)
    if identifier and hasWasabiPermission(identifier, permission) then return true end

    return false
end

function DojPermissions.Assert(source, permission)
    local xPlayer = DOJ.GetPlayer(source)
    if not xPlayer then return false, 'player_not_found' end
    if not DojPermissions.Has(xPlayer, permission) then return false, 'no_permission' end
    return true, xPlayer
end

function DojPermissions.IsHighSealingRole(xPlayer)
    local role = DojPermissions.GetRole(xPlayer)
    if not role then return false end
    for _, allowedRole in ipairs(Config.Sealing.highRoles or {}) do
        if allowedRole == role then return true end
    end
    return false
end

function DojPermissions.CanViewSealed(xPlayer)
    return DojPermissions.IsHighSealingRole(xPlayer) or DojPermissions.Has(xPlayer, 'audit_view')
end

function DojPermissions.CanSignRole(role)
    return Config.Signatures.allowedRoles[role] == true
end
