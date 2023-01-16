if not DrGBase then return end -- Короче это залупа база где он прыгает бегает, не трогать!
ENT.Base = "drgbase_nextbot_sprite" -- Тоже не трогать! но как хотите это же спрайт

--Вся информация бота!--
ENT.PrintName = "Pirizuka" -- Имя нпс
ENT.Category = "SYRSA" -- Категория
ENT.ModelScale = 1
ENT.CollisionBounds = Vector(13, 13, 72)
ENT.BloodColor = BLOOD_COLOR_RED

ENT.Killicon = { --типа киил--
	icon = "sy/npc_sy_killicon2",
	color = Color(255, 255, 255, 255)
}

-- Звуки --
ENT.OnDamageSounds = {}
ENT.OnDeathSounds = {""}
ENT.OnIdleSounds = {""}
-- ХП --
ENT.SpawnHealth = 999999 -- HP

-- Атака --
ENT.RangeAttackRange = 10
ENT.MeleeAttackRange = 10
ENT.ReachEnemyRange = 10
ENT.AvoidEnemyRange = 0

-- Отношение --
ENT.Factions = {FACTION_LASTATION}
ENT.Frightening = true

-- Анимация и картинка --
--ENT.SpriteFolder = "sy"--
ENT.FramesPerSecond = 6
ENT.WalkAnimation = "walk"
ENT.WalkAnimRate = 1
ENT.RunAnimRate = 3
ENT.IdleAnimRate = 1
ENT.RunAnimation = "walk"
ENT.IdleAnimation = "idle"
ENT.JumpAnimation = "idle"

ENT.WalkSpeed = 520
ENT.RunSpeed = 720

-- Обнаружение --
ENT.EyeOffset = Vector(0, 0, 30)

-- Позиция или владение --
ENT.PossessionEnabled = true
ENT.PossessionMovement = POSSESSION_MOVE_1DIR
ENT.PossessionViews = {
  {
    offset = Vector(0, 30, 20),
    distance = 140
  },
  {
    offset = Vector(7.5, 0, 0),
    distance = 0,
    eyepos = true
  }
}
ENT.MaxYawRate = 200
ENT.PossessionBinds = {
  [IN_ATTACK] = {{
    coroutine = true,
    onkeydown = function(self)
      self:EmitSound("")
self:AttackForNpc()
      self:PlaySpriteAnimAndWait("attack", 1, self.PossessionFaceForward)
    end
}},
  [IN_JUMP] = {{
    coroutine = false,
    onkeydown = function(self)
   
self:Jump(600)
    end
  }}
}

if SERVER then

  -- Трайк --

  function ENT:CustomInitialize()
    self:SetDefaultRelationship(D_HT) -- D_HT это ненависть, D_LI это любовь, D_NU это игнор
  end
end

--Важная хрень как он называется, и картинка убийства--

if CLIENT then
killicon.Add("sy", "sy/npc_sy_killicon2", color_white)
language.Add("sy", "Pirizuka")

	local DRAW_OFFSET = 128 / 2 * Vector(0,0,1)

	local sy_npcMaterial = Material("sy/npc_sy.png") --сама картиночка где я ставляю
	function ENT:DrawTranslucent()
		render.SetMaterial(sy_npcMaterial) --материал


		local pos = self:GetPos() + DRAW_OFFSET
		local normal = EyePos() - pos
		normal:Normalize()
		local xyNormal = Vector(normal.x, normal.y, 0)
		xyNormal:Normalize()


		local pitch = math.acos(math.Clamp(normal:Dot(xyNormal), -1, 1)) / 3
		local cos = math.cos(pitch)
		normal = Vector(
			xyNormal.x * cos,
			xyNormal.y * cos,
			math.sin(pitch)
		)

		render.DrawQuadEasy(pos, normal, 128, 128,
			color_white, 180)
	end

	local developer = GetConVar("developer")
	local function DevPrint(devLevel, msg)
		if (developer:GetInt() >= devLevel) then
			print("npc_sy: " .. msg)
		end
	end
	
	local panicMusic = nil
	local lastPanic = 0 
	
	--Как убрать эти флажки? Да не как))))
	local npc_sy_music_volume = CreateConVar("npc_sy_music_volume", 1, bit.bor(FCVAR_CLIENTDLL, FCVAR_DEMO, FCVAR_ARCHIVE),
	                                                    "Maximum music volume when being chased by sy. (0-1, where 0 is muted)")

	local MUSIC_RESTART_DELAY = 2

	local MUSIC_CUTOFF_DISTANCE   = 8192
	local MUSIC_PANIC_DISTANCE    = 4096
	local MUSIC_DRGBOT_PANIC_COUNT = 8--
	
	local MUSIC_DRGBOT_MAX_DISTANCE_SCORE = (MUSIC_CUTOFF_DISTANCE - MUSIC_PANIC_DISTANCE) * MUSIC_DRGBOT_PANIC_COUNT
	
	local function updatePanicMusic()
		if (#ents.FindByClass("npc_sy") == 0) then

			DevPrint(4, "Halting music timer.")
			timer.Remove("syPanicMusicUpdate")

			if (panicMusic ~= nil) then
				panicMusic:Stop()
			end

			return
		end

		if (panicMusic == nil) then
			if (IsValid(LocalPlayer())) then
				panicMusic = CreateSound(LocalPlayer(), "npc_sy/panic.mp3") --Паника музыкы
				panicMusic:Stop()
			else
				return
			end
		end

		if (npc_sy_music_volume:GetFloat() <= 0 or not IsValid(LocalPlayer())) then
			panicMusic:Stop()
			return
		end

		local totalDistanceScore = 0
		local nearEntities = ents.FindInSphere(LocalPlayer():GetPos(), 4096)
		for _, ent in pairs(nearEntities) do
			if (IsValid(ent) and ent:GetClass() == "npc_sy") then
				local distanceScore = math.max(0, MUSIC_CUTOFF_DISTANCE - LocalPlayer():GetPos():Distance(ent:GetPos()))
				totalDistanceScore = totalDistanceScore + distanceScore
			end
		end

		local musicVolume = math.min(1, totalDistanceScore / MUSIC_DRGBOT_MAX_DISTANCE_SCORE)

        local shouldRestartMusic = (CurTime() - lastPanic >= MUSIC_RESTART_DELAY)
		if (musicVolume > 0) then
			if (shouldRestartMusic) then
				panicMusic:Play()
			end

			if (not LocalPlayer():Alive()) then
			
				musicVolume = musicVolume / 4
			end

			lastPanic = CurTime()
		elseif (shouldRestartMusic) then
			panicMusic:Stop()
			return
		else
			musicVolume = 0
		end

		musicVolume = math.max(0.01, musicVolume * math.Clamp(npc_sy_music_volume:GetFloat(), 0, 1))

		panicMusic:Play()
		panicMusic:ChangePitch(math.Clamp(game.GetTimeScale() * 100, 50, 255), 0) -- Просто для удовольствия.
		panicMusic:ChangeVolume(musicVolume, 0)
	end
 
    local function startTimer()
		if (not timer.Exists("syanicMusicUpdate")) then
			timer.Create("syanicMusicUpdate", 0.15, 0, updatePanicMusic)
			DevPrint(4, "Beginning music timer.")
		end
	end
	
	--хуйня1
	
    hook.Add("OnEntityCreated", "syInitialize", function(ent)
		if (not IsValid(ent)) then return end
		if (ent:GetClass() ~= "npc_sy") then return end

		local sy_npcEntTable = scripted_ents.GetStored("npc_sy")

		table.Merge(ent, sy_npcEntTable.t) --Типа что то взлома--
		ent:CallOnRemove("sy_removed", npc_syDeregister)
	end)

	hook.Add("NetworkEntityCreated", "syNetInit", function(ent)
		if (not IsValid(ent)) then return end
		if (ent:GetClass() ~= "npc_sy") then return end

		startTimer()
	end)
end
--типа что то по домагу--
   function ENT:OnMeleeAttack(enemy)
    self:EmitSound("npc_sy/damage.mp3") --sy/attack
self:AttackForNpc()
 self:PlaySpriteAnimAndWait("attack", 1, self.FaceEnemy)
  end

  function ENT:OnReachedPatrol()
self:PlaySpriteAnimAndWait("idle")
    self:Wait(math.random(3, 7))
self:PlaySpriteAnimAndWait("idle")
  end
  function ENT:OnIdle()
    self:AddPatrolPos(self:RandomPos(1500)) --Застявляет нпс ходить по кругу, ставьте ноль если вы не хотите
  end

  -- Дамаг --
  function ENT:OnDeath(dmg, delay, hitgroup)
 self:PlaySpriteAnimAndWait("death", 0.5, self.FaceEnemy)
  end
  
  function ENT:OnNewEnemy() 
    self:EmitSound("")
  end

  function ENT:AttackForNpc()
      self:Attack({
        damage = 7000,
        range = 100,
        type = DMG_SLASH,
        delay = 0,
        radius=600,
        force=Vector(800,100,100),
        viewpunch = Angle(20, math.random(-10, 10), 0),
      }, function(self, hit)
        if #hit > 0 then
          self:EmitSound("Zombie.AttackHit")
        else self:EmitSound("Zombie.AttackMiss") end
      end)
end

-- НЕ ПРИКАСАЙТЕСЬ --
AddCSLuaFile()
DrGBase.AddNextbot(ENT)