DojUtils = {}

function DojUtils.Debug(...)
    if not Config.Debug then
        return
    end

    print(('[%s][DEBUG] %s'):format(Config.ResourceName, table.concat({ ... }, ' ')))
end

function DojUtils.LogError(context, err)
    print(('[%s][ERROR] %s: %s'):format(Config.ResourceName, context, tostring(err)))
end

function DojUtils.SafeEncode(value)
    local ok, result = pcall(json.encode, value or {})
    if not ok then
        return '{}'
    end

    return result
end

function DojUtils.SafeDecode(value)
    if not value or value == '' then
        return {}
    end

    local ok, result = pcall(json.decode, value)
    if not ok or type(result) ~= 'table' then
        return {}
    end

    return result
end

function DojUtils.GetPreferredIdentifier(source, xPlayer)
    local identifiers = source and GetPlayerIdentifiers(source) or {}
    local preferred, fallback

    for _, identifier in ipairs(identifiers) do
        if identifier:find('^' .. Config.Identifier.primaryPrefix .. ':') then
            preferred = identifier
            break
        end

        if identifier:find('^' .. Config.Identifier.fallbackPrefix .. ':') then
            fallback = identifier
        end
    end

    if preferred then
        return preferred
    end

    if fallback then
        return fallback
    end

    if xPlayer and xPlayer.identifier then
        return xPlayer.identifier
    end

    return identifiers[1]
end

function DojUtils.IsInList(value, arr)
    for _, entry in ipairs(arr or {}) do
        if entry == value then
            return true
        end
    end

    return false
end

function DojUtils.Clamp(num, min, max)
    if num < min then return min end
    if num > max then return max end
    return num
end

function DojUtils.UtcNow()
    return os.date('!%Y-%m-%d %H:%M:%S')
end

function DojUtils.Actor(source, xPlayer)
    local name = Config.Identifier.fallbackName
    if xPlayer and xPlayer.getName then
        name = xPlayer.getName()
    end

    return {
        source = source,
        identifier = DojUtils.GetPreferredIdentifier(source, xPlayer),
        name = name,
        session = tostring(source)
    }
end

function DojUtils.TableMerge(base, incoming)
    local out = {}
    for k, v in pairs(base or {}) do out[k] = v end
    for k, v in pairs(incoming or {}) do out[k] = v end
    return out
end
