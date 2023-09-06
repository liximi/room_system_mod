local MoveQueue = Class(function(self, inst)
    self.inst = inst

	-- self.on_reach_fn = function(inst, pt) end	--pt:Vector3
	self.queue = nil	--{{x, z}, {x, z}, ...}
end)


function MoveQueue:SetQueue(pts)	--{{x, z}, {x, z}, ...}
	self.queue = {}
	for i, pt in ipairs(pts) do
		table.insert(self.queue, pt)
	end
end

function MoveQueue:SetOnReach(fn)
	if type(fn) == "function" then
		self.on_reach_fn = fn
	end
end

function MoveQueue:Move()
	if type(self.queue) == "table" then
		local pt = table.remove(self.queue, 1)
		if pt then
			if self.inst.components.locomotor and self.inst.Physics then
				self.inst.components.locomotor:SetReachDestinationCallback(function()
					self.inst:StopUpdatingComponent(self)
					if self.change_physics then
						ChangeToObstaclePhysics(self.inst)
					end
					if self.on_reach_fn then
						self.on_reach_fn(self.inst, Vector3(pt[1], 0, pt[2]))
					end
				end)
				self.inst.components.locomotor:GoToPoint(Vector3(pt[1], 0, pt[2]), nil, true)
				if self.inst.Physics:GetMass() == 0 then
					self.change_physics = true
					ChangeToCharacterPhysics(self.inst, 75)
				end
				self.inst:StartUpdatingComponent(self)
			else
				self.inst.Transform:SetPosition(pt[1], 0, pt[2])
				if self.on_reach_fn then
					self.on_reach_fn(self.inst, Vector3(pt[1], 0, pt[2]))
				end
			end
			return true
		end
	end
	return false
end

function MoveQueue:IsEmpty()
	return type(self.queue) == "table" and type(self.queue[1]) == "table"
end

function MoveQueue:OnUpdate(dt)
	self.inst.components.locomotor:RunForward()
end

return MoveQueue