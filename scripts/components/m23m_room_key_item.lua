local function on_remove(inst)
	local pos = inst:GetPosition()
    TheRegionMgr:OnUpdateKeyItemPosition(inst.prefab, pos)
end


local KeyItem = Class(function (self, inst)
	self.inst = inst
	self.last_pos = Vector3(-9999, 0, -9999)
	self.updatedistsq = 0.25	-- 0.5 * 0.5

	self.inst:DoTaskInTime(0, function () self:StartUpdating() end)	--等到物品初始化坐标之后再开始更新
	self.inst:ListenForEvent("onremove", on_remove)	--移除时通知房间系统
end)

function KeyItem:OnRemoveFromEntity()
    self:StopUpdating()
	--移除时通知房间系统
	on_remove(self.inst)
    self.inst:RemoveEventCallback("onremove", on_remove)
end


--运动时通知房间系统
function KeyItem:UpdatePosition(x, z)
	TheRegionMgr:OnUpdateKeyItemPosition(self.inst.prefab, self.last_pos, Vector3(x, 0, z))
	self.last_pos.x, self.last_pos.z = x, z
end

function KeyItem:StartUpdating()
	self.inst:StartUpdatingComponent(self)
end

function KeyItem:StopUpdating()
	self.inst:StopUpdatingComponent(self)
end

function KeyItem:OnUpdate(dt)
	local x, y, z = self.inst.Transform:GetWorldPosition()
    if distsq(x, z, self.last_pos.x, self.last_pos.z) > self.updatedistsq then
        self:UpdatePosition(x, z)
    end
end


return KeyItem