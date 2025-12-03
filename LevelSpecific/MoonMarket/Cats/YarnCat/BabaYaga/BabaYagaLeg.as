class ABabaYagaLeg : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DebrisNiagara;
	default DebrisNiagara.SetAutoActivate(false);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve BaseStandAnimationCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve BaseStandPitchCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve BaseSitAnimationCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve BaseSitRotationCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve BaseOffsetCurve;
	
	UPROPERTY(EditAnywhere)
	FVector FootTargetLocation;

	UPROPERTY(EditAnywhere)
	FRotator FootTargetRotation;

	UPROPERTY(EditAnywhere)
	FVector BaseTargetLocation;

	UPROPERTY(EditAnywhere)
	FVector TargetBaseOffset;

	FVector CurrentBaseLocation;
	FVector CurrentFootLocation;
	FRotator CurrentHouseRotation;

	FVector OriginalRelativeLocation;
	float OriginalYaw;
	float OriginalRoll;

	bool bIsMoving = false;
	bool bIsStanding = false;

	float AnimStartTime;

	UPROPERTY(EditAnywhere)
	const float PitchTilt = 100;

	UPROPERTY(EditAnywhere)
	const float RollTilt = 1;

	UPROPERTY(EditAnywhere)
	const float RollSwaySpeed = 0.5;

	UPROPERTY(EditAnywhere)
	const float ShakeFrequency = 7;

	UPROPERTY(EditAnywhere)
	const float ShakeStrength = 0.05;

	UPROPERTY(EditAnywhere)
	float HeightBobAmount = 30;

	float ClawGrip = 0;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	bool bPlayStandingFeedback;

	float SpeedMultiplier = 0.35;
	const float MaxAnimationDuration = 6.5 / SpeedMultiplier;

	UPROPERTY(EditInstanceOnly)
	bool bDebugSit = false;
	bool bDebugWasSitting = false;
	bool bFirstTick = true;

	UPROPERTY(EditInstanceOnly)
	ABabaYagaGeoRootMover GeoRootMover;

	FHazeAcceleratedFloat AccelFFFloat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GeoRootMover.Leg = this;
		FTransform SocketTransform = Mesh.GetSocketTransform(n"UpLeg");
		//GeoRootMover.AttachToComponent(Mesh, n"UpLeg", EAttachmentRule::KeepWorld);
		DebrisNiagara.AttachToComponent(GeoRootMover.Root, NAME_None, EAttachmentRule::KeepWorld);
		OriginalRelativeLocation = SocketTransform.InverseTransformPosition(GeoRootMover.ActorLocation);
		CurrentHouseRotation = GeoRootMover.ActorRotation;
		OriginalYaw = CurrentHouseRotation.Yaw;
		OriginalRoll = CurrentHouseRotation.Roll;
		CurrentBaseLocation = BaseTargetLocation;

		Mesh.HazeForceUpdateAnimation(true);
	}

	void StandInstant()
	{
		bIsMoving = false;
		bIsStanding = true;
		CurrentBaseLocation.Z = 0;
		GeoRootMover.SetActorRelativeLocation(OriginalRelativeLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bFirstTick)
		{
			bFirstTick = false;
			FTransform SocketTransform = Mesh.GetSocketTransform(n"UpLeg");
			GeoRootMover.SetActorLocation(SocketTransform.TransformPosition(OriginalRelativeLocation) + TargetBaseOffset);
		}

		float TimeSinceStandStarted = Time::GetGameTimeSince(AnimStartTime);

		const float DistanceToPlayers = Game::GetDistanceFromLocationToClosestPlayer(GeoRootMover.ActorLocation);
		const bool bUpdateMovement = DistanceToPlayers < 12000;
		
		if(bIsMoving && bUpdateMovement)
		{
			if(bIsStanding)
			{
				FTransform SocketTransform = Mesh.GetSocketTransform(n"UpLeg");
				CurrentBaseLocation.Z = BaseTargetLocation.Z - BaseStandAnimationCurve.GetFloatValue(TimeSinceStandStarted * SpeedMultiplier) * BaseTargetLocation.Z;
				CurrentHouseRotation.Pitch = BaseStandPitchCurve.GetFloatValue(TimeSinceStandStarted * SpeedMultiplier) * PitchTilt;
				FVector Offset = TargetBaseOffset * BaseOffsetCurve.GetFloatValue(TimeSinceStandStarted * SpeedMultiplier);
				GeoRootMover.SetActorLocationAndRotation(SocketTransform.TransformPosition(OriginalRelativeLocation) + Offset, CurrentHouseRotation);
			}
			else
			{
				CurrentBaseLocation.Z = BaseTargetLocation.Z - BaseSitAnimationCurve.GetFloatValue(TimeSinceStandStarted) * BaseTargetLocation.Z;
				CurrentHouseRotation.Pitch = BaseSitRotationCurve.GetFloatValue(TimeSinceStandStarted) * PitchTilt;
				CurrentHouseRotation.Roll = Math::FInterpConstantTo(CurrentHouseRotation.Roll, 0, DeltaSeconds, 2);
				GeoRootMover.SetActorRotation(CurrentHouseRotation);
			}

			CurrentFootLocation = FootTargetLocation;
		}


		if(bIsStanding && bUpdateMovement)
		{
			const float Shake = OriginalYaw + (ShakeStrength * Math::PerlinNoise1D(Time::GameTimeSeconds * ShakeFrequency));

			CurrentHouseRotation.Roll = OriginalRoll + Math::Sin(TimeSinceStandStarted * RollSwaySpeed) * RollTilt;
			CurrentBaseLocation.Y = -Math::Sin(TimeSinceStandStarted * RollSwaySpeed) * HeightBobAmount;
			CurrentHouseRotation.Yaw = Shake;

			if(!bIsMoving)
				GeoRootMover.SetActorRotation(CurrentHouseRotation);
		}

		if(TimeSinceStandStarted > MaxAnimationDuration && bIsMoving)
		{
			bIsMoving = false;
			UBabaYagaLegEventHandler::Trigger_OnFinishedRising(this);
		}

		TEMPORAL_LOG(this)
			.Value("bIsMoving", bIsMoving)
			.Point("UpLegLocation", Mesh.GetSocketLocation(n"UpLeg"))
			.Point("CurrentBaseLocation", CurrentBaseLocation)
			.Value("CurrentHouseRotation", CurrentHouseRotation)
		;

		if (bPlayStandingFeedback)
			AccelFFFloat.AccelerateTo(1.0, 1.5, DeltaSeconds);
		else
			AccelFFFloat.AccelerateTo(0.0, 1.2, DeltaSeconds);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			float MaxDistance = 10000.0;
			float MinDistance = 6500.0;
			float DistanceDiffCheck = MaxDistance - MinDistance;
			float PlayerOffsetDistance = Player.GetDistanceTo(this) - MinDistance;
			float CappedDistance = 1- Math::Saturate(PlayerOffsetDistance / DistanceDiffCheck);

			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 3500.0, MaxDistance * 1.2, 0.7, AccelFFFloat.Value);

			float FFFrequency = 25.0;
			FHazeFrameForceFeedback FF;
			FF.RightMotor = CappedDistance * (1.25 + Math::Sin(Time::GameTimeSeconds * FFFrequency));
			FF.LeftMotor = CappedDistance * (1.25 + Math::Sin(Time::GameTimeSeconds * -FFFrequency));
			Player.SetFrameForceFeedback(FF, 0.1 * AccelFFFloat.Value);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UAnimInstanceBabaYagaLeg AnimInstance = Cast<UAnimInstanceBabaYagaLeg>(Mesh.AnimInstance);

		if(bDebugSit)
		{
			AnimInstance.SetValues(FootTargetLocation, FootTargetRotation, BaseTargetLocation);
		}
		else
		{
			AnimInstance.SetValues(FootTargetLocation, FootTargetRotation, FVector::ZeroVector);
		}

		Mesh.HazeForceUpdateAnimation(true);
	}
	#endif

	UFUNCTION(BlueprintCallable, DevFunction)
	void Stand()
	{
		GeoRootMover.OnStartStanding.Broadcast();
		bIsStanding = true;
		bIsMoving = true;
		UBabaYagaLegEventHandler::Trigger_OnStartRising(this);
		AnimStartTime = Time::GameTimeSeconds;
		Timer::SetTimer(this, n"DelayedEffectActivate", 1.2, false);
		Timer::SetTimer(this, n"DelayedEffectDeactivateFeedback", 7.0, false);
		Timer::SetTimer(this, n"DelayedEffectDeactivate", 9.25, false);
	}

	UFUNCTION()
	void DelayedEffectActivate()
	{
		DebrisNiagara.Activate();
		bPlayStandingFeedback = true;
	}

	UFUNCTION()
	void DelayedEffectDeactivateFeedback()
	{
		bPlayStandingFeedback = false;
	}

	UFUNCTION()
	void DelayedEffectDeactivate()
	{
		DebrisNiagara.Deactivate();
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void Sit()
	{
		bIsStanding = false;
		bIsMoving = true;
		AnimStartTime = Time::GameTimeSeconds;
	}

	// #if EDITOR
	// UFUNCTION(BlueprintOverride)
	// void OnActorModifiedInEditor()
	// {
	// 	Cast<UAnimInstanceBabaYagaLeg>(Mesh.GetAnimInstance()).SetValues(FootTargetLocation, FootTargetRotation, BaseTargetLocation);
	// 	Mesh.HazeForceUpdateAnimation(true);
	// }
	// #endif
};