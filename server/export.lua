DojExport = {}

local function gatherCaseData(caseId, profile)
    local data = {}
    data.case = DojDB.Single('SELECT * FROM doj_cases WHERE id = ? AND deleted_at IS NULL LIMIT 1', { caseId })
    if not data.case then return nil end

    data.people = DojDB.Query('SELECT * FROM doj_case_people WHERE case_id = ? AND deleted_at IS NULL', { caseId })
    data.vehicles = DojDB.Query('SELECT * FROM doj_case_vehicles WHERE case_id = ? AND deleted_at IS NULL', { caseId })
    data.weapons = DojDB.Query('SELECT * FROM doj_case_weapons WHERE case_id = ? AND deleted_at IS NULL', { caseId })
    data.charges = DojDB.Query('SELECT * FROM doj_case_charges WHERE case_id = ? AND deleted_at IS NULL', { caseId })
    data.incidents = DojDB.Query('SELECT * FROM doj_case_incidents WHERE case_id = ? AND deleted_at IS NULL', { caseId })
    data.warrants = DojDB.Query('SELECT * FROM doj_case_warrants WHERE case_id = ? AND deleted_at IS NULL', { caseId })
    data.evidence = DojDB.Query([[SELECT e.* FROM doj_case_evidence ce JOIN doj_evidence e ON e.id = ce.evidence_id WHERE ce.case_id = ? AND ce.deleted_at IS NULL AND e.deleted_at IS NULL]], { caseId })
    data.custody = DojDB.Query([[SELECT ec.* FROM doj_case_evidence ce JOIN doj_evidence_custody ec ON ec.evidence_id = ce.evidence_id WHERE ce.case_id = ? ORDER BY ec.id ASC]], { caseId })
    data.notes = DojDB.Query([[SELECT n.* FROM doj_case_notes cn JOIN doj_notes n ON n.id = cn.note_id WHERE cn.case_id = ? AND cn.deleted_at IS NULL AND n.deleted_at IS NULL]], { caseId })
    data.documents = DojDB.Query([[SELECT d.*, cd.relation_type FROM doj_case_documents cd JOIN doj_documents d ON d.id = cd.document_id WHERE cd.case_id = ? AND cd.deleted_at IS NULL AND d.deleted_at IS NULL]], { caseId })
    data.hearings = DojDB.Query('SELECT * FROM doj_hearings WHERE case_id = ? AND deleted_at IS NULL ORDER BY start_at ASC', { caseId })
    data.timeline = DojDB.Query('SELECT * FROM doj_case_timeline WHERE case_id = ? ORDER BY id ASC', { caseId })

    if Config.Export.profiles[profile] and Config.Export.profiles[profile].includeAudit then
        data.audit = DojDB.Query('SELECT * FROM doj_audit_log WHERE entity_type = ? AND entity_id = ? ORDER BY id ASC', { 'case', tostring(caseId) })
    else
        data.audit = {}
    end

    if Config.Export.profiles[profile] and Config.Export.profiles[profile].redactSensitive then
        data.case.description = '[REDACTED]'
        data.notes = {}
        for _, doc in ipairs(data.documents) do
            doc.content = '[REDACTED]'
        end
    end

    return data
end

function DojExport.Create(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'export_case')
    if not ok then return { ok = false, error = xPlayer } end

    local actor = DojUtils.Actor(source, xPlayer)
    local profile = payload.profile or 'full'
    if not Config.Export.profiles[profile] then
        return { ok = false, error = 'invalid_export_profile' }
    end

    local caseRow = DojCases.GetById(payload.case_id)
    if not caseRow then return { ok = false, error = 'case_not_found' } end
    if caseRow.is_sealed == 1 and not DojPermissions.CanViewSealed(xPlayer) then
        return { ok = false, error = 'case_sealed' }
    end

    local data = gatherCaseData(payload.case_id, profile)
    if not data then return { ok = false, error = 'export_collect_failed' } end

    local exportId = DojDB.Insert([[
        INSERT INTO doj_case_exports (case_id, exported_by_identifier, exported_by_name, profile, format, export_payload)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        payload.case_id, actor.identifier, actor.name, profile, payload.format or 'print', DojUtils.SafeEncode(data)
    })

    DojDB.Insert([[
        INSERT INTO doj_audit_log (action, entity_type, entity_id, actor_identifier, actor_name, actor_session, metadata)
        VALUES ('case_exported', 'case_export', ?, ?, ?, ?, ?)
    ]], {
        tostring(exportId), actor.identifier, actor.name, actor.session,
        DojUtils.SafeEncode({ case_id = payload.case_id, profile = profile, format = payload.format or 'print' })
    })

    return {
        ok = true,
        data = {
            export_id = exportId,
            profile = profile,
            format = payload.format or 'print',
            generated_at = DojUtils.UtcNow(),
            payload = data
        }
    }
end

function DojExport.VerifyEvidenceChain(evidenceId)
    return DojEvidence.VerifyChain(-1, evidenceId)
end

function DojExport.GetCase(caseId)
    return DojDB.Single('SELECT * FROM doj_cases WHERE id = ? AND deleted_at IS NULL LIMIT 1', { caseId })
end

exports('VerifyEvidenceChain', DojExport.VerifyEvidenceChain)
exports('GetCase', DojExport.GetCase)
exports('CreateCaseExport', function(source, payload) return DojExport.Create(source, payload) end)
