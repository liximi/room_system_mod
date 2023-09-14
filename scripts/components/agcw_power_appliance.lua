local function OnEfficiencyChanged(inst, data)
	if inst.components.agcw_power_appliance then
		inst.components.agcw_power_appliance:SetEfficiency(data.new)
	end
end

local PowerApp = Class(function(self, inst)
    self.inst = inst

	self.standard_demand = 0
	self.current_demand = self.standard_demand
	self.efficiency = 0

	self.inst:AddTag("agcw_power_appliance")
	self.inst:ListenForEvent("agcw_power_manager.efficiencies", OnEfficiencyChanged)
end)


function PowerApp:OnRemoveFromEntity()
	self.inst:RemoveTag("agcw_power_appliance")
	self.inst:RemoveEventCallback("agcw_power_manager.efficiencies", OnEfficiencyChanged)
end

function PowerApp:OnRemoveEntity()
	self:Unregister()
end


function PowerApp:Register()
	local pos = self.inst:GetPosition()
	local tile_x, y, tile_z = TheWorld.Map:GetTileCenterPoint(pos.x, 0, pos.z)
	local success, net_id = TheWorld.net.AgcwPowerMgr:AddPowerAppliance(self.inst, tile_x, tile_z)
	if net_id then
		self:SetEfficiency(TheWorld.net.AgcwPowerMgr:GetEfficiencyByNet(net_id))
	end
	return success, net_id
end

function PowerApp:Unregister()
	return TheWorld.net.AgcwPowerMgr:RemovePowerAppliance(self.inst)
end


function PowerApp:SetStandardDemand(val)
	self.standard_demand = val
end

function PowerApp:GetStandardDemand()
	return self.standard_demand
end


function PowerApp:SetDemand(val)
	self.current_demand = math.clamp(val, 0, self.standard_demand)
end

function PowerApp:GetCurrentDemand()
	return self.current_demand
end


function PowerApp:SetEfficiency(val)
	if val ~= self.efficiency then
		local old = self.efficiency
		self.efficiency = val
		if self.on_efficiency_changed_fn then
			self.on_efficiency_changed_fn(val, old)
		end
	end
end

function PowerApp:SetOnEfficiencyChangedFn(fn)	--fn(new_val, old_val)
	if type(fn) == "function" then
		self.on_efficiency_changed_fn = fn
	end
end


return PowerApp