-- 没有使用AddComponentPostInit()，直接覆盖本体的接口，避免和其他Mod冲突
local SleepingBagUser = require "components/sleepingbaguser"

local function GetBedroomMult(pt)
	local cur_room_type = TheRegionMgr:GetRoomType(pt.x, pt.z)
	return M23M.BEDROOMS[cur_room_type] or 1
end

function SleepingBagUser:SleepTick()
    local goodsleeperequipped = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD):HasTag("good_sleep_aid")

    ---- Mod Part
	local bedroom_mult = GetBedroomMult(self.bed:GetPosition())
    local hunger_tick = self.bed.components.sleepingbag.hunger_tick * self.hunger_bonus_mult * bedroom_mult
    local health_tick = self.bed.components.sleepingbag.health_tick * self.health_bonus_mult * bedroom_mult
    local sanity_tick = self.bed.components.sleepingbag.sanity_tick * self.sanity_bonus_mult * (goodsleeperequipped and TUNING.GOODSLEEP_SANITY or 1)
    ----
    local isstarving = false
    if self.inst.components.hunger ~= nil then
        self.inst.components.hunger:DoDelta(hunger_tick, true, true)
        isstarving = self.inst.components.hunger:IsStarving()
    end

    if self.inst.components.sanity ~= nil and self.inst.components.sanity:GetPercentWithPenalty() < 1 then
        self.inst.components.sanity:DoDelta(sanity_tick, true)
    end

    if not isstarving and self.bed.components.sleepingbag.healthsleep and self.inst.components.health ~= nil then
        self.inst.components.health:DoDelta(health_tick, true, self.bed.prefab, true)
    end

    if self.bed.components.sleepingbag.temperaturetickfn ~= nil then
        self.bed.components.sleepingbag.temperaturetickfn(self.bed, self.inst)
    end

    if isstarving then
        self.bed.components.sleepingbag:DoWakeUp()
    end
end