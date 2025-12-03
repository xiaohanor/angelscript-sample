class ULightSeekerTargetingComponent : UActorComponent
{
	ALightSeeker LightSeeker;
	private ULightBirdUserComponent LightBirdComp;

	bool bHasCalculatedBirdTargetThisFrame = false;
	bool bCachedHasLighBirdTarget = false;

	float LocationInterpolationProgress = 1.0;
	float RotationInterpolationProgress = 1.0;

	UHazeCrumbSyncedVectorComponent SyncedDesiredHeadLocation;
	UHazeCrumbSyncedRotatorComponent SyncedDesiredHeadRotation;
	// FVector DesiredHeadLocation;
	// FQuat DesiredHeadRotation;

	float ChaseSpeedBoost = 1.0; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FString SyncedHeadName = "HeadSyncedComp_";
		SyncedDesiredHeadLocation = UHazeCrumbSyncedVectorComponent::Create(Owner, FName(SyncedHeadName + "Location"));
		SyncedDesiredHeadRotation = UHazeCrumbSyncedRotatorComponent::Create(Owner, FName(SyncedHeadName + "Rotation"));
		LightSeeker = Cast<ALightSeeker>(Owner);

		// DesiredHeadRotation = LightSeeker.Origin.WorldRotation.Quaternion();
		// DesiredHeadLocation = LightSeeker.Origin.WorldLocation;

		SyncedDesiredHeadLocation.SetValue(LightSeeker.Origin.WorldLocation);
		SyncedDesiredHeadRotation.SetValue(LightSeeker.Origin.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) 
	{
		bHasCalculatedBirdTargetThisFrame = false;
		if (LightBirdComp == nullptr)
			LightBirdComp = ULightBirdUserComponent::Get(Game::Mio);
#if EDITOR
		TEMPORAL_LOG(Owner, "HeadSyncedComp_Location").Value("Loc", SyncedDesiredHeadLocation.Value);
#endif
	}

	bool HasActiveLightBirdTarget()
	{
		if (bHasCalculatedBirdTargetThisFrame)
			return bCachedHasLighBirdTarget;

		bCachedHasLighBirdTarget = InternalHasActiveLightBirdTarget();
		bHasCalculatedBirdTargetThisFrame = true;
		return bCachedHasLighBirdTarget;
	}

	private bool InternalHasActiveLightBirdTarget() const
	{
		if (LightBirdComp == nullptr)
			return false;

		if (!LightBirdComp.IsIlluminating())
			return false;

		FVector HeadLocation = LightSeeker.Head.WorldLocation;
		FVector BirdLocation = LightBirdComp.GetLightBirdLocation();
		FVector ToBird = BirdLocation - HeadLocation;

		if (ToBird.Size() > LightSeeker.DetectionRange)
		{
			if (LightSeeker.bDebugging)
				PrintToScreen("Out of Range: " + LightSeeker.Name, 0.0, FLinearColor::Yellow);

			return false;
		}
		
		FVector OriginToBird = BirdLocation - LightSeeker.Origin.WorldLocation;
		float AngleToBird = LightSeeker.ActorForwardVector.GetAngleDegreesTo(OriginToBird);
		if (AngleToBird > LightSeeker.DetectionAngle)
		{
			if (LightSeeker.bDebugging)
			{
				Debug::DrawDebugLine(HeadLocation, BirdLocation, FLinearColor::LucBlue, 10.0, 0.0);
				PrintToScreen("Back Angle: " + AngleToBird + " - " + LightSeeker.Name, 0.0, FLinearColor::Blue);
			}

			return false;
		}

		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		auto HitResult = Trace.QueryTraceSingle(LightSeeker.Origin.WorldLocation + LightSeeker.Origin.ForwardVector * 300.0, BirdLocation);

		if (HitResult.bBlockingHit)
		{
			if (LightSeeker.bDebugging)
			{
				Debug::DrawDebugLine(HeadLocation + Owner.ActorForwardVector * 300.0, BirdLocation, FLinearColor::Red, 10.0, 0.0);
				Debug::DrawDebugLine(HeadLocation, BirdLocation, FLinearColor::Red, 10.0, 0.0);
				PrintToScreen("Blocking hit: " + LightSeeker.Name, 0.0, FLinearColor::Red);
			}
			return false;
		}

		if (LightSeeker.bDebugging)
			PrintToScreen("In range: " + LightSeeker.Name, 0.0, FLinearColor::DPink);

		return true;
	}

	FVector GetOriginToBirdWithOffset()
	{
		FVector BirdLocation = GetLightBirdLocation();
		FVector OriginToBird = BirdLocation - LightSeeker.Origin.WorldLocation;
		FVector DesiredOffsetOriginToBird = OriginToBird.GetSafeNormal() * LightSeeker.DesiredOffset;
		return OriginToBird - DesiredOffsetOriginToBird;
	}

	FVector GetLightBirdLocation() const
	{
		if (LightBirdComp != nullptr)
			return LightBirdComp.GetLightBirdLocation();

		return FVector::ZeroVector;
	}
}