local BLOOMS_NOW	= GetModConfigData("blooms_now")
local NORMAL_SOURCE	= GetModConfigData("normal_source")
local SKIN_BLOOMS	= GetModConfigData("skin_blooms")

PrefabFiles = {
	"wormwood",
	"compostwrap"
}

Assets =
	{
		Asset("ANIM", "anim/wormwood_plant_fx_cactus.zip"),
		Asset("ANIM", "anim/wormwood_plant_fx_mushroom.zip"),
		Asset("ANIM", "anim/wormwood_plant_fx_rose.zip"),
	}

-- --- Blooms Now --- --
if BLOOMS_NOW then
	GLOBAL.setmetatable(
		env,
		{
			__index = function(t, k)
				return GLOBAL.rawget(GLOBAL, k)
			end
		}
	)
	
	TUNING.KEY1 = 273
	TUNING.KEY2 = 276
	TUNING.KEY3 = 275
	
	local function OnBloomFXDirty(inst)
		local fx = CreateEntity()
		fx:AddTag("FX")
		fx:AddTag("NOCLICK")
		fx.entity:SetCanSleep(false)
		fx.persists = false
		fx.entity:AddTransform()
		fx.entity:AddAnimState()
		fx.AnimState:SetBank("wormwood_bloom_fx")
		fx.AnimState:SetBuild("wormwood_bloom_fx")
		fx.AnimState:SetFinalOffset(2)
		if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
			fx.Transform:SetSixFaced()
			fx.AnimState:PlayAnimation(inst.bloomfx:value() and "poof_mounted_less" or "poof_mounted")
		else
			fx.Transform:SetFourFaced()
			fx.AnimState:PlayAnimation(inst.bloomfx:value() and "poof_less" or "poof")
		end
		fx:ListenForEvent("animover", fx.Remove)
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		fx.Transform:SetRotation(inst.Transform:GetRotation())
		local skin_build = string.match(inst.AnimState:GetSkinBuild() or "", "wormwood(_.+)") or ""
		skin_build = skin_build:match("(.*)_build$") or skin_build
		skin_build = skin_build:match("(.*)_stage_?%d$") or skin_build
		if skin_build:len() > 0 then
			fx.AnimState:OverrideSkinSymbol("bloom_fx_swap_leaf", "wormwood" .. skin_build, "bloom_fx_swap_leaf")
		end
	end
	local function SpawnBloomFX(inst)
		inst.bloomfx:set_local(false)
		inst.bloomfx:set(false)
		if not TheNet:IsDedicated() then
			OnBloomFXDirty(inst)
		end
	end
	local function OnTimiyBlooming(inst)
		if inst:HasTag("playerghost") then
			return
		end
		local oldskin = inst.components.skinner:GetSkinMode()
		if oldskin == "normal_skin" then
			inst.overrideskinmode = "stage_2"
		elseif oldskin == "stage_2" then
			inst.overrideskinmode = "stage_3"
		elseif oldskin == "stage_3" then
			inst.overrideskinmode = "stage_4"
		elseif oldskin == "stage_4" then
			inst.overrideskinmode = "normal_skin"
		end
		inst.components.skinner:SetSkinMode(inst.overrideskinmode or "normal_skin", "wilson")
		SpawnBloomFX(inst)
		inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds", nil, .6)
	end
	local function OnPollenDirty(inst)
		local fx = CreateEntity()
		fx:AddTag("FX")
		fx:AddTag("NOCLICK")
		fx.entity:SetCanSleep(false)
		fx.persists = false
		fx.entity:AddTransform()
		fx.entity:AddAnimState()
		fx.AnimState:SetBank("wormwood_pollen_fx")
		fx.AnimState:SetBuild("wormwood_pollen_fx")
		fx.AnimState:PlayAnimation("pollen" .. tostring(inst.pollen:value()))
		fx.AnimState:SetFinalOffset(2)
		fx:ListenForEvent("animover", fx.Remove)
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
	local function DoSpawnPollen(inst)
		local rnd = math.random()
		rnd = table.remove(inst.pollenpool, math.clamp(math.ceil(rnd * rnd * #inst.pollenpool), 1, #inst.pollenpool))
		table.insert(inst.pollenpool, rnd)
		inst.pollen:set_local(0)
		inst.pollen:set(rnd)
		if not TheNet:IsDedicated() then
			OnPollenDirty(inst)
		end
	end
	local function PollenTick(inst)
		inst:DoTaskInTime(math.random() * .6, DoSpawnPollen)
	end
	local function PlantTick(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		if #TheSim:FindEntities(x, y, z, 1, {"wormwood_plant_fx"}) < 18 then
			local map = TheWorld.Map
			local pt = Vector3(0, 0, 0)
			local offset =
				FindValidPositionByFan(
				math.random() * 2 * PI,
				math.random() * 1,
				3,
				function(offset)
					pt.x = x + offset.x
					pt.z = z + offset.z
					local tile = map:GetTileAtPoint(pt:Get())
					return tile ~= GROUND.ROCKY and tile ~= GROUND.ROAD and tile ~= GROUND.WOODFLOOR and tile ~= GROUND.CARPET and
						tile ~= GROUND.IMPASSABLE and
						tile ~= GROUND.INVALID and
						#TheSim:FindEntities(pt.x, 0, pt.z, .5, {"wormwood_plant_fx"}) < 3 and
						map:IsDeployPointClear(pt, nil, .5) and
						not map:IsPointNearHole(pt, .4)
				end
			)
			if offset ~= nil then
				local plant = SpawnPrefab("wormwood_plant_fx")
				plant.Transform:SetPosition(x + offset.x, 0, z + offset.z)
				local rnd = math.random()
				rnd = table.remove(inst.plantpool, math.clamp(math.ceil(rnd * rnd * #inst.plantpool), 1, #inst.plantpool))
				table.insert(inst.plantpool, rnd)
				plant:SetVariation(rnd)
			end
		end
	end
	local function OnTimiyFullBloom(inst)
		if inst:HasTag("playerghost") then
			return
		end
		if inst.pollentask == nil then
			if inst.pollentask == nil then
				inst.pollentask = inst:DoPeriodicTask(.7, PollenTick)
			end
			if inst.planttask == nil then
				inst.planttask = inst:DoPeriodicTask(.25, PlantTick)
			end
		else
			if inst.pollentask then
				inst.pollentask:Cancel()
				inst.pollentask = nil
			end
			if inst.planttask then
				inst.planttask:Cancel()
				inst.planttask = nil
			end
		end
	end
	local function SpawnLeaves(inst)
		if inst.sg:HasStateTag("moving") then
			if inst.leaftask == nil then
				inst.leaftask = inst:DoPeriodicTask(.25, SpawnBloomFX)
			end
		else
			if inst.leaftask then
				inst.leaftask:Cancel()
				inst.leaftask = nil
			end
		end
	end
	local function OnLeaves(inst)
		if inst.leaf == nil then
			inst.leaf = true
			inst:ListenForEvent("locomote", SpawnLeaves)
		else
			inst.leaf = nil
			inst:RemoveEventCallback("locomote", SpawnLeaves)
			if inst.leaftask then
				inst.leaftask:Cancel()
				inst.leaftask = nil
			end
		end
	end
	AddPrefabPostInit(
		"wormwood",
		function(inst)
			if not TheWorld.ismastersim then
				return inst
			end
			inst.OnTimiyBlooming = OnTimiyBlooming
			inst.OnTimiyFullBloom = OnTimiyFullBloom
			inst.OnLeaves = OnLeaves
		end
	)
	local function TimiyBlooming(inst)
		if inst.OnTimiyBlooming then
			inst.OnTimiyBlooming(inst)
		end
	end
	AddModRPCHandler(modname, "TimiyBlooming", TimiyBlooming)
	TheInput:AddKeyDownHandler(
		TUNING.KEY1,
		function()
			if ThePlayer and ThePlayer.prefab == "wormwood" and ThePlayer.HUD == TheFrontEnd:GetActiveScreen() then
				SendModRPCToServer(MOD_RPC[modname]["TimiyBlooming"])
			end
		end
	)
	local function TimiyFullBloom(inst)
		if inst.OnTimiyFullBloom then
			inst.OnTimiyFullBloom(inst)
		end
	end
	AddModRPCHandler(modname, "TimiyFullBloom", TimiyFullBloom)
	TheInput:AddKeyDownHandler(
		TUNING.KEY2,
		function()
			if ThePlayer and ThePlayer.prefab == "wormwood" and ThePlayer.HUD == TheFrontEnd:GetActiveScreen() then
				SendModRPCToServer(MOD_RPC[modname]["TimiyFullBloom"])
			end
		end
	)
	local function Leaves(inst)
		if inst.OnLeaves then
			inst.OnLeaves(inst)
		end
	end
	AddModRPCHandler(modname, "Leaves", Leaves)
	TheInput:AddKeyDownHandler(
		TUNING.KEY3,
		function()
			if ThePlayer and ThePlayer.prefab == "wormwood" and ThePlayer.HUD == TheFrontEnd:GetActiveScreen() then
				SendModRPCToServer(MOD_RPC[modname]["Leaves"])
			end
		end
	)
end


-- --- Normal Source --- --
if NORMAL_SOURCE then
	AddPrefabPostInit("wormwood", function(inst)
	    inst.components.talker.fontsize = nil
	    inst.components.talker.font = nil
	end)
end


-- --- Skin Blooms --- --
if SKIN_BLOOMS then
	local MODENV = env

	

	if MODENV.MODROOT:find("wormwood_mod") then
		CHEATS_ENABLED = true
	end

	local function GetBuild(inst)
		local build = (inst.entity:GetDebugString():match("build: [%w_]+"))
		return build and (build:gsub("build: ", ""))
	end

	local BUILD_OVERRIDES =
	{
		cactus = "wormwood_plant_fx_cactus",
		mushroom = "wormwood_plant_fx_mushroom",
		rose = "wormwood_plant_fx_rose",
	}

	MODENV.AddPrefabPostInit("wormwood_plant_fx", function(inst)
		inst:DoTaskInTime(0, function(inst)
			local pos = inst:GetPosition()
			
			local owner = TheSim:FindEntities(pos.x, 0, pos.z, 2, {"plantkin"})[1]
			if owner then
				local build = GetBuild(owner)
				if build then
					local override = build
					if build:find("stage") then
						override = string.match(build, "wormwood_.+_")
					end
					override = override:gsub("wormwood", ""):gsub("_", "")
					if override and BUILD_OVERRIDES[override] then
						inst.AnimState:SetBank(BUILD_OVERRIDES[override])
						inst.AnimState:SetBuild(BUILD_OVERRIDES[override])
					end
				end
			end
		end)
	end)
end