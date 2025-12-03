event void FSmallBossHitSignature();
event void FSmallRespawnShieldSignature();
event void FSmallBossDied();
class ASkylineBallBossSmallBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeDecalComponent BlobShadowDecalComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LaserRoot;

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	UCapsuleComponent LaserColComp;

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	UStaticMeshComponent LaserMeshComp;

	UPROPERTY(DefaultComponent, Attach = LaserColComp)
	UHazeCapsuleCollisionComponent LaserPassbyAudioCollisionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RollRoot;

	UPROPERTY(DefaultComponent, Attach = RollRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USkylineBallBossHealthBarComponent BallBossHealthBarComp;

	UPROPERTY(DefaultComponent, Attach = RollRoot)
	UGravityBladeCombatTargetComponent GravityBladeCombatTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeCombatResponseComponent;

	UPROPERTY(DefaultComponent, Attach = RollRoot)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapbilityComponent;
	default CapbilityComponent.DefaultSheets.Add(SkylineBallBossSmallBossJumpSheet);
	default CapbilityComponent.DefaultSheets.Add(SkylineBallBossSmallBossProjectileSheet);

	UPROPERTY(DefaultComponent)
	USkylineBallBossSmallBossJumpActionComponent JumpLoopComp;

	UPROPERTY(DefaultComponent)
	USkylineBallBossSmallBossProjectileActionComponent ProjectileLoopComp;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ZoeInteractionCameraSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset MioInteractionCameraSettings;

	UPROPERTY()
	TArray<FText> SmallBossNames;
	int SmallBossNameIndex = 0;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;
	float SplineProgress = 0.0;

	UPROPERTY(EditAnywhere)
	float RollSpeed = 2000.0;
	float MinRollSpeed = 0.0;

	

	float ActualRollSpeed = 0.0;

	UPROPERTY(EditAnywhere)
	float JumpHeight = 1000.0;

	UPROPERTY()
	float Radius = 200.0;

	UPROPERTY()
	float LaserDamage = 0.6;

	UPROPERTY()
	float BladeDamage = 0.05;

	UPROPERTY(EditAnywhere)
	float StumbleDistance = 1500.0;

	UPROPERTY(EditAnywhere)
	int SegmentQuantity = 7;
	int SegmentCurrentQuantity;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossSmallBossShieldSegment> ShieldSegmentClass;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossSmallBossShockwave> ShockwaveClass;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossSmallBossProjectile> ProjectileClass;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossSmallBossTurret> TurretClass;

	UPROPERTY()
	UNiagaraSystem ShieldSpawnVFX;

	UPROPERTY()
	UNiagaraSystem RemoveShieldVFX;

	UPROPERTY()
	UNiagaraSystem BladeHitVFX;

	UPROPERTY()
	FHazeTimeLike SpawnShieldSegmentsTimeLike;
	default SpawnShieldSegmentsTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike JumpTimeLike;
	default JumpTimeLike.UseSmoothCurveZeroToOne();

	FHazeTimeLike RollSpeedTimeLike;
	default RollSpeedTimeLike.UseLinearCurveZeroToOne();
	default RollSpeedTimeLike.Duration = 2.0;

	UPROPERTY()
	FHazeTimeLike LaserTimeLike;
	default LaserTimeLike.UseSmoothCurveZeroToOne();
	default LaserTimeLike.Duration = 4.0;

	UPROPERTY()
	float DelayedMovementAfterShieldSegmentsAttached = 1.0;

	UPROPERTY()
	FSmallBossHitSignature OnSmallBossHit;
	bool bOnSmallBossHitBroadcasted = false;

	UPROPERTY()
	FSmallRespawnShieldSignature OnRespawnShield;

	UPROPERTY()
	FSmallBossDied OnSmallBossDied;
	bool bOnSmallBossDiedBroadcasted = false;

	UPROPERTY()
	FHazePlaySlotAnimationParams MioFinisherSlotAnimationParams;

	UPROPERTY()
	FHazeTimeLike LaserLengthTimeLike;
	default LaserLengthTimeLike.UseLinearCurveZeroToOne();
	default LaserLengthTimeLike.Duration = 0.3;

	UPROPERTY()
	FHazeTimeLike LaserWidthTimeLike;
	default LaserWidthTimeLike.UseLinearCurveZeroToOne();
	default LaserWidthTimeLike.Duration = 0.3;

	TArray<ASkylineBallBossSmallBossShieldSegment> ShieldSegments;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> ImpactDamageEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ImpactDeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDamageEffect> LaserDamageEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> LaserDeathEffect;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocation;

	FVector PredictedTargetLocation;
	FHazeAcceleratedVector AcceleratedLocation;

	FVector LastFrameActorLocation;

	TPerPlayer<float> LastTimeHit;
	float Cooldown = 0.5;
	
	UPROPERTY(BlueprintReadWrite)
	bool bDoActions = false;

	bool bDoJump = false;
	AHazePlayerCharacter ProjectileTargetPlayer = nullptr;
	bool bDoLaser = false;

	bool bActive = false;
	bool bLaserActive = false;
	bool bFollowingSpline = false;
	bool bWeak = false;
	bool bEvenHit = false;
	bool bWhipHeld = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeCombatTargetComponent.DisableForPlayer(Game::Mio, this);

		SplineComp = UHazeSplineComponent::Get(SplineActor);

		SpawnShieldSegmentsTimeLike.BindUpdate(this, n"SpawnShieldSegmentsTimeLikeUpdate");
		SpawnShieldSegmentsTimeLike.BindFinished(this, n"SpawnShieldSegmentsTimeLikeFinished");
		RollSpeedTimeLike.BindUpdate(this, n"RollSpeedTimeLikeUpdate");
		RollSpeedTimeLike.BindFinished(this, n"RollSpeedTimeLikeFinished");
		JumpTimeLike.BindUpdate(this, n"JumpTimeLikeUpdate");
		JumpTimeLike.BindFinished(this, n"JumpTimeLikeFinished");
		LaserTimeLike.BindUpdate(this, n"LaserTimeLikeUpdate");
		LaserTimeLike.BindFinished(this, n"LaserTimeLikeFinished");
		LaserWidthTimeLike.BindUpdate(this, n"LaserWidthTimeLikeUpdate");
		LaserWidthTimeLike.BindFinished(this, n"LaserWidthTimeLikeFinished");
		LaserLengthTimeLike.BindUpdate(this, n"LaserLengthTimeLikeUpdate");
		LaserLengthTimeLike.BindFinished(this, n"LaserLengthTimeLikeFinished");


		GravityBladeCombatResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");

		GravityWhipTargetComponent.Disable(this);
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");

		LaserColComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleLaserOverlap");

		LaserRoot.SetHiddenInGame(true, true);
		LaserColComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		LaserPassbyAudioCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		LaserPassbyAudioCollisionComp.SetHiddenInGame(true);

		LaserPassbyAudioCollisionComp.SetCapsuleHalfHeight(LaserColComp.CapsuleHalfHeight);
		LaserPassbyAudioCollisionComp.SetCapsuleRadius(LaserColComp.CapsuleRadius * 8);

		SetActorControlSide(Game::Zoe);
		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Game::Zoe);
		PlayerHealthComp.OnStartDying.AddUFunction(this, n"ReleaseSmallBoss");
	}

	UFUNCTION()
	private void ReleaseSmallBoss()
	{
		ReleaseBall();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		TEMPORAL_LOG(this, "Action Queue Jump & Laser").Value("Queue", JumpLoopComp.Queue);
		TEMPORAL_LOG(this, "Action Queue Projectile").Value("Queue", ProjectileLoopComp.Queue);
#endif
		if (bActive)
		{
			if (bFollowingSpline && HasControl())
			{
				SplineProgress += ActualRollSpeed * DeltaSeconds;

				if (SplineProgress > SplineComp.SplineLength)
					SplineProgress -= SplineComp.SplineLength;

				PredictedTargetLocation = SplineComp.GetWorldLocationAtSplineDistance(SplineProgress) + FVector::UpVector * Radius;
				SyncedLocation.SetValue(PredictedTargetLocation);
			}
			
			if (Network::IsGameNetworked())
			{
				if (!HasControl())
					AcceleratedLocation.AccelerateTo(SyncedLocation.Value, Network::PingRoundtripSeconds * 0.5, DeltaSeconds);
				else
					AcceleratedLocation.AccelerateTo(SyncedLocation.Value, Network::PingRoundtripSeconds * 2.0, DeltaSeconds);
			}
			else
				AcceleratedLocation.AccelerateTo(SyncedLocation.Value, 0.5, DeltaSeconds);

			SetActorLocation(AcceleratedLocation.Value);

			if (SkylineBallBossDevToggles::DrawSmallBoss.IsEnabled())
			{
				Debug::DrawDebugSphere(ActorLocation, 50.0, 12, ColorDebug::Cyan, 5.0, 0.0, true);
				Debug::DrawDebugSphere(SyncedLocation.Value, 50.0, 12, ColorDebug::Pink, 5.0, 0.0, true);
			}

			FVector AngularVelocity = ((ActorLocation - LastFrameActorLocation) / DeltaSeconds).CrossProduct(FVector::UpVector);
			LastFrameActorLocation = ActorLocation;

			float RotationSpeed = (AngularVelocity.Size() / Radius);

			const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaSeconds * -1);
			RollRoot.AddWorldRotation(DeltaQuat);

			BlobShadowDecalComp.SetRelativeLocation(FVector::UpVector * -Radius);

			if(bLaserActive)
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
				FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
				ForceFeedback::PlayWorldForceFeedbackForFrame(FF, LaserColComp.WorldLocation, 700, 1300);
			}

			//CHECK PLAYER IMPACT
			bool bVulnerable = bWeak && bWhipHeld;
			if (!bVulnerable) //GravityBladeCombatResponseComponent.IsResponseComponentDisabled())
			{
				for (auto Player : Game::GetPlayers())
				{
					FVector ClosestShapeLocation;

					Player.CapsuleComponent.GetClosestPointOnCollision(RollRoot.WorldLocation, ClosestShapeLocation);

					float DistanceToPlayer = ClosestShapeLocation.Distance(RollRoot.WorldLocation);

					if (DistanceToPlayer <= Radius && LastTimeHit[Player] + Cooldown < Time::GameTimeSeconds)
					{
						FVector Move = (Player.ActorLocation - RollRoot.WorldLocation).GetSafeNormal() * StumbleDistance;
						
						if (Move.Z < 500.0)
							Move.Z = 500.0;
						
						Player.AddMovementImpulse(Move);
						//Player.ApplyStumble(Move);
						Player.DamagePlayerHealth(0.1, FPlayerDeathDamageParams(Move.GetSafeNormal()), ImpactDamageEffect, ImpactDeathEffect);

						LastTimeHit[Player] = Time::GameTimeSeconds;
					}
				}
			}
		}
	}

	UFUNCTION()
	void Activate()
	{
		DetachFromActor(EDetachmentRule::KeepWorld);
		SetActorRotation(FRotator::ZeroRotator);

		bActive = true;
		SpawnShieldSegments(SegmentQuantity);
		PredictedTargetLocation = ActorLocation;
		AcceleratedLocation.SnapTo(PredictedTargetLocation);
		if (HasControl())
			SyncedLocation.SetValue(PredictedTargetLocation);
		RollSpeedTimeLike.SetNewTime(RollSpeedTimeLike.Duration);

		//fix to not damage mio when she is exiting ball boss
		LastTimeHit[Game::Mio] = Time::GameTimeSeconds + 1.0;
	}

	UFUNCTION()
	void Jump()
	{
		if (!bActive)
			return;

		if (JumpTimeLike.IsPlaying())
			return;

		if (bLaserActive)
			return;

		if (bWeak)
			return;

		bDoJump = true;
	}

	UFUNCTION()
	void SpawnProjectile(AHazePlayerCharacter TargetPlayer)
	{
		if (!bActive)
			return;

		if (bWeak)
			return;

		if (bLaserActive)
			return;

		if (!HasControl())
			return;

		ProjectileTargetPlayer = TargetPlayer;
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnedProjectile()
	{
	}

	UFUNCTION()
	void SpawnTurret()
	{
		if (!bActive)
			return;

		if (JumpTimeLike.IsPlaying())
			return;

		if (bWeak)
			return;

		SpawnActor(TurretClass, RollRoot.WorldLocation - FVector::UpVector * Radius);
	}

	UFUNCTION()
	void ActivateLaser()
	{
		if (!bActive)
			return;

		if (JumpTimeLike.IsPlaying())
			return;

		if (bWeak)
			return;

		bDoLaser = true;
	}

	UFUNCTION()
	private void LaserTimeLikeUpdate(float CurrentValue)
	{
		SetActorRotation(FRotator(0.0, CurrentValue * 720.0, 0.0));
	}

	UFUNCTION()
	private void LaserTimeLikeFinished()
	{
		if (!bWeak)
			LaserWidthTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	private void LaserWidthTimeLikeUpdate(float CurrentValue)
	{
		float XYScale = Math::Lerp(0.02, 0.4, CurrentValue);
		LaserMeshComp.SetRelativeScale3D(FVector(XYScale, XYScale, 2.5));
	}

	UFUNCTION()
	private void LaserWidthTimeLikeFinished()
	{
		LaserLengthTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	private void LaserLengthTimeLikeUpdate(float CurrentValue)
	{
		LaserRoot.SetRelativeScale3D(FVector(1.0, 1.0, Math::Lerp(0.0001, 1.0, CurrentValue)));
	}

	UFUNCTION()
	private void LaserLengthTimeLikeFinished()
	{
		bLaserActive = false;
		
		LaserRoot.SetHiddenInGame(true, true);
		LaserColComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		LaserPassbyAudioCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		BP_LaserEnd();
	
		if (!bWeak)
			RollSpeedTimeLike.Play();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_LaserStart()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void BP_LaserEnd()
	{
	}

	UFUNCTION()
	private void DelayedLaserActivation()
	{
		BP_LaserStart();
		LaserTimeLike.PlayFromStart();
		LaserRoot.SetRelativeScale3D(FVector(1.0));
		LaserMeshComp.SetRelativeScale3D(FVector(0.4, 0.4, 2.5));
		LaserRoot.SetHiddenInGame(false, true);
		LaserColComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		LaserPassbyAudioCollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION()
	private void HandleLaserOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.DamagePlayerHealth(LaserDamage, FPlayerDeathDamageParams(LaserColComp.RightVector), LaserDamageEffect, LaserDeathEffect);
		}
	}

	UFUNCTION()
	private void JumpTimeLikeUpdate(float CurrentValue)
	{
		RollRoot.SetRelativeLocation(FVector::UpVector * CurrentValue * JumpHeight);
	}

	UFUNCTION()
	private void JumpTimeLikeFinished()
	{
		USkylineSmallBossMiscVOEventHandler::Trigger_SmallBossSmash(this);
		SpawnActor(ShockwaveClass, ActorLocation - FVector::UpVector * Radius);

		if (!bWeak)
			RollSpeedTimeLike.Play();

		BP_ShockwaveSpawned();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ShockwaveSpawned()
	{
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (bWeak && bWhipHeld)
		{
			MinRollSpeed = 0.0;
			ActualRollSpeed = 0.0;

			Game::Mio.ApplyCameraSettings(MioInteractionCameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);

			BP_Hit();

			bEvenHit = !bEvenHit;

			if (SmallBossNameIndex < SmallBossNames.Num() - 1 && bEvenHit)
			{
				SmallBossNameIndex++;
				BallBossHealthBarComp.SetNewName(SmallBossNames[SmallBossNameIndex]);
				Niagara::SpawnOneShotNiagaraSystemAttached(BladeHitVFX, RollRoot);
			}

			MeshRoot.RelativeScale3D *= 0.92;
			BlobShadowDecalComp.RelativeScale3D *= 0.92;
			
			Radius = 100.0 * MeshRoot.RelativeScale3D.X;

			HealthComp.TakeDamage(BladeDamage, EDamageType::Default, this);
			USkylineSmallBossMiscVOEventHandler::Trigger_MioHitSmallBoss(this);

			if (!bOnSmallBossHitBroadcasted)
			{
				bOnSmallBossHitBroadcasted = true;
				OnSmallBossHit.Broadcast();
			}

			if (HealthComp.CurrentHealth <= KINDA_SMALL_NUMBER && !bOnSmallBossDiedBroadcasted)
			{
				if (HasControl())
					CrumbDied();

				Game::Mio.PlaySlotAnimation(MioFinisherSlotAnimationParams);
			}
		}
		else
		{
			if (!bWeak)
				USkylineSmallBossMiscVOEventHandler::Trigger_MioTryHitShieldedSmallBoss(this);
			else if (!bWhipHeld)
				USkylineSmallBossMiscVOEventHandler::Trigger_MioTryHitNakedSpeedySmallBoss(this);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDied()
	{
		bOnSmallBossDiedBroadcasted = true;
		OnSmallBossDied.Broadcast();	
	}

	UFUNCTION()
	private void RollSpeedTimeLikeUpdate(float CurrentValue)
	{
		ActualRollSpeed = Math::Lerp(MinRollSpeed, RollSpeed, CurrentValue);
	}

	UFUNCTION()
	private void RollSpeedTimeLikeFinished()
	{
	}

	UFUNCTION()
	private void RespawnShieldSegments()
	{
		SpawnShieldSegments(SegmentQuantity);
		OnRespawnShield.Broadcast();
	}

	private void SpawnShieldSegments(int Segments)
	{
		for (int i = 0; i < Segments; i++)
		{
			auto SpawnedSegment = SpawnActor(ShieldSegmentClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
			SpawnedSegment.MakeNetworked(this, i);
			SpawnedSegment.SmallBoss = this;
			SpawnedSegment.TractorBeamAppearDelay = 3.5 + ShieldSegments.Num() * 0.1;

			FinishSpawningActor(SpawnedSegment);

			SpawnedSegment.AttachToComponent(RollRoot, NAME_None, EAttachmentRule::KeepWorld);

			float DegreesPerSegment = 360.0 / Segments;
			float SpreadYaw = DegreesPerSegment * i;
			
			FVector Direction = FRotator(Math::RandRange(-90.0, 90.0), SpreadYaw, 0.0).ForwardVector;

			//FVector Location = Math::GetRandomPointOnSphere() * Radius + ActorLocation;
			FVector Location = ActorLocation + Direction * Radius;
			FRotator Rotation = (ActorLocation - Location).GetSafeNormal().Rotation();

			SpawnedSegment.SetActorLocationAndRotation(Location, Rotation);

			ShieldSegments.Add(SpawnedSegment);
			SegmentCurrentQuantity++;

			SpawnedSegment.GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnShieldSegmentGrabbed");
		}

		for (auto Shield : ShieldSegments)
		{
			Shield.GravityWhipTargetComponent.Disable(this);
		}

		SpawnShieldSegmentsTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void SpawnShieldSegmentsTimeLikeUpdate(float CurrentValue)
	{
		for (auto Shield : ShieldSegments)
		{
			FVector Location = FVector::ForwardVector * Math::Lerp(-700.0, 0.0, CurrentValue);
			Shield.MeshRoot.SetRelativeLocation(Location);
		}
	}

	UFUNCTION()
	private void SpawnShieldSegmentsTimeLikeFinished()
	{
		Niagara::SpawnOneShotNiagaraSystemAttached(ShieldSpawnVFX, RollRoot);
		
		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
		BallBossHealthBarComp.UpdateHealthBarVisibility();

		BP_Assembled();

		Timer::SetTimer(this, n"DelayedStartAfterShieldSegmentsAttached", DelayedMovementAfterShieldSegmentsAttached);

		for (auto ShieldSegment : ShieldSegments)
		{
			ShieldSegment.DeactivateTractorBeam();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Assembled()
	{}

	UFUNCTION()
	private void DelayedStartAfterShieldSegmentsAttached()
	{
		for (auto Shield : ShieldSegments)
		{
			Shield.GravityWhipTargetComponent.Enable(this);
		}

		bFollowingSpline = true;

		RollSpeedTimeLike.Play();

		USkylineSmallBossMiscVOEventHandler::Trigger_DelayedStartAfterShieldSegmentsAttached(this);
	}

	UFUNCTION()
	private void OnShieldSegmentGrabbed(UGravityWhipUserComponent UserComponent,
	                     UGravityWhipTargetComponent TargetComponent,
	                     TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ShieldSegmentRemoved(Cast<ASkylineBallBossSmallBossShieldSegment>(TargetComponent.AttachmentRootActor));
	}

	void ShieldSegmentRemoved(ASkylineBallBossSmallBossShieldSegment RemovedSegment)
	{
		SegmentCurrentQuantity--;
		if (SegmentCurrentQuantity <= 0)
		{
			ShieldSegments.Empty();
			Timer::ClearTimer(this, n"DelayedLaserActivation");

			if (LaserTimeLike.IsPlaying())
			{
				LaserTimeLike.Stop();
				LaserTimeLikeFinished();
				bLaserActive = false;
			}
			
			bOnSmallBossHitBroadcasted = false;
			bWeak = true;
			Radius = 100.0;

			RollSpeedTimeLike.Play();
			GravityWhipTargetComponent.Enable(this);

			MinRollSpeed = 100.0;
		}
		HealthComp.TakeDamage(0.5 / SegmentQuantity, EDamageType::Default, this);

		if (RemovedSegment != nullptr)
		{
			FVector ToSegment = (RemovedSegment.ActorLocation - ActorLocation).GetSafeNormal();
			FRotator VFXRotation;
			if (ToSegment.DotProduct(FVector::UpVector) > 1.0 - KINDA_SMALL_NUMBER)
				VFXRotation = FRotator::MakeFromXZ(ToSegment, ActorRightVector);
			else 
				VFXRotation = FRotator::MakeFromXZ(ToSegment, FVector::UpVector);
		
			if (RemoveShieldVFX != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(RemoveShieldVFX, ActorLocation, VFXRotation);
			USkylineSmallBossMiscVOEventHandler::Trigger_ZoeWhipBreakOffPlate(this);
		}

		// Debug::DrawDebugCoordinateSystem(ActorLocation, VFXRotation, 200.0, 10.0, 30.0);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		BP_Grabbed();

		RollSpeedTimeLike.PlayRate = 4.0;
		RollSpeedTimeLike.Reverse();
		Game::Zoe.ApplyCameraSettings(ZoeInteractionCameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);
		bWhipHeld = true;
		USkylineSmallBossMiscVOEventHandler::Trigger_ZoeWhipHoldNakedSmallBossStart(this);
		GravityBladeCombatTargetComponent.EnableForPlayer(Game::Mio, this);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ReleaseBall();
	}

	private void ReleaseBall()
	{
		if (bWhipHeld)
		{
			GravityBladeCombatTargetComponent.DisableForPlayer(Game::Mio, this);
			USkylineSmallBossMiscVOEventHandler::Trigger_ZoeWhipHoldNakedSmallBossEnd(this);
			RollSpeedTimeLike.PlayRate = 8.0;
			RollSpeedTimeLike.Play();
			Game::Zoe.ClearCameraSettingsByInstigator(this);
			Game::Mio.ClearCameraSettingsByInstigator(this);
			bWhipHeld = false;

			BP_Released();
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Grabbed(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Released(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Hit(){}
};