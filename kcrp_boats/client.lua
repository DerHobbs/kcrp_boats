local keys = { ['O'] = 0xF1301666, ['S'] = 0xD27782E3, ['W'] = 0x8FD015D8, ['H'] = 0x24978A28, ['G'] = 0x5415BE48, ["ENTER"] = 0xC7B5340A, ['E'] = 0xDFF812F9 }
local BoatGroup = GetRandomIntInRange(0, 0xffffff)
local pressTime = 0
local pressLeft = 0
local OwnedBoats = {}
local near = 1000
local recentlySpawned = 0
local boatModel;
local boatSpawn = {}
local NumberboatSpawn = 0
local boating = false
local isAnchored = false
local stand = { x = 0, y = 0, z = 0 }

local _BoatPrompt
function BoatPrompt()
    Citizen.CreateThread(function()
        local str = "Öffnen"
        _BoatPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(_BoatPrompt, 0x760A9C6F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(_BoatPrompt, str)
        PromptSetEnabled(_BoatPrompt, true)
        PromptSetVisible(_BoatPrompt, true)
        PromptSetStandardMode(_BoatPrompt, true)
        PromptSetGroup(_BoatPrompt, BoatGroup)
        PromptRegisterEnd(_BoatPrompt)
        PromptSetPriority(_BoatPrompt , true)
    end)
end

TriggerEvent("menuapi:getData",function(call)
    MenuData = call
end)

--Config Boats Here
local boates = {
	[1] = {
		['Text'] = "Ruderboot",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Ruderboot",
			['Price'] = 89,
			['Model'] = "rowboat",
		}
	},
	[2] = {
		['Text'] = "Sumpf Ruderboot",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Sumpf Ruderboot",
			['Price'] = 89,
			['Model'] = "rowboatSwamp",
		}
	},
	[3] = {
		['Text'] = "Kanu",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Kanu",
			['Price'] = 29,
			['Model'] = "CANOE",
		}
	},
	[4] = {
		['Text'] = "Piroggen Boot",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Piroggen Boot",
			['Price'] = 45,
			['Model'] = "pirogue",
		}
	},
	[5] = {
		['Text'] = "Piroggen Boot 2",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Piroggen Boot 2",
			['Price'] = 49,
			['Model'] = "pirogue2",
		}
	},
	[6] = {
		['Text'] = "Baumstamm Kanu",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Baumstamm Kanu",
			['Price'] = 19,
			['Model'] = "CANOETREETRUNK",
		}
	},
	[7] = {
		['Text'] = "Dampfboot",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Dampfboot",
			['Price'] = 799,
			['Model'] = "KEELBOAT",
		}
	},
	[8] = {
		['Text'] = "Modernes Dampfschiff",
		['SubText'] = "",
		['Desc'] = "",
		['Param'] = {
			['Name'] = "Modernes Dampfschiff",
			['Price'] = 1199,
			['Model'] = "boatsteam02x",
		}
	}
}

Citizen.CreateThread(function()
	BoatPrompt()
	while true do
		Citizen.Wait(near)
		for i, zone in pairs(Config.Marker) do
			if GetDistanceBetweenCoords(zone.x, zone.y, zone.z, GetEntityCoords(PlayerPedId()), false) < 2 then
				stand = zone
				near = 5
				local BoatGroupName  = CreateVarString(10, 'LITERAL_STRING', "Bootshändler")
				PromptSetActiveGroupThisFrame(BoatGroup, BoatGroupName)
				PromptSetEnabled(_BoatPrompt, true)
				PromptSetVisible(_BoatPrompt, true)
			end
			if PromptHasStandardModeCompleted(_BoatPrompt) then
				OpenMenu()
			end
		end
		if GetDistanceBetweenCoords(stand.x, stand.y, stand.z, GetEntityCoords(PlayerPedId()), false) > 2 then
			MenuData.Close('default', GetCurrentResourceName(), 'menuapi')
			near = 1000
		end
	end
end)

function OpenrsBoatMenu()
    MenuData.CloseAll()
    local elements = {
        { label = "Anker werfen/einholen", value = 'anker', desc = "Ankern" },
        { label = "Einparken", value = 'parken', desc = "Der Bootswärter wird dein Boot gleich einparken" }
    }
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi2',
	{
		title    = "Boot",
		subtext  = "Menu",
		align    = 'top-right',
		elements = elements,
	},
	function(data, menu)
		if data.current.value == "anker" then
			local ped = PlayerPedId()
				if IsPedInAnyBoat(ped) then
					boat = GetVehiclePedIsIn(ped, true)
					if not isAnchored then
						SetBoatAnchor(boat, true)
						SetBoatFrozenWhenAnchored(boat, true)
						isAnchored = true
					else
						SetBoatAnchor(boat, false)
						isAnchored = false
					end
				end
			menu.close()
		elseif data.current.value == "parken" then
			TaskLeaveVehicle(PlayerPedId(), spawn_boat, 0)
			menu.close()
			Wait(15000)
			DeleteEntity(spawn_boat)
			boating = false
							
		end
	end,
	function(data, menu)
		menu.close()
	end)
end

function OpenMenu()
    MenuData.CloseAll()

    local elements = {
        { label = "Boot Kaufen", value = 'buy', desc = "Hier kannst du ein Boot kaufen" },
        { label = "Eigene Boote", value = 'own', desc = "Hier findest du deine eigenen Boote" }
    }
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
	{
		title    = "Boots Handel",
		subtext  = "Boote",
		align    = 'top-right',
		elements = elements,
	},
	function(data, menu)
		if data.current.value == "buy" then
			OpenBuyBoatsMenu()
		elseif data.current.value == "own" then
			TriggerServerEvent('rs:loadownedboats')
		end
	end,
	function(data, menu)
		menu.close()
	end)
end

function OpenOwnBoatsMenu()
    MenuData.CloseAll()
	local elements = {}
	
	for k, boot in pairs(OwnedBoats) do
		 elements[#elements + 1] = {
            label = boot['name'],
            value = k,
            desc = boot['name'], 
			info = boot['boat']
        }
	end
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
	{
		title    = "Deine Boote",
		subtext  = "Boote",
		align    = 'top-right',
		elements = elements,
	},
	function(data, menu)
		if data.current.value then
			local boatget = data.current.info
			TriggerEvent('rs:spawnBoat', boatget)
			menu.close()
		end
	end,
	function(data, menu)
		menu.close()
	end)
end

function OpenBuyBoatsMenu()
    MenuData.CloseAll()
	local elements = {}
	for k, boot in pairs(boates) do
		elements[#elements + 1] = {
			label = boates[k]['Text'],
            value = k,
            desc = 'Preis: <span style=color:MediumSeaGreen;>'..boates[k]['Param']['Price']..'$</span>',
			info = boates[k]['Param']
		}
	end
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
	{
		title    = "Kaufen",
		subtext  = "Boote",
		align    = 'top-right',
		elements = elements,
	},
	function(data, menu)
		if data.current.value then
			local boatbuy = data.current.info
			TriggerServerEvent('rs:buyboat', boatbuy)
			menu.close()
		end
	end,
	function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent("rs:loadBoatsMenu")
AddEventHandler("rs:loadBoatsMenu", function(result)
	OwnedBoats = result
	OpenOwnBoatsMenu()
end)

-- | Blips and NPC | --
Citizen.CreateThread(function()
    for _,marker in pairs(Config.Marker) do
        local blip = N_0x554d9d53f696d002(1664425300, marker.x, marker.y, marker.z)
        SetBlipSprite(blip, marker.sprite, 1)
        SetBlipScale(blip, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, marker.name)
    end  
end)

Citizen.CreateThread(function()
    for _, zone in pairs(Config.Marker) do
        TriggerEvent("rs_boats:CreateNPC", zone)
    end
end)

RegisterNetEvent("rs_boats:CreateNPC")
AddEventHandler("rs_boats:CreateNPC", function(zone)
    if not DoesEntityExist(boatnpc) then
        local model = GetHashKey("A_M_M_UniBoatCrew_01")
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(500)
        end     
        boatnpc = CreatePed(model, zone.x, zone.y, zone.z - 0.98, zone.h,  false, true)
        Citizen.InvokeNative(0x283978A15512B2FE , boatnpc, true )
        SetEntityNoCollisionEntity(PlayerPedId(), boatnpc, false)
        SetEntityCanBeDamaged(boatnpc, false)
        SetEntityInvincible(boatnpc, true)
        FreezeEntityPosition(boatnpc, true)
        SetBlockingOfNonTemporaryEvents(boatnpc, true)
        SetModelAsNoLongerNeeded(model)
    end
end)

-- | Boat Storage | --
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		
		if IsControlJustReleased(0, keys['O']) then
			if IsPedInAnyBoat(PlayerPedId()) then
				OpenBoatMenu()
			else
				return
			end
		end
	end
end)

function OpenBoatMenu()
	if boating == true then
		OpenrsBoatMenu()
	else
		return
	end
end

-- | Spawn boat | --
RegisterNetEvent('rs:spawnBoat' )
AddEventHandler('rs:spawnBoat', function(_model)
	DeleteVehicle(spawn_boat)
	RequestModel(_model)
	while not HasModelLoaded(_model) do
		Wait(500)
	end
	spawn_boat = CreateVehicle(_model, stand.xo, stand.yo, stand.zo, stand.ho, true, false)
	SetVehicleOnGroundProperly(spawn_boat)
	SetModelAsNoLongerNeeded(_model)
	local player = PlayerPedId()
	DoScreenFadeOut(500)
	Wait(500)
	SetPedIntoVehicle(player, spawn_boat, -1)
	Wait(500)
	DoScreenFadeIn(500)
	boating = true
end)