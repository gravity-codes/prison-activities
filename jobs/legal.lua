--[[
    This script runs the "good" side of the prison jobs
    Inmates interact with the guard in front of the window and recieves a task. these tasks reduce the time
    Timeoff = 2 minutes for each cell clean job
        2 minutes for a correct lunch -1 for each they get wrong
    The jobs can be done once per jail sentence
]]

-- Enums
local jobs = {
    NONE = 0,
    MEAL_GATHER = 1,
    GUARD_LUNCHES = 2,
    CELL_CLEANUP = 3
}

local lunch_drinks = {"water", "juice", "soda", "milk"}
local lunch_sandwiches = {"ham_cheese", "pbj", "turkey_swiss", "bologna"}
local lunch_snacks = {"pretzels", "fruit_cup", "cookies", "chips"}

--=================== Value tracking =================================
local currentJob = 0

-- Inmate round up
local inmatesTold = 0

-- Cell cleaning
local timesFailedToilet = 0
local cellsCleaned = 0
local completedCells = {}
local completedCellParts = {}

-- Guard lunches
local guardLunchCount = 0
local guardLunchFailedCount = 0
local currentLunchGuard = 0
local currentLunchMeal = {}
local lunchMealGoal = {}
local guardsComplete = {}

-- Conditionals
local isGuardSpawned = false
local isOnJob = false
local lunchDoneThisSentence = false
local bathroomsDoneThisSentence = false

-- Objects
local guardPed
local guardLunchPeds = {}

exports['rz-interact']:AddPeekEntryByPolyTarget("guard_interact", {{
    event = "rz-jail:finishjob",
    id = "guard_interactfinishjob",
    icon = "flag-checkered",
    label = "Finish the job"
}}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and isOnJob end})

RegisterNetEvent("rz-jail:finishjob", function()
    if currentJob == jobs.MEAL_GATHER then
        -- Handle ending the meal gather job
        TriggerEvent("ShortText", "Ended prisoner gathering job.", 2)
    elseif currentJob == jobs.GUARD_LUNCHES then
        local timeoff = (2 * guardLunchCount) - guardLunchFailedCount
        if timeoff > 0 then
            TriggerEvent("LongText", "Let's see... so you got lunch for " .. guardLunchCount .. " guards. But it looks like you got the wrong lunch " .. guardLunchFailedCount .. " times. I guess I can give you " .. timeoff .. " months off for the effort.", 1)
            TriggerNetEvent('rz-jail:SetupTimeOff', timeoff)
            lunchDoneThisSentence = true
        end
    elseif currentJob == jobs.CELL_CLEANUP then
        local timeoff = cellsCleaned
        if timeoff > 0 then
            TriggerEvent("LongText", "Alright, looks like you got to ".. cellsCleaned .. " cells. I guess I can give " .. timeoff .. " months off your time. Move along.", 1)
            TriggerNetEvent('rz-jail:SetupTimeOff', timeoff)
            bathroomsDoneThisSentence = true
        end
    end

    isOnJob = false
    job = jobs.NONE
end)

--================= Prisoner Meal Roundup Job =========================
--[[ shit dont work and i dont care enough to get it going
    exports['rz-interact']:AddPeekEntryByPolyTarget("guard_interact", {{
    event = "rz-jail:mealgather",
    id = "guard_interactmealjob",
    icon = "people-arrows",
    label = "Job: Round up the inmates for meal time"
}}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and not isOnJob end})]]

RegisterNetEvent("rz-jail:mealgather", function()
    isOnJob = true
    currentJob = jobs.MEAL_GATHER
end)

exports['rz-interact']:AddPeekEntryByModel(GetHashKey(config.other_prisoners1), {{
    event = "rz-jail:inmatemeal",
    id = "guard_interactmealprisoner",
    icon = "user-plus",
    label = "Tell about meal time"
}}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.MEAL_GATHER end})

exports['rz-interact']:AddPeekEntryByModel(GetHashKey(config.other_prisoners2), {{
    event = "rz-jail:inmatemeal",
    id = "guard_interactmealprisoner",
    icon = "user-plus",
    label = "Tell about meal time"
}}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.MEAL_GATHER end})

RegisterNetEvent("rz-jail:inmatemeal", function()
    inmatesTold = inmatesTold + 1

    local walkCoords = config.coords.cafeteria_walk
    local coords = GetEntityCoords(PlayerPedId())
    local interactPed = GetClosestPed(coords.x, coords.y, coords.z, 3.5, 0, 0, 0, 0, -1)
    ClearPedTasks(interactPed)
    TaskGoToCoordAnyMeans(interactPed, walkCoords.x, walkCoords.y, walkCoords.z, 1.0, 0, 0, GetHashKey('MOVE_M@TOUGH_GUY@'), 0)
end)

--==================== Getting Guard's Lunches Job ====================
exports['rz-interact']:AddPeekEntryByPolyTarget("guard_interact", {{
    event = "rz-jail:guardlunches",
    id = "guard_interactguardmeals",
    icon = "clipboard-list",
    label = "Job: Get lunch for the guards"
}}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and not isOnJob and not lunchDoneThisSentence end})

RegisterNetEvent("rz-jail:guardlunches", function()
    isOnJob = true
    currentJob = jobs.GUARD_LUNCHES
    TriggerEvent("ShortText", "Go around the yard and collect orders.", 1)

    local numSpawned = 0
    for i = 1, 16, 1 do
        if numSpawned == 10 then
            break
        end
        local rand = math.random(10)
        if rand <= 4 then
            SpawnOtherGuard(i)
            numSpawned = numSpawned + 1
        end
    end
end)

RegisterNetEvent("rz-jail:AskGuardLunch", function(params)
    local index = params.index
    currentLunchGuard = index

    lunchMealGoal = CreateGuardLunch()
    TriggerEvent("LongText", "Alright prisoner I want a " .. GetLunchPretty(lunchMealGoal['sandwich']) .. ', a ' .. GetLunchPretty(lunchMealGoal['snack']) .. ', and a ' .. GetLunchPretty(lunchMealGoal['drink']) .. '.', 1)
end)

RegisterNetEvent("rz-jail:RepeatLunch", function(params)
    local index = params.index
    TriggerEvent("LongText", "Cant you listen?! I said I want a " .. GetLunchPretty(lunchMealGoal['sandwich']) .. ', a ' .. GetLunchPretty(lunchMealGoal['snack']) .. ', and a ' .. GetLunchPretty(lunchMealGoal['drink']) .. '.', 1)
end)

RegisterNetEvent("rz-jail:CompleteLunch", function(params)
    local index = params.index
    if currentLunchMeal['sandwich'] == lunchMealGoal['sandwich'] and currentLunchMeal['snack'] == lunchMealGoal['snack'] and currentLunchMeal['drink'] == lunchMealGoal['drink'] then
        table.insert(guardsComplete, index)
        guardLunchCount = guardLunchCount + 1
        currentLunchGuard = 0
        currentLunchMeal = {}
        lunchMealGoal = {}

        FreezeEntityPosition(guardLunchPeds[index], false)
        SetEntityAsNoLongerNeeded(guardLunchPeds[index])

        TriggerEvent("ShortText", "Lunch complete. That's " .. guardLunchCount .. " lunches delivered.", 2)
    else
        TriggerEvent("ShortText", "That is wrong. Go back to the cafeteria and try again.", 3)
        guardLunchFailedCount = guardLunchFailedCount + 1
    end
end)

RegisterNetEvent("rz-jail:GrabDrink", function(params)
    local drink = params.drink
    if currentLunchMeal['drink'] == nil then
        TriggerEvent("ShortText", "Grabbed a " .. GetLunchPretty(drink), 1)
    else
        TriggerEvent("ShortText", "Put back the " .. GetLunchPretty(currentLunchMeal['drink']) .. ' and grabbed a ' .. GetLunchPretty(drink) .. '.')
    end
    
    currentLunchMeal['drink'] = drink
end)

RegisterNetEvent("rz-jail:GrabSandwich", function(params)
    local sandwich = params.sandwich
    if currentLunchMeal['sandwich'] == nil then
        TriggerEvent("ShortText", "Grabbed a " .. GetLunchPretty(sandwich), 1)
    else
        TriggerEvent("ShortText", "Put back the " .. GetLunchPretty(currentLunchMeal['sandwich']) .. ' and grabbed a ' .. GetLunchPretty(sandwich) .. '.')
    end
    currentLunchMeal['sandwich'] = sandwich
end)

RegisterNetEvent("rz-jail:GrabSnack", function(params)
    local snack = params.snack
    if currentLunchMeal['snack'] == nil then
        TriggerEvent("ShortText", "Grabbed a " .. GetLunchPretty(snack), 1)
    else
        TriggerEvent("ShortText", "Put back the " .. GetLunchPretty(currentLunchMeal['snack']) .. ' and grabbed a ' .. GetLunchPretty(snack) .. '.')
    end
    currentLunchMeal['snack'] = snack
end)

exports["rz-interact"]:AddPeekEntryByPolyTarget("prison_fridge", {{
        event = "rz-jail:GrabDrink",
        id = "guardlunch_drink_water",
        icon = "hand-holding-water",
        label = "Grab a water",
        parameters = {drink = "water"}
    }}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("prison_fridge", {{
    event = "rz-jail:GrabDrink",
    id = "guardlunch_drink_juice",
    icon = "hand-holding-water",
    label = "Grab a juice box",
    parameters = {drink = "juice"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("prison_fridge", {{
    event = "rz-jail:GrabDrink",
    id = "guardlunch_drink_soda",
    icon = "glass-whiskey",
    label = "Grab a soda",
    parameters = {drink = "soda"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("prison_fridge", {{
    event = "rz-jail:GrabDrink",
    id = "guardlunch_drink_milk",
    icon = "shopping-bag",
    label = "Grab a milk",
    parameters = {drink = "milk"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("sandwich_table", {{
    event = "rz-jail:GrabSandwich",
    id = "guardlunch_sandwich_hamcheese",
    icon = "bread-slice",
    label = "Grab a ham & cheese sandwhich",
    parameters = {sandwich = "ham_cheese"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("sandwich_table", {{
    event = "rz-jail:GrabSandwich",
    id = "guardlunch_sandwich_pbj",
    icon = "bread-slice",
    label = "Grab a peanut butter & jelly sandwich",
    parameters = {sandwich = "pbj"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("sandwich_table", {{
    event = "rz-jail:GrabSandwich",
    id = "guardlunch_sandwich_turkswiss",
    icon = "bread-slice",
    label = "Grab a turkey and swiss sandwich",
    parameters = {sandwich = "turkey_swiss"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("sandwich_table", {{
    event = "rz-jail:GrabSandwich",
    id = "guardlunch_sandwich_bologna",
    icon = "bread-slice",
    label = "Grab a bologna sandwich",
    parameters = {sandwich = "bologna"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("snack_shelf", {{
    event = "rz-jail:GrabSnack",
    id = "guardlunch_snack_pretzels",
    icon = "hand-rock",
    label = "Grab a bag of pretzels",
    parameters = {snack = "pretzels"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("snack_shelf", {{
    event = "rz-jail:GrabSnack",
    id = "guardlunch_snack_fruitcup",
    icon = "hand-rock",
    label = "Grab a fruit cup",
    parameters = {snack = "fruit_cup"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("snack_shelf", {{
    event = "rz-jail:GrabSnack",
    id = "guardlunch_snack_cookies",
    icon = "cookie-bite",
    label = "Grab some cookies",
    parameters = {snack = "cookies"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

exports["rz-interact"]:AddPeekEntryByPolyTarget("snack_shelf", {{
    event = "rz-jail:GrabSnack",
    id = "guardlunch_snack_chips",
    icon = "hand-rock",
    label = "Grab a bag of chips",
    parameters = {snack = "chips"}
}}, {distance = {radius = 2}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES end})

--=================== Cleaning Cells Job ==============================
exports['rz-interact']:AddPeekEntryByPolyTarget("guard_interact", {{
    event = "rz-jail:cellcleanup",
    id = "guard_interactcleaningjob",
    icon = "toilet",
    label = "Job: Clean up the cells"
}}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and not isOnJob and not bathroomsDoneThisSentence end})

RegisterNetEvent("rz-jail:cellcleanup", function()
    isOnJob = true
    currentJob = jobs.CELL_CLEANUP

    TriggerEvent("ShortText", "Head to the cells and start cleanin!", 1)
end)

-- Loop through all the cell zones and add the appropriate interact
for i = 1, 27, 1 do
    exports["rz-interact"]:AddPeekEntryByPolyTarget('cell' .. i, {{
        event = "rz-jail:CleanFloor",
        id = "cell" .. i .. "_cleanfloor",
        icon = "broom",
        label = "Sweep the floor",
        parameters = {cell = i}
    }}, {distance = {radius = 3.5}, isEnabled = function() return isOnJob and currentJob == jobs.CELL_CLEANUP and not TableHasValue(completedCells, "cell" .. i) and not TableHasValue(completedCellParts, "cell" .. i) end})

    exports["rz-interact"]:AddPeekEntryByPolyTarget('cell' .. i .. "_bed", {{
        event = "rz-jail:MakeBed",
        id = "cell" .. i .. "_makebed",
        icon = "bed",
        label = "Make the bed",
        parameters = {cell = i}
    }}, {distance = {radius = 1.5}, isEnabled = function() return isOnJob and currentJob == jobs.CELL_CLEANUP and not TableHasValue(completedCells, "cell" .. i) and not TableHasValue(completedCellParts, "cell" .. i .. "_bed") end})

    exports["rz-interact"]:AddPeekEntryByPolyTarget('cell' .. i .. "_toilet", {{
        event = "rz-jail:CleanToilet",
        id = "cell" .. i .. "_cleantoilet",
        icon = "toilet-paper",
        label = "Scrub the toilet",
        parameters = {cell = i}
    }}, {distance = {radius = 2.0}, isEnabled = function() return isOnJob and currentJob == jobs.CELL_CLEANUP and not TableHasValue(completedCells, "cell" .. i) and not TableHasValue(completedCellParts, "cell" .. i .. "_toilet") end})
end 

RegisterNetEvent("rz-jail:CleanFloor", function(params)
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_JANITOR", 0, true)
    exports["rz-taskbar"]:TaskBar("Sweeping the floor", 4000)
    ClearPedTasks(PlayerPedId())
    TriggerEvent("ShortText", "Floor of Cell " .. params.cell .. " cleaned.", 2)
    table.insert(completedCellParts, "cell" .. params.cell)

    if TableHasValue(completedCellParts, "cell" .. params.cell) and TableHasValue(completedCellParts, "cell" .. params.cell .. "_bed") and TableHasValue(completedCellParts, "cell" .. params.cell .. "_toilet") then
        TriggerEvent("ShortText", "Cell " .. params.cell .. " is all done!", 2)
        cellsCleaned = cellsCleaned + 1
    end
end)

RegisterNetEvent("rz-jail:MakeBed", function(params)
    TaskAnimTimedNoCancel("mini@repair", "fixing_a_player", 16, 8.0, 2000)
    exports["rz-taskbar"]:TaskBar("Making the bed", 2000)
    TriggerEvent("ShortText", "Bed for Cell " .. params.cell .. " has been made.", 2)
    table.insert(completedCellParts, "cell" .. params.cell .. "_bed")

    if TableHasValue(completedCellParts, "cell" .. params.cell) and TableHasValue(completedCellParts, "cell" .. params.cell .. "_bed") and TableHasValue(completedCellParts, "cell" .. params.cell .. "_toilet") then
        TriggerEvent("ShortText", "Cell " .. params.cell .. " is all done!", 2)
        cellsCleaned = cellsCleaned + 1
    end
end)

RegisterNetEvent("rz-jail:CleanToilet", function(params)
    TaskStartScenarioInPlace(PlayerPedId(), "CODE_HUMAN_MEDIC_KNEEL", 0, false)
    exports["rz-taskbar"]:TaskBar("Cleaning the toilet", 1000)
    
    if AttemptCleanToilet() then
        TriggerEvent("ShortText", "Cell " .. params.cell .. " toilet has been cleaned.", 2)
        table.insert(completedCellParts, "cell" .. params.cell .. "_toilet")
        if TableHasValue(completedCellParts, "cell" .. params.cell) and TableHasValue(completedCellParts, "cell" .. params.cell .. "_bed") and TableHasValue(completedCellParts, "cell" .. params.cell .. "_toilet") then
            table.insert(completedCells, "cell" .. params.cell)
            cellsCleaned = cellsCleaned + 1
            TriggerEvent("ShortText", "Cell " .. params.cell .. " is all done! Cells cleaned: " .. cellsCleaned, 2)
        end
    else
        TriggerEvent("ShortText", "Toilet failed! Try again!", 3)
    end
    
    ClearPedTasks(PlayerPedId())
end)

--================ Spawn the guard in the courtyard ====================
-- Zone to spawn the job guard
exports['rz-polyzone']:AddBoxZone("guard_spawn", vector3(config.coords.guard_spawn.x, config.coords.guard_spawn.y, config.coords.guard_spawn.z), 70, 70, {
        name = "guard_spawn",
        heading = 300,
        debugPoly = false,
        minZ = config.coords.guard_spawn.z - 1.0,
        maxZ = config.coords.guard_spawn.z  + 5,
})

exports["rz-polytarget"]:AddBoxZone("guard_interact", vector3(config.coords.guard_spawn.x, config.coords.guard_spawn.y, config.coords.guard_spawn.z), 1, 1, {
        name = "guard_interact",
        heading = 183.81,
        debugPoly = false,
        minZ = config.coords.guard_spawn.z - 1.0,
        maxZ = config.coords.guard_spawn.z + 2
})

-- Event to handle the enter
RegisterNetEvent("rz-polyzone:enter", function(zone)
    if zone == "guard_spawn" then
        if not DoesEntityExist(guardPed) then
            SpawnGuard()
        end
    end
end)

--=================== Helper functions ================================
function MakePlayerSick(_duration)
    SetPedIsDrunk(PlayerPedId(), true)
    DoScreenFadeIn(1000)
    ShakeGameplayCam("DRUNK_SHAKE", 3.0)
    SetPedMotionBlur(PlayerPedId(), true)
    SetPedConfigFlag(PlayerPedId(), 100, true)

    -- Lasts for <duration> seconds long
    TaskAnimTimedNoCancel('oddjobs@taxi@tie', 'vomit_outside', 48, 1.0, _duration * 1000)
    Wait(_duration * 1000)

    SetPedIsDrunk(PlayerPedId(), false)
    SetPedMotionBlur(PlayerPedId(), false)
    SetPedConfigFlag(PlayerPedId(), 100, false)
    StopGameplayCamShaking(true)
end

function AttemptCleanToilet()
    -- 
    local randLoops = math.random(4)
    local attempt = SkillCircleLooped(randLoops)

    if attempt then
        -- Player cleans the toilet
        timesFailedToilet = 0
        return true
    else
        --Make the player sick before returning
        timesFailedToilet = timesFailedToilet + 1
        MakePlayerSick(timesFailedToilet * 2)
        return false
    end
end

function SpawnGuard()
    RequestModel(GetHashKey(config.guard_model))
    while not HasModelLoaded(GetHashKey(config.guard_model)) do
        Wait(1)
    end
    ClearAreaOfPeds(config.coords.guard_spawn.x, config.coords.guard_spawn.y, config.coords.guard_spawn.z, 1.0, 1)
    guardPed = CreatePed(28, GetHashKey(config.guard_model), config.coords.guard_spawn.x, config.coords.guard_spawn.y, config.coords.guard_spawn.z, config.coords.guard_spawn.h, false, false)
    SetEntityAsMissionEntity(guardPed, true, true)
    ClearPedSecondaryTask(guardPed)
    FreezeEntityPosition(guardPed, true)
    TaskStartScenarioInPlace(guardPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    SetEntityInvincible(guardPed, true)
    SetPedCanRagdollFromPlayerImpact(guardPed, false)
    PlaceObjectOnGroundProperly(guardPed)
    SetPedFleeAttributes(guardPed, 0, 0)
    SetBlockingOfNonTemporaryEvents(guardPed, true)
    SetPedCombatAttributes(guardPed, 17, 1)
end

function SpawnOtherGuard(_index)
    local guardCoords = config.coords.guard_spawns[_index]

    RequestModel(GetHashKey(config.other_guards))
    while not HasModelLoaded(GetHashKey(config.other_guards)) do
        Wait(1)
    end
    ClearAreaOfPeds(guardCoords.x, guardCoords.y, guardCoords.z, 1.0, 1)
    guardLunchPeds[_index] = CreatePed(28, GetHashKey(config.other_guards), guardCoords.x, guardCoords.y, guardCoords.z, guardCoords.h, false, false)
    SetEntityAsMissionEntity(guardLunchPeds[_index], true, true)
    ClearPedSecondaryTask(guardLunchPeds[_index])
    FreezeEntityPosition(guardLunchPeds[_index], true)
    TaskStartScenarioInPlace(guardLunchPeds[_index], 'WORLD_HUMAN_GUARD_STAND', 0, true)
    SetEntityInvincible(guardLunchPeds[_index], true)
    SetPedCanRagdollFromPlayerImpact(guardLunchPeds[_index], false)
    PlaceObjectOnGroundProperly(guardLunchPeds[_index])
    SetPedFleeAttributes(guardLunchPeds[_index], 0, 0)
    SetBlockingOfNonTemporaryEvents(guardLunchPeds[_index], true)
    SetPedCombatAttributes(guardLunchPeds[_index], 17, 1)

    exports['rz-polytarget']:AddBoxZone('guard_lunch' .. _index, vector3(guardCoords.x, guardCoords.y, guardCoords.z), 1, 1, {
        name = 'guard_lunch' .. _index,
        debugPoly = false,
        heading = guardCoords.h,
        minZ = guardCoords.z - 1,
        maxZ = guardCoords.z + 2
    })

    exports['rz-interact']:AddPeekEntryByPolyTarget('guard_lunch' .. _index, {{
        id = "lunch_interact" .. _index,
        event = "rz-jail:AskGuardLunch",
        icon = "microphone-alt",
        label = "What would you like for lunch?",
        parameters = {index = _index}
    }}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES and currentLunchGuard == 0 and not TableHasValue(guardsComplete, _index) end})

    exports['rz-interact']:AddPeekEntryByPolyTarget('guard_lunch' .. _index, {{
        id = "guard_lunch_repeat" .. _index,
        event = "rz-jail:RepeatLunch",
        icon = "microphone-alt",
        label = "Repeat the order",
        parameters = {index = _index}
    }}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES and _index == currentLunchGuard and not TableHasValue(guardsComplete, _index) end})

    exports['rz-interact']:AddPeekEntryByPolyTarget('guard_lunch' .. _index, {{
        id = "guard_lunch_complete" .. _index,
        event = "rz-jail:CompleteLunch",
        icon = "hands-helping",
        label = "Hand in the order",
        parameters = {index = _index}
    }}, {distance = {radius = 3.5}, isEnabled = function() return InJail() and isOnJob and currentJob == jobs.GUARD_LUNCHES and _index == currentLunchGuard and not TableHasValue(guardsComplete, _index) end})
end

function CreateGuardLunch()
    local newLunch = {}
    newLunch['sandwich'] = lunch_sandwiches[math.random(4)]
    newLunch['snack'] = lunch_snacks[math.random(4)]
    newLunch['drink'] = lunch_drinks[math.random(4)]
    return newLunch
end

function GetLunchPretty(_item)
    if _item == 'water' then
        return 'Bottle of Water'
    elseif _item == 'juice' then
        return 'Juice Box'
    elseif _item == 'soda' then
        return 'Can of Soda'
    elseif _item == 'milk' then
        return 'Bag of Milk'
    elseif _item == 'ham_cheese' then
        return 'Ham & Cheese Sandwich'
    elseif _item == 'pbj' then
        return 'Peanut Butter & Jelly Sandwich'
    elseif _item == 'turkey_swiss' then
        return 'Turkey and Swiss Sandwich'
    elseif _item == 'bologna' then
        return 'Bologna Sandwich'
    elseif _item == 'pretzels' then
        return 'Bag of Pretzels'
    elseif _item == 'fruit_cup' then
        return 'Fruit Cup'
    elseif _item == 'cookies' then
        return 'Pack of Cookies'
    elseif _item == 'chips' then
        return 'Bag of Chips'
    end
end

function IsOnJob()
    return isOnJob
end

exports("IsOnPrisonJob", IsOnJob)

RegisterNetEvent('rz-jail:ResetJailJobs', function()
    currentJob = 0

    -- Inmate round up
    inmatesTold = 0

    -- Cell cleaning
    timesFailedToilet = 0
    cellsCleaned = 0
    completedCells = {}
    completedCellParts = {}

    -- Guard lunches
    guardLunchCount = 0
    guardLunchFailedCount = 0
    currentLunchGuard = 0
    currentLunchMeal = {}
    lunchMealGoal = {}
    guardsComplete = {}

    -- Conditionals
    isOnJob = false
    lunchDoneThisSentence = false
    bathroomsDoneThisSentence = false
end)

function TableHasValue(_table, _value)
    for _,value in ipairs(_table) do
        if value == _value then
            return true
        end
    end
end