Config = {}

Config.Locale = 'de'
Config.Debug = false
Config.ResourceName = 'doj_casehub'
Config.Command = 'doj'
Config.EnableAutoMigrations = true
Config.DefaultPageSize = 25
Config.MaxPageSize = 100

Config.Identifier = {
    primaryPrefix = 'char',
    fallbackPrefix = 'license',
    fallbackName = 'Unbekannt'
}

Config.CaseNumber = {
    prefix = 'DOJ',
    padLength = 6,
    includeTypeToken = true,
    typeTokens = {
        criminal_case = 'CR',
        court_case = 'CT'
    }
}

Config.Tablet = {
    prop = 'prop_cs_tablet',
    animDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a',
    animName = 'idle_a',
    animFlag = 49,
    attachBone = 28422,
    offset = vec3(-0.05, 0.0, 0.03),
    rotation = vec3(10.0, 160.0, 0.0)
}

Config.Integrations = {
    wasabi = {
        enabled = true,
        resource = 'wasabi_mdt',
        useOfficerChecks = true,
        mirrorEvidence = false,
        mirrorNotes = false,
        mirrorPhotos = false,
        mirrorWarrants = false
    },
    vms = {
        enabled = true,
        resource = 'vms_cityhall',
        useGiveBill = false
    },
    externalIdentity = {
        enabled = true,
        table = 'users',
        identifierColumn = 'identifier'
    },
    externalFines = {
        enabled = false,
        table = 'fines',
        fineIdColumn = 'id',
        fineTypeColumn = 'type',
        fineDataColumn = 'data',
        fineTargetIdentifierColumn = 'receiver',
        fineOfficerIdentifierColumn = 'issuer'
    }
}

Config.WasabiSchema = {
    citizens = { table = 'wsb_mdt_citizens', identifier = 'identifier', firstname = 'firstname', lastname = 'lastname' },
    charges = { table = 'wsb_mdt_charges', id = 'id', title = 'title', description = 'description', jail_time = 'jail_time', fine = 'fine', category = 'category', created_by = 'created_by', created_by_name = 'created_by_name', metadata = 'metadata' },
    incidents = { table = 'wsb_mdt_incidents', id = 'id', incident_number = 'incident_number', primary_citizen = 'primary_citizen' },
    vehicles = { table = 'wsb_mdt_vehicles', id = 'id', plate = 'plate', model = 'model', owner_id = 'owner_id' },
    weapons = { table = 'wsb_mdt_weapons', id = 'id', serial_number = 'serial_number', weapon_type = 'weapon_type', owner_id = 'owner_id' },
    warrants = { table = 'wsb_mdt_warrants', id = 'id', citizen_id = 'citizen_id' },
    evidence = { table = 'wsb_mdt_evidence', id = 'id', evidence_number = 'evidence_number', evidence_type = 'evidence_type', collected_by = 'collected_by' },
    notes = { table = 'wsb_mdt_notes', id = 'id', entity_type = 'entity_type', entity_id = 'entity_id' },
    photos = { table = 'wsb_mdt_photos', id = 'id', entity_type = 'entity_type', entity_id = 'entity_id' },
    entityLinks = { table = 'wsb_mdt_entity_links', from_type = 'from_type', from_id = 'from_id', to_type = 'to_type', to_id = 'to_id' }
}

Config.Defaults = {
    caseStatus = { 'draft', 'open', 'under_review', 'submitted_to_court', 'hearing_scheduled', 'in_trial', 'closed', 'archived', 'sealed' },
    casePriority = { 'low', 'normal', 'high', 'critical' },
    caseTypes = { 'criminal_case', 'court_case' },
    evidenceStatus = { 'checked_in', 'checked_out', 'submitted', 'under_analysis', 'returned', 'destroyed' },
    evidenceTypes = { 'document', 'weapon', 'drugs', 'photo', 'video', 'blood', 'fingerprint', 'shell_casing', 'phone', 'financial_record', 'vehicle_part', 'misc' },
    hearingTypes = { 'arraignment', 'bail', 'pretrial', 'trial', 'sentencing', 'appeal' },
    hearingStatus = { 'scheduled', 'postponed', 'cancelled', 'completed' },
    documentTypes = { 'indictment', 'warrant_request', 'hearing_summary', 'plea_agreement', 'judgement', 'prosecutor_note', 'judge_note', 'internal_memo', 'evidence_summary', 'appeal_document' },
    taskStatus = { 'open', 'in_progress', 'blocked', 'done', 'cancelled' }
}

Config.Calendar = {
    defaultBufferMinutes = 15,
    hardBlockConflicts = true,
    allowOverridePermissions = { 'admin_manage_permissions', 'hearing_edit' }
}

Config.Sealing = {
    highRoles = { 'attorney_general', 'judge', 'head_doj' },
    inheritVisibilityToLinkedData = true,
    logAccessAttempts = true
}

Config.Export = {
    profiles = {
        compact = { redactSensitive = false, includeAudit = false },
        full = { redactSensitive = false, includeAudit = true },
        redacted = { redactSensitive = true, includeAudit = false }
    }
}

Config.Signatures = {
    allowedRoles = {
        judge = true,
        attorney_general = true,
        district_attorney = true,
        assistant_da = true,
        doj = true,
        head_doj = true
    }
}

Config.Permissions = {
    roles = {
        doj = { tablet_open = true, case_create = true, case_edit = true, case_close = true, case_archive = true, case_seal = true, case_unseal = true, hearing_create = true, hearing_edit = true, hearing_override_conflict = true, verdict_write = true, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = true, document_sign = true, template_manage = true, warrant_create = true, warrant_approve = true, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = true, admin_manage_permissions = true, task_manage = true, filter_manage = true, export_case = true },
        head_doj = { tablet_open = true, case_create = true, case_edit = true, case_close = true, case_archive = true, case_seal = true, case_unseal = true, hearing_create = true, hearing_edit = true, hearing_override_conflict = true, verdict_write = true, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = true, document_sign = true, template_manage = true, warrant_create = true, warrant_approve = true, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = true, admin_manage_permissions = true, task_manage = true, filter_manage = true, export_case = true },
        attorney_general = { tablet_open = true, case_create = true, case_edit = true, case_close = true, case_archive = true, case_seal = true, case_unseal = true, hearing_create = true, hearing_edit = true, hearing_override_conflict = true, verdict_write = true, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = true, document_sign = true, template_manage = true, warrant_create = true, warrant_approve = true, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = true, admin_manage_permissions = true, task_manage = true, filter_manage = true, export_case = true },
        district_attorney = { tablet_open = true, case_create = true, case_edit = true, case_close = true, case_archive = true, case_seal = false, case_unseal = false, hearing_create = true, hearing_edit = true, hearing_override_conflict = false, verdict_write = true, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = true, document_sign = true, template_manage = false, warrant_create = true, warrant_approve = false, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = true, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = true },
        assistant_da = { tablet_open = true, case_create = true, case_edit = true, case_close = false, case_archive = false, case_seal = false, case_unseal = false, hearing_create = true, hearing_edit = true, hearing_override_conflict = false, verdict_write = false, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = false, document_sign = true, template_manage = false, warrant_create = true, warrant_approve = false, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = true, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = true },
        judge = { tablet_open = true, case_create = true, case_edit = true, case_close = true, case_archive = true, case_seal = true, case_unseal = true, hearing_create = true, hearing_edit = true, hearing_override_conflict = true, verdict_write = true, evidence_create = false, evidence_transfer = false, note_create = true, document_create = true, document_finalize = true, document_sign = true, template_manage = false, warrant_create = true, warrant_approve = true, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = true, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = true },
        clerk = { tablet_open = true, case_create = false, case_edit = true, case_close = false, case_archive = false, case_seal = false, case_unseal = false, hearing_create = true, hearing_edit = true, hearing_override_conflict = false, verdict_write = false, evidence_create = false, evidence_transfer = false, note_create = true, document_create = true, document_finalize = false, document_sign = false, template_manage = false, warrant_create = false, warrant_approve = false, citizen_link = true, vehicle_link = true, charge_link = false, incident_link = false, audit_view = true, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = false },
        police = { tablet_open = true, case_create = true, case_edit = true, case_close = false, case_archive = false, case_seal = false, case_unseal = false, hearing_create = false, hearing_edit = false, hearing_override_conflict = false, verdict_write = false, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = false, document_sign = false, template_manage = false, warrant_create = true, warrant_approve = false, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = false, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = false },
        sheriff = { tablet_open = true, case_create = true, case_edit = true, case_close = false, case_archive = false, case_seal = false, case_unseal = false, hearing_create = false, hearing_edit = false, hearing_override_conflict = false, verdict_write = false, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = false, document_sign = false, template_manage = false, warrant_create = true, warrant_approve = false, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = false, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = false },
        fib = { tablet_open = true, case_create = true, case_edit = true, case_close = false, case_archive = false, case_seal = false, case_unseal = false, hearing_create = false, hearing_edit = false, hearing_override_conflict = false, verdict_write = false, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = false, document_sign = false, template_manage = false, warrant_create = true, warrant_approve = false, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = false, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = false },
        state_trooper = { tablet_open = true, case_create = true, case_edit = true, case_close = false, case_archive = false, case_seal = false, case_unseal = false, hearing_create = false, hearing_edit = false, hearing_override_conflict = false, verdict_write = false, evidence_create = true, evidence_transfer = true, note_create = true, document_create = true, document_finalize = false, document_sign = false, template_manage = false, warrant_create = true, warrant_approve = false, citizen_link = true, vehicle_link = true, charge_link = true, incident_link = true, audit_view = false, admin_manage_permissions = false, task_manage = true, filter_manage = true, export_case = false }
    },
    jobRoleMap = {
        doj = 'doj', head_doj = 'head_doj', attorney_general = 'attorney_general', district_attorney = 'district_attorney', assistant_da = 'assistant_da',
        judge = 'judge', clerk = 'clerk', police = 'police', sheriff = 'sheriff', fib = 'fib', state_trooper = 'state_trooper'
    }
}
