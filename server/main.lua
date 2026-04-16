DOJ = {}
local ESX = exports['es_extended']:getSharedObject()

function DOJ.GetPlayer(source)
    return ESX.GetPlayerFromId(source)
end

local function responseSafe(fn)
    return function(source, cb, payload)
        local ok, result = pcall(fn, source, payload or {})
        if not ok then
            DojUtils.LogError('ServerCallback', result)
            cb({ ok = false, error = 'internal_error' })
            return
        end
        cb(result)
    end
end

local function getDashboard(xPlayer)
    local allowSealed = DojPermissions.CanViewSealed(xPlayer)
    local sealedFilter = allowSealed and '' or ' AND is_sealed = 0'

    return {
        open_cases = DojDB.Scalar(("SELECT COUNT(*) FROM doj_cases WHERE deleted_at IS NULL%s AND status IN ('open','under_review','in_trial','hearing_scheduled')"):format(sealedFilter)) or 0,
        hearings_today = DojDB.Scalar("SELECT COUNT(*) FROM doj_hearings WHERE deleted_at IS NULL AND DATE(start_at)=UTC_DATE()") or 0,
        new_evidence = DojDB.Scalar("SELECT COUNT(*) FROM doj_evidence WHERE deleted_at IS NULL AND DATE(created_at)=UTC_DATE()") or 0,
        sealed_cases = DojDB.Scalar("SELECT COUNT(*) FROM doj_cases WHERE deleted_at IS NULL AND is_sealed=1") or 0,
        overdue_tasks = DojDB.Scalar("SELECT COUNT(*) FROM doj_case_tasks WHERE deleted_at IS NULL AND status <> 'done' AND due_at < UTC_TIMESTAMP()") or 0,
        latest_activity = DojDB.Query("SELECT id, action, entity_type, entity_id, actor_name, created_at FROM doj_audit_log ORDER BY id DESC LIMIT 20")
    }
end

ESX.RegisterServerCallback('doj_casehub:bootstrap', responseSafe(function(source)
    local ok, xPlayer = DojPermissions.Assert(source, 'tablet_open')
    if not ok then return { ok = false, error = xPlayer } end

    local actor = DojUtils.Actor(source, xPlayer)
    return {
        ok = true,
        data = {
            actor = actor,
            dashboard = getDashboard(xPlayer),
            role = DojPermissions.GetRole(xPlayer),
            permissions = Config.Permissions.roles[DojPermissions.GetRole(xPlayer) or ''] or {},
            defaults = Config.Defaults,
            filters = DojDB.Query('SELECT id, name, module, filter_payload FROM doj_saved_filters WHERE owner_identifier = ? AND deleted_at IS NULL ORDER BY id DESC', { actor.identifier }),
            courtrooms = DojDB.Query('SELECT id, room_code, label FROM doj_courtrooms WHERE active = 1 ORDER BY room_code ASC'),
            templates = DojTemplates.List(true)
        }
    }
end))

ESX.RegisterServerCallback('doj_casehub:search', responseSafe(DojCases.Search))
ESX.RegisterServerCallback('doj_casehub:getCases', responseSafe(DojCases.GetList))
ESX.RegisterServerCallback('doj_casehub:createCase', responseSafe(DojCases.Create))
ESX.RegisterServerCallback('doj_casehub:updateCase', responseSafe(DojCases.Update))
ESX.RegisterServerCallback('doj_casehub:linkEntity', responseSafe(DojCases.LinkEntity))
ESX.RegisterServerCallback('doj_casehub:createTask', responseSafe(DojCases.CreateTask))
ESX.RegisterServerCallback('doj_casehub:saveFilter', responseSafe(DojCases.SaveFilter))
ESX.RegisterServerCallback('doj_casehub:sealCase', responseSafe(DojCases.Seal))
ESX.RegisterServerCallback('doj_casehub:unsealCase', responseSafe(DojCases.Unseal))
ESX.RegisterServerCallback('doj_casehub:saveTemplate', responseSafe(DojTemplates.Save))
ESX.RegisterServerCallback('doj_casehub:listTemplates', responseSafe(function(source, payload)
    local ok = DojPermissions.Assert(source, 'tablet_open')
    if not ok then return { ok = false, error = 'no_permission' } end
    return { ok = true, data = DojTemplates.List(payload.active_only ~= false) }
end))

ESX.RegisterServerCallback('doj_casehub:getCalendar', responseSafe(DojHearings.GetCalendar))
ESX.RegisterServerCallback('doj_casehub:createHearing', responseSafe(DojHearings.Create))

ESX.RegisterServerCallback('doj_casehub:createEvidence', responseSafe(DojEvidence.Create))
ESX.RegisterServerCallback('doj_casehub:transferEvidence', responseSafe(function(source, payload) return DojEvidence.AppendCustody(source, payload) end))
ESX.RegisterServerCallback('doj_casehub:verifyEvidenceChain', responseSafe(function(source, payload) return DojEvidence.VerifyChain(source, payload.evidence_id) end))

ESX.RegisterServerCallback('doj_casehub:createDocument', responseSafe(DojDocuments.Create))
ESX.RegisterServerCallback('doj_casehub:updateDocumentContent', responseSafe(DojDocuments.UpdateContent))
ESX.RegisterServerCallback('doj_casehub:finalizeDocument', responseSafe(DojDocuments.Finalize))
ESX.RegisterServerCallback('doj_casehub:signDocument', responseSafe(DojSignatures.Sign))
ESX.RegisterServerCallback('doj_casehub:verifySignature', responseSafe(function(source, payload)
    local ok = DojPermissions.Assert(source, 'audit_view')
    if not ok then return { ok = false, error = 'no_permission' } end
    return DojSignatures.VerifySignature(payload.signature_id)
end))
ESX.RegisterServerCallback('doj_casehub:createNote', responseSafe(DojDocuments.CreateNote))
ESX.RegisterServerCallback('doj_casehub:exportCase', responseSafe(DojExport.Create))
ESX.RegisterServerCallback('doj_casehub:getTimeline', responseSafe(function(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'tablet_open')
    if not ok then return { ok = false, error = xPlayer } end

    local caseRow = DojCases.GetById(payload.case_id)
    if not caseRow then return { ok = false, error = 'case_not_found' } end
    if caseRow.is_sealed == 1 and not DojPermissions.CanViewSealed(xPlayer) then return { ok = false, error = 'case_sealed' } end

    local rows = DojDB.Query('SELECT * FROM doj_case_timeline WHERE case_id = ? ORDER BY id DESC LIMIT 300', { payload.case_id })
    return { ok = true, data = rows }
end))

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    DojDB.Init()
    DojTemplates.SeedBuiltInTemplates()
    print(('[%s] gestartet.'):format(GetCurrentResourceName()))
end)
