DojTablet = {
    isOpen = false,
    propEntity = nil
}

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then
            return false
        end
        Wait(0)
    end

    return true
end

local function loadModel(modelHash)
    if HasModelLoaded(modelHash) then
        return true
    end

    RequestModel(modelHash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > timeout then
            return false
        end
        Wait(0)
    end

    return true
end

function DojTablet.Attach()
    local ped = PlayerPedId()
    if not loadAnimDict(Config.Tablet.animDict) then
        return false
    end

    TaskPlayAnim(ped, Config.Tablet.animDict, Config.Tablet.animName, 3.0, 3.0, -1, Config.Tablet.animFlag, 0.0, false, false, false)

    local modelHash = joaat(Config.Tablet.prop)
    if not loadModel(modelHash) then
        return false
    end

    local obj = CreateObject(modelHash, 0.0, 0.0, 0.0, true, true, false)
    if obj == 0 then
        return false
    end

    local o = Config.Tablet.offset
    local r = Config.Tablet.rotation
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, Config.Tablet.attachBone), o.x, o.y, o.z, r.x, r.y, r.z, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(modelHash)

    DojTablet.propEntity = obj
    return true
end

function DojTablet.Detach()
    local ped = PlayerPedId()
    ClearPedTasks(ped)

    if DojTablet.propEntity and DoesEntityExist(DojTablet.propEntity) then
        DeleteEntity(DojTablet.propEntity)
    end

    DojTablet.propEntity = nil
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    DojTablet.Detach()
    SetNuiFocus(false, false)
end)
