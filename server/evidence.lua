DojEvidence = {}

local validActions = {
    collected = true, checked_in = true, checked_out = true, transferred = true,
    submitted = true, analyzed = true, returned = true, destroyed = true, sealed = true
}

local function buildEntryHash(previousHash, payload)
    local raw = table.concat({
        previousHash or '',
        tostring(payload.evidence_id or ''),
        payload.action_type or '',
        payload.from_person_identifier or '',
        payload.to_person_identifier or '',
        payload.from_location or '',
        payload.to_location or '',
        payload.reason_note or '',
        payload.created_by or '',
        payload.created_at or ''
    }, '|')

    return DojDB.HashText(raw)
end

function DojEvidence.GenerateNumber()
    local seq = DojDB.Scalar('SELECT IFNULL(MAX(sequence_no), 0) + 1 FROM doj_evidence WHERE YEAR(created_at)=YEAR(UTC_TIMESTAMP())') or 1
    return ('EVD-%s-%06d'):format(os.date('%Y'), seq), seq
end

function DojEvidence.Create(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'evidence_create')
    if not ok then return { ok = false, error = xPlayer } end

    if not DojUtils.IsInList(payload.evidence_type, Config.Defaults.evidenceTypes) then
        return { ok = false, error = 'invalid_evidence_type' }
    end

    if payload.case_id then
        local caseOk, caseErr = DojCases.AssertCaseEditable(source, payload.case_id)
        if not caseOk then return { ok = false, error = caseErr } end
    end

    local actor = DojUtils.Actor(source, xPlayer)
    local evidenceNumber, sequenceNo = DojEvidence.GenerateNumber()

    local evidenceId = DojDB.Insert([[
        INSERT INTO doj_evidence (evidence_number, sequence_no, evidence_type, title, description, location_found, storage_location,
            status, collected_by_identifier, collected_by_name, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        evidenceNumber, sequenceNo, payload.evidence_type, payload.title, payload.description, payload.location_found,
        payload.storage_location, payload.status or 'checked_in', actor.identifier, actor.name, DojUtils.SafeEncode(payload.metadata or {})
    })

    if not evidenceId then
        return { ok = false, error = 'create_evidence_failed' }
    end

    local chain = DojEvidence.AppendCustody(source, {
        evidence_id = evidenceId,
        action_type = 'collected',
        from_person_identifier = nil,
        to_person_identifier = actor.identifier,
        from_location = payload.location_found,
        to_location = payload.storage_location,
        reason_note = 'Evidence erstellt'
    })

    if payload.case_id then
        DojDB.Insert('INSERT INTO doj_case_evidence (case_id, evidence_id, relation_type, created_by_identifier, created_by_name) VALUES (?, ?, ?, ?, ?)', {
            payload.case_id, evidenceId, 'supporting_evidence', actor.identifier, actor.name
        })
    end

    DojIntegrations.MirrorEvidence({
        evidence_number = evidenceNumber,
        evidence_type = payload.evidence_type,
        description = payload.description,
        location_found = payload.location_found,
        storage_location = payload.storage_location,
        status = payload.status or 'checked_in',
        collected_by = actor.identifier,
        collected_by_name = actor.name,
        metadata = payload.metadata or {}
    })

    return { ok = true, data = { id = evidenceId, evidence_number = evidenceNumber, custody = chain.data } }
end

function DojEvidence.AppendCustody(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'evidence_transfer')
    if not ok then return { ok = false, error = xPlayer } end

    if not validActions[payload.action_type] then
        return { ok = false, error = 'invalid_action_type' }
    end

    local actor = DojUtils.Actor(source, xPlayer)
    local previous = DojDB.Single('SELECT entry_hash FROM doj_evidence_custody WHERE evidence_id = ? ORDER BY id DESC LIMIT 1', { payload.evidence_id })
    local previousHash = previous and previous.entry_hash or string.rep('0', 64)
    local createdAt = DojUtils.UtcNow()

    local hashPayload = {
        evidence_id = payload.evidence_id,
        action_type = payload.action_type,
        from_person_identifier = payload.from_person_identifier,
        to_person_identifier = payload.to_person_identifier,
        from_location = payload.from_location,
        to_location = payload.to_location,
        reason_note = payload.reason_note,
        created_by = actor.identifier,
        created_at = createdAt
    }

    local entryHash = buildEntryHash(previousHash, hashPayload)

    local id = DojDB.Insert([[
        INSERT INTO doj_evidence_custody (evidence_id, action_type, from_person_identifier, to_person_identifier, from_location, to_location,
            reason_note, created_by_identifier, created_by_name, previous_hash, entry_hash, metadata, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.evidence_id, payload.action_type, payload.from_person_identifier, payload.to_person_identifier,
        payload.from_location, payload.to_location, payload.reason_note, actor.identifier, actor.name,
        previousHash, entryHash, DojUtils.SafeEncode(payload.metadata or {})
    })

    if not id then
        return { ok = false, error = 'custody_insert_failed' }
    end

    DojDB.Update('UPDATE doj_evidence SET status = ?, storage_location = COALESCE(?, storage_location), updated_at = UTC_TIMESTAMP() WHERE id = ?', {
        payload.action_type, payload.to_location, payload.evidence_id
    })

    return {
        ok = true,
        data = {
            id = id,
            previous_hash = previousHash,
            entry_hash = entryHash
        }
    }
end

function DojEvidence.VerifyChain(source, evidenceId)
    if source and source > 0 then
        local ok = DojPermissions.Assert(source, 'audit_view')
        if not ok then return { ok = false, error = 'no_permission' } end
    end

    local rows = DojDB.Query('SELECT * FROM doj_evidence_custody WHERE evidence_id = ? ORDER BY id ASC', { evidenceId })
    local previousHash = string.rep('0', 64)
    local broken = {}

    for _, row in ipairs(rows) do
        local hashPayload = {
            evidence_id = row.evidence_id,
            action_type = row.action_type,
            from_person_identifier = row.from_person_identifier,
            to_person_identifier = row.to_person_identifier,
            from_location = row.from_location,
            to_location = row.to_location,
            reason_note = row.reason_note,
            created_by = row.created_by_identifier,
            created_at = tostring(row.created_at)
        }

        local expected = buildEntryHash(previousHash, hashPayload)
        if row.previous_hash ~= previousHash or row.entry_hash ~= expected then
            broken[#broken + 1] = {
                id = row.id,
                expected_previous_hash = previousHash,
                actual_previous_hash = row.previous_hash,
                expected_entry_hash = expected,
                actual_entry_hash = row.entry_hash
            }
        end

        previousHash = row.entry_hash
    end

    return { ok = true, data = { valid = #broken == 0, inconsistencies = broken, entries = rows } }
end
