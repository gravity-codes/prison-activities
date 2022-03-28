Citizen.CreateThread(function()
  exports['rz-polytarget']:AddBoxZone("prison_slushy_machine", vector3(1777.6, 2560.06, 46.3), 0.6, 0.6, {
    heading = 0,
    minZ = 45.6,
    maxZ = 46.7
  })

  --====================== Slushies ================================
  exports['rz-interact']:AddPeekEntryByPolyTarget('prison_slushy_machine', {{
    id = "prison_slushy_green",
    event = "rz-jail:MakeSlushy",
    icon = "glass-whiskey",
    label = "Make a Green Slushy",
    parameters = {flavor = 'green'}
  }}, {distance = {radius = 2.0}})

  exports['rz-interact']:AddPeekEntryByPolyTarget('prison_slushy_machine', {{
    id = "prison_slushy_red",
    event = "rz-jail:MakeSlushy",
    icon = "glass-whiskey",
    label = "Make a Red Slushy",
    parameters = {flavor = 'red'}
  }}, {distance = {radius = 2.0}})

  exports['rz-interact']:AddPeekEntryByPolyTarget('prison_slushy_machine', {{
    id = "prison_slushy_yellow",
    event = "rz-jail:MakeSlushy",
    icon = "glass-whiskey",
    label = "Make a Yellow Slushy",
    parameters = {flavor = 'yellow'}
  }}, {distance = {radius = 2.0}})

  exports['rz-interact']:AddPeekEntryByPolyTarget('prison_slushy_machine', {{
    id = "prison_slushy_blue",
    event = "rz-jail:MakeSlushy",
    icon = "glass-whiskey",
    label = "Make a Blue Slushy",
    parameters = {flavor = 'blue'}
  }}, {distance = {radius = 2.0}})

  exports['rz-interact']:AddPeekEntryByPolyTarget('prison_slushy_machine', {{
    id = "prison_slushy_special",
    event = "rz-jail:MakeSlushy",
    icon = "glass-whiskey",
    label = "Make a Special Slushy",
    parameters = {flavor = 'special'}
  }}, {distance = {radius = 2.0}})
)

RegisterNetEvent('rz-jail:MakeSlushy', function(params)
  local flavor = params.flavor
  if flavor == 'red' then
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GUARD_STAND", 0, false)
    exports['rz-taskbar']:TaskBar("Making a slushy", 5000)
    ClearPedTasks(PlayerPedId())
    exports["rz-inventory"]:AddItem("red_slushy", 1)
  end
  
  if flavor == 'blue' then
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GUARD_STAND", 0, false)
    exports['rz-taskbar']:TaskBar("Making a slushy", 5000)
    ClearPedTasks(PlayerPedId())
    exports["rz-inventory"]:AddItem("blue_slushy", 1)
  end
  
  if flavor == 'yellow' then
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GUARD_STAND", 0, false)
    exports['rz-taskbar']:TaskBar("Making a slushy", 10000)
    ClearPedTasks(PlayerPedId())
    exports["rz-inventory"]:AddItem("yellow_slushy", 1)
  end
  
  if flavor == 'green' then
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GUARD_STAND", 0, false)
    exports['rz-taskbar']:TaskBar("Making a slushy", 15000)
    ClearPedTasks(PlayerPedId())
    exports["rz-inventory"]:AddItem("green_slushy", 1)
  end
  
  if flavor == 'special' then
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GUARD_STAND", 0, false)
    exports['rz-taskbar']:TaskBar("Making a slushy", 30000)
    ClearPedTasks(PlayerPedId())
    exports["rz-inventory"]:AddItem("multi_slushy", 1)
  end
end)