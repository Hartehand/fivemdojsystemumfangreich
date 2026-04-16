DojTemplates = {}

local builtInTemplates = {
    {
        template_key = 'verkehrsunfall',
        display_name = 'Verkehrsunfall',
        case_type = 'criminal_case',
        default_title = 'Verkehrsunfall-Ermittlung',
        default_status = 'open',
        default_tags = { 'verkehr', 'unfall', 'ermittlung' },
        recommended_evidence_types = { 'photo', 'video', 'financial_record', 'misc' },
        recommended_roles = { 'driver', 'holder', 'witness', 'officer' },
        checklist = {
            'Fahrer identifizieren', 'Kennzeichen prüfen', 'Versicherungsstatus prüfen', 'Zeugenaussagen aufnehmen', 'Unfallbericht erstellen'
        },
        timeline_milestones = { 'fall_angelegt', 'unfallaufnahme_abgeschlossen', 'bericht_finalisiert' },
        tasks = {
            { title = 'Fahrer identifizieren', description = 'Primären Fahrer und weitere Beteiligte erfassen', status = 'open' },
            { title = 'Kennzeichen prüfen', description = 'Kennzeichen, Halter und Fahrzeugdaten prüfen', status = 'open' },
            { title = 'Versicherungsstatus prüfen', description = 'Versicherungs- und Lizenzstatus prüfen', status = 'open' },
            { title = 'Zeugenaussagen aufnehmen', description = 'Zeugen anhören und Aussagen dokumentieren', status = 'open' },
            { title = 'Unfallbericht erstellen', description = 'Finalen Unfallbericht erstellen', status = 'open' }
        },
        documents = {
            { title = 'Unfallbericht', document_type = 'internal_memo' },
            { title = 'Beweismittelübersicht Unfall', document_type = 'evidence_summary' }
        }
    },
    {
        template_key = 'raub',
        display_name = 'Raub',
        case_type = 'criminal_case',
        default_title = 'Raub-Ermittlung',
        default_status = 'open',
        default_tags = { 'raub', 'gewalt', 'tatort' },
        recommended_evidence_types = { 'photo', 'video', 'fingerprint', 'blood', 'weapon' },
        recommended_roles = { 'victim', 'witness', 'suspect', 'officer', 'prosecutor' },
        checklist = {
            'Opfer erfassen', 'Tatort dokumentieren', 'Beweise sichern', 'Zeugen anhören', 'Verdächtige verknüpfen', 'Haftbefehl prüfen'
        },
        timeline_milestones = { 'fall_angelegt', 'tatort_dokumentiert', 'anklage_pruefung' },
        tasks = {
            { title = 'Opfer erfassen', description = 'Opferdaten vollständig erfassen', status = 'open' },
            { title = 'Tatort dokumentieren', description = 'Tatortfotos und Lageplan erfassen', status = 'open' },
            { title = 'Beweise sichern', description = 'Physische und digitale Beweise sichern', status = 'open' },
            { title = 'Zeugen anhören', description = 'Zeugen identifizieren und befragen', status = 'open' },
            { title = 'Verdächtige verknüpfen', description = 'Verdächtige Personen und Fahrzeuge verknüpfen', status = 'open' },
            { title = 'Haftbefehl prüfen', description = 'Warrant-Notwendigkeit bewerten', status = 'open' }
        },
        documents = {
            { title = 'Anklagevorprüfung Raub', document_type = 'indictment' },
            { title = 'Warrant Request Raub', document_type = 'warrant_request' }
        }
    },
    {
        template_key = 'mord',
        display_name = 'Mord',
        case_type = 'criminal_case',
        default_title = 'Mord-Ermittlung',
        default_status = 'under_review',
        default_tags = { 'mord', 'forensik', 'high_priority' },
        recommended_evidence_types = { 'blood', 'fingerprint', 'shell_casing', 'weapon', 'photo', 'video' },
        recommended_roles = { 'victim', 'suspect', 'witness', 'investigator', 'prosecutor', 'judge' },
        checklist = {
            'Tatort sichern', 'Leiche/Opfer erfassen', 'forensische Beweise dokumentieren', 'Timeline rekonstruieren',
            'Verdächtige priorisieren', 'Prosecutor Review', 'Gerichtsvorbereitung'
        },
        timeline_milestones = { 'fall_angelegt', 'forensik_abgeschlossen', 'prosecutor_review', 'court_ready' },
        tasks = {
            { title = 'Tatort sichern', description = 'Tatort absperren und Zugriff dokumentieren', status = 'open' },
            { title = 'Leiche / Opfer erfassen', description = 'Opferdaten und Coroner-Referenz erfassen', status = 'open' },
            { title = 'Forensische Beweise dokumentieren', description = 'Forensik-Beweise katalogisieren', status = 'open' },
            { title = 'Timeline rekonstruieren', description = 'Chronologie der Ereignisse ausarbeiten', status = 'open' },
            { title = 'Verdächtige priorisieren', description = 'Priorisierung und Ermittlungsfokus festlegen', status = 'open' },
            { title = 'Prosecutor review', description = 'Falleinordnung mit Staatsanwaltschaft abstimmen', status = 'open' },
            { title = 'Gerichtsvorbereitung', description = 'Unterlagen für Gericht aufbereiten', status = 'open' }
        },
        documents = {
            { title = 'Mordfall Indictment', document_type = 'indictment' },
            { title = 'Forensik-Summary Mord', document_type = 'evidence_summary' },
            { title = 'Gerichtsvorbereitung Mord', document_type = 'internal_memo' }
        }
    }
}

local function encodeTemplate(template)
    return {
        default_tags = DojUtils.SafeEncode(template.default_tags),
        recommended_evidence_types = DojUtils.SafeEncode(template.recommended_evidence_types),
        recommended_roles = DojUtils.SafeEncode(template.recommended_roles),
        checklist = DojUtils.SafeEncode(template.checklist),
        timeline_milestones = DojUtils.SafeEncode(template.timeline_milestones)
    }
end

function DojTemplates.SeedBuiltInTemplates()
    for _, template in ipairs(builtInTemplates) do
        local encoded = encodeTemplate(template)
        DojDB.Insert([[
            INSERT INTO doj_case_templates (template_key, display_name, case_type, default_title, default_status, default_tags,
                recommended_evidence_types, recommended_roles, checklist, timeline_milestones, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                display_name = VALUES(display_name),
                case_type = VALUES(case_type),
                default_title = VALUES(default_title),
                default_status = VALUES(default_status),
                default_tags = VALUES(default_tags),
                recommended_evidence_types = VALUES(recommended_evidence_types),
                recommended_roles = VALUES(recommended_roles),
                checklist = VALUES(checklist),
                timeline_milestones = VALUES(timeline_milestones)
        ]], {
            template.template_key,
            template.display_name,
            template.case_type,
            template.default_title,
            template.default_status,
            encoded.default_tags,
            encoded.recommended_evidence_types,
            encoded.recommended_roles,
            encoded.checklist,
            encoded.timeline_milestones,
            DojUtils.SafeEncode({ seeded = true })
        })

        local templateRow = DojDB.Single('SELECT id FROM doj_case_templates WHERE template_key = ? LIMIT 1', { template.template_key })
        if templateRow then
            DojDB.Query('DELETE FROM doj_case_template_tasks WHERE template_id = ?', { templateRow.id })
            DojDB.Query('DELETE FROM doj_case_template_documents WHERE template_id = ?', { templateRow.id })

            for index, task in ipairs(template.tasks) do
                DojDB.Insert([[
                    INSERT INTO doj_case_template_tasks (template_id, sort_order, title, description, default_status, metadata)
                    VALUES (?, ?, ?, ?, ?, ?)
                ]], { templateRow.id, index, task.title, task.description, task.status or 'open', DojUtils.SafeEncode(task.metadata or {}) })
            end

            for index, doc in ipairs(template.documents) do
                DojDB.Insert([[
                    INSERT INTO doj_case_template_documents (template_id, sort_order, title, document_type, metadata)
                    VALUES (?, ?, ?, ?, ?)
                ]], { templateRow.id, index, doc.title, doc.document_type, DojUtils.SafeEncode(doc.metadata or {}) })
            end
        end
    end
end

function DojTemplates.List(activeOnly)
    local sql = 'SELECT * FROM doj_case_templates WHERE deleted_at IS NULL'
    if activeOnly then
        sql = sql .. ' AND is_active = 1'
    end
    sql = sql .. ' ORDER BY display_name ASC'

    local templates = DojDB.Query(sql)
    for _, template in ipairs(templates) do
        template.default_tags = DojUtils.SafeDecode(template.default_tags)
        template.recommended_evidence_types = DojUtils.SafeDecode(template.recommended_evidence_types)
        template.recommended_roles = DojUtils.SafeDecode(template.recommended_roles)
        template.checklist = DojUtils.SafeDecode(template.checklist)
        template.timeline_milestones = DojUtils.SafeDecode(template.timeline_milestones)
        template.tasks = DojDB.Query('SELECT * FROM doj_case_template_tasks WHERE template_id = ? ORDER BY sort_order ASC', { template.id })
        template.documents = DojDB.Query('SELECT * FROM doj_case_template_documents WHERE template_id = ? ORDER BY sort_order ASC', { template.id })
    end

    return templates
end

function DojTemplates.GetByKey(templateKey)
    local template = DojDB.Single('SELECT * FROM doj_case_templates WHERE template_key = ? AND deleted_at IS NULL AND is_active = 1 LIMIT 1', { templateKey })
    if not template then return nil end

    template.default_tags = DojUtils.SafeDecode(template.default_tags)
    template.recommended_evidence_types = DojUtils.SafeDecode(template.recommended_evidence_types)
    template.recommended_roles = DojUtils.SafeDecode(template.recommended_roles)
    template.checklist = DojUtils.SafeDecode(template.checklist)
    template.timeline_milestones = DojUtils.SafeDecode(template.timeline_milestones)
    template.tasks = DojDB.Query('SELECT * FROM doj_case_template_tasks WHERE template_id = ? ORDER BY sort_order ASC', { template.id })
    template.documents = DojDB.Query('SELECT * FROM doj_case_template_documents WHERE template_id = ? ORDER BY sort_order ASC', { template.id })
    return template
end

function DojTemplates.ApplyToCase(caseId, templateKey, actor)
    local template = DojTemplates.GetByKey(templateKey)
    if not template then return { ok = false, error = 'template_not_found' } end

    for _, task in ipairs(template.tasks or {}) do
        DojDB.Insert([[
            INSERT INTO doj_case_tasks (case_id, title, description, status, reminder_enabled, created_by_identifier, created_by_name, metadata)
            VALUES (?, ?, ?, ?, 0, ?, ?, ?)
        ]], {
            caseId, task.title, task.description, task.default_status or 'open', actor.identifier, actor.name,
            DojUtils.SafeEncode({ source_template = template.template_key })
        })
    end

    for _, doc in ipairs(template.documents or {}) do
        local docId = DojDB.Insert([[
            INSERT INTO doj_documents (title, document_type, content, status, created_by_identifier, created_by_name, metadata)
            VALUES (?, ?, ?, 'draft', ?, ?, ?)
        ]], {
            doc.title, doc.document_type, DojTemplates.BuildDocumentSeed(template, doc), actor.identifier, actor.name,
            DojUtils.SafeEncode({ source_template = template.template_key })
        })

        if docId then
            DojDB.Insert('INSERT INTO doj_document_versions (document_id, version_number, content, edited_by_identifier, edited_by_name, change_note) VALUES (?, 1, ?, ?, ?, ?)', {
                docId,
                DojTemplates.BuildDocumentSeed(template, doc),
                actor.identifier,
                actor.name,
                ('Template %s angewendet'):format(template.display_name)
            })

            DojDB.Insert('INSERT INTO doj_case_documents (case_id, document_id, relation_type, created_by_identifier, created_by_name, metadata) VALUES (?, ?, ?, ?, ?, ?)', {
                caseId, docId, 'template_document', actor.identifier, actor.name,
                DojUtils.SafeEncode({ source_template = template.template_key })
            })
        end
    end

    for _, milestone in ipairs(template.timeline_milestones or {}) do
        DojDB.Insert([[
            INSERT INTO doj_case_timeline (case_id, event_type, event_label, actor_identifier, actor_name, actor_session, metadata)
            VALUES (?, 'template_milestone', ?, ?, ?, ?, ?)
        ]], {
            caseId,
            milestone,
            actor.identifier,
            actor.name,
            actor.session,
            DojUtils.SafeEncode({ source_template = template.template_key })
        })
    end

    return { ok = true, data = template }
end

function DojTemplates.BuildDocumentSeed(template, doc)
    return ('# %s\n\nTemplate: %s\n\n## Sachverhalt\n\n## Bewertung\n\n## Nächste Schritte'):format(doc.title, template.display_name)
end


function DojTemplates.Save(source, payload)
    local ok, xPlayer = DojPermissions.Assert(source, 'template_manage')
    if not ok then return { ok = false, error = xPlayer } end

    local actor = DojUtils.Actor(source, xPlayer)
    local existing = DojDB.Single('SELECT id FROM doj_case_templates WHERE template_key = ? LIMIT 1', { payload.template_key })

    if existing then
        DojDB.Update([[
            UPDATE doj_case_templates
            SET display_name = ?, case_type = ?, default_title = ?, default_status = ?, default_tags = ?,
                recommended_evidence_types = ?, recommended_roles = ?, checklist = ?, timeline_milestones = ?,
                is_active = ?, metadata = ?, updated_at = UTC_TIMESTAMP()
            WHERE id = ?
        ]], {
            payload.display_name, payload.case_type, payload.default_title, payload.default_status,
            DojUtils.SafeEncode(payload.default_tags or {}), DojUtils.SafeEncode(payload.recommended_evidence_types or {}),
            DojUtils.SafeEncode(payload.recommended_roles or {}), DojUtils.SafeEncode(payload.checklist or {}),
            DojUtils.SafeEncode(payload.timeline_milestones or {}), payload.is_active and 1 or 0,
            DojUtils.SafeEncode(payload.metadata or {}), existing.id
        })
        DojDB.Query('DELETE FROM doj_case_template_tasks WHERE template_id = ?', { existing.id })
        DojDB.Query('DELETE FROM doj_case_template_documents WHERE template_id = ?', { existing.id })
    else
        local id = DojDB.Insert([[
            INSERT INTO doj_case_templates (template_key, display_name, case_type, default_title, default_status, default_tags, recommended_evidence_types, recommended_roles, checklist, timeline_milestones, is_active, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            payload.template_key, payload.display_name, payload.case_type, payload.default_title, payload.default_status,
            DojUtils.SafeEncode(payload.default_tags or {}), DojUtils.SafeEncode(payload.recommended_evidence_types or {}),
            DojUtils.SafeEncode(payload.recommended_roles or {}), DojUtils.SafeEncode(payload.checklist or {}),
            DojUtils.SafeEncode(payload.timeline_milestones or {}), payload.is_active and 1 or 0,
            DojUtils.SafeEncode(payload.metadata or {})
        })
        existing = { id = id }
    end

    for index, task in ipairs(payload.tasks or {}) do
        DojDB.Insert('INSERT INTO doj_case_template_tasks (template_id, sort_order, title, description, default_status, metadata) VALUES (?, ?, ?, ?, ?, ?)', {
            existing.id, index, task.title, task.description, task.default_status or 'open', DojUtils.SafeEncode(task.metadata or {})
        })
    end

    for index, doc in ipairs(payload.documents or {}) do
        DojDB.Insert('INSERT INTO doj_case_template_documents (template_id, sort_order, title, document_type, metadata) VALUES (?, ?, ?, ?, ?)', {
            existing.id, index, doc.title, doc.document_type, DojUtils.SafeEncode(doc.metadata or {})
        })
    end

    DojDB.Insert("INSERT INTO doj_audit_log (action, entity_type, entity_id, actor_identifier, actor_name, actor_session, metadata) VALUES ('template_saved', 'case_template', ?, ?, ?, ?, ?)", {
        tostring(existing.id), actor.identifier, actor.name, actor.session, DojUtils.SafeEncode({ template_key = payload.template_key })
    })

    return { ok = true, data = { id = existing.id } }
end
