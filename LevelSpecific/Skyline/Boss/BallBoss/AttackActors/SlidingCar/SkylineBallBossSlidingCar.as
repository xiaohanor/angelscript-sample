class ASkylineBallBossSlidingCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ThrowRoot;

	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UStaticMeshComponent CarMesh;

	UPROPERTY(DefaultComponent, Attach = CarMesh)
	USkylineBallBossTractorBeamComponent TractorBeamVFXComp;

	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UNiagaraComponent CarSparkVFXComp1;
	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UNiagaraComponent CarSparkVFXComp2;
	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UNiagaraComponent CarSparkVFXComp3;
	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UNiagaraComponent CarSparkVFXComp4;

	UPROPERTY(EditAnywhere)
	FVector TargetLocation;
	FVector StartLocation;
	FVector ActorStartLocation;

	UPROPERTY(EditAnywhere)
	float GlideSpeed = 400.0;

	UPROPERTY(EditAnywhere)
	float GlideRotationSpeed = 20.0;

	UPROPERTY()
	float CarDirectionImpulse = 3000.0;

	UPROPERTY()
	float FromCarImpulse = 0.0;

	UPROPERTY()
	float UpImpulse = 1500.0;

	UPROPERTY()
	float Damage = 0.3;

	UPROPERTY()
	FHazeTimeLike AppearTimeLike;
	default AppearTimeLike.UseSmoothCurveZeroToOne();
	default AppearTimeLike.Duration = 2.0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ThrowActionQueueComp;

	UPROPERTY()
	FRuntimeFloatCurve ThrowCurve;

	UPROPERTY()
	FRuntimeFloatCurve BounceCurve;

	AHazePlayerCharacter TargetedPlayer;

	bool bDisappear = false;
	bool bAppearing = false;
	bool bAppeared = false;
	bool bAttacking = false;
	bool bThrown = false;
	bool bGliding = false;
	bool bReachedPlatform = false;
	bool bFalling = false;

	FHazeAcceleratedFloat AccPitch;
	float GravityForce = 0.0;

	TPerPlayer<float> LastTimeHitPlayer;

	ASkylineBallBoss BallBoss = nullptr;
	bool bPhaseChangeBound = false;

	FVector DesiredBallBossOffsetLocation;
	FHazeAcceleratedVector AccDesiredBallBossOffsetLocation;
	FHazeAcceleratedQuat AccDesiredRotation;

	bool bRotateAligningBoss = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AppearTimeLike.BindUpdate(this, n"AppearTimeLikeUpdate");
		AppearTimeLike.BindFinished(this, n"AppearTimeLikeEnd");

		StartLocation = CarRoot.RelativeLocation;
		CarRoot.RelativeRotation = (TargetLocation - StartLocation).Rotation();

		ActorStartLocation = ActorLocation;

		TractorBeamVFXComp.SetupTractorBeamMaterial(CarMesh);

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
		if (bDisappear)
		{
			bDisappear = false;
			return;
		}
		bAppeared = true;
		DesiredBallBossOffsetLocation = ActorLocation - BallBoss.ActorLocation;
		AccDesiredBallBossOffsetLocation.SnapTo(ActorLocation);
		AccDesiredRotation.SnapTo(ActorRotation.Quaternion());
		USkylineBallBossSlidingCarEventHandler::Trigger_AppearEnd(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAppeared && !bThrown)
		{
			TargetedPlayer = BallBoss.FocusPlayerComponent.GetViableFocusPlayer(TargetedPlayer);
			FVector ClosestLocation = BallBoss.FocusPlayerComponent.GetConstrainedFocusLocation(TargetedPlayer, CarMesh.WorldLocation);
			AccDesiredRotation.AccelerateTo(((ClosestLocation - ActorLocation) * FVector(1.0, 1.0, 0.0)).Rotation().Quaternion(), 0.5, DeltaSeconds);
			SetActorRotation(AccDesiredRotation.Value);
		}

		if (SkylineBallBossDevToggles::DrawCarThings.IsEnabled())
		{
			TargetedPlayer = BallBoss.FocusPlayerComponent.GetViableFocusPlayer(TargetedPlayer);
			FVector ClosestLocation = BallBoss.FocusPlayerComponent.GetConstrainedFocusLocation(TargetedPlayer, CarMesh.WorldLocation);
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
			float ClampedPitch = Math::Max(GravityForce * 0.05, -70.0);
			AccPitch.AccelerateTo(ClampedPitch, 4.0, DeltaSeconds);
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
		Extents *= FVector(0.2, 1, 0.5);

		// Move the box to the front of the car
		Origin += FVector(250, 0, -30);

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

		}

		CarRoot.AddRelativeLocation(RelativeDelta);
		CarRoot.AddRelativeRotation(RotationDelta);
		CarRoot.SetRelativeRotation(FRotator(AccPitch.Value, CarRoot.RelativeRotation.Yaw, CarRoot.RelativeRotation.Roll));
	}

	private void StartFalling()
	{
		bFalling = true;

		CarSparkVFXComp1.Deactivate();
		CarSparkVFXComp2.Deactivate();
		CarSparkVFXComp3.Deactivate();
		CarSparkVFXComp4.Deactivate();
	
		USkylineBallBossSlidingCarEventHandler::Trigger_StartFalling(this);
	}

	UFUNCTION()
	void MaybeDisappear(ESkylineBallBossPhase NewPhase)
	{
		if (bAppearing && !bAttacking)
		{
			TractorBeamVFXComp.TractorBeamLetGo();
			bDisappear = true;
			bAppearing = false;
			AppearTimeLike.Reverse();
			Timer::SetTimer(this, n"Disable", 3.0);
			USkylineBallBossSlidingCarEventHandler::Trigger_Disappear(this);

			//This might fix a bug where the ball boss gets a weird rotation
			BossStopRotateAlign();
		}
	}

	UFUNCTION()
	void Appear()
	{
		Timer::ClearTimer(this, n"Disable");

		TryCacheBallBoss();
		if (!bPhaseChangeBound)
		{
			bPhaseChangeBound = true;
			BallBoss.OnPhaseChanged.AddUFunction(this, n"MaybeDisappear");
		}
		TargetedPlayer = BallBoss.FocusPlayerComponent.GetFlipFlopFocusPlayer();
		RemoveActorDisable(this);

		bAppearing = true;
		bAppeared = false;
		bAttacking = false;
		bGliding = false;
		bThrown = false;
		bFalling = false;
		bReachedPlatform = false;
		bDisappear = false;

		AccPitch.SnapTo(0.0);
		GravityForce = 0.0;

		CarRoot.SetRelativeLocation(StartLocation);
		CarRoot.SetRelativeRotation(FRotator::ZeroRotator);
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
			ThrowActionQueueComp.Duration(0.5, this, n"ChargeUpdate");
			ThrowActionQueueComp.Duration(1.0, this, n"ThrowUpdate");
			ThrowActionQueueComp.Event(this, n"ThrowFinished");
			ThrowActionQueueComp.Duration(0.3, this, n"BounceUpdate");
			//ThrowTimeLike.PlayFromStart();
			BossStartRotateAlign();
			USkylineBallBossSlidingCarEventHandler::Trigger_Thrown(this);
			Timer::SetTimer(this, n"TractorBeamLetGo", 1.4);
			Timer::SetTimer(this, n"Disable", 8.0);

			USkylineBallBossMiscVOEventHandler::Trigger_SlidingCarThrow(BallBoss);
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
	private void ChargeUpdate(float Alpha)
	{
		float CurrentValue = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);

		FVector CurrentRelative = Math::Lerp(StartLocation, ThrowRoot.RelativeLocation, CurrentValue);
		CarRoot.SetRelativeLocation(CurrentRelative);
		CarRoot.SetRelativeRotation(FRotator(CarRoot.RelativeRotation.Pitch, 0.0, Math::Lerp(0.0, 130.0, Alpha)));
	}

	UFUNCTION()
	private void ThrowUpdate(float Alpha)
	{
		float CurrentValue = ThrowCurve.GetFloatValue(Alpha);
		
		FVector CurrentRelative = Math::Lerp(ThrowRoot.RelativeLocation, TargetLocation, CurrentValue);
		CarRoot.SetRelativeLocation(CurrentRelative);
		CarRoot.SetRelativeRotation(FRotator(CarRoot.RelativeRotation.Pitch, 0.0, Math::Lerp(130.0, 360.0, Alpha)));
	}

	UFUNCTION()
	private void ThrowFinished()
	{
		USkylineBallBossSlidingCarEventHandler::Trigger_ImpactGround(this);
		CarRoot.RelativeRotation = FRotator(0.0);
		bGliding = true;

		CarSparkVFXComp1.Activate();
		CarSparkVFXComp2.Activate();
		CarSparkVFXComp3.Activate();
		CarSparkVFXComp4.Activate();

		BP_Landed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Landed(){}

	UFUNCTION()
	private void BounceUpdate(float Alpha)
	{
		float CurrentValue = BounceCurve.GetFloatValue(Alpha);
		FVector CarRelativeLocation = CarRoot.RelativeLocation;
		CarRelativeLocation.Z = CurrentValue * 30.0 + TargetLocation.Z;
		CarRoot.SetRelativeLocation(CarRelativeLocation);
	}

	private void BossStartRotateAlign()
	{
		if (!bRotateAligningBoss)
		{
			bRotateAligningBoss = true;
			bool bCarIsRightToBoss = BallBoss.ActorRightVector.DotProduct(ActorLocation - BallBoss.ActorLocation) > 0.0;
			FBallBossAlignRotationData AlignData;
			AlignData.BallLocalDirection = bCarIsRightToBoss ? FVector::RightVector : -FVector::RightVector;
			AlignData.OverrideTargetComp = CarMesh;
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
			BallBoss.RemoveRotationTarget(CarMesh);
		}
	}
};