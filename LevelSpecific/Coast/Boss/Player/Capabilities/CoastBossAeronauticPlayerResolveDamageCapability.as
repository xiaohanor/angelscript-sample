class UCoastBossAeronauticPlayerResolveDamageCapability : UHazePlayerCapability
{
	// Simluated locally on both sides.
	// Player control decides if it takes damage
	// Boss control side decides when drones die, since they use so many shots to take down anyways

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UCoastBossAeronauticComponent AeroComp;
	ACoastBoss Boss;
	ACoastBossActorReferences References;

	const float DebugKillDronesTime = 1.5;
	float DebugKillDronesCooldown = DebugKillDronesTime;
	TMap<AHazeActor, float> TimeOfLastLaserHit;
	float QueuedDamage = 0.0;
	float TimeOfDamage = 0.0;

	FVector ShipCenterLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AeroComp = UCoastBossAeronauticComponent::Get(Player);
		CoastBossDevToggles::Draw::DrawDebugCollisions.MakeVisible();
		CoastBossDevToggles::AutoKillDrones.MakeVisible();
		CoastBossDevToggles::KillAnyDrones.MakeVisible();
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AeroComp.AttachedToShip == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheBoss())
			return;

		ShipCenterLocation = AeroComp.AttachedToShip.InvulnerableShield.WorldLocation;

		AeroComp.InvincibleFramesCooldown -= DeltaTime;
		DebugKillDronesCooldown -= DeltaTime;

		BossVSPlayer();
		PlayerVSBoss();
		if (HasControl())
		{
			PlayerVSPickups();
		}
	}

	void BossVSPlayer()
	{
		if(Player.IsPlayerDead())
			return;

		float PlayerRadius = AeroComp.bPlayerInvulnerable ? AeroComp.InvulnerablePlayerCollisionRadius : AeroComp.PlayerCollisionRadius;
		const float BulletDamageOnPlayer = 0.6;

		if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
			Debug::DrawDebugSphere(ShipCenterLocation, PlayerRadius, 12, Player.GetPlayerUIColor(), 5.0, 0.0, true);

		if (CoastBossDevToggles::UseManyDrones.IsEnabled())
		{
			for (int iDrone = 0; iDrone < Boss.DroneActors.Num(); ++iDrone)
			{
				ACoastBossDroneActor Drone = Boss.DroneActors[iDrone];
				if (Drone.bDead)
					continue;
				// HURT PLAYERZ
				if (Drone.ActorLocation.Distance(ShipCenterLocation) < CoastBossConstants::ManyDronesBoss::DroneCollisionRadius + PlayerRadius)
					AeroComp.TryDamagePlayer(3.0, ECoastBossAeuronauticPlayerReceiveDamageType::DroneCollision);
			}
		}
		else
		{
			if (!Boss.bDead && Boss.ActorLocation.Distance(ShipCenterLocation) < PlayerRadius + CoastBossConstants::BigDroneBoss::BigBossCollisionHitPlayersRadius)
				AeroComp.TryDamagePlayer(3.0, ECoastBossAeuronauticPlayerReceiveDamageType::DroneCollision);
		}

		// BALLZ
		for (int iBall = 0; iBall < Boss.ActiveBalls.Num(); ++iBall)
		{
			ACoastBossBulletBall Ball = Boss.ActiveBalls[iBall];
			if (!Ball.bDangerous)
				continue;
			if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
				Debug::DrawDebugSphere(Ball.ActorLocation, Ball.BallData.CollisionRadius, 12, ColorDebug::Ruby, 5.0, 0.0, true);
			if (Ball.ActorLocation.Distance(ShipCenterLocation) < PlayerRadius + Ball.BallData.CollisionRadius)
			{
				AeroComp.TryDamagePlayer(BulletDamageOnPlayer, ECoastBossAeuronauticPlayerReceiveDamageType::Bullet);
				Boss.SendHitBall(Ball.ID);
			}
		}

		// AUTO BALLZ
		for (int iBall = 0; iBall < Boss.ActiveAutoBalls.Num(); ++iBall)
		{
			ACoastBossBulletBall Ball = Boss.ActiveAutoBalls[iBall];
			if (!Ball.bDangerous)
				continue;
			if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
				Debug::DrawDebugSphere(Ball.ActorLocation, Ball.BallData.CollisionRadius, 12, ColorDebug::Ruby, 5.0, 0.0, true);
			if (Ball.ActorLocation.Distance(ShipCenterLocation) < PlayerRadius + Ball.BallData.CollisionRadius)
			{
				AeroComp.TryDamagePlayer(BulletDamageOnPlayer, ECoastBossAeuronauticPlayerReceiveDamageType::Bullet);
				Boss.SendHitBall(Ball.ID);
			}
		}

		// MINEZ
		for (int iMine = 0; iMine < Boss.ActiveMines.Num(); ++iMine)
		{
			ACoastBossBulletMine Mine = Boss.ActiveMines[iMine];
			if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
				Debug::DrawDebugSphere(Mine.ActorLocation, Mine.MineData.CollisionRadius, 12, ColorDebug::Ruby, 5.0, 0.0, true);

			if (Mine.MineData.bDetonated)
				continue;
			if (!Mine.bIsDangerous)
				continue;
			
			bool bPlayerTriggered = Mine.ActorLocation.Distance(ShipCenterLocation) < PlayerRadius + Mine.MineData.CollisionRadius || Mine.MineData.bPlayerBulletHit;
			bool bTimedOut = Mine.AliveDuration > Mine.MaxAliveTime;
			if (bTimedOut || bPlayerTriggered)
			{
				if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
					Debug::DrawDebugSphere(Mine.ActorLocation, CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_MineExplosionRadius, 12, ColorDebug::Ruby, 5.0, 0.0, true);
				
				Boss.SendMineExplode(Mine.ID);
			}
		}

		// MILLZ
		for (int iMill = 0; iMill < Boss.ActiveMills.Num(); ++iMill)
		{
			ACoastBossBulletMill Mill = Boss.ActiveMills[iMill];
			float MillRadius = Mill.AccScale.Value * 100.0;
			if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
			{
				Debug::DrawDebugSphere(Mill.ActorLocation, Mill.MillData.WeakpointRadius, 12, ColorDebug::Ruby);
				for (int iBlade = 0; iBlade < Mill.MillData.MillBlades.Num(); ++iBlade)
				{
					FVector EndLocation = Mill.MillData.MillBlades[iBlade].WorldLocation + Mill.MillData.MillBlades[iBlade].WorldRotation.ForwardVector * MillRadius;
					Debug::DrawDebugLine(Mill.MillData.MillBlades[iBlade].WorldLocation, EndLocation, ColorDebug::Ruby, 10.0, 0.0, true);
				}
			}

			if (Mill.ActorLocation.Distance(ShipCenterLocation) < Mill.MillData.WeakpointRadius)
			{
				AeroComp.TryDamagePlayer(BulletDamageOnPlayer, ECoastBossAeuronauticPlayerReceiveDamageType::MillZap);
				if (Mill.ImpactVFX != nullptr)
					Niagara::SpawnOneShotNiagaraSystemAttached(Mill.ImpactVFX, Player.MeshOffsetComponent);
			}

			// cull
			if (Mill.ActorLocation.Distance(ShipCenterLocation) < MillRadius)
			{
				// trace!
				for (int iBlade = 0; iBlade < Mill.MillData.MillBlades.Num(); ++iBlade)
				{
					if (Math::LineSphereIntersection(Mill.ActorLocation, Mill.MillData.MillBlades[iBlade].WorldRotation.ForwardVector, MillRadius, ShipCenterLocation, PlayerRadius))
					{
						AeroComp.TryDamagePlayer(BulletDamageOnPlayer, ECoastBossAeuronauticPlayerReceiveDamageType::MillZap);
						if (Mill.ImpactVFX != nullptr)
							Niagara::SpawnOneShotNiagaraSystemAttached(Mill.ImpactVFX, Player.MeshOffsetComponent);
					}
				}
			}
		}
	}

	void PlayerVSBoss()
	{
		bool bKillAliveDroneThisFrame = (DebugKillDronesCooldown < 0.0 && CoastBossDevToggles::KillAnyDrones.IsEnabled());
		if (bKillAliveDroneThisFrame)
			DebugKillDronesCooldown = DebugKillDronesTime;

		float DroneRadius = 110.0;
		if (!Boss.bDead)
		{
			FVector HitLocation;
			float OutDamage = 0.0;
			AHazeActor OutWeaponActor;
			if (PlayerWeaponHitSphere(Boss, Boss.ActorLocation, CoastBossConstants::BigDroneBoss::BigBossCollisionPlayersHitBulletRadius, HitLocation, OutDamage, OutWeaponActor))
			{
				FCoastBossAeuronauticBossReceiveDamageData BossImpactParams;
				ACoastBossPlayerBullet Bullet = Cast<ACoastBossPlayerBullet>(OutWeaponActor);
				if(Bullet != nullptr)
				{
					FCoastBossPlayerBulletOnImpactParams Params;
					Params.HitLocation = HitLocation;
					Params.PlaneToAttachTo = References.CoastBossPlane2D.Root;
					UCoastBossPlayerBulletEffectHandler::Trigger_OnImpact(OutWeaponActor, Params);	

					if(Bullet.bIsHomingBullet)
						BossImpactParams.DamageType = ECoastBossAeuronauticBossReceiveDamageType::HomingProjectile;
					else if(Bullet.DamageMultiplier == CoastBossConstants::PowerUp::BarrageDamageMultiplier)
						BossImpactParams.DamageType = ECoastBossAeuronauticBossReceiveDamageType::BarrageProjectile;
				}
				else
				{
					FCoastBossPlayerLaserOnImpactTickEffectParams Params;
					Params.HitLocation = HitLocation;
					Params.PlaneToAttachTo = References.CoastBossPlane2D.Root;
					UCoastBossPlayerLaserEffectHandler::Trigger_OnImpactTick(OutWeaponActor, Params);
					BossImpactParams.DamageType = ECoastBossAeuronauticBossReceiveDamageType::Laser;
				}
				

				UCoastBossAeuronauticPlayerEventHandler::Trigger_OnPlayerProjectileImpactBoss(Player, BossImpactParams);

				if(HasControl())
					QueuedDamage += OutDamage;
			}
		}

		if(QueuedDamage > 0.0 && (!Network::IsGameNetworked() || Time::GetGameTimeSince(TimeOfDamage) > 0.1))
		{
			if(Boss.HasControl())
				Boss.DamageBoss(QueuedDamage);
			else
				NetDamageBoss(QueuedDamage);
			
			TimeOfDamage = Time::GetGameTimeSeconds();
			QueuedDamage = 0.0;
		}

		for (int iMine = 0; iMine < Boss.ActiveMines.Num(); ++iMine)
		{
			ACoastBossBulletMine Mine = Boss.ActiveMines[iMine];
			if (Mine.MineData.bDetonated || !Mine.bIsDangerous)
				continue;

			FVector HitLocation;
			float Damage;
			ACoastBossPlayerBullet Bullet;
			ACoastBossPlayerLaser Laser;
			if (PlayerLaserHitSphere(Mine, Mine.ActorLocation, Mine.MineData.CollisionRadius, HitLocation, Damage, Laser))
			{
				Mine.Health -= Mine.Health;
				Mine.MineData.bPlayerBulletHit = true;

				if(HasControl())
					Boss.SendMineExplode(Mine.ID);
			}
			else if (PlayerBulletHitSphere(Mine, Mine.ActorLocation, Mine.MineData.CollisionRadius, HitLocation, Damage, Bullet))
			{
				Mine.Health -= 1.0;
				if (Mine.Health < KINDA_SMALL_NUMBER)
				{
					Mine.MineData.bPlayerBulletHit = true;

					if(HasControl())
						Boss.SendMineExplode(Mine.ID);
				}
				else
				{
					FCoastBossPlayerBulletOnImpactParams Params;
					Params.HitLocation = HitLocation;
					Params.PlaneToAttachTo = References.CoastBossPlane2D.Root;
					UCoastBossPlayerBulletEffectHandler::Trigger_OnImpact(Bullet, Params);
				}
			}
		}

		if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
		{
			if (CoastBossDevToggles::UseManyDrones.IsEnabled())
			{
				for (int iDrone = 0; iDrone < Boss.DroneActors.Num(); ++iDrone)
				{
					if (!Boss.DroneActors[iDrone].bDead)
						Debug::DrawDebugSphere(Boss.DroneActors[iDrone].ActorLocation, DroneRadius, 12, ColorDebug::Cyan, 5.0, 0.0, true);
				}
			}
			else if (!Boss.bDead)
			{
				Debug::DrawDebugSphere(Boss.ActorLocation, CoastBossConstants::BigDroneBoss::BigBossCollisionHitPlayersRadius, 12, ColorDebug::Ruby, 5.0, 0.0, true);
				Debug::DrawDebugSphere(Boss.ActorLocation, CoastBossConstants::BigDroneBoss::BigBossCollisionPlayersHitBulletRadius, 12, ColorDebug::Cyan, 5.0, 0.0, true);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetDamageBoss(float Damage)
	{
		if(!Boss.HasControl())
			return;

		Boss.DamageBoss(Damage);
	}

	bool PlayerWeaponHitSphere(AHazeActor SphereOwner, FVector SphereLocation, float SphereRadius, FVector&out OutHitLocation, float&out OutDamage, AHazeActor&out OutWeaponActor)
	{
		ACoastBossPlayerLaser OutLaser;
		ACoastBossPlayerBullet OutBullet;
		bool bResult = PlayerLaserHitSphere(SphereOwner, SphereLocation, SphereRadius, OutHitLocation, OutDamage, OutLaser) || PlayerBulletHitSphere(SphereOwner, SphereLocation, SphereRadius, OutHitLocation, OutDamage, OutBullet);
		OutWeaponActor = OutLaser != nullptr ? OutLaser : OutBullet;
		return bResult;
	}

	bool PlayerBulletHitSphere(AHazeActor SphereOwner, FVector SphereLocation, float SphereRadius, FVector&out OutHitLocation, float&out OutDamage, ACoastBossPlayerBullet&out OutBullet)
	{
		for (int iBullet = 0; iBullet < AeroComp.ActiveBullets.Num(); ++iBullet)
		{
			ACoastBossPlayerBullet PlayerBullet = AeroComp.ActiveBullets[iBullet];
			if (PlayerBullet.bShouldDespawn)
				continue;

			if(PlayerBullet.HitActors.Contains(SphereOwner))
				continue;

			if (SphereLocation.Distance(PlayerBullet.ActorLocation) < SphereRadius)
			{
				PlayerBullet.bShouldDespawn = ShouldBulletDespawn(PlayerBullet, SphereOwner);
				PlayerBullet.HitActors.Add(SphereOwner);
				OutHitLocation = PlayerBullet.ActorLocation;
				OutDamage = CoastBossConstants::Player::PlayerBulletDamage * AeroComp.DamageMultiplier * PlayerBullet.DamageMultiplier;
				OutBullet = PlayerBullet;
				return true;
			}
		}

		return false;
	}

	bool ShouldBulletDespawn(ACoastBossPlayerBullet Bullet, AHazeActor HitActor)
	{
		// if(Bullet.bIsHomingBullet && !HitActor.IsA(ACoastBoss))
		// 	return false;

		return true;
	}

	bool PlayerLaserHitSphere(AHazeActor SphereOwner, FVector SphereLocation, float SphereRadius, FVector&out OutHitLocation, float&out OutDamage, ACoastBossPlayerLaser&out OutLaser)
	{
		if(!AeroComp.bLaserActive)
			return false;

		FVector LaserOrigin = AeroComp.Laser.ActorLocation;
		FVector LaserDirection = AeroComp.Laser.ActorForwardVector;
		float DecreaseRadius = 0.0;

		if(SphereOwner.IsA(ACoastBoss))
		{
			DecreaseRadius = AeroComp.Laser.DecreaseRadiusForLaserBeamEnd;

			FLineSphereIntersection Intersection = Math::GetLineSegmentSphereIntersectionPoints(LaserOrigin, LaserOrigin + LaserDirection * 10000.0, SphereLocation, SphereRadius - DecreaseRadius);
			if(Intersection.bHasIntersection)
			{
				AeroComp.Laser.SetBeamEnd(Intersection.MinIntersection);

				if(!AeroComp.Laser.bCurrentlyHittingCoastBoss)
				{
					FCoastBossPlayerLaserStartImpactingEffectParams Params;
					Params.PlaneToAttachTo = References.CoastBossPlane2D.Root;
					Params.HitLocation = Intersection.MinIntersection;
					UCoastBossPlayerLaserEffectHandler::Trigger_OnStartImpactingCoastBoss(AeroComp.Laser, Params);
				}

				AeroComp.Laser.bCurrentlyHittingCoastBoss = true;
			}
			else
			{
				AeroComp.Laser.SetBeamEnd(AeroComp.Laser.ActorLocation + AeroComp.Laser.ActorForwardVector * 5000.0);
				
				if(AeroComp.Laser.bCurrentlyHittingCoastBoss)
				{
					FCoastBossPlayerLaserStopImpactingEffectParams Params;
					Params.PlaneToAttachTo = References.CoastBossPlane2D.Root;
					UCoastBossPlayerLaserEffectHandler::Trigger_OnStopImpactingCoastBoss(AeroComp.Laser, Params);
				}

				AeroComp.Laser.bCurrentlyHittingCoastBoss = false;
			}
		}
		
		if(TimeOfLastLaserHit.Contains(SphereOwner) && Time::GetGameTimeSince(TimeOfLastLaserHit[SphereOwner]) < CoastBossConstants::PowerUp::LaserPowerUpDamageCooldown)
			return false;

		FLineSphereIntersection Intersection = Math::GetLineSegmentSphereIntersectionPoints(LaserOrigin, LaserOrigin + LaserDirection * 10000.0, SphereLocation, SphereRadius - DecreaseRadius);
		if(Intersection.bHasIntersection)
		{
			OutHitLocation = Intersection.MinIntersection;
			OutDamage = CoastBossConstants::PowerUp::LaserPowerUpDamagePerSecond * CoastBossConstants::PowerUp::LaserPowerUpDamageCooldown * AeroComp.DamageMultiplier;
			OutLaser = AeroComp.Laser;
			TimeOfLastLaserHit.Add(SphereOwner, Time::GetGameTimeSeconds());
			
			return true;
		}

		return false;
	}

	void PlayerVSPickups()
	{
		if(Player.IsPlayerDead())
			return;

		for (auto PowerUp : References.PowerUps)
		{
			if (PowerUp.bActive && !PowerUp.bPlayerPicked)
			{
				if (PowerUp.ActorLocation.Distance(ShipCenterLocation) < CoastBossConstants::PowerUp::Radius + AeroComp.InvulnerablePlayerCollisionRadius)
				{
					PowerUp.TryPickup(Player);
				}
			}
			if (CoastBossDevToggles::Draw::DrawDebugCollisions.IsEnabled())
			{
				Debug::DrawDebugSphere(PowerUp.ActorLocation, CoastBossConstants::PowerUp::Radius, 12, ColorDebug::Cyan, 5.0, 0.0, true);
				Debug::DrawDebugSphere(ShipCenterLocation, AeroComp.InvulnerablePlayerCollisionRadius, 12, ColorDebug::Cyan, 5.0, 0.0, true);
			}
		}
	}

	bool TryCacheBoss()
	{
		TListedActors<ACoastBossActorReferences> Refs;
		if (Refs.Num() > 0)
		{
			Boss = Refs.Single.Boss;
		}
		return Boss != nullptr;
	}
};