DojCases = {}

local searchableFields = {
    status = 'c.status',
    case_type = 'c.case_type',
    priority = 'c.priority',
    department = 'c.department',
    judge_identifier = 'h.judge_identifier',
    prosecutor_identifier = 'h.prosecutor_identifier'
}

local function addAudit(action, entityType, entityId, actor, oldValue, newValue, metadata)
    DojDB.Insert([[INSERT INTO doj_audit_log (action, entity_type, entity_id, actor_identifier, actor_name, actor_session, old_value, new_value, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        action, entityType, tostring(entityId), actor.identifier, actor.name, actor.session,
        DojUtils.SafeEncode(oldValue), DojUtils.SafeEncode(newValue), DojUtils.SafeEncode(metadata)
    })
end

local function addTimeline(caseId, eventType, eventLabel, actor, oldValue, newValue, metadata)
    DojDB.Insert([[INSERT INTO doj_case_timeline (case_id, event_type, event_label, actor_identifier, actor_name, actor_session, old_value, new_value, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        caseId, eventType, eventLabel, actor.identifier, actor.name, actor.session,
        DojUtils.SafeEncode(oldValue), DojUtils.SafeEncode(newValue), DojUtils.SafeEncode(metadata)
    })
end

function DojCases.GetById(caseId)
    return DojDB.Single('SELECT * FROM doj_cases WHERE id = ? AND deleted_at IS NULL LIMIT 1', { caseId })
end

function DojCases.AssertCaseEditable(source, caseId)
    local xPlayer = DOJ.GetPlayer(source)
    if not xPlayer then return false, 'player_not_found' end

    local caseRow = DojCases.GetById(caseId)
    if not caseRow then return false, 'case_not_found' end

    if caseRow.is_sealed == 1 and not DojPermissions.CanViewSealed(xPlayer) then
        if Config.Sealing.logAccessAttempts then
            local actor = DojUtils.Actor(source, xPlayer)
            addAudit('sealed_case_access_denied', 'case', caseId, actor, nil, nil, { requested_action = 'edit' })
        end
        return false, 'case_sealed'
    end

    return true, caseRow, xPlayer
end

function DojCases.GenerateCaseNumber(caseType)
    local token = Config.CaseNumber.typeTokens[caseType] or 'CS'
    local seq = DojDB.Scalar('SELECT IFNULL(MAX(sequence_no), 0) + 1 FROM doj_cases WHERE YEAR(created_at) = YEAR(UTC_TIMESTAMP())') or 1
    local padded = string.format('%0' .. Config.CaseNumber.padLength .. 'd', seq)
    if Config.CaseNumber.includeTypeToken then
        return ('%s-%s-%s-%s'):format(Config.CaseNumber.prefix, os.date('%Y'), token, padded), seq
    end
    return ('%s-%s-%s'):format(Config.CaseNumber.prefix, os.date('%Y'), padded), seq
end

function DojCases.Create(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'case_create')
    if not ok then return { ok = false, error = xPlayer } end
    local actor = DojUtils.Actor(source, xPlayer)

    local template
    if payload.template_key and payload.template_key ~= '' then
        template = DojTemplates.GetByKey(payload.template_key)
        if not template then return { ok = false, error = 'template_not_found' } end
    end

    local caseType = payload.case_type or (template and template.case_type) or 'criminal_case'
    if not DojUtils.IsInList(caseType, Config.Defaults.caseTypes) then return { ok = false, error = 'invalid_case_type' } end

    local caseNumber, sequenceNo = DojCases.GenerateCaseNumber(caseType)
    local tags = payload.tags or (template and template.default_tags) or {}
    local status = payload.status or (template and template.default_status) or 'open'
    local title = payload.title or (template and template.default_title) or 'Neuer Fall'

    local caseId = DojDB.Insert([[
        INSERT INTO doj_cases (case_number, sequence_no, case_type, title, description, status, priority, category, department,
            created_by_identifier, created_by_name, lead_identifier, lead_name, tags, confidential, is_sealed, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
    ]], {
        caseNumber, sequenceNo, caseType, title, payload.description, status, payload.priority or 'normal', payload.category, payload.department,
        actor.identifier, actor.name, payload.lead_identifier, payload.lead_name, DojUtils.SafeEncode(tags), payload.confidential and 1 or 0,
        DojUtils.SafeEncode({ template_key = payload.template_key, metadata = payload.metadata or {} })
    })

    addTimeline(caseId, 'case_created', 'Fall erstellt', actor, nil, payload)
    addAudit('create_case', 'case', caseId, actor, nil, payload)

    if payload.parent_case_id then
        DojDB.Insert('INSERT INTO doj_case_links (case_id, linked_case_id, relation_type, created_by_identifier, created_by_name) VALUES (?, ?, ?, ?, ?)', {
            payload.parent_case_id, caseId, 'child_case', actor.identifier, actor.name
        })
        DojDB.Insert('INSERT INTO doj_case_links (case_id, linked_case_id, relation_type, created_by_identifier, created_by_name) VALUES (?, ?, ?, ?, ?)', {
            caseId, payload.parent_case_id, 'parent_case', actor.identifier, actor.name
        })
    end

    if template then
        DojTemplates.ApplyToCase(caseId, template.template_key, actor)
        addTimeline(caseId, 'template_applied', ('Template angewendet: %s'):format(template.display_name), actor, nil, { template = template.template_key })
    end

    return { ok = true, data = { id = caseId, case_number = caseNumber } }
end

function DojCases.Update(source, payload)
    local okPerm, xPlayer = DojPermissions.Assert(source, 'case_edit')
    if not okPerm then return { ok = false, error = xPlayer } end
    local ok, existing = DojCases.AssertCaseEditable(source, payload.case_id)
    if not ok then return { ok = false, error = existing } end

    local actor = DojUtils.Actor(source, xPlayer)
    DojDB.Update([[UPDATE doj_cases
        SET title = ?, description = ?, status = ?, priority = ?, category = ?, department = ?, lead_identifier = ?, lead_name = ?,
            tags = ?, confidential = ?, metadata = ?, updated_at = UTC_TIMESTAMP(),
            closed_at = CASE WHEN ? = 'closed' THEN UTC_TIMESTAMP() ELSE closed_at END,
            archived_at = CASE WHEN ? = 'archived' THEN UTC_TIMESTAMP() ELSE archived_at END
        WHERE id = ?
    ]], {
        payload.title or existing.title,
        payload.description or existing.description,
        payload.status or existing.status,
        payload.priority or existing.priority,
        payload.category or existing.category,
        payload.department or existing.department,
        payload.lead_identifier or existing.lead_identifier,
        payload.lead_name or existing.lead_name,
        DojUtils.SafeEncode(payload.tags or DojUtils.SafeDecode(existing.tags)),
        payload.confidential and 1 or 0,
        DojUtils.SafeEncode(payload.metadata or DojUtils.SafeDecode(existing.metadata)),
        payload.status or existing.status,
        payload.status or existing.status,
        payload.case_id
    })

    addTimeline(payload.case_id, 'case_updated', 'Fall aktualisiert', actor, existing, payload)
    addAudit('update_case', 'case', payload.case_id, actor, existing, payload)
    return { ok = true }
end

function DojCases.Seal(source, payload)
    local okPerm, xPlayer = DojPermissions.Assert(source, 'case_seal')
    if not okPerm then return { ok = false, error = xPlayer } end
    if not DojPermissions.IsHighSealingRole(xPlayer) then return { ok = false, error = 'high_role_required' } end

    local caseRow = DojCases.GetById(payload.case_id)
    if not caseRow then return { ok = false, error = 'case_not_found' } end
    if caseRow.is_sealed == 1 then return { ok = false, error = 'already_sealed' } end

    local actor = DojUtils.Actor(source, xPlayer)
    DojDB.Update([[
        UPDATE doj_cases
        SET is_sealed = 1, status = 'sealed', sealed_by_identifier = ?, sealed_by_name = ?, sealed_at = UTC_TIMESTAMP(), sealed_reason = ?, updated_at = UTC_TIMESTAMP()
        WHERE id = ?
    ]], { actor.identifier, actor.name, payload.reason, payload.case_id })

    addTimeline(payload.case_id, 'case_sealed', 'Fall versiegelt', actor, nil, { reason = payload.reason })
    addAudit('seal_case', 'case', payload.case_id, actor, nil, { reason = payload.reason })
    return { ok = true }
end

function DojCases.Unseal(source, payload)
    local okPerm, xPlayer = DojPermissions.Assert(source, 'case_unseal')
    if not okPerm then return { ok = false, error = xPlayer } end
    if not DojPermissions.IsHighSealingRole(xPlayer) then return { ok = false, error = 'high_role_required' } end

    local caseRow = DojCases.GetById(payload.case_id)
    if not caseRow then return { ok = false, error = 'case_not_found' } end
    if caseRow.is_sealed == 0 then return { ok = false, error = 'not_sealed' } end

    local actor = DojUtils.Actor(source, xPlayer)
    DojDB.Update([[
        UPDATE doj_cases
        SET is_sealed = 0, status = ?, unsealed_by_identifier = ?, unsealed_by_name = ?, unsealed_at = UTC_TIMESTAMP(), unsealed_reason = ?, updated_at = UTC_TIMESTAMP()
        WHERE id = ?
    ]], { payload.status_after_unseal or 'under_review', actor.identifier, actor.name, payload.reason, payload.case_id })

    addTimeline(payload.case_id, 'case_unsealed', 'Fall entsiegelt', actor, nil, { reason = payload.reason })
    addAudit('unseal_case', 'case', payload.case_id, actor, nil, { reason = payload.reason })
    return { ok = true }
end

function DojCases.LinkEntity(source, payload)
    local perm = 'case_edit'
    if payload.entity_type == 'citizen' then perm = 'citizen_link' end
    if payload.entity_type == 'vehicle' then perm = 'vehicle_link' end
    if payload.entity_type == 'charge' then perm = 'charge_link' end
    if payload.entity_type == 'incident' then perm = 'incident_link' end
    local okPerm, xPlayer = DojPermissions.Assert(source, perm)
    if not okPerm then return { ok = false, error = xPlayer } end

    local okCase, caseRow = DojCases.AssertCaseEditable(source, payload.case_id)
    if not okCase then return { ok = false, error = caseRow } end

    local actor = DojUtils.Actor(source, xPlayer)
    local mappingTable = {
        citizen = { table = 'doj_case_people', column = 'citizen_identifier' }, vehicle = { table = 'doj_case_vehicles', column = 'plate' },
        weapon = { table = 'doj_case_weapons', column = 'serial_number' }, evidence = { table = 'doj_case_evidence', column = 'evidence_id' },
        charge = { table = 'doj_case_charges', column = 'charge_id' }, incident = { table = 'doj_case_incidents', column = 'incident_id' },
        warrant = { table = 'doj_case_warrants', column = 'warrant_id' }, document = { table = 'doj_case_documents', column = 'document_id' },
        note = { table = 'doj_case_notes', column = 'note_id' }
    }
    local map = mappingTable[payload.entity_type]
    if not map then return { ok = false, error = 'unsupported_entity_type' } end

    local id = DojDB.Insert(([[INSERT INTO %s (case_id, %s, relation_type, metadata, created_by_identifier, created_by_name) VALUES (?, ?, ?, ?, ?, ?)]]):format(map.table, map.column), {
        payload.case_id, payload.entity_id, payload.relation_type, DojUtils.SafeEncode(payload.metadata or {}), actor.identifier, actor.name
    })

    addTimeline(payload.case_id, 'entity_linked', ('%s verknüpft'):format(payload.entity_type), actor, nil, payload)
    addAudit('link_entity', payload.entity_type, id, actor, nil, payload)
    return { ok = true, data = { id = id } }
end

function DojCases.CreateTask(source, payload)
    local okPerm, xPlayer = DojPermissions.Assert(source, 'task_manage')
    if not okPerm then return { ok = false, error = xPlayer } end

    local okCase, caseRow = DojCases.AssertCaseEditable(source, payload.case_id)
    if not okCase then return { ok = false, error = caseRow } end

    local actor = DojUtils.Actor(source, xPlayer)
    local id = DojDB.Insert([[
        INSERT INTO doj_case_tasks (case_id, title, description, due_at, assigned_identifier, assigned_name, status, reminder_enabled, created_by_identifier, created_by_name, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.case_id, payload.title, payload.description, payload.due_at, payload.assigned_identifier, payload.assigned_name,
        payload.status or 'open', payload.reminder_enabled and 1 or 0, actor.identifier, actor.name, DojUtils.SafeEncode(payload.metadata or {})
    })

    addTimeline(caseRow.id, 'task_created', 'Aufgabe erstellt', actor, nil, payload)
    addAudit('create_task', 'case_task', id, actor, nil, payload)
    return { ok = true, data = { id = id } }
end

function DojCases.GetList(source, payload)
    local okPerm, xPlayer = DojPermissions.Assert(source, 'tablet_open')
    if not okPerm then return { ok = false, error = xPlayer } end

    local where = { 'c.deleted_at IS NULL' }
    local params = {}

    local canViewSealed = DojPermissions.CanViewSealed(xPlayer)
    if not canViewSealed then
        where[#where + 1] = 'c.is_sealed = 0'
    end

    for key, column in pairs(searchableFields) do
        if payload[key] and payload[key] ~= '' then
            where[#where + 1] = (column .. ' = ?')
            params[#params + 1] = payload[key]
        end
    end

    if payload.date_from then where[#where + 1] = 'c.created_at >= ?'; params[#params + 1] = payload.date_from end
    if payload.date_to then where[#where + 1] = 'c.created_at <= ?'; params[#params + 1] = payload.date_to end

    local filterSql = table.concat(where, ' AND ')
    local baseSql = ([[
        SELECT c.*, (SELECT COUNT(*) FROM doj_case_tasks t WHERE t.case_id = c.id AND t.deleted_at IS NULL AND t.status <> 'done') AS open_tasks
        FROM doj_cases c
        LEFT JOIN doj_hearings h ON h.case_id = c.id AND h.deleted_at IS NULL
        WHERE %s
        GROUP BY c.id
        ORDER BY c.updated_at DESC
    ]]):format(filterSql)
    local countSql = ('SELECT COUNT(DISTINCT c.id) FROM doj_cases c LEFT JOIN doj_hearings h ON h.case_id = c.id AND h.deleted_at IS NULL WHERE %s'):format(filterSql)

    return { ok = true, data = DojDB.Paginate(baseSql, countSql, params, payload.page, payload.pageSize) }
end

function DojCases.SaveFilter(source, payload)
    local okPerm, xPlayer = DojPermissions.Assert(source, 'filter_manage')
    if not okPerm then return { ok = false, error = xPlayer } end
    local actor = DojUtils.Actor(source, xPlayer)
    local id = DojDB.Insert('INSERT INTO doj_saved_filters (owner_identifier, name, module, filter_payload) VALUES (?, ?, ?, ?)', {
        actor.identifier, payload.name, payload.module or 'cases', DojUtils.SafeEncode(payload.filter_payload or {})
    })
    return { ok = true, data = { id = id } }
end

function DojCases.Search(source, payload)
    local okPerm, xPlayer = DojPermissions.Assert(source, 'tablet_open')
    if not okPerm then return { ok = false, error = xPlayer } end

    local whereCase = 'deleted_at IS NULL'
    if not DojPermissions.CanViewSealed(xPlayer) then
        whereCase = whereCase .. ' AND is_sealed = 0'
    end

    local q = ('%%%s%%'):format(payload.query or '')
    return {
        ok = true,
        data = {
            cases = DojDB.Query(('SELECT id, case_number, title, status, case_type, is_sealed FROM doj_cases WHERE %s AND (case_number LIKE ? OR title LIKE ?) LIMIT 50'):format(whereCase), { q, q }),
            people = DojDB.Query('SELECT case_id, citizen_identifier, full_name, role_type FROM doj_case_people WHERE deleted_at IS NULL AND (citizen_identifier LIKE ? OR full_name LIKE ?) LIMIT 50', { q, q }),
            vehicles = DojDB.Query('SELECT case_id, plate, model, vin FROM doj_case_vehicles WHERE deleted_at IS NULL AND (plate LIKE ? OR vin LIKE ? OR model LIKE ?) LIMIT 50', { q, q, q }),
            weapons = DojDB.Query('SELECT case_id, serial_number, weapon_type FROM doj_case_weapons WHERE deleted_at IS NULL AND serial_number LIKE ? LIMIT 50', { q }),
            evidence = DojDB.Query('SELECT id, evidence_number, title, status FROM doj_evidence WHERE deleted_at IS NULL AND evidence_number LIKE ? LIMIT 50', { q })
        }
    }
end
