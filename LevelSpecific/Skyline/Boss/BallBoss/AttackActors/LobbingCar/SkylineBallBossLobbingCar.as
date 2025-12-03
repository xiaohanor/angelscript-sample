class ASkylineBallBossLobbingCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarRoot;

	UPROPERTY(DefaultComponent, Attach = CarRoot)
	USceneComponent CarRollRoot;

	UPROPERTY(DefaultComponent, Attach = CarRollRoot)
	UStaticMeshComponent CarMesh1;

	UPROPERTY(DefaultComponent, Attach = CarRollRoot)
	UStaticMeshComponent CarMesh2;

	UPROPERTY(DefaultComponent, Attach = CarMesh1)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp;

	UPROPERTY()
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(EditAnywhere)
	FVector TargetLocation;
	FVector StartLocation;
	FVector ActorStartLocation;

	UPROPERTY(EditAnywhere)
	float GlideSpeed = 400.0;

	UPROPERTY(EditAnywhere)
	float GlideRotationSpeed = 20.0;

	UPROPERTY()
	float CarDirectionImpulse = 2500.0;

	UPROPERTY()
	float FromCarImpulse = 0.0;

	UPROPERTY()
	float UpImpulse = 1000.0;

	UPROPERTY()
	float Damage = 0.3;

	UPROPERTY()
	float ArcHeight = 1000.0;

	UPROPERTY()
	FHazeTimeLike AppearTimeLike;
	default AppearTimeLike.UseSmoothCurveZeroToOne();
	default AppearTimeLike.Duration = 2.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ThrowTimeLike;
	default ThrowTimeLike.UseLinearCurveZeroToOne();

	AHazePlayerCharacter TargetedPlayer;

	bool bDisappear = false;
	bool bAppearing = false;
	bool bAppeared = false;
	bool bAttacking = false;
	bool bThrown = false;
	bool bGliding = false;
	bool bFalling = false;
	bool bReachedPlatform = false;
	
	float GravityForce = 0.0;

	TPerPlayer<float> LastTimeHitPlayer;

	ASkylineBallBoss BallBoss = nullptr;
	bool bPhaseChangeBound = false;

	FVector DesiredBallBossOffsetLocation;
	FHazeAcceleratedVector AccDesiredBallBossOffsetLocation;
	FHazeAcceleratedQuat AccDesiredRotation;
	FHazeAcceleratedFloat RollSpeed;

	FHazeAcceleratedFloat AccBounce;

	float TargetRollSpeed = 0.0;

	bool bRotateAligningBoss = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AppearTimeLike.BindUpdate(this, n"AppearTimeLikeUpdate");
		AppearTimeLike.BindFinished(this, n"AppearTimeLikeEnd");

		ThrowTimeLike.BindUpdate(this, n"ThrowTimeLikeUpdate");
		ThrowTimeLike.BindFinished(this, n"ThrowTimeLikeFinished");

		StartLocation = CarRoot.RelativeLocation;
		CarRoot.SetRelativeRotation((TargetLocation - StartLocation).Rotation());

		ActorStartLocation = ActorLocation;

		TractorBeamVFXComp.SetupTractorBeamMaterial(CarMesh1);

		AddActorDisable(this);
	}

	UFUNCTION()
	private void AppearTimeLikeUpdate(float CurrentValue)
	{
		CarRoot.SetRelativeLocation(Math::Lerp(StartLocation - FVector::UpVector * 3000.0, StartLocation, CurrentValue));
	}

	UFUNCTION()
	private void AppearTimeLikeEnd()
	{
		bAppeared = true;
		DesiredBallBossOffsetLocation = ActorLocation - BallBoss.ActorLocation;
		AccDesiredBallBossOffsetLocation.SnapTo(ActorLocation);
		AccDesiredRotation.SnapTo(ActorRotation.Quaternion());
		if (!bDisappear)
			USkylineBallBossSlidingCarEventHandler::Trigger_AppearEnd(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAppeared && !bThrown)
		{
			TargetedPlayer = BallBoss.FocusPlayerComponent.GetViableFocusPlayer(TargetedPlayer);
			FVector ClosestLocation = BallBoss.FocusPlayerComponent.GetConstrainedFocusLocation(TargetedPlayer, CarMesh1.WorldLocation);
			AccDesiredRotation.AccelerateTo(((ClosestLocation - ActorLocation).VectorPlaneProject(FVector::UpVector)).Rotation().Quaternion(), 0.5, DeltaSeconds);
			SetActorRotation(AccDesiredRotation.Value);
		}

		if (SkylineBallBossDevToggles::DrawCarThings.IsEnabled())
		{
			TargetedPlayer = BallBoss.FocusPlayerComponent.GetViableFocusPlayer(TargetedPlayer);
			FVector ClosestLocation = BallBoss.FocusPlayerComponent.GetConstrainedFocusLocation(TargetedPlayer, CarMesh1.WorldLocation);
			Debug::DrawDebugSphere(ClosestLocation, 5.0, 12, TargetedPlayer.GetPlayerUIColor(), 3.0, 0.0, true);
		}

		if (bGliding)
			UpdateGliding(DeltaSeconds);

		else if (bAppeared)
		{
			if (!bAttacking)
			{
				AccDesiredBallBossOffsetLocation.AccelerateTo(BallBoss.ActorLocation + DesiredBallBossOffsetLocation, 1.0, DeltaSeconds);
				SetActorLocation(AccDesiredBallBossOffsetLocation.Value);
			}
			else
			{
				AccDesiredBallBossOffsetLocation.AccelerateTo(ActorStartLocation, 1.0, DeltaSeconds);
				SetActorLocation(AccDesiredBallBossOffsetLocation.Value);
			}
		}

		RollSpeed.AccelerateTo(TargetRollSpeed, 1.0, DeltaSeconds);
		CarRollRoot.AddRelativeRotation(FRotator(0.0, 0.0, -RollSpeed.Value * DeltaSeconds));
	}

	private void UpdateGliding(float DeltaSeconds)
	{
		if (GlideSpeed == 0.0)
			GlideSpeed = SMALL_NUMBER;

		if (!bFalling)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
			Trace.IgnoreActor(this);
			FHitResult HitResult = Trace.QueryTraceSingle(CarRoot.WorldLocation, CarRoot.WorldLocation + FVector::UpVector * -1000.0);

			if (bReachedPlatform)
			{
				if (!HitResult.bBlockingHit)
					StartFalling();
			}
			else if (HitResult.bBlockingHit)
				bReachedPlatform = true;
		}

		if (bFalling)
		{
			GravityForce += DeltaSeconds * -2000.0;
		}

		FVector RelativeDelta = (FVector::ForwardVector * GlideSpeed + FVector::UpVector * GravityForce) * DeltaSeconds;
		FVector WorldDelta = CarRoot.WorldTransform.TransformVectorNoScale(RelativeDelta);
		FRotator RotationDelta = FRotator(0.0, GlideRotationSpeed * DeltaSeconds, 0.0);

		// Get the local bounding box of the actor, ignoring scale, position and rotation
		FVector Extents;
		FVector Origin;
		GetActorLocalBounds(true, Origin, Extents);

		// Transform extents to world space (take actor scale into account)
		Extents *= ActorScale3D;

		// Make the extents be roughly the size of the bonnet
		Extents *= FVector(0.5, 1, 0.5);

		// Move the box to the front of the car
		Origin += FVector(0, 0, 0);

		// Transform to world space
		Origin = ActorTransform.TransformPosition(Origin);

		FVector End = Origin + WorldDelta;


		for(auto Player : Game::Players)
		{
			if(Time::GetGameTimeSince(LastTimeHitPlayer[Player]) < 1)
				continue;

			auto MoveComp = UPlayerMovementComponent::Get(Player);

			// If the player is standing on the car, ignore the player
			if(MoveComp.HasGroundContact() && MoveComp.GroundContact.Actor == this)
				continue;

			// Sweep only against the player
			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Player.CapsuleComponent);
			Trace.UseBoxShape(Extents, ActorQuat);


			const FHitResult Hit = Trace.QueryTraceComponent(Origin, End);
			if(Hit.bBlockingHit)
			{
				HandlePlayerImpact(Player);
				LastTimeHitPlayer[Player] = Time::GameTimeSeconds;
			}

			//Debug::DrawDebugBox(Origin, Extents, ActorQuat.Rotator());
		}

		CarRoot.AddRelativeLocation(RelativeDelta);
		CarRoot.AddRelativeRotation(RotationDelta);

		//CarBounce
		//AccBounce.SpringTo(0.0, 20.0, 0.1, DeltaSeconds);
		//	float BounceValue = Math::Abs(AccBounce.Value);

		float PreviousBounce = AccBounce.Value;
		AccBounce.SpringTo(0.0, 20.0, 0.1, DeltaSeconds);
		if (!Math::IsNearlyEqual(Math::Sign(PreviousBounce), Math::Sign(AccBounce.Value)))
		{
			//Debug::DrawDebugString(CarRollRoot.WorldLocation, "Bounce!", Duration = 3.0);
			USkylineBallBossCarLobEventHandler::Trigger_Bounce(this);
		}

		float BounceValue = Math::Abs(AccBounce.Value);

		CarRollRoot.SetRelativeLocation(FVector::UpVector * BounceValue);
		
	}

	private void StartFalling()
	{
		bFalling = true;
	
		USkylineBallBossSlidingCarEventHandler::Trigger_StartFalling(this);
	}

	UFUNCTION()
	void MaybeDisappear(ESkylineBallBossPhase NewPhase)
	{
		if (bAppearing && !bAttacking)
		{
			TractorBeamVFXComp.TractorBeamLetGo();
			bDisappear = true;
			AppearTimeLike.Reverse();
			Timer::SetTimer(this, n"Disable", 3.0);
			USkylineBallBossSlidingCarEventHandler::Trigger_Disappear(this);
		}
	}

	UFUNCTION()
	void Appear()
	{
		TryCacheBallBoss();
		if (!bPhaseChangeBound)
		{
			bPhaseChangeBound = true;
			BallBoss.OnPhaseChanged.AddUFunction(this, n"MaybeDisappear");
		}
		TargetedPlayer = BallBoss.FocusPlayerComponent.GetFlipFlopFocusPlayer();

		Timer::ClearTimer(this, n"Disable");
		Disable();
		RemoveActorDisable(this);

		bAppearing = true;
		bAppeared = false;
		bAttacking = false;
		bGliding = false;
		bThrown = false;
		bFalling = false;
		bReachedPlatform = false;

		GravityForce = 0.0;
		
		TargetRollSpeed = 0.0;
		RollSpeed.SnapTo(TargetRollSpeed);

		CarRollRoot.SetRelativeRotation(FRotator(0.0, 90.0, 0.0));
		CarRoot.SetRelativeRotation(FRotator::ZeroRotator);
		CarRoot.SetRelativeLocation(StartLocation);
		
		CarMesh1.SetHiddenInGame(false);
		CarMesh2.SetHiddenInGame(true);
		
		TractorBeamVFXComp.Start();

		AppearTimeLike.PlayFromStart();
		USkylineBallBossSlidingCarEventHandler::Trigger_AppearStart(this);
	}

	private void TryCacheBallBoss()
	{
		if (BallBoss == nullptr)
		{
			TListedActors<ASkylineBallBoss> BallBosses;
			if (BallBosses.Num() == 1)
				BallBoss = BallBosses[0];
		}
	}

	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		FVector Impulse = CarRoot.ForwardVector * CarDirectionImpulse;
		Impulse += (CarRoot.WorldLocation - Player.ActorLocation).GetSafeNormal() * FromCarImpulse;
		Impulse += FVector::UpVector * UpImpulse;

		Player.AddMovementImpulse(Impulse);

		Player.DamagePlayerHealth(Damage, FPlayerDeathDamageParams(CarRoot.ForwardVector, 2.0), BallBoss.ObjectLargeDamageEffect, BallBoss.ObjectLargeDeathEffect);
	}

	UFUNCTION()
	void Activate()
	{
		if (SkylineBallBossDevToggles::NoThrowsImpacts.IsEnabled())
			return;

		if (!bAttacking)
		{
			bAttacking = true;
			TargetRollSpeed = 100.0;
			ThrowTimeLike.PlayFromStart();
			BossStartRotateAlign();
			USkylineBallBossSlidingCarEventHandler::Trigger_Thrown(this);
			Timer::SetTimer(this, n"TractorBeamLetGo", 1.3);
			Timer::SetTimer(this, n"Disable", 8.0);

			USkylineBallBossMiscVOEventHandler::Trigger_LobbingCarThrow(BallBoss);
		}
	}

	UFUNCTION()
	private void Disable()
	{
		bAppearing = false;
		bAttacking = false;
		TractorBeamVFXComp.Stop();
		AddActorDisable(this);
		BossStopRotateAlign();

		BP_Disabled();
	}

	UFUNCTION()
	private void TractorBeamLetGo()
	{
		bThrown = true;
		TractorBeamVFXComp.TractorBeamLetGo();
		BossStopRotateAlign();
	}

	UFUNCTION()
	void SetPlayer(AHazePlayerCharacter Player)
	{
		// TargetedPlayer = Player;
	}

	UFUNCTION()
	private void ThrowTimeLikeUpdate(float CurrentValue)
	{
		FVector Location = Math::Lerp(StartLocation, TargetLocation, CurrentValue);
		Location.Z += Math::Sin(CurrentValue * PI) * ArcHeight;
		CarRoot.SetRelativeLocation(Location);
		CarRoot.SetRelativeRotation(FRotator(CarRoot.RelativeRotation.Pitch, 0.0, Math::Lerp(0.0, 360.0, ThrowTimeLike.Position)));
	}

	UFUNCTION()
	private void ThrowTimeLikeFinished()
	{
		USkylineBallBossSlidingCarEventHandler::Trigger_ImpactGround(this);
		CarRoot.RelativeRotation = FRotator(0.0);
		bGliding = true;

		AccBounce.SnapTo(0.0, 2000.0);

		TargetRollSpeed = 600.0;
		RollSpeed.SnapTo(TargetRollSpeed);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, CarRoot.WorldLocation);
		CarMesh1.SetHiddenInGame(true);
		CarMesh2.SetHiddenInGame(false);

		BP_Landed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Landed()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Disabled()
	{
	}

	private void BossStartRotateAlign()
	{
		if (!bRotateAligningBoss)
		{
			bRotateAligningBoss = true;
			bool bCarIsRightToBoss = BallBoss.ActorRightVector.DotProduct(ActorLocation - BallBoss.ActorLocation) > 0.0;
			FBallBossAlignRotationData AlignData;
			AlignData.BallLocalDirection = bCarIsRightToBoss ? FVector::RightVector : -FVector::RightVector;
			AlignData.OverrideTargetComp = CarMesh1;
			AlignData.bContinuousUpdate = true;
			AlignData.bSnapOverTime = true;
			BallBoss.AddRotationTarget(AlignData);
		}
	}

	private void BossStopRotateAlign()
	{
		if (bRotateAligningBoss)
		{
			bRotateAligningBoss = false;
			BallBoss.RemoveRotationTarget(CarMesh1);
		}
	}
};

class USkylineBallBossCarLobEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Bounce() 
	{
		//PrintToScreen("Bounce", 5.0);
	}

};