local function OnEfficiencyChanged(inst, data)
	if inst.components.agcw_power_appliance then
		inst.components.agcw_power_appliance:SetEfficiency(data.new)
	end
end

local PowerApp = Class(function(self, inst)
    self.inst = inst

	self.is_turnon = false
	self.standard_demand = 0
	self.current_demand = self.standard_demand
	self.efficiency = 0
	-- self.on_turnon_fn = nil	--fn(self.inst, is_turnon)
	-- self.output_changed_fn = nil	--fn(self.inst, new_val, old_val)
	-- self.calc_current_demand_fn = nill	--fn(self.inst)

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
	val = math.max(0, val)
	self.standard_demand = val
end

function PowerApp:GetStandardDemand()
	return self.standard_demand
end


function PowerApp:SetDemand(val)
	local old_val = self.current_demand
	self.current_demand = math.clamp(val, 0, self.standard_demand)
	local delta = val - old_val
	if delta ~= 0 then
		TheWorld.net.AgcwPowerMgr:OnPowerApplianceDemandChanged(self.inst, delta)
		if self.output_changed_fn then
			self.output_changed_fn(self.inst, self.current_demand, old_val)
		end
	end
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

function PowerApp:TurnOn()
	self.is_turnon = true
	self:RefreshDemand()
	if self.on_turnon_fn then
		self.on_turnon_fn(self.inst, true)
	end
end

function PowerApp:TurnOff()
	self.is_turnon = false
	self:RefreshDemand()
	if self.on_turnon_fn then
		self.on_turnon_fn(self.inst, true)
	end
end

function PowerApp:RefreshDemand()
	if self:IsTurnOn() then
		self:SetDemand(self.calc_current_demand_fn and self.calc_current_demand_fn(self.inst) or self:GetStandardDemand())
	else
		self:SetDemand(0)
	end
end

function PowerApp:IsTurnOn()
	return self.is_turnon
end


function PowerApp:OnSave()
	return {
		is_turnon = self.is_turnon
	}
end

function PowerApp:OnLoad(data)
	if data then
		if data.is_turnon and not self:IsTurnOn() then
			self:TurnOn()
		elseif not data.is_turnon and self:IsTurnOn() then
			self:TurnOff()
		end
	end
end

return PowerApp