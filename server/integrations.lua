DojIntegrations = {}

local function hasResource(resource)
    return resource and GetResourceState(resource) == 'started'
end

local function callWasabiExport(name, ...)
    local cfg = Config.Integrations.wasabi
    if not cfg.enabled or not hasResource(cfg.resource) then
        return nil
    end

    local ok, response = pcall(function(...)
        return exports[cfg.resource][name](...)
    end, ...)

    if not ok then
        DojUtils.LogError('Integrations.wasabi.' .. name, response)
        return nil
    end

    return response
end

function DojIntegrations.ResolveCitizen(identifier)
    local citizen = callWasabiExport('GetCitizen', identifier)
    if citizen then
        return citizen
    end

    local schema = Config.WasabiSchema.citizens
    local sql = ('SELECT %s as identifier, %s as firstname, %s as lastname FROM %s WHERE %s = ? LIMIT 1')
        :format(schema.identifier, schema.firstname, schema.lastname, schema.table, schema.identifier)
    local row = DojDB.Single(sql, { identifier })
    if row then
        return row
    end

    local ext = Config.Integrations.externalIdentity
    if ext.enabled then
        local identity = DojDB.Single(('SELECT * FROM %s WHERE %s = ? LIMIT 1'):format(ext.table, ext.identifierColumn), { identifier })
        if identity then
            return identity
        end
    end

    return nil
end

function DojIntegrations.ResolveVehicleByPlate(plate)
    local vehicle = callWasabiExport('GetVehicleByPlate', plate)
    if vehicle then return vehicle end

    local schema = Config.WasabiSchema.vehicles
    return DojDB.Single(('SELECT %s as id, %s as plate, %s as model, %s as owner_id FROM %s WHERE %s = ? LIMIT 1')
        :format(schema.id, schema.plate, schema.model, schema.owner_id, schema.table, schema.plate), { plate })
end

function DojIntegrations.ResolveWeaponBySerial(serial)
    local weapon = callWasabiExport('GetWeaponBySerial', serial)
    if weapon then return weapon end

    local schema = Config.WasabiSchema.weapons
    return DojDB.Single(('SELECT %s as id, %s as serial_number, %s as weapon_type, %s as owner_id FROM %s WHERE %s = ? LIMIT 1')
        :format(schema.id, schema.serial_number, schema.weapon_type, schema.owner_id, schema.table, schema.serial_number), { serial })
end

function DojIntegrations.ResolveCharge(chargeId)
    local charge = callWasabiExport('GetCharge', chargeId)
    if charge then return charge end

    local schema = Config.WasabiSchema.charges
    return DojDB.Single(('SELECT * FROM %s WHERE %s = ? LIMIT 1'):format(schema.table, schema.id), { chargeId })
end

function DojIntegrations.ResolveIncident(incidentId)
    local incident = callWasabiExport('GetIncident', incidentId)
    if incident then return incident end

    local schema = Config.WasabiSchema.incidents
    return DojDB.Single(('SELECT * FROM %s WHERE %s = ? LIMIT 1'):format(schema.table, schema.id), { incidentId })
end

function DojIntegrations.MirrorEvidence(evidence)
    if not Config.Integrations.wasabi.mirrorEvidence then
        return
    end

    callWasabiExport('CreateEvidence', {
        evidence_number = evidence.evidence_number,
        evidence_type = evidence.evidence_type,
        description = evidence.description,
        location_found = evidence.location_found,
        storage_location = evidence.storage_location,
        status = evidence.status,
        collected_by = evidence.collected_by,
        collected_by_name = evidence.collected_by_name,
        metadata = evidence.metadata
    })
end

function DojIntegrations.MirrorNote(payload)
    if not Config.Integrations.wasabi.mirrorNotes then return end
    callWasabiExport('CreateNote', payload)
end

function DojIntegrations.MirrorPhoto(payload)
    if not Config.Integrations.wasabi.mirrorPhotos then return end
    callWasabiExport('CreatePhoto', payload)
end

function DojIntegrations.GiveBill(identifier, amount, reason)
    local cfg = Config.Integrations.vms
    if not cfg.enabled or not cfg.useGiveBill or not hasResource(cfg.resource) then
        return false
    end

    local ok, err = pcall(function()
        exports[cfg.resource]:giveBill(identifier, amount, reason)
    end)

    if not ok then
        DojUtils.LogError('Integrations.vms.giveBill', err)
    end

    return ok
end

function DojIntegrations.GetOfficers()
    local officers = callWasabiExport('GetOfficers')
    return officers or {}
end
