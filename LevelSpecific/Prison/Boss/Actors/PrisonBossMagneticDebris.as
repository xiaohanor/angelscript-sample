event void FPrisonBossMagneticDebrisEvent(APrisonBossMagneticDebris Debris, bool bHitBoss);

UCLASS(Abstract)
class APrisonBossMagneticDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeOffsetComponent OffsetComponent;

	UPROPERTY(DefaultComponent, Attach = OffsetComponent)
	USceneComponent DebrisRoot;

	UPROPERTY(DefaultComponent, Attach = DebrisRoot)
	UNiagaraComponent TargetingVFX;

	UPROPERTY(DefaultComponent)
	UWidgetComponent TargetWidgetComp;
	default TargetWidgetComp.bHiddenInGame = true;
	default TargetWidgetComp.bDrawAtDesiredSize = true;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RespawnTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UOutlineDataAsset OutlineDataAsset;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BossDeflectAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike AttachToBossTimeLike;
	default AttachToBossTimeLike.Duration = 0.1;
	FVector AttachToBossStartLoc;

	UPROPERTY(EditAnywhere)
	bool bDisableOnDestroy = false;
	bool bOverrideDisable = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FPrisonBossMagneticDebrisEvent OnExploded;

	FVector Direction;
	FVector Velocity;
	float Gravity = 3000.0;
	float MoveSpeed = 8000.0;

	float Lifetime = 0.0;

	AHazePlayerCharacter TargetPlayer;

	bool bMagnetBursted = false;
	bool bHitBoss = false;
	bool bDeflectedByBoss = false;
	int CurrentBossDeflectAmount = 0;
	UPROPERTY(EditAnywhere)
	int MaxBossDeflectAmount = 2;

	bool bLaunched = false;
	FVector LaunchDirection = FVector::ZeroVector;
	float LaunchSpeed = 2200.0;
	float DefaultLaunchSpeed;
	float LaunchSlowdownTimeRemaining = 0.0;

	// How long we can magnetize burst too early but still hit the magnetic debris actor back
	const float MagnetBurstTooEarlyForgivenessWindow = 0.4;

	FTransform OriginalTransform;

	APrisonBoss BossActor;

	bool bTargetWidgetEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		BossActor = TListedActors<APrisonBoss>().GetSingle();

		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"OnMagnetBursted");

		TargetPlayer = Game::Zoe;

		AttachToBossTimeLike.BindUpdate(this, n"UpdateAttachToBoss");

		OriginalTransform = ActorTransform;

		DefaultLaunchSpeed = LaunchSpeed;

		RespawnTimeLike.BindUpdate(this, n"UpdateRespawn");
		RespawnTimeLike.BindFinished(this, n"FinishRespawn");

		TargetWidgetComp.SetRenderedForPlayer(Game::Zoe, false);

		TargetingVFX.SetRenderedForPlayer(Game::Zoe, false);
	}

	UFUNCTION()
	private void UpdateRespawn(float CurValue)
	{
		float Offset = Math::Lerp(400.0, 0.0, CurValue);
		DebrisRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));

		DebrisRoot.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION()
	private void FinishRespawn()
	{
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateAttachToBoss(float CurValue)
	{
		FVector Loc = Math::Lerp(AttachToBossStartLoc, FVector(160.0, 0.0, 0.0), CurValue);
		SetActorRelativeLocation(Loc);
	}

	void Launch(FVector Location, FVector Dir, bool bLaunchedByBoss)
	{
		if (ActorLocation.Distance(Location) > 1.0)
			OffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.2);
		SetActorLocation(Location);

		CurrentBossDeflectAmount = 0;
		LaunchSpeed = DefaultLaunchSpeed;
		LaunchDirection = Dir;
		bLaunched = true;
		SetActorTickEnabled(true);

		if (bLaunchedByBoss)
			UPrisonBossMagneticDebrisEffectEventHandler::Trigger_LaunchedByBoss(this);
		else
			UPrisonBossMagneticDebrisEffectEventHandler::Trigger_LaunchedByPlayer(this);
	}

	void SlowdownLaunchForNetworkCatchup()
	{
		if (Network::IsGameNetworked())
		{
			LaunchSlowdownTimeRemaining =
				Time::GetEstimatedCrumbRoundtripDelay() * 5.0 // Ping and Crumb Trail Delay
				+ 0.25 // Compensate for acceleration lerping back up
			;
		}
	}

	UFUNCTION()
	private void OnMagnetBursted(FMagneticFieldData Data)
	{
		if (bMagnetBursted)
			return;
		if (!HasControl())
			return;

		TriggerMagnetBurst(Data.ForceOrigin);
	}

	private void TriggerMagnetBurst(FVector ForceOrigin)
	{
		if (BossActor == nullptr)
			BossActor = TListedActors<APrisonBoss>().GetSingle();

		FVector Dir = (ActorLocation - ForceOrigin).GetSafeNormal();

		Dir.Z = 0.1;
		FVector TargetLoc = ActorLocation + (Dir * 2000.0);
		
		FVector ConstrainedForceDirection = Dir.ConstrainToPlane(FVector::UpVector);

		FVector DirToBoss = (BossActor.ActorLocation - ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		
		float Dot = ConstrainedForceDirection.DotProduct(DirToBoss);
		if (Dot >= 0.5)
		{
			TargetLoc = BossActor.ActorCenterLocation;
			bHitBoss = true;
		}

		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, TargetLoc, Gravity, MoveSpeed);
		Direction = Dir;
		CrumbMagnetBursted(ActorLocation, Direction, Velocity, bHitBoss);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMagnetBursted(FVector NewLocation, FVector NewDirection, FVector NewVelocity, bool InHitBoss)
	{
		if (ActorLocation.Distance(NewLocation) > 1.0 && !HasControl())
			OffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.2);

		Lifetime = 0.0;
		bLaunched = false;
		bMagnetBursted = true;
		LaunchSlowdownTimeRemaining = 0.0;

		bHitBoss = InHitBoss;
		SetActorLocation(NewLocation);
		Velocity = NewVelocity;
		Direction = NewDirection;
		SetActorTickEnabled(true);
		
		UPrisonBossMagneticDebrisEffectEventHandler::Trigger_MagnetBursted(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (BossActor == nullptr)
			BossActor = TListedActors<APrisonBoss>().GetSingle();

		if (HasControl() && !bMagnetBursted && bLaunched)
		{
			// If we get close enough to the player to be magnet bursted and the player has bursted recently,
			// then count the debris as having been bursted
			auto FieldComp = UMagneticFieldPlayerComponent::Get(Game::Zoe);
			if (FieldComp.HasRecentlyMagnetizeBursted(MagnetBurstTooEarlyForgivenessWindow))
			{
				FVector FieldCenter = FieldComp.GetMagneticFieldCenterPoint();
				float DistanceToField = ActorLocation.Distance(FieldCenter);
				if (DistanceToField < MagneticField::GetTotalRadius() + 120.0)
				{
					TriggerMagnetBurst(FieldCenter);
				}
			}
		}

		if (bLaunched)
		{
			FVector DeltaMove = LaunchDirection * LaunchSpeed * DeltaTime;

			// Slow down the launch movement to let the network catch up
			if (LaunchSlowdownTimeRemaining > 0.0)
			{
				DeltaMove *= Math::Lerp(1.0, 0.8, Math::Saturate(LaunchSlowdownTimeRemaining / 0.5));
				LaunchSlowdownTimeRemaining -= DeltaTime;
			}

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(BossActor);
			Trace.IgnoreActor(this);
			Trace.UseSphereShape(100.0);
			
			FVector TraceLoc = ActorLocation;
			FHitResult HitResult = Trace.QueryTraceSingle(TraceLoc, TraceLoc + DeltaMove);
			if (HitResult.bBlockingHit)
			{
				if (HasControl())
				{
					CrumbExplode(HitResult.Location);
					return;
				}
			}

			AddActorWorldOffset(DeltaMove);

			Lifetime += DeltaTime;
			if (Lifetime >= 2.2 && HasControl())
				CrumbExplode(ActorLocation);

			float Scale = Math::FInterpConstantTo(ActorScale3D.X, 1.0, DeltaTime, 2.0);
			SetActorScale3D(FVector(Scale));

			FVector AngularVelocity =  LaunchDirection.CrossProduct(FVector::UpVector);
			float RotationSpeed = 10.0;
			const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
			DebrisRoot.AddWorldRotation(DeltaQuat);

			TEMPORAL_LOG(this)
				.Point("Position", DebrisRoot.WorldLocation)
				.Value("LaunchSlowdownTimeRemaining", LaunchSlowdownTimeRemaining)
			;
		}

		else if (bMagnetBursted)
		{
			if (bHitBoss)
			{
				FVector Loc = Math::VInterpConstantTo(ActorLocation, BossActor.ActorCenterLocation, DeltaTime, 6000.0);
				SetActorLocation(Loc);

				FVector Dir = (BossActor.ActorCenterLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				FVector AngularVelocity =  Dir.CrossProduct(FVector::UpVector);
				float RotationSpeed = 20.0;
				const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
				DebrisRoot.AddWorldRotation(DeltaQuat);

				if (ActorLocation.Distance(BossActor.ActorCenterLocation) <= 500.0)
				{
					if (HasControl())
					{
						if (BossActor.bDeflectProjectiles)
						{
							if (CurrentBossDeflectAmount >= MaxBossDeflectAmount)
								CrumbHitBoss(ActorLocation);
							else
								CrumbDeflect();
						}
						else
						{
							CrumbHitBoss(ActorLocation);
						}
					}
				}
			}
			else
			{
				Velocity -= FVector(0.0, 0.0, Gravity) * DeltaTime;
				FVector DeltaVelocity = Velocity * DeltaTime;

				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
				Trace.IgnorePlayers();
				Trace.IgnoreActor(this);
				Trace.UseSphereShape(50.0);
				
				FVector TraceLoc = ActorLocation;
				FHitResult HitResult = Trace.QueryTraceSingle(TraceLoc, TraceLoc + DeltaVelocity);
				if (HitResult.bBlockingHit && HasControl())
				{
					CrumbDestroy(HitResult.Location);
					return;
				}

				AddActorWorldOffset(DeltaVelocity);

				FVector AngularVelocity =  DeltaVelocity.CrossProduct(FVector::UpVector);
				float RotationSpeed = 20.0;
				const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
				DebrisRoot.AddWorldRotation(DeltaQuat);
			}

			Lifetime += DeltaTime;
			if (Lifetime >= 2.0 && HasControl())
				CrumbDestroy(ActorLocation);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode(FVector Location)
	{
		if (ActorLocation.Distance(Location) > 1.0 && !HasControl())
			OffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.2);

		SetActorLocation(Location);
		Explode();
		Destroy();
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

	UFUNCTION(CrumbFunction)
	void CrumbDeflect()
	{
		BossActor.SetAnimBoolParam(n"Deflect", true);
		BossActor.bIsDeflecting = true;
		bLaunched = false;
		bMagnetBursted = false;
		bHitBoss = false;
		Lifetime = 0.0;
		bDeflectedByBoss = true;
		CurrentBossDeflectAmount++;

		FName AttachSocket = BossActor.bHacked ? n"LeftAttach" : n"Align";
		AttachToComponent(BossActor.Mesh, AttachSocket, EAttachmentRule::KeepWorld);
		AttachToBossStartLoc = ActorRelativeLocation;
		AttachToBossTimeLike.PlayFromStart();

		float DetachDelay = BossActor.bHacked ? PrisonBoss::TakeControlGrabDebrisDeflectDetachDelay : PrisonBoss::GrabDebrisDeflectDetachDelay;
		Timer::SetTimer(this, n"ReleaseFromBoss", DetachDelay);

		UPrisonBossEffectEventHandler::Trigger_GrabDebrisDeflect(BossActor);

		if (BossActor.bHacked)
			UPrisonBossMagneticDebrisEffectEventHandler::Trigger_DeflectedByPlayer(this);
		else
			UPrisonBossMagneticDebrisEffectEventHandler::Trigger_DeflectedByBoss(this);
	}

	UFUNCTION()
	private void ReleaseFromBoss()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		Lifetime = 0.0;
		LaunchSpeed *= 1.2;
		LaunchDirection = ((Game::Zoe.ActorCenterLocation + (FVector::UpVector * 30.0)) - ActorLocation).GetSafeNormal();
		bLaunched = true;
		BossActor.bIsDeflecting = false;

		if (BossActor.bHacked)
			UPrisonBossEffectEventHandler::Trigger_TakeControlDeflectThrow(BossActor);
		else
			UPrisonBossEffectEventHandler::Trigger_GrabDebrisDeflectThrow(BossActor);

	}

	UFUNCTION(CrumbFunction)
	void CrumbHitBoss(FVector Location)
	{
		if (ActorLocation.Distance(Location) > 1.0 && !HasControl())
			OffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.2);

		SetActorLocation(Location);
		BossActor.HitByDeflectedProjectile();
		Destroy();
	}

	UFUNCTION(CrumbFunction)
	void CrumbDestroy(FVector Location)
	{
		if (ActorLocation.Distance(Location) > 1.0 && !HasControl())
			OffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.2);

		SetActorLocation(Location);
		Destroy();
	}

	UFUNCTION()
	void Destroy()
	{
		OnExploded.Broadcast(this, bHitBoss);
		BP_Destroy();
		Reset();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}

	void Reset()
	{
		SetActorTickEnabled(false);
		bHitBoss = false;
		Lifetime = 0.0;
		bDeflectedByBoss = false;
		bMagnetBursted = false;
		bLaunched = false;
		SetActorTransform(OriginalTransform);
		DebrisRoot.SetRelativeRotation(FRotator::ZeroRotator);
		DebrisRoot.SetRelativeLocation(FVector(0.0, 0.0, 0.0));

		if (bDisableOnDestroy)
		{
			if (!bOverrideDisable)
				AddActorDisable(this);
			else
				Respawn();
		}
		else
		{
			Respawn();
		}

		bOverrideDisable = false;
	}

	void Respawn()
	{
		RespawnTimeLike.PlayFromStart();
	}

	void SetTargetWidgetEnabled(bool bEnabled)
	{
		if (bTargetWidgetEnabled == bEnabled)
			return;

		bTargetWidgetEnabled = bEnabled;
		TargetWidgetComp.SetHiddenInGame(!bEnabled);

		if (bEnabled)
			TargetingVFX.Activate();
		else
			TargetingVFX.Deactivate();
	}
}