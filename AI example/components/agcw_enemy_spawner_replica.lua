local EnemySpawner = Class(function(self, inst)
    self.inst = inst

	self.current_turn = net_byte(inst.GUID, "agcw_enemy_spawner.current_turn", "agcw_enemy_spawner.current_turn")
	self.current_turn:set(0)
	self.is_started = net_bool(inst.GUID, "agcw_enemy_spawner.is_started", "agcw_enemy_spawner.is_started")
	self.is_started:set(false)
end)

function EnemySpawner:CanStart()
	return not self.is_started:value()
end

function EnemySpawner:Start()
	if TheWorld.ismastersim then
		self.is_started:set(true)
		self.current_turn:set(self.current_turn:value() + 1)
	end
end

function EnemySpawner:Stop()
	if TheWorld.ismastersim then
		self.is_started:set(false)
	end
end

function EnemySpawner:GetCurrentTurn()
	return self.current_turn:value()
end

function EnemySpawner:IsStarted()
	return self.is_started:value()
end

return EnemySpawner