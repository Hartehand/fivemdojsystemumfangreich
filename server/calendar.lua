DojCalendar = {}

local function overlap(aStart, aEnd, bStart, bEnd)
    return aStart < bEnd and bStart < aEnd
end

local function toTimestamp(dt)
    if not dt then return nil end
    local y, m, d, h, mi, s = dt:match('(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)')
    if not y then return nil end
    return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
end

function DojCalendar.GetRangeFilters(payload)
    local mode = payload.mode or 'week'
    local dateStr = payload.date or os.date('%Y-%m-%d')
    local y, m, d = dateStr:match('(%d+)%-(%d+)%-(%d+)')
    local base = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12, min = 0, sec = 0 })

    local startDate = os.date('%Y-%m-%d 00:00:00', base)
    local endDate = os.date('%Y-%m-%d 23:59:59', base)

    if mode == 'week' then
        local weekday = tonumber(os.date('%w', base))
        local mondayOffset = (weekday == 0 and -6) or (1 - weekday)
        local weekStart = base + (mondayOffset * 86400)
        local weekEnd = weekStart + (6 * 86400)
        startDate = os.date('%Y-%m-%d 00:00:00', weekStart)
        endDate = os.date('%Y-%m-%d 23:59:59', weekEnd)
    elseif mode == 'month' then
        local monthStart = os.time({ year = tonumber(y), month = tonumber(m), day = 1, hour = 0, min = 0, sec = 0 })
        local nextMonth = os.time({ year = tonumber(y), month = tonumber(m) + 1, day = 1, hour = 0, min = 0, sec = 0 })
        local monthEnd = nextMonth - 1
        startDate = os.date('%Y-%m-%d 00:00:00', monthStart)
        endDate = os.date('%Y-%m-%d 23:59:59', monthEnd)
    end

    return startDate, endDate
end

function DojCalendar.GetEntries(payload)
    local startDate, endDate = DojCalendar.GetRangeFilters(payload)
    local sql = [[
        SELECT h.id, h.case_id, c.case_number, c.case_type, h.hearing_type, h.status, h.start_at, h.end_at, h.courtroom_id,
               cr.room_code, cr.label as courtroom_label, h.judge_identifier, h.judge_name, h.prosecutor_identifier,
               h.prosecutor_name, h.defense_identifier, h.defense_name
        FROM doj_hearings h
        JOIN doj_cases c ON c.id = h.case_id
        LEFT JOIN doj_courtrooms cr ON cr.id = h.courtroom_id
        WHERE h.deleted_at IS NULL
          AND h.start_at BETWEEN ? AND ?
        ORDER BY h.start_at ASC
    ]]

    return DojDB.Query(sql, { startDate, endDate })
end

function DojCalendar.FindConflicts(data, ignoreHearingId)
    local rows = DojDB.Query([[
        SELECT id, start_at, end_at, judge_identifier, prosecutor_identifier, defense_identifier, courtroom_id
        FROM doj_hearings
        WHERE deleted_at IS NULL
          AND status IN ('scheduled', 'postponed')
          AND (? IS NULL OR id <> ?)
    ]], { ignoreHearingId, ignoreHearingId })

    local buffer = tonumber(data.buffer_minutes) or Config.Calendar.defaultBufferMinutes
    local startAt = toTimestamp(data.start_at)
    local endAt = toTimestamp(data.end_at)
    if not startAt or not endAt then
        return { { type = 'invalid_datetime', hearing_id = nil, message = 'Start/Ende ungültig.' } }
    end
    local startTs = startAt - (buffer * 60)
    local endTs = endAt + (buffer * 60)
    local conflicts = {}

    for _, row in ipairs(rows) do
        local rowStart = toTimestamp(row.start_at)
        local rowEnd = toTimestamp(row.end_at)
        if overlap(startTs, endTs, rowStart, rowEnd) then
            if data.judge_identifier and row.judge_identifier == data.judge_identifier then
                conflicts[#conflicts + 1] = { type = 'judge', hearing_id = row.id, message = 'Richter ist bereits eingeplant.' }
            end
            if data.prosecutor_identifier and row.prosecutor_identifier == data.prosecutor_identifier then
                conflicts[#conflicts + 1] = { type = 'prosecutor', hearing_id = row.id, message = 'Prosecutor ist bereits eingeplant.' }
            end
            if data.defense_identifier and row.defense_identifier == data.defense_identifier then
                conflicts[#conflicts + 1] = { type = 'defense', hearing_id = row.id, message = 'Defense ist bereits eingeplant.' }
            end
            if data.courtroom_id and row.courtroom_id == data.courtroom_id then
                conflicts[#conflicts + 1] = { type = 'courtroom', hearing_id = row.id, message = 'Gerichtssaal ist belegt.' }
            end
        end
    end

    return conflicts
end

function DojCalendar.CanOverride(source)
    local xPlayer = DOJ.GetPlayer(source)
    if not xPlayer then return false end
    for _, permission in ipairs(Config.Calendar.allowOverridePermissions) do
        if DojPermissions.Has(xPlayer, permission) then
            return true
        end
    end
    return false
end
