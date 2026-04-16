DojHearings = {}

local function addAudit(action, entityType, entityId, actor, oldValue, newValue)
    DojDB.Insert([[
        INSERT INTO doj_audit_log (action, entity_type, entity_id, actor_identifier, actor_name, actor_session, old_value, new_value)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        action, entityType, tostring(entityId), actor.identifier, actor.name, actor.session,
        DojUtils.SafeEncode(oldValue), DojUtils.SafeEncode(newValue)
    })
end

function DojHearings.Create(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'hearing_create')
    if not ok then return { ok = false, error = xPlayer } end

    if not DojUtils.IsInList(payload.hearing_type, Config.Defaults.hearingTypes) then
        return { ok = false, error = 'invalid_hearing_type' }
    end


    local caseOk, caseRow = DojCases.AssertCaseEditable(source, payload.case_id)
    if not caseOk then return { ok = false, error = caseRow } end

    local actor = DojUtils.Actor(source, xPlayer)
    local conflicts = DojCalendar.FindConflicts(payload)

    if #conflicts > 0 then
        local canOverride = payload.override_conflicts == true and DojCalendar.CanOverride(source)
        if Config.Calendar.hardBlockConflicts and not canOverride then
            return { ok = false, error = 'calendar_conflict', conflicts = conflicts }
        end
    end

    local hearingId = DojDB.Insert([[
        INSERT INTO doj_hearings (case_id, hearing_type, status, start_at, end_at, courtroom_id, judge_identifier, judge_name,
            prosecutor_identifier, prosecutor_name, defense_identifier, defense_name, outcome, notes, reminder_state,
            conflict_override, created_by_identifier, created_by_name, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.case_id, payload.hearing_type, payload.status or 'scheduled', payload.start_at, payload.end_at, payload.courtroom_id,
        payload.judge_identifier, payload.judge_name, payload.prosecutor_identifier, payload.prosecutor_name,
        payload.defense_identifier, payload.defense_name, payload.outcome, payload.notes, payload.reminder_state,
        payload.override_conflicts and 1 or 0, actor.identifier, actor.name, DojUtils.SafeEncode({ conflicts = conflicts, metadata = payload.metadata or {} })
    })

    for _, participant in ipairs(payload.participants or {}) do
        DojDB.Insert([[
            INSERT INTO doj_hearing_participants (hearing_id, participant_identifier, participant_name, participant_role, attendance_status, metadata)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], { hearingId, participant.identifier, participant.name, participant.role, participant.attendance_status or 'expected', DojUtils.SafeEncode(participant.metadata or {}) })
    end

    addAudit('create_hearing', 'hearing', hearingId, actor, nil, payload)

    DojDB.Insert([[
        INSERT INTO doj_case_timeline (case_id, event_type, event_label, actor_identifier, actor_name, actor_session, new_value)
        VALUES (?, 'hearing_scheduled', 'Anhörung terminiert', ?, ?, ?, ?)
    ]], { payload.case_id, actor.identifier, actor.name, actor.session, DojUtils.SafeEncode(payload) })

    return { ok = true, data = { id = hearingId, conflicts = conflicts } }
end

function DojHearings.GetCalendar(source, payload)
    local ok = DojPermissions.Assert(source, 'tablet_open')
    if not ok then return { ok = false, error = 'no_permission' } end

    local entries = DojCalendar.GetEntries(payload or {})
    return { ok = true, data = entries }
end
