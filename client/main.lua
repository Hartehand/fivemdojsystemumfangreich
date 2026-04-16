local ESX = exports['es_extended']:getSharedObject()

local function nuiMessage(action, payload)
    SendNUIMessage({ action = action, payload = payload })
end

local function closeTablet()
    if not DojTablet.isOpen then
        return
    end

    DojTablet.isOpen = false
    SetNuiFocus(false, false)
    nuiMessage('close', {})
    DojTablet.Detach()
end

local function openTablet()
    if DojTablet.isOpen then
        return
    end

    ESX.TriggerServerCallback('doj_casehub:bootstrap', function(response)
        if not response or not response.ok then
            return
        end

        if not DojTablet.Attach() then
            return
        end

        DojTablet.isOpen = true
        SetNuiFocus(true, true)
        nuiMessage('open', response.data)
    end)
end

local function callServer(name, data, cb)
    ESX.TriggerServerCallback(name, function(response)
        cb(response or { ok = false, error = 'no_response' })
    end, data)
end

RegisterCommand(Config.Command, function()
    if DojTablet.isOpen then
        closeTablet()
    else
        openTablet()
    end
end)

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb({ ok = true })
end)


RegisterNUICallback('bootstrap', function(data, cb)
    callServer('doj_casehub:bootstrap', data, cb)
end)
RegisterNUICallback('search', function(data, cb)
    callServer('doj_casehub:search', data, cb)
end)


RegisterNUICallback('getCaseDetails', function(data, cb)
    callServer('doj_casehub:getCaseDetails', data, cb)
end)

RegisterNUICallback('updateTaskStatus', function(data, cb)
    callServer('doj_casehub:updateTaskStatus', data, cb)
end)

RegisterNUICallback('listHearings', function(data, cb)
    callServer('doj_casehub:listHearings', data, cb)
end)

RegisterNUICallback('updateHearing', function(data, cb)
    callServer('doj_casehub:updateHearing', data, cb)
end)

RegisterNUICallback('listDocuments', function(data, cb)
    callServer('doj_casehub:listDocuments', data, cb)
end)
RegisterNUICallback('getCases', function(data, cb)
    callServer('doj_casehub:getCases', data, cb)
end)

RegisterNUICallback('createCase', function(data, cb)
    callServer('doj_casehub:createCase', data, cb)
end)

RegisterNUICallback('updateCase', function(data, cb)
    callServer('doj_casehub:updateCase', data, cb)
end)

RegisterNUICallback('linkEntity', function(data, cb)
    callServer('doj_casehub:linkEntity', data, cb)
end)

RegisterNUICallback('createTask', function(data, cb)
    callServer('doj_casehub:createTask', data, cb)
end)

RegisterNUICallback('saveFilter', function(data, cb)
    callServer('doj_casehub:saveFilter', data, cb)
end)

RegisterNUICallback('getCalendar', function(data, cb)
    callServer('doj_casehub:getCalendar', data, cb)
end)

RegisterNUICallback('createHearing', function(data, cb)
    callServer('doj_casehub:createHearing', data, cb)
end)

RegisterNUICallback('createEvidence', function(data, cb)
    callServer('doj_casehub:createEvidence', data, cb)
end)

RegisterNUICallback('transferEvidence', function(data, cb)
    callServer('doj_casehub:transferEvidence', data, cb)
end)

RegisterNUICallback('verifyEvidenceChain', function(data, cb)
    callServer('doj_casehub:verifyEvidenceChain', data, cb)
end)

RegisterNUICallback('createDocument', function(data, cb)
    callServer('doj_casehub:createDocument', data, cb)
end)

RegisterNUICallback('finalizeDocument', function(data, cb)
    callServer('doj_casehub:finalizeDocument', data, cb)
end)

RegisterNUICallback('createNote', function(data, cb)
    callServer('doj_casehub:createNote', data, cb)
end)

RegisterNUICallback('getTimeline', function(data, cb)
    callServer('doj_casehub:getTimeline', data, cb)
end)


RegisterNUICallback('sealCase', function(data, cb)
    callServer('doj_casehub:sealCase', data, cb)
end)

RegisterNUICallback('unsealCase', function(data, cb)
    callServer('doj_casehub:unsealCase', data, cb)
end)

RegisterNUICallback('signDocument', function(data, cb)
    callServer('doj_casehub:signDocument', data, cb)
end)

RegisterNUICallback('updateDocumentContent', function(data, cb)
    callServer('doj_casehub:updateDocumentContent', data, cb)
end)

RegisterNUICallback('exportCase', function(data, cb)
    callServer('doj_casehub:exportCase', data, cb)
end)


RegisterNUICallback('saveTemplate', function(data, cb)
    callServer('doj_casehub:saveTemplate', data, cb)
end)

RegisterNUICallback('verifySignature', function(data, cb)
    callServer('doj_casehub:verifySignature', data, cb)
end)
RegisterNUICallback('listTemplates', function(data, cb)
    callServer('doj_casehub:listTemplates', data, cb)
end)
AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        closeTablet()
    end
end)
