function GetPositionInfrontOfElement(posX, posY, posZ, hed, distance)
    local meters = (type(distance) == "number" and distance) or 3
    posX = posX - math.sin(math.rad(hed)) * meters
    posY = posY + math.cos(math.rad(hed)) * meters
    hed = hed + math.cos(math.rad(hed))
    local vec = vector3(posX, posY, posZ)
    return vec
end

local PlantingProcess = false
local CurrentPlants = 0

-- MaxPlants Logic

RegisterNetEvent('bcc-farming:client:MaxPlantsAmount',function(Number)
    if Number == 1 then
        CurrentPlants = CurrentPlants +1
    elseif Number == -1 then
        CurrentPlants = CurrentPlants -1
    end
end)

---@param plantData table
---@param bestFertilizer table
RegisterNetEvent('bcc-farming:PlantingCrop', function(plantData, bestFertilizer)
    local seed = plantData.seedName
    local amount = plantData.seedAmount
    if CurrentPlants < Config.plantSetup.maxPlants then  -- MaxPlants Check
    local playerCoords = GetEntityCoords(PlayerPedId())
    local stop = false
    for e, a in pairs(Plants) do
        local entity = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, plantData.plantingDistance, joaat(a.plantProp), false, false, false)
        if entity ~= 0 then
            stop = true
            TriggerServerEvent("bcc-farming:GiveBackSeed",seed,amount)
            VORPcore.NotifyRightTip(_U("tooCloseToAnotherPlant"), 4000) break
        end
    end
    if not stop then
        if not PlantingProcess then
            PlantingProcess = true
        VORPcore.NotifyRightTip(_U("raking"), 16000)
        PlayAnim("amb_work@world_human_farmer_rake@male_a@idle_a", "idle_a", 16000, true, true)
        TriggerServerEvent("bcc-farming:PlantToolUsage",plantData)
        VORPcore.NotifyRightTip(_U("plantingDone"), 16000)
        if not IsEntityDead(PlayerPedId()) then
            local PromptGroup = BccUtils.Prompt:SetupPromptGroup()
            local firstprompt = PromptGroup:RegisterPrompt(_U("yes"), 0x4CC0E2FE, 1, 1, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"})
            local secondprompt = PromptGroup:RegisterPrompt(_U("no"), 0x9959A6F0, 1, 2, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"})
            while true do
                Wait(5)
                local newPlayerCoords = GetEntityCoords(PlayerPedId())
                if GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, newPlayerCoords.x, newPlayerCoords.y, newPlayerCoords.z, true) < 3 then
                    PromptGroup:ShowGroup(_U("fertilize"))
                    if firstprompt:HasCompleted() then
                        if bestFertilizer then
                            plantData.timeToGrow = plantData.timeToGrow - bestFertilizer.fertTimeReduction
                            TriggerServerEvent('bcc-farming:RemoveFertilizer', bestFertilizer.fertName)
                        else
                            VORPcore.NotifyRightTip(_U("noFert"), 4000)
                        end
                        break
                    end
                    if secondprompt:HasCompleted() then
                        break
                    end
                end
            end
            local entCoords = GetEntityCoords(PlayerPedId())
            local entRot = GetEntityHeading(PlayerPedId())
            local plantCoords = GetPositionInfrontOfElement(entCoords.x, entCoords.y, entCoords.z, entRot, 0.75)
            TriggerServerEvent('bcc-farming:AddPlant', plantData, plantCoords)
            TriggerEvent('bcc-farming:client:MaxPlantsAmount',1)
            PlantingProcess = false
        else
            TriggerServerEvent("bcc-farming:GiveBackSeed",seed,amount)
            VORPcore.NotifyRightTip(_U("failed"), 4000)
        end
        else
            VORPcore.NotifyRightTip(_U("FinishPlantingProcessFirst"), 4000)
        end
    end
    elseif CurrentPlants == Config.plantSetup.maxPlants then
        TriggerServerEvent("bcc-farming:GiveBackSeed",seed,amount)
        VORPcore.NotifyRightTip(_U("maxPlantsReached"), 4000)
    end
end)