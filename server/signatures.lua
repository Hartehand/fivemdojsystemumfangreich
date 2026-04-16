DojSignatures = {}

local function digestForSignature(documentVersion, actor, note, signedAt)
    local raw = table.concat({
        tostring(documentVersion.document_id),
        tostring(documentVersion.id),
        tostring(documentVersion.version_number),
        tostring(documentVersion.content),
        actor.identifier or '',
        actor.name or '',
        actor.role or '',
        note or '',
        signedAt or DojUtils.UtcNow()
    }, '|')

    return DojDB.HashText(raw)
end

function DojSignatures.RequiredRoles(document)
    local policy = DojUtils.SafeDecode(document.signature_policy)
    local requiredRoles = policy.required_roles or {}
    if #requiredRoles == 0 then
        if document.sign_off_role and document.sign_off_role ~= '' then
            requiredRoles = { document.sign_off_role }
        else
            requiredRoles = { 'judge' }
        end
    end

    return requiredRoles
end

function DojSignatures.GetStatus(documentId, versionId)
    local signatures = DojDB.Query('SELECT signer_role FROM doj_document_signatures WHERE document_id = ? AND document_version_id = ?', { documentId, versionId })
    local signedRoles = {}
    for _, row in ipairs(signatures) do
        signedRoles[row.signer_role] = true
    end

    local document = DojDB.Single('SELECT * FROM doj_documents WHERE id = ? LIMIT 1', { documentId })
    if not document then
        return { status = 'unsigned', signed = {}, required = {} }
    end

    local requiredRoles = DojSignatures.RequiredRoles(document)
    local signedCount = 0
    for _, role in ipairs(requiredRoles) do
        if signedRoles[role] then
            signedCount = signedCount + 1
        end
    end

    local status = 'unsigned'
    if signedCount > 0 and signedCount < #requiredRoles then
        status = 'partially_signed'
    elseif signedCount >= #requiredRoles and #requiredRoles > 0 then
        status = 'fully_signed'
    end

    return {
        status = status,
        signed = signedRoles,
        required = requiredRoles
    }
end

function DojSignatures.Sign(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'document_sign')
    if not ok then return { ok = false, error = xPlayer } end

    local actor = DojUtils.Actor(source, xPlayer)
    actor.role = DojPermissions.GetRole(xPlayer)
    if not DojPermissions.CanSignRole(actor.role) then
        return { ok = false, error = 'role_not_allowed' }
    end

    local version = DojDB.Single('SELECT * FROM doj_document_versions WHERE id = ? AND deleted_at IS NULL LIMIT 1', { payload.document_version_id })
    if not version then return { ok = false, error = 'document_version_not_found' } end

    local document = DojDB.Single('SELECT * FROM doj_documents WHERE id = ? AND deleted_at IS NULL LIMIT 1', { version.document_id })
    if not document then return { ok = false, error = 'document_not_found' } end

    local requiredRoles = DojSignatures.RequiredRoles(document)
    local roleAllowed = false
    for _, role in ipairs(requiredRoles) do
        if role == actor.role then roleAllowed = true break end
    end
    if not roleAllowed then
        return { ok = false, error = 'signature_slot_not_available_for_role' }
    end

    local duplicate = DojDB.Single('SELECT id FROM doj_document_signatures WHERE document_version_id = ? AND signer_role = ? LIMIT 1', {
        version.id, actor.role
    })
    if duplicate then return { ok = false, error = 'already_signed_this_slot' } end

    local signedAt = DojUtils.UtcNow()
    local signatureHash = digestForSignature(version, actor, payload.note, signedAt)
    local signatureId = DojDB.Insert([[
        INSERT INTO doj_document_signatures (document_id, document_version_id, signer_identifier, signer_name, signer_role, signed_at, signature_hash, note)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        document.id, version.id, actor.identifier, actor.name, actor.role, signedAt, signatureHash, payload.note
    })

    DojDB.Insert([[
        INSERT INTO doj_audit_log (action, entity_type, entity_id, actor_identifier, actor_name, actor_session, metadata)
        VALUES ('document_signed', 'document_signature', ?, ?, ?, ?, ?)
    ]], {
        tostring(signatureId), actor.identifier, actor.name, actor.session,
        DojUtils.SafeEncode({ document_id = document.id, version_id = version.id, signer_role = actor.role })
    })

    local status = DojSignatures.GetStatus(document.id, version.id)
    if payload.finalize_if_fully_signed and status.status == 'fully_signed' then
        DojDB.Update('UPDATE doj_documents SET is_final = 1, status = \"final\", finalised_by_identifier = ?, finalised_by_name = ?, finalised_at = UTC_TIMESTAMP() WHERE id = ?', {
            actor.identifier, actor.name, document.id
        })
    end

    return { ok = true, data = { signature_id = signatureId, status = status.status } }
end


function DojSignatures.VerifySignature(signatureId)
    local row = DojDB.Single('SELECT ds.*, dv.content, dv.version_number FROM doj_document_signatures ds JOIN doj_document_versions dv ON dv.id = ds.document_version_id WHERE ds.id = ? LIMIT 1', { signatureId })
    if not row then return { ok = false, error = 'signature_not_found' } end

    local actor = { identifier = row.signer_identifier, name = row.signer_name, role = row.signer_role }
    local expected = digestForSignature({ document_id = row.document_id, id = row.document_version_id, version_number = row.version_number, content = row.content }, actor, row.note, tostring(row.signed_at))
    return { ok = true, valid = expected == row.signature_hash, expected_hash = expected, signature_hash = row.signature_hash }
end
