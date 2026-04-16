DojDB = {}

local function safeCall(context, fn)
    local ok, result = pcall(fn)
    if not ok then
        DojUtils.LogError(context, result)
        return nil
    end
    return result
end

function DojDB.Query(sql, params)
    return safeCall('DB.Query', function()
        return MySQL.query.await(sql, params or {})
    end) or {}
end

function DojDB.Single(sql, params)
    local rows = DojDB.Query(sql, params)
    return rows[1]
end

function DojDB.Scalar(sql, params)
    local row = DojDB.Single(sql, params)
    if not row then return nil end
    for _, value in pairs(row) do return value end
    return nil
end

function DojDB.Insert(sql, params)
    return safeCall('DB.Insert', function()
        return MySQL.insert.await(sql, params or {})
    end)
end

function DojDB.Update(sql, params)
    return safeCall('DB.Update', function()
        return MySQL.update.await(sql, params or {})
    end) or 0
end

function DojDB.Execute(sql, params)
    return safeCall('DB.Execute', function()
        return MySQL.rawExecute.await(sql, params or {})
    end)
end

function DojDB.HashText(text)
    local hash = DojDB.Scalar('SELECT SHA2(?, 256) AS h', { text })
    return hash or ''
end

function DojDB.Paginate(baseSql, countSql, params, page, pageSize)
    local p = tonumber(page) or 1
    local ps = tonumber(pageSize) or Config.DefaultPageSize
    p = DojUtils.Clamp(p, 1, 100000)
    ps = DojUtils.Clamp(ps, 1, Config.MaxPageSize)
    local offset = (p - 1) * ps

    local queryParams = {}
    for _, v in ipairs(params or {}) do queryParams[#queryParams + 1] = v end
    queryParams[#queryParams + 1] = ps
    queryParams[#queryParams + 1] = offset
    local list = DojDB.Query(('%s LIMIT ? OFFSET ?'):format(baseSql), queryParams)
    local total = DojDB.Scalar(countSql, params or {}) or 0

    return {
        items = list,
        page = p,
        pageSize = ps,
        total = total,
        totalPages = math.ceil(total / ps)
    }
end

function DojDB.Init()
    if not Config.EnableAutoMigrations then
        return
    end

    local sqlFile = LoadResourceFile(GetCurrentResourceName(), 'sql/doj_casehub.sql')
    if not sqlFile then
        DojUtils.LogError('DB.Init', 'sql/doj_casehub.sql nicht gefunden')
        return
    end

    for statement in sqlFile:gmatch('([^;]+);') do
        local trimmed = statement:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' and trimmed:sub(1, 2) ~= '--' then
            local ok = safeCall('DB.Migration', function()
                return MySQL.query.await(trimmed)
            end)
            if not ok then
                DojUtils.LogError('DB.Init', 'Migration fehlgeschlagen')
            end
        end
    end
end
