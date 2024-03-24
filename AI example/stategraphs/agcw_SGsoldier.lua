require "stategraphs/commonstates"


local function ConfigureRunState(inst)
	if inst.components.inventory:IsHeavyLifting() then
        inst.sg.statemem.heavy = true
		inst.sg.statemem.heavy_fast = inst.components.mightiness ~= nil and inst.components.mightiness:IsMighty()
    else
        inst.sg.statemem.normal = true
        inst.sg.statemem.normalwonkey = inst:HasTag("wonkey") or nil
    end
end

local function GetRunStateAnim(inst)
    return ((inst.sg.statemem.heavy and inst.sg.statemem.heavy_fast) and "heavy_walk_fast")
        or (inst.sg.statemem.heavy and "heavy_walk")
        or (inst.sg.statemem.sandstorm and "sand_walk")
        or ((inst.sg.statemem.groggy or inst.sg.statemem.moosegroggy or inst.sg.statemem.goosegroggy) and "idle_walk")
        or (inst.sg.statemem.careful and "careful_walk")
        or (inst.sg.statemem.ridingwoby and "run_woby")
        or "run"
end

local function DoEquipmentFoleySounds(inst)
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.foleysound ~= nil then
            inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
        end
    end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    if inst.foleysound ~= nil then
        inst.SoundEmitter:PlaySound(inst.foleysound, nil, nil, true)
    end
end

local function DoMountedFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
end

local function DoRunSounds(inst)
    if inst.sg.mem.footsteps > 3 then
        PlayFootstep(inst, .6, true)
    else
        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
        PlayFootstep(inst, 1, true)
    end
end


--------------------------------------------------


local actionhandlers = {
    ActionHandler(ACTIONS.PICKUP, function(inst, action)
        return (inst.components.rider ~= nil and inst.components.rider:IsRiding()
            and (action.target ~= nil and action.target:HasTag("heavy") and "dodismountaction"
                or "domediumaction")
            )
        or (action.target ~= nil and action.target:HasTag("minigameitem") and "dosilentshortaction")
        or "doshortaction"
    end),
    ActionHandler(ACTIONS.PICK, function(inst, action)
        return (inst.components.rider ~= nil and inst.components.rider:IsRiding() and "dolongaction")
        or (action.target ~= nil
        and action.target.components.pickable ~= nil
        and (   (action.target.components.pickable.jostlepick and "dojostleaction") or
                (action.target.components.pickable.quickpick and "doshortaction") or
                (inst:HasTag("fastpicker") and "doshortaction") or
                (inst:HasTag("quagmire_fasthands") and "domediumaction") or
                "dolongaction"  ))
        or nil
    end),
	ActionHandler(ACTIONS.EAT, function(inst, action)
		if inst.sg:HasStateTag("busy") then
			return
		end
		local obj = action.target or action.invobject
		if obj == nil then
			return
		elseif obj.components.edible ~= nil then
			if not inst.components.eater:PrefersToEat(obj) then
				inst:PushEvent("wonteatfood", { food = obj })
				return
			end
		elseif obj.components.soul ~= nil then
			if inst.components.souleater == nil then
				inst:PushEvent("wonteatfood", { food = obj })
				return
			end
		else
			return
		end
		return (obj.components.soul ~= nil and "eat")
			or (obj.components.edible.foodtype == FOODTYPE.MEAT and "eat")
			or "quickeat"
	end),
	ActionHandler(ACTIONS.ATTACK, function(inst, action)
		print("ActionHandler(ACTIONS.ATTACK")
		inst.sg.mem.localchainattack = not action.forced or nil

		if not inst.components.health:IsDead() then
			local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
			return (weapon == nil and "attack")
			or (weapon:HasTag("blowdart") and "blowdart")
			or (weapon:HasTag("slingshot") and "slingshot_shoot")
			or (weapon:HasTag("thrown") and "throw")
			or (weapon:HasTag("pillow") and "attack_pillow_pre")
			or (weapon:HasTag("propweapon") and "attack_prop_pre")
			or (weapon:HasTag("multithruster") and "multithrust_pre")
			or (weapon:HasTag("helmsplitter") and "helmsplitter_pre")
			or "attack"
		end
	end),
}


--------------------------------------------------


local events =
{
    EventHandler("locomote", function(inst, data)
        if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("overridelocomote") then
            return
        end

        local is_moving = inst.sg:HasStateTag("moving")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        if inst:HasTag("ingym") then
            inst.sg.statemem.dontleavegym = true
            local gym = inst.components.strongman.gym
            if gym then
                gym.components.mightygym:CharacterExitGym(inst)
            end
        elseif inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent") or inst.sg:HasStateTag("waking") then -- wakeup on locomote
            if inst.sleepingbag ~= nil and inst.sg:HasStateTag("sleeping") then
                inst.sleepingbag.components.sleepingbag:DoWakeUp()
                inst.sleepingbag = nil
            end
        elseif is_moving and not should_move then
            inst.sg:GoToState("run_stop")
        elseif not is_moving and should_move then
            inst.sg:GoToState("run_start")
        elseif data.force_idle_state and not (is_moving or should_move or inst.sg:HasStateTag("idle") or inst:HasTag("is_furling"))  then
            inst.sg:GoToState("idle")
        end
    end),
	CommonHandlers.OnAttack(),
	CommonHandlers.OnDeath(),
}


--------------------------------------------------


local states = {
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            inst.sg.statemem.ignoresandstorm = true

			if inst.sg.mem.queuetalk_timeout ~= nil then
				local remaining_talk_time = inst.sg.mem.queuetalk_timeout - GetTime()
				inst.sg.mem.queuetalk_timeout = nil
				if not inst:HasTag("ignoretalking") and not pushanim then
					if remaining_talk_time > 1 then
						if not inst:HasTag("mime") then
							inst.sg:GoToState("talk")
							return
						elseif not inst.components.inventory:IsHeavyLifting() then
							inst.sg:GoToState("mime")
							return
						end
					end
				end
			end

            local anims = {}
            local dofunny = true

            if inst.components.inventory:IsHeavyLifting() then
                table.insert(anims, "heavy_idle")
                dofunny = false
            else
                inst.sg.statemem.ignoresandstorm = false
				table.insert(anims, "idle_loop")
            end

            if pushanim then
                for k, v in pairs(anims) do
                    inst.AnimState:PushAnimation(v, k == #anims)
                end
            else
                inst.AnimState:PlayAnimation(anims[1], #anims == 1)
                for k, v in pairs(anims) do
                    if k > 1 then
                        inst.AnimState:PushAnimation(v, k == #anims)
                    end
                end
            end

            if dofunny then
                inst.sg:SetTimeout(math.random() * 4 + 2)
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("funnyidle")
        end,
    },

    State{
        name = "funnyidle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            if inst.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then
                inst.AnimState:PlayAnimation("hungry")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")
            elseif inst:HasTag("groggy") then
                inst.AnimState:PlayAnimation("idle_groggy01_pre")
                inst.AnimState:PushAnimation("idle_groggy01_loop")
                inst.AnimState:PushAnimation("idle_groggy01_pst", false)
            elseif inst.customidleanim == nil and inst.customidlestate == nil then
                inst.AnimState:PlayAnimation("idle_inaction")
			else
                local anim = inst.customidleanim ~= nil and (type(inst.customidleanim) == "string" and inst.customidleanim or inst:customidleanim()) or nil
				local state = anim == nil and (inst.customidlestate ~= nil and (type(inst.customidlestate) == "string" and inst.customidlestate or inst:customidlestate())) or nil
                if anim ~= nil or state ~= nil then
                    if inst.sg.mem.idlerepeats == nil then
                        inst.sg.mem.usecustomidle = math.random() < .5
                        inst.sg.mem.idlerepeats = 0
                    end
                    if inst.sg.mem.idlerepeats > 1 then
                        inst.sg.mem.idlerepeats = inst.sg.mem.idlerepeats - 1
                    else
                        inst.sg.mem.usecustomidle = not inst.sg.mem.usecustomidle
                        inst.sg.mem.idlerepeats = inst.sg.mem.usecustomidle and 1 or math.ceil(math.random(2, 5) * .5)
                    end
					if inst.sg.mem.usecustomidle then
						if anim ~= nil then
		                    inst.AnimState:PlayAnimation(anim)
						else
							inst.sg:GoToState(state)
						end
					else
	                    inst.AnimState:PlayAnimation("idle_inaction")
					end
                else
                    inst.AnimState:PlayAnimation("idle_inaction")
                end
            end
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "run_start",
        tags = { "moving", "running", "canrotate", "autopredict" },

        onenter = function(inst)
            ConfigureRunState(inst)
            if inst.sg.statemem.normalwonkey and inst.components.locomotor:GetTimeMoving() >= TUNING.WONKEY_TIME_TO_RUN then
                inst.sg:GoToState("run_monkey") --resuming after brief stop from changing directions, or resuming prediction after running into obstacle
                return
            end
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation(GetRunStateAnim(inst).."_pre")
            --goose footsteps should always be light
            inst.sg.mem.footsteps = (inst.sg.statemem.goose or inst.sg.statemem.goosegroggy) and 4 or 0
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --mounted
            TimeEvent(0, function(inst)
                if inst.sg.statemem.riding then
                    DoMountedFoleySounds(inst)
                end
            end),

            --heavy lifting
            TimeEvent(1 * FRAMES, function(inst)
                if inst.sg.statemem.heavy and not inst.sg.statemem.heavy_fast then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),

            --unmounted
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.normal then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),

            --mounted
            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    PlayFootstep(inst, nil, true)
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State{
        name = "run",
        tags = { "moving", "running", "canrotate", "autopredict" },

        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:RunForward()

            local anim = GetRunStateAnim(inst)
            if anim == "run" then
                anim = "run_loop"
            elseif anim == "run_woby" then
                anim = "run_woby_loop"
            end
            if not inst.AnimState:IsCurrentAnimation(anim) then
                inst.AnimState:PlayAnimation(anim, true)
            end

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onupdate = function(inst)
            if inst.sg.statemem.normalwonkey and inst.components.locomotor:GetTimeMoving() >= TUNING.WONKEY_TIME_TO_RUN then
                inst.sg:GoToState("run_monkey_start")
                return
            end
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --unmounted
            TimeEvent(7 * FRAMES, function(inst)
                if inst.sg.statemem.normal then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(15 * FRAMES, function(inst)
                if inst.sg.statemem.normal then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            TimeEvent(26 * FRAMES, function(inst)
                if inst.sg.statemem.careful then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            TimeEvent(23 * FRAMES, function(inst)
                if inst.sg.statemem.sandstorm then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            --heavy lifting
            TimeEvent(0 * FRAMES, function(inst)
                if inst.sg.statemem.heavy and inst.sg.statemem.heavy_fast then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                    if inst.sg.mem.footsteps > 3 then
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                    end
                end
            end),
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.heavy and inst.sg.statemem.heavy_fast then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                    if inst.sg.mem.footsteps > 3 then
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                    end
                end
            end),
            TimeEvent(11 * FRAMES, function(inst)
                if inst.sg.statemem.heavy and not inst.sg.statemem.heavy_fast then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                    if inst.sg.mem.footsteps > 3 then
                        --normally stops at > 3, but heavy needs to keep count
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                    end
                elseif inst.sg.statemem.sandstorm
                    or inst.sg.statemem.careful then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(36 * FRAMES, function(inst)
                if inst.sg.statemem.heavy and not inst.sg.statemem.heavy_fast then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                    if inst.sg.mem.footsteps > 12 then
                        inst.sg.mem.footsteps = math.random(4, 6)
                        inst:PushEvent("encumberedwalking")
                    elseif inst.sg.mem.footsteps > 3 then
                        --normally stops at > 3, but heavy needs to keep count
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                    end
                end
            end),

            --mounted
            TimeEvent(0 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    DoMountedFoleySounds(inst)
                end
            end),
            TimeEvent(1 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    DoRunSounds(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/beefalo/walk",nil,.5)
                    if inst.sg.statemem.ridingwoby then
                        inst.SoundEmitter:PlaySoundWithParams("dontstarve/characters/walter/woby/big/footstep", {intensity= 1})
                    end
                end
            end),
            TimeEvent(3 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    if inst.sg.statemem.ridingwoby then
                        inst.SoundEmitter:PlaySoundWithParams("dontstarve/characters/walter/woby/big/footstep", {intensity= 1})
                    end
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    DoRunSounds(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/beefalo/walk",nil,.5)
                    if inst.sg.statemem.ridingwoby then
                        inst.SoundEmitter:PlaySoundWithParams("dontstarve/characters/walter/woby/big/footstep", {intensity= 1})
                    end
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    if inst.sg.statemem.ridingwoby then
                        inst.SoundEmitter:PlaySoundWithParams("dontstarve/characters/walter/woby/big/footstep", {intensity= 1})
                    end
                end
            end),
        },

        events =
        {
            EventHandler("gogglevision", function(inst, data)
                if data.enabled then
                    if inst.sg.statemem.sandstorm then
                        inst.sg:GoToState("run")
                    end
                elseif not (inst.sg.statemem.riding or
                            inst.sg.statemem.heavy or
                            inst.sg.statemem.iswere or
                            inst.sg.statemem.sandstorm or
                            inst:GetStormLevel() < TUNING.SANDSTORM_FULL_LEVEL) then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("sandstormlevel", function(inst, data)
                if data.level < TUNING.SANDSTORM_FULL_LEVEL then
                    if inst.sg.statemem.sandstorm then
                        inst.sg:GoToState("run")
                    end
                elseif not (inst.sg.statemem.riding or
                            inst.sg.statemem.heavy or
                            inst.sg.statemem.iswere or
                            inst.sg.statemem.sandstorm or
                            inst.components.playervision:HasGoggleVision()) then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("carefulwalking", function(inst, data)
                if not data.careful then
                    if inst.sg.statemem.careful then
                        inst.sg:GoToState("run")
                    end
                elseif not (inst.sg.statemem.riding or
                            inst.sg.statemem.heavy or
                            inst.sg.statemem.sandstorm or
                            inst.sg.statemem.groggy or
                            inst.sg.statemem.careful or
                            inst.sg.statemem.iswere) then
                    inst.sg:GoToState("run")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "canrotate", "idle", "autopredict" },

        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation(GetRunStateAnim(inst).."_pst")
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                if inst.sg.statemem.goose or inst.sg.statemem.goosegroggy then
                    PlayFootstep(inst, .5, true)
                    DoFoleySounds(inst)
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "doshortaction",
        tags = { "doing", "busy" },

        onenter = function(inst, silent)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_pst", false)

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg.statemem.silent = silent
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
                inst:PerformBufferedAction()
            end),
        },

        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action and
            (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                inst:ClearBufferedAction()
            end
        end,
    },

	State{
        name = "eat",
        tags = { "busy", "nodangle" },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
                inst.sg:AddStateTag("pausepredict")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

            if feed == nil or
                feed.components.edible == nil or
                feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
            end

            if feed ~= nil and feed.components.soul ~= nil then
                inst.sg.statemem.soulfx = SpawnPrefab("wortox_eat_soul_fx")
                inst.sg.statemem.soulfx.entity:SetParent(inst.entity)
            end

			inst.AnimState:PlayAnimation("eat_pre")
			inst.AnimState:PushAnimation("eat", false)

            inst.components.hunger:Pause()
        end,

        timeline =
        {
            TimeEvent(28 * FRAMES, function(inst)
                if inst.sg.statemem.feed == nil then
                    inst:PerformBufferedAction()
                elseif inst.sg.statemem.feed.components.soul == nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                elseif inst.components.souleater ~= nil then
                    inst.components.souleater:EatSoul(inst.sg.statemem.feed)
                end
            end),

            TimeEvent(30 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("pausepredict")
            end),

            TimeEvent(70 * FRAMES, function(inst)
                inst.SoundEmitter:KillSound("eating")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("eating")
            if not GetGameModeProperty("no_hunger") then
                inst.components.hunger:Resume()
            end
            if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                inst.sg.statemem.feed:Remove()
            end
            if inst.sg.statemem.soulfx ~= nil then
                inst.sg.statemem.soulfx:Remove()
            end
        end,
    },

    State{
        name = "quickeat",
        tags = { "busy" },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
                inst.sg:AddStateTag("pausepredict")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

            if feed == nil or
                feed.components.edible == nil or
                feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
            end

			inst.AnimState:PlayAnimation("quick_eat_pre")
			inst.AnimState:PushAnimation("quick_eat", false)

            inst.components.hunger:Pause()
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.feed ~= nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                else
                    inst:PerformBufferedAction()
                end
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("pausepredict")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("eating")
            if not GetGameModeProperty("no_hunger") then
                inst.components.hunger:Resume()
            end
            if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                inst.sg.statemem.feed:Remove()
            end
        end,
    },

	State{
        name = "attack",
        tags = { "attack", "notalking", "abouttoattack", "busy" },

        onenter = function(inst)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst.sg:GoToState("idle", true)
                return
            end
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true		--连招(怀表)
            end
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = inst.components.combat.min_attack_period

			--处理攻击冷却
           	if equip ~= nil and equip:HasTag("toolpunch") then
                inst.AnimState:PlayAnimation("toolpunch")
                inst.sg.statemem.istoolpunch = true
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip ~= nil and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                cooldown = math.max(cooldown, 17 * FRAMES)
			elseif equip ~= nil and equip:HasTag("pocketwatch") then
				inst.AnimState:PlayAnimation(inst.sg.statemem.chained and "pocketwatch_atk_pre_2" or "pocketwatch_atk_pre" )
				inst.AnimState:PushAnimation("pocketwatch_atk", false)
				inst.sg.statemem.ispocketwatch = true
				cooldown = math.max(cooldown, 15 * FRAMES)
                if equip:HasTag("shadow_item") then
	                inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre_shadow", nil, nil, true)
					inst.AnimState:Show("pocketwatch_weapon_fx")
					inst.sg.statemem.ispocketwatch_fueled = true
                else
	                inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre", nil, nil, true)
					inst.AnimState:Hide("pocketwatch_weapon_fx")
                end
            elseif equip ~= nil and equip:HasTag("book") then
                inst.AnimState:PlayAnimation("attack_book")
                inst.sg.statemem.isbook = true
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 19 * FRAMES)
            elseif equip ~= nil and equip:HasTag("chop_attack") and inst:HasTag("woodcutter") then
				inst.AnimState:PlayAnimation(inst.AnimState:IsCurrentAnimation("woodie_chop_loop") and inst.AnimState:GetCurrentAnimationFrame() <= 7 and "woodie_chop_atk_pre" or "woodie_chop_pre")
                inst.AnimState:PushAnimation("woodie_chop_loop", false)
                inst.sg.statemem.ischop = true
                cooldown = math.max(cooldown, 11 * FRAMES)
            elseif equip ~= nil and equip:HasTag("jab") then
                inst.AnimState:PlayAnimation("spearjab_pre")
                inst.AnimState:PushAnimation("spearjab", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 21 * FRAMES)
            elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                if (equip.projectiledelay or 0) > 0 then
                    inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                    if inst.sg.statemem.projectiledelay > FRAMES then
                        inst.sg.statemem.projectilesound =
                            (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                            (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                            (equip:HasTag("firepen") and "wickerbottom_rework/firepen/launch") or
                            "dontstarve/wilson/attack_weapon"
                    elseif inst.sg.statemem.projectiledelay <= 0 then
                        inst.sg.statemem.projectiledelay = nil
                    end
                end
                if inst.sg.statemem.projectilesound == nil then
                    inst.SoundEmitter:PlaySound(
                        (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                        (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                        (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                        (equip:HasTag("firepen") and "wickerbottom_rework/firepen/launch") or
                        "dontstarve/wilson/attack_weapon",
                        nil, nil, true
                    )
                end
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif inst:HasTag("beaver") then
                inst.sg.statemem.isbeaver = true
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif inst:HasTag("weremoose") then
                inst.sg.statemem.ismoose = true
                inst.AnimState:PlayAnimation(
                    ((inst.AnimState:IsCurrentAnimation("punch_a") or inst.AnimState:IsCurrentAnimation("punch_c")) and "punch_b") or
                    (inst.AnimState:IsCurrentAnimation("punch_b") and "punch_c") or
                    "punch_a"
                )
                cooldown = math.max(cooldown, 15 * FRAMES)
            else
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 24 * FRAMES)
            end

            inst.sg:SetTimeout(cooldown)
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.ismoose then
                    inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/moose/punch", nil, nil, true)
                end
            end),
            TimeEvent(6 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
					inst.components.combat:DoAttack()
                    inst.sg:RemoveStateTag("abouttoattack")
                elseif inst.sg.statemem.ischop then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                end
            end),
            TimeEvent(7 * FRAMES, function(inst)
                if inst.sg.statemem.ismoose then
					inst.components.combat:DoAttack()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                if not (inst.sg.statemem.isbeaver or
				inst.sg.statemem.ismoose or
				inst.sg.statemem.iswhip or
				inst.sg.statemem.ispocketwatch or
				inst.sg.statemem.isbook) and
				inst.sg.statemem.projectiledelay == nil then
					inst.components.combat:DoAttack()
					inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip or inst.sg.statemem.isbook or inst.sg.statemem.ispocketwatch then
					inst.components.combat:DoAttack()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(17*FRAMES, function(inst)
				if inst.sg.statemem.ispocketwatch then
                    inst.SoundEmitter:PlaySound(inst.sg.statemem.ispocketwatch_fueled and "wanda2/characters/wanda/watch/weapon/pst_shadow" or "wanda2/characters/wanda/watch/weapon/pst")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

	State{
        name = "death",
        tags = { "busy", "dead", "pausepredict", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

			inst.SoundEmitter:PlaySound("dontstarve/wilson/death")

			if inst.deathsoundoverride ~= nil then
				inst.SoundEmitter:PlaySound(inst.deathsoundoverride)
			elseif not inst:HasTag("mime") then
				inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/death_voice")
			end

			if HUMAN_MEAT_ENABLED then
				inst.components.inventory:GiveItem(SpawnPrefab("humanmeat")) -- Drop some player meat!
			end
			if inst.components.revivablecorpse ~= nil then
				inst.AnimState:PlayAnimation("death2")
			else
				-- inst.components.inventory:DropEverything(true)
				inst.AnimState:PlayAnimation(inst.deathanimoverride or "death")
			end

			inst.AnimState:Hide("swap_arm_carry")

			if inst.components.burnable then
				inst.components.burnable:Extinguish()
			end

            --Don't process other queued events if we died this frame
            inst.sg:ClearBufferedEvents()
        end,

        timeline = {},

        onexit = function(inst)

        end,

        events = {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },
}


return StateGraph("agcw_SGsoldier", states, events, "idle", actionhandlers)