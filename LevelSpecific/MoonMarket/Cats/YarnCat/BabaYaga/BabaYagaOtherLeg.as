class ABabaYagaOtherLeg : ABabaYagaLeg
{
	UPROPERTY(EditInstanceOnly)
	ABabaYagaLeg OtherLeg;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve FootLocationCurve;

	bool bIsAttached = false;
	float AttachTime;
	bool bHasStartedStand = false;

	default MaxAnimationDuration = 4.5 / SpeedMultiplier;

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void BeginPlay()
	{
		GeoRootMover.OtherLeg = this;
		UAnimInstanceBabaYagaLeg AnimInstance = Cast<UAnimInstanceBabaYagaLeg>(Mesh.AnimInstance);
		AnimInstance.SetValues(FootTargetLocation + FVector::DownVector * 1000, FRotator::ZeroRotator, FVector::ZeroVector);
		Mesh.HazeForceUpdateAnimation(true);
		//CurrentFootLocation = FootTargetLocation;
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void Tick(float DeltaSeconds)
	{
		CurrentBaseLocation = OtherLeg.CurrentBaseLocation;
		
		if(!bHasStartedStand && !OtherLeg.bIsMoving)
			return;

		bHasStartedStand = true;

		float TimeSinceStandStarted = Time::GetGameTimeSince(OtherLeg.AnimStartTime);

		if(OtherLeg.bIsMoving)
		{
			if(OtherLeg.bIsStanding)
			{
				CurrentFootLocation.Z = FootTargetLocation.Z * FootLocationCurve.GetFloatValue(TimeSinceStandStarted * OtherLeg.SpeedMultiplier);
			}
		}
		
		if(TimeSinceStandStarted >= MaxAnimationDuration)
		{
			if(!bIsAttached)
			{
				AttachTime = Time::GameTimeSeconds;
				bIsAttached = true;
				AttachToActor(GeoRootMover, AttachmentRule = EAttachmentRule::KeepWorld);
			}

			const float TimeSinceFinishedStand = Time::GetGameTimeSince(AttachTime);
			float BobHeight = 150;
			float ZOffset = Math::Saturate(TimeSinceFinishedStand / 2) * BobHeight;
			CurrentFootLocation.Z = FootTargetLocation.Z + ZOffset + Math::Sin(TimeSinceFinishedStand * RollSwaySpeed) * BobHeight;
			const float ClawGripAmount = 80;
			ClawGrip = Math::Sin(TimeSinceFinishedStand * RollSwaySpeed * 2) * ClawGripAmount;
		}
	}

	void StandInstant() override
	{
		Super::StandInstant();
		CurrentFootLocation.Z = FootTargetLocation.Z * FootLocationCurve.GetFloatValue(MaxAnimationDuration);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void OnActorModifiedInEditor()
	{
		UAnimInstanceBabaYagaLeg AnimInstance = Cast<UAnimInstanceBabaYagaLeg>(Mesh.AnimInstance);

		CurrentFootLocation = FootTargetLocation;
		AnimInstance.SetValues(FootTargetLocation, FootTargetRotation, FVector::ZeroVector);
		

		Mesh.HazeForceUpdateAnimation(true);

		// if(bDebugSit != bDebugWasSitting)
		// {
		// 	FVector GeoLocation = Mesh.GetSocketLocation(n"UpLeg");

		// 	if(bDebugSit)
		// 		GeoLocation += TargetBaseOffset;

		// 	GeoRootMover.SetActorLocation(GeoLocation);
		// 	bDebugWasSitting = bDebugSit;
		// }
	}
	#endif
};