event void FPrisonBossHackableMagneticProjectileExplosionEvent(bool bHitBoss);
event void FPrisonBossHackableMagneticProjectileHackedEvent();

UCLASS(Abstract)
class APrisonBossHackableMagneticProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	USphereComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	URemoteHackingResponseComponent RemoteHackingResponseComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"PrisonBossHackableMagneticProjectileMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FPrisonBossHackableMagneticProjectileExplosionEvent OnExploded;

	UPROPERTY()
	FPrisonBossHackableMagneticProjectileHackedEvent OnHacked;

	FVector Direction;
	FVector Velocity;
	float Gravity = 5000.0;
	float MoveSpeed = 5000.0;

	float Lifetime = 0.0;

	AHazePlayerCharacter TargetPlayer;

	bool bMagnetBursted = false;
	bool bHoming = true;
	bool bHitBoss = false;

	float HomingSpeed = 1400.0;

	float Scale = 0.0;

	bool bHackInitialized = false;

	float HackedTime = 0.0;
	float HackedExplodeDelay = 6.0;

	bool bLaunched = false;
	bool bTimedOutAfterHack = false;

	FVector InitialHackedVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");

		TargetPlayer = Game::Mio;

		RemoteHackingResponseComp.OnLaunchStarted.AddUFunction(this, n"HackLaunchStarted");
		RemoteHackingResponseComp.OnHackingStarted.AddUFunction(this, n"Hacked");

		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Game::Mio);
		PlayerHealthComp.OnDeathTriggered.AddUFunction(this, n"PlayerDied");

		UPrisonBossHackableMagneticProjectileEffectEventHandler::Trigger_Spawned(this);
	}

	void Launch()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		bLaunched = true;

		RemoteHackingResponseComp.SetHackingAllowed(true);
		BP_Launched();

		UPrisonBossHackableMagneticProjectileEffectEventHandler::Trigger_Launched(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Launched() {}

	UFUNCTION()
	private void HackLaunchStarted(FRemoteHackingLaunchEventParams LaunchParams)
	{
		bHackInitialized = true;
		InitialHackedVelocity = (ActorLocation - Game::Mio.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		UPrisonBossHackableMagneticProjectileEffectEventHandler::Trigger_HackInitialized(this);
	}

	UFUNCTION()
	private void Hacked()
	{
		OnHacked.Broadcast();

		BP_Hacked();

		UPrisonBossHackableMagneticProjectileEffectEventHandler::Trigger_Hacked(this);

		CollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Hacked() {}

	UFUNCTION()
	private void PlayerDied()
	{
		if (RemoteHackingResponseComp.IsHacked())
		{
			URemoteHackingPlayerComponent PlayerComp = URemoteHackingPlayerComponent::Get(Game::Mio);
			PlayerComp.StopHacking();

			Destroy(false);
		}
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		if (bMagnetBursted)
			return;
		if (bTimedOutAfterHack)
			return;

		if (!Game::Zoe.HasControl())
			return;

		FVector Dir = (ActorLocation - Data.ForceOrigin).GetSafeNormal();

		Dir.Z = 0.1;
		FVector TargetLoc = ActorLocation + (Dir * 2000.0);
		
		FVector ConstrainedForceDirection = Dir.ConstrainToPlane(FVector::UpVector);

		APrisonBoss BossActor = TListedActors<APrisonBoss>().GetSingle();
		FVector DirToBoss = (BossActor.ActorLocation - ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		
		float Dot = ConstrainedForceDirection.DotProduct(DirToBoss);
		if (Dot >= 0.75)
		{
			TargetLoc = BossActor.ActorCenterLocation;
			bHitBoss = true;
		}

		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, TargetLoc, Gravity, MoveSpeed);
		Direction = Dir;

		CrumbMagnetBurst(ActorLocation, Velocity, Direction, bHitBoss);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMagnetBurst(FVector InLocation, FVector InVelocity, FVector InDirection, bool bInHitBoss)
	{
		if (bTimedOutAfterHack)
			return;

		ActorLocation = InLocation;
		bHitBoss = bInHitBoss;
		Velocity = InVelocity;
		Direction = InDirection;

		Lifetime = 0.0;
		bMagnetBursted = true;
		bHoming = false;

		SetActorTickEnabled(true);

		UPrisonBossHackableMagneticProjectileEffectEventHandler::Trigger_MagnetBursted(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Scale = Math::FInterpConstantTo(Scale, 1.0, DeltaTime, 2.0);
		SetActorScale3D(FVector(Scale));

		if (!bLaunched)
		{
			RotationRoot.AddWorldRotation(FRotator(270.0 * DeltaTime, 180.0 * DeltaTime, 120.0 * DeltaTime));
			return;
		}

		if (RemoteHackingResponseComp.IsHacked())
		{
			if (!bMagnetBursted)
			{
				HackedTime += DeltaTime;
				if (Game::Zoe.HasControl())
				{
					if (HackedTime >= HackedExplodeDelay && !bTimedOutAfterHack && Game::Mio.GetGodMode() != EGodMode::God)
					{
						CrumbTimedOutAfterHack();
					}
				}
			}
		}

		if (bMagnetBursted)
		{
			Velocity -= FVector(0.0, 0.0, Gravity) * DeltaTime;
			FVector DeltaVelocity = Velocity * DeltaTime + FVector(0, 0, Gravity) * Math::Square(DeltaTime) * 0.5;

			if (bHitBoss)
			{
				APrisonBoss BossActor = TListedActors<APrisonBoss>().GetSingle();
				FVector Loc = Math::VInterpConstantTo(ActorLocation, BossActor.ActorCenterLocation, DeltaTime, 6000.0);
				SetActorLocation(Loc);
				RotationRoot.AddWorldRotation(FRotator(270.0 * DeltaTime, 180.0 * DeltaTime, 120.0 * DeltaTime));

				if (ActorLocation.Distance(BossActor.ActorCenterLocation) <= 20.0)
				{
					if (Game::Zoe.HasControl())
						CrumbProjectileHit();
				}
			}
			else
			{
				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
				Trace.IgnorePlayers();
				Trace.IgnoreActor(this);
				Trace.UseSphereShape(50.0);
				
				FVector TraceLoc = ActorLocation;
				FHitResult HitResult = Trace.QueryTraceSingle(TraceLoc, TraceLoc + DeltaVelocity);
				if (HitResult.bBlockingHit)
				{
					if (Game::Zoe.HasControl())
						CrumbProjectileHit();
					return;
				}

				AddActorWorldOffset(DeltaVelocity);
				RotationRoot.AddWorldRotation(FRotator(270.0 * DeltaTime, 180.0 * DeltaTime, 120.0 * DeltaTime));
			}

			Lifetime += DeltaTime;
			if (Lifetime >= 1.0 && Game::Zoe.HasControl())
				CrumbDestroy();
		}

		if (RemoteHackingResponseComp.IsHacked())
			return;

		if (bHoming)
		{
			FVector TargetLoc = TargetPlayer.ActorLocation + (FVector::UpVector * 120.0);
			FVector Dir = (TargetLoc - ActorLocation).GetSafeNormal();

			float Speed = HomingSpeed;
			if (bHackInitialized)
			{
				float SpeedMultiplier = Math::GetMappedRangeValueClamped(FVector2D(400.0, 1600.0), FVector2D(0.2, 1.0), GetDistanceTo(TargetPlayer));
				Speed *= SpeedMultiplier;
			}

			AddActorWorldOffset(Dir * Speed * DeltaTime);
			RotationRoot.AddWorldRotation(FRotator(270.0 * DeltaTime, 180.0 * DeltaTime, 120.0 * DeltaTime));

			if (Game::Mio.HasControl())
			{
				if (!bHackInitialized)
				{
					if (ActorLocation.Equals(TargetLoc, 100.0))
					{
						CrumbExplode();
					}
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTimedOutAfterHack()
	{
		bTimedOutAfterHack = true;
		Game::Mio.KillPlayer(FPlayerDeathDamageParams(FVector::UpVector), DeathEffect);
	}

	UFUNCTION(CrumbFunction)
	void CrumbProjectileHit()
	{
		if (bHitBoss)
		{
			APrisonBoss BossActor = TListedActors<APrisonBoss>().GetSingle();
			BossActor.HitByProjectile();

			BossActor.OnHitByHackableMagneticProjectile.Broadcast();

			if (BossActor.HitsTaken >= 3)
			{
				Destroy(true);
				return;
			}
		}
			
		Destroy(false);
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode()
	{
		Explode();
		Destroy(false);
	}

	void Explode()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (ActorLocation.IsWithinDist(Player.ActorCenterLocation, 400.0))
			{
				FVector Dir = (Player.ActorLocation - ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
				Player.ApplyKnockdown(Dir * 500.0, 1.5);
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(Dir), DamageEffect, DeathEffect);
			}
		}
	}

	UFUNCTION()
	private void ReleaseFromBoss()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		bHoming = true;
		HomingSpeed *= 2;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDestroy()
	{
		Destroy(false);
	}

	UFUNCTION()
	void Destroy(bool bFinalHit)
	{
		RemoteHackingResponseComp.SetHackingAllowed(false);
		if (!bFinalHit)
		{
			FVector Impulse = -Velocity.GetSafeNormal().ConstrainToPlane(FVector::UpVector);
			Impulse *= 1800.0;
			Impulse += FVector::UpVector * 600.0;
			Game::Mio.AddMovementImpulse(FVector(Impulse));

			UPrisonBossHackableMagneticProjectileEffectEventHandler::Trigger_Exploded(this);
			BP_Destroy();
		}

		OnExploded.Broadcast(bHitBoss);
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}
}