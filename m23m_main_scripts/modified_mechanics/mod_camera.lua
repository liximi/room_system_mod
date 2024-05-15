-- [Camera]
-- 视角锁定(通过设置摄像机的lock_heading_target属性为true来锁定视角)
AddGlobalClassPostConstruct("cameras/followcamera", "FollowCamera", function(self)
    local old_SetHeadingTarget = self.SetHeadingTarget
    self.SetHeadingTarget = function(_self, r)
        if self:IsHeadingTargetLocked() then
            return old_SetHeadingTarget(_self, self.headingtarget)
        else
            return old_SetHeadingTarget(_self, r)
        end
    end
    self.LockHeadingTarget = function(_self, lock_name)
        self.headingtarget_locks = self.headingtarget_locks or {}
        self.headingtarget_locks[lock_name] = true
    end
    self.UnLockHeadingTarget = function(_self, lock_name)
        if type(self.headingtarget_locks) == "table" then
            self.headingtarget_locks[lock_name] = nil
        end
    end
    self.IsHeadingTargetLocked = function(_self)
        if type(self.headingtarget_locks) == "table" then
            for lock, _ in pairs(self.headingtarget_locks) do
                return true
            end
        end
        return false
    end

    self:SetHeadingTarget(0)

    self.ZoomIn = function(step)
        self.distancetarget = math.max(self.mindist, self.distancetarget - self.zoomstep)
        self.time_since_zoom = 0
    end

    self.ZoomOut = function(step)
        self.distancetarget = math.min(self.maxdist, self.distancetarget + self.zoomstep)
        self.time_since_zoom = 0
    end
end)