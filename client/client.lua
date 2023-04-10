-- Pulls vorp core, and utils for the notify
local VORPcore = {}
TriggerEvent("getCore", function(core)
    VORPcore = core
end)

--This is what handle the planting of the crop
RegisterNetEvent('bcc-farming:plantcrop') --Registers a client event for the server to trigger
AddEventHandler('bcc-farming:plantcrop', function(prop, reward, amount, timer, isoutsideoftown, type) --Makes the event have code to run and catches those 5 variables from the server
    ---------------------------PLANTING ANIMATION SETUP----------------------------------------------
    if isoutsideoftown == true then -- if variable is true (you are out of town or config = true then)
        if Config.Debug == false then --If debug in config is set to false then(if its true it skips the animation entirely)
            FreezeEntityPosition(PlayerPedId(), true) --freezes player
            TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_FARMER_RAKE'), 12000, true, false, false, false) --triggers anim
            VORPcore.NotifyRightTip(Config.Language.Raking,16000) --Prints on the players screen what is set in config.language table
            Wait(12000) --waits 12 seconds (until anim is over)
            ClearPedTasksImmediately(PlayerPedId()) --clears anims
	        Wait(500) --waits half a second
            VORPcore.NotifyRightTip(Config.Language.Weeding,16000) --Prints on the players screen what is set in config.language table
            TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_FARMER_WEEDING'), 9000, true, false, false, false) --triggers anim
            Wait(9000) --waits 9 seconds(until anim is over)
            ClearPedTasksImmediately(PlayerPedId()) --clears anim
            FreezeEntityPosition(PlayerPedId(), false) --unfreezes player
            VORPcore.NotifyRightTip(Config.Language.PlantFinished,16000) --Prints on the players screen what is set in config.language table
        end
        -----------------------------CROP SPAWN SETUP----------------------------------
        local plcoord = GetEntityCoords(PlayerPedId()) --gets player coords as soon as the plant is planted
        local object = CreateObject(prop, plcoord.x, plcoord.y, plcoord.z, true, true, false) --creates a networked object at the players coords
        Citizen.InvokeNative(0x9587913B9E772D29, object, true) --places entity on the ground properly
        local plantcoords = GetEntityCoords(object) --Gets the plants coordinates once the plant is planted
        TriggerServerEvent('bcc-farming:dbinsert', type, plantcoords, prop, timer, reward, amount, object) --this triggers the server event which inserts the plant into database and returns the database table too the client
    elseif isoutsideoftown == false then
        VORPcore.NotifyRightTip(Config.Language.Tooclosetotown, 4000)
    end
end)

--event is used to catch hasplants2 from server and trigger function
RegisterNetEvent('bcc-farming:plantcrop2')
AddEventHandler('bcc-farming:plantcrop2', function(plantcoords, timer, reward, amount, object, plantid) --catches all from server
    WaterPlant(plantcoords, timer, reward, amount, object, plantid) --passes all to function
end)

--TODO still sometimes takes double input on prompt groups, but once pressed 2nd time no issue no double remove or anything so not really a big issue

--database testing

--This will be used to spawn the plants the player has planted in the database--
--This is used to run the server event for loading the plants after the char has been chosen(if ran before char is chosen it wont work as the db query requires charid)
RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    TriggerServerEvent('bcc-farming:loadplants') --triggers the server event to get the stuff from database
end)

--This is used to spawn the plants in
RegisterNetEvent('bcc-farming:clientspawnplantsinitload')
AddEventHandler('bcc-farming:clientspawnplantsinitload', function(HasPlants) --catches var from server
    for k, v in pairs(HasPlants) do --opens up the table
        local notwateredtimer --var used to store the timer if not watered
        local notwateredreward
        local notwateredamount
        for e, a in pairs(Config.Farming) do --creates for loop
            if a.Type == v['planttype'] then --if a.type = HasPlants type in db then
                notwateredtimer = a.TimetoGrow
                notwateredreward = a.HarvestItem
                notwateredamount = a.HarvestAmount
            end
        end
        if v['watered'] == 'true' then --checks if the row/plant has been watered and if so then
            local object = CreateObject(v['prop'], tonumber(v['x']), tonumber(v['y']), tonumber(v['z']), true, true, false) --creates a networked object at the players coords (no need to minus 1 the  z as we did it when placing the plant to begin with)
            Citizen.InvokeNative(0x9587913B9E772D29, object, true) --places entity on the ground properly
            local plantcoords = GetEntityCoords(object)
            TriggerEvent('bcc-farming:DbAfterLoadManageHarvest', v['timeleft'], plantcoords, v['plantid'], v['planttype'], object)
        else --else if it has not been watered then
            local object = CreateObject(v['prop'], tonumber(v['x']), tonumber(v['y']), tonumber(v['z']), true, true, false) --creates a networked object at the players coords (no need to minus 1 the  z as we did it when placing the plant to begin with)
            Citizen.InvokeNative(0x9587913B9E772D29, object, true) --places entity on the ground properly
            local plantcoords = GetEntityCoords(object) --gets plants coords
            TriggerEvent('bcc-farming:DbAfterLoadManageWater', plantcoords, notwateredtimer, notwateredreward, notwateredamount, object, v['plantid']) --triggers the function for watering the plant
        end
    end
end)


--------------------------- Is Ped Currently In Water Check -------------------------------------------------
RegisterNetEvent('bcc-farming:PedInWaterClientCatch')
AddEventHandler('bcc-farming:PedInWaterClientCatch', function(_source)
    local inwater = IsEntityInWater(PlayerPedId()) --gets if the player is in water 1 if is false if not
    if inwater == 1 then --if you are in water then
        if Config.Debug == false then --if debug is false then
            FreezeEntityPosition(PlayerPedId(), true) --freezes player in place
            TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_CAMP_JACK_ES_BUCKET_FILL"), 7000, true, false, false, false) --triggers anim
            Wait(7000) --waits 7 seconds(until anim is over)
            ClearPedTasksImmediately(PlayerPedId()) --stops animation
            FreezeEntityPosition(PlayerPedId(), false) --unfreezes player
        end
        TriggerServerEvent('bcc-farming:RefillWateringCan', _source) --triggers server event to add the item(goes regardless of debug)
    elseif inwater == false then --elseif not in water then
        VORPcore.NotifyRightTip(Config.Language.Notinwater) --print not in water
    end
end)

----------------------- Distance Check for player to town coordinates --------------------------------
RegisterNetEvent('bcc-farming:IsPLayerNearTownCheck')
AddEventHandler('bcc-farming:IsPLayerNearTownCheck', function(_source, v)
    local isoutsideoftown = false --creates a variable used as a catch to see if your in a town
    if Config.Plantintowns == true then --if the config value is set to true (allowed to plant in town then)
        isoutsideoftown = true --sets variable to true to allow if statement to trigger server event
    elseif Config.Plantintowns == false then --elseif config is false then
        for k, e in pairs(Config.Towns) do --opens up the town table and creates a for loop
            local pl = GetEntityCoords(PlayerPedId()) --gets your coords once per loop run
            local dist = GetDistanceBetweenCoords(pl.x, pl.y, pl.z, e.coordinates.x, e.coordinates.y, e.coordinates.z, false) --gets the distance between you and the coord
            if Config.Debug == true then --if debug mode is true then
                print('Is  ' .. e.coordinates.x .. ' ' .. e.coordinates.y .. ' ' .. e.coordinates.z .. ' This far from those coords ' .. dist)
                print('is near  town')
            end
            if dist > e.range then --if dist is more htan 150 then
                isoutsideoftown = true --set to true
            elseif dist < e.range then --if its less then
                VORPcore.NotifyRightTip(Config.Language.Tooclosetotown, 4000)
                isoutsideoftown = false break --sets it too false and breaks the for loop
            end
        end
    end
    if isoutsideoftown == true then --after all the above code runs if outside of town = true then
        TriggerServerEvent('bcc-farming:PlayerNotNearTown', _source, v, isoutsideoftown) --trigger server event to continue planting
    end
end)

-- TODO Setup distance check between all plants and do not allow anyone to plant if they are near any crop they planted