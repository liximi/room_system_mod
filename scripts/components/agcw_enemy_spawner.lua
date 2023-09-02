local function OnPlayerDeath(player)
	player.components.agcw_enemy_spawner:Stop()
end

local EnemySpawner = Class(function(self, inst)
    self.inst = inst

	self.period = 4
	self.time = self.period
	self.last_spawn_times = 10
	self.current_turn = 0
	self.is_started = false

	self.inst:ListenForEvent("death", OnPlayerDeath)
    -- self:Start()
end)


function EnemySpawner:SpawnEnemy()
	local enemy = "hound"

	for i, player in ipairs(AllPlayers) do
		local num = math.random(self.current_turn * 3, self.current_turn * 6)
		local radius = 20
		local pt = player:GetPosition()
		for j = 1, num do
			local pos = GetRandomPointRound(pt, radius)
			SpawnAt(enemy, pos)
		end
	end
end

function EnemySpawner:CanStart()
	return not self.is_started
end

function EnemySpawner:Start()
	if self:CanStart() then
		self.inst:StartUpdatingComponent(self, true)
		self.is_started = true
		self.current_turn = self.current_turn + 1
		self.inst.replica.agcw_enemy_spawner:Start()
	end
end

function EnemySpawner:Stop()
	self.inst:StopUpdatingComponent(self, true)
	self.is_started = false
	self.inst.replica.agcw_enemy_spawner:Stop()
end

--------------------------------------------------
-- Update
--------------------------------------------------

function EnemySpawner:OnUpdate(dt)
	self.time = self.time + dt

	if self.time >= self.period then
		self.time = 0
		self:SpawnEnemy()
		self.last_spawn_times = self.last_spawn_times - 1
		if self.last_spawn_times <= 0 then
			self.last_spawn_times = 10
			self:Stop()
		end
	end
end

return EnemySpawner