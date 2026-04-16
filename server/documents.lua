DojDocuments = {}

local function addAudit(action, entityType, entityId, actor, oldValue, newValue)
    DojDB.Insert([[
        INSERT INTO doj_audit_log (action, entity_type, entity_id, actor_identifier, actor_name, actor_session, old_value, new_value)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        action, entityType, tostring(entityId), actor.identifier, actor.name, actor.session,
        DojUtils.SafeEncode(oldValue), DojUtils.SafeEncode(newValue)
    })
end

function DojDocuments.Create(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'document_create')
    if not ok then return { ok = false, error = xPlayer } end
    if not DojUtils.IsInList(payload.document_type, Config.Defaults.documentTypes) then return { ok = false, error = 'invalid_document_type' } end

    local actor = DojUtils.Actor(source, xPlayer)
    local content = payload.content
    if not content or content == '' then content = DojTemplates.BuildDocumentSeed({ display_name = 'Custom' }, { title = payload.title }) end

    local signaturePolicy = payload.signature_policy or { required_roles = payload.required_signature_roles or {} }

    local documentId = DojDB.Insert([[
        INSERT INTO doj_documents (title, document_type, content, status, sign_off_role, signature_policy, created_by_identifier, created_by_name, metadata)
        VALUES (?, ?, ?, 'draft', ?, ?, ?, ?, ?)
    ]], {
        payload.title, payload.document_type, content, payload.sign_off_role,
        DojUtils.SafeEncode(signaturePolicy), actor.identifier, actor.name, DojUtils.SafeEncode(payload.metadata or {})
    })

    local versionId = DojDB.Insert([[
        INSERT INTO doj_document_versions (document_id, version_number, content, edited_by_identifier, edited_by_name, change_note)
        VALUES (?, 1, ?, ?, ?, ?)
    ]], { documentId, content, actor.identifier, actor.name, 'Initiale Version' })

    DojDB.Update('UPDATE doj_documents SET current_version_id = ? WHERE id = ?', { versionId, documentId })

    if payload.case_id then
        DojDB.Insert([[
            INSERT INTO doj_case_documents (case_id, document_id, relation_type, created_by_identifier, created_by_name)
            VALUES (?, ?, 'primary_document', ?, ?)
        ]], { payload.case_id, documentId, actor.identifier, actor.name })
    end

    addAudit('create_document', 'document', documentId, actor, nil, payload)
    return { ok = true, data = { id = documentId, version_id = versionId } }
end

function DojDocuments.UpdateContent(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'document_create')
    if not ok then return { ok = false, error = xPlayer } end

    local document = DojDB.Single('SELECT * FROM doj_documents WHERE id = ? AND deleted_at IS NULL LIMIT 1', { payload.document_id })
    if not document then return { ok = false, error = 'document_not_found' } end
    if document.is_final == 1 then return { ok = false, error = 'document_final_locked' } end

    local actor = DojUtils.Actor(source, xPlayer)

    local maxVersion = DojDB.Scalar('SELECT IFNULL(MAX(version_number), 0) FROM doj_document_versions WHERE document_id = ?', { payload.document_id }) or 0
    local nextVersion = maxVersion + 1
    local versionId = DojDB.Insert([[
        INSERT INTO doj_document_versions (document_id, version_number, content, edited_by_identifier, edited_by_name, change_note)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { payload.document_id, nextVersion, payload.content, actor.identifier, actor.name, payload.change_note or 'Inhalt aktualisiert' })

    DojDB.Update('UPDATE doj_documents SET content = ?, current_version_id = ?, updated_at = UTC_TIMESTAMP() WHERE id = ?', {
        payload.content, versionId, payload.document_id
    })

    addAudit('update_document_content', 'document', payload.document_id, actor, nil, { version_id = versionId, version_number = nextVersion })
    return { ok = true, data = { version_id = versionId, version_number = nextVersion } }
end

function DojDocuments.Finalize(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'document_finalize')
    if not ok then return { ok = false, error = xPlayer } end

    local document = DojDB.Single('SELECT * FROM doj_documents WHERE id = ? AND deleted_at IS NULL LIMIT 1', { payload.document_id })
    if not document then return { ok = false, error = 'document_not_found' } end

    local actor = DojUtils.Actor(source, xPlayer)
    local role = DojPermissions.GetRole(xPlayer)
    if document.sign_off_role and document.sign_off_role ~= '' and role ~= document.sign_off_role then
        return { ok = false, error = 'invalid_signoff_role' }
    end

    local status = DojSignatures.GetStatus(document.id, document.current_version_id)
    if payload.require_full_signatures and status.status ~= 'fully_signed' then
        return { ok = false, error = 'document_not_fully_signed', signature_status = status.status }
    end

    DojDB.Update([[
        UPDATE doj_documents
        SET is_final = 1, status = 'final', finalised_by_identifier = ?, finalised_by_name = ?, finalised_at = UTC_TIMESTAMP(), updated_at = UTC_TIMESTAMP()
        WHERE id = ?
    ]], { actor.identifier, actor.name, payload.document_id })

    addAudit('finalize_document', 'document', payload.document_id, actor, document, { signature_status = status.status })
    return { ok = true, data = { signature_status = status.status } }
end

function DojDocuments.CreateNote(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'note_create')
    if not ok then return { ok = false, error = xPlayer } end

    local actor = DojUtils.Actor(source, xPlayer)
    local noteId = DojDB.Insert([[
        INSERT INTO doj_notes (entity_type, entity_id, visibility, content, created_by_identifier, created_by_name, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        payload.entity_type, tostring(payload.entity_id), payload.visibility or 'team', payload.content,
        actor.identifier, actor.name, DojUtils.SafeEncode(payload.metadata or {})
    })

    DojDB.Insert([[
        INSERT INTO doj_note_versions (note_id, version_number, content, edited_by_identifier, edited_by_name, change_note)
        VALUES (?, 1, ?, ?, ?, 'Initiale Version')
    ]], { noteId, payload.content, actor.identifier, actor.name })

    if payload.case_id then
        DojDB.Insert([[
            INSERT INTO doj_case_notes (case_id, note_id, relation_type, created_by_identifier, created_by_name)
            VALUES (?, ?, 'case_note', ?, ?)
        ]], { payload.case_id, noteId, actor.identifier, actor.name })
    end

    DojIntegrations.MirrorNote({
        content = payload.content,
        entity_type = payload.entity_type,
        entity_id = payload.entity_id,
        created_by = actor.identifier,
        created_by_name = actor.name,
        metadata = payload.metadata or {}
    })

    addAudit('create_note', 'note', noteId, actor, nil, payload)
    return { ok = true, data = { id = noteId } }
end


function DojDocuments.List(source, payload)
    local ok = DojPermissions.Assert(source, 'tablet_open')
    if not ok then return { ok = false, error = 'no_permission' } end

    local rows
    if payload and payload.case_id then
        rows = DojDB.Query([[SELECT d.* FROM doj_case_documents cd JOIN doj_documents d ON d.id = cd.document_id WHERE cd.case_id = ? AND cd.deleted_at IS NULL AND d.deleted_at IS NULL ORDER BY d.updated_at DESC]], { payload.case_id })
    else
        rows = DojDB.Query('SELECT * FROM doj_documents WHERE deleted_at IS NULL ORDER BY updated_at DESC LIMIT 200')
    end

    return { ok = true, data = rows }
end
