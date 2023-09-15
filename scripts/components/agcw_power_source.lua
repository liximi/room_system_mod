local PowerSource = Class(function(self, inst)
    self.inst = inst

	self.is_turnon = false
	self.standard_output_power = 0
	self.current_output_power = self.standard_output_power
	-- self.on_turnon_fn = nil	--fn(self.inst, is_turnon)
	-- self.output_changed_fn = nil	--fn(self.inst, new_val, old_val)
	-- self.calc_current_output_fn = nill	--fn(self.inst)

	self.inst:AddTag("agcw_power_source")
end)


function PowerSource:OnRemoveFromEntity()
	self.inst:RemoveTag("agcw_power_source")
end

function PowerSource:OnRemoveEntity()
	self:Unregister()
end


function PowerSource:Register()
	local pos = self.inst:GetPosition()
	local tile_x, y, tile_z = TheWorld.Map:GetTileCenterPoint(pos.x, 0, pos.z)
	return TheWorld.net.AgcwPowerMgr:AddPowerSource(self.inst, tile_x, tile_z)
end

function PowerSource:Unregister()
	return TheWorld.net.AgcwPowerMgr:RemovePowerSource(self.inst)
end


function PowerSource:SetStandardOutput(val)
	val = math.max(0, val)
	self.standard_output_power = val
end

function PowerSource:GetStandardOutput()
	return self.standard_output_power
end


function PowerSource:SetOuput(val)
	if not self:IsTurnOn() then
		return
	end
	local old_val = self.current_output_power
	self.current_output_power = math.clamp(val, 0, self.standard_output_power)
	local delta = val - old_val
	if delta ~= 0 then
		TheWorld.net.AgcwPowerMgr:OnPowerSourceOutputChanged(self.inst, delta)
	end
	if self.output_changed_fn then
		self.output_changed_fn(self.inst, self.current_output_power, old_val)
	end
end

function PowerSource:GetCurrentOuput()
	return self.current_output_power
end


function PowerSource:TurnOn()
	self.is_turnon = true
	self:RefreshOutput()
	if self.on_turnon_fn then
		self.on_turnon_fn(self.inst, true)
	end
end

function PowerSource:TurnOff()
	self.is_turnon = false
	self:RefreshOutput()
	if self.on_turnon_fn then
		self.on_turnon_fn(self.inst, true)
	end
end

function PowerSource:RefreshOutput()
	if self:IsTurnOn() then
		self:SetOuput(self.calc_current_output_fn and self.calc_current_output_fn(self.inst) or self:GetStandardOutput())
	else
		self:SetOuput(0)
	end
end

function PowerSource:IsTurnOn()
	return self.is_turnon
end


function PowerSource:OnSave()
	return {
		is_turnon = self.is_turnon
	}
end

function PowerSource:OnLoad(data)
	if data then
		if data.is_turnon and not self:IsTurnOn() then
			self:TurnOn()
		end
	end
end

return PowerSource