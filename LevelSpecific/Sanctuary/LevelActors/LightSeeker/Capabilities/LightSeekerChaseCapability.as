class ULightSeekerChaseCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightSeekerChase");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ALightSeeker LightSeeker;
	ULightSeekerTargetingComponent TargetingComp;
	bool bTriggeredSpeedInterpolation = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		TargetingComp = ULightSeekerTargetingComponent::Get(LightSeeker);
		LightSeeker.ChaseSpeedTimeLike.BindUpdate(this, n"OnChaseSpeedUpdate");
		LightSeeker.ChaseSpeedTimeLike.BindFinished(this, n"OnChaseSpeedFinished");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TargetingComp.HasActiveLightBirdTarget())
			return true;

		if (!HasControl())
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TargetingComp.HasActiveLightBirdTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LightSeeker.bIsChasing = true;
		LightSeeker.BlockCapabilities(n"LightSeekerSleep", this);
		TargetingComp.ChaseSpeedBoost = 0.0;
		bTriggeredSpeedInterpolation = false;

		if (!LightSeekerStatics::GetManager().bAnyLightseekerEmerged)
		{
			LightSeekerStatics::GetManager().bAnyLightseekerEmerged = true;
			LightSeekerStatics::GetManager().OnFirstLightSeekerEmerge.Broadcast();
			ULightSeekerEventHandler::Trigger_FirstStartChasingLight(LightSeeker);
		}

		ULightSeekerEventHandler::Trigger_StartChasingLight(LightSeeker);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LightSeeker.bIsChasing = false;
		LightSeeker.UnblockCapabilities(n"LightSeekerSleep", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ChaseBehavior(DeltaTime);
	}

	void ChaseBehavior(float DeltaTime)
	{
		FVector BirdLocation = TargetingComp.GetLightBirdLocation();
		if (LightSeeker.bDebugging)
		{
			PrintToScreen("Chasing", 0.0, FLinearColor::Green);
			Debug::DrawDebugLine(LightSeeker.Head.WorldLocation, BirdLocation, FLinearColor::Green, 2.0, 0.0);
		}
		
		FVector OriginToHead = LightSeeker.Origin.WorldLocation - LightSeeker.Head.WorldLocation;
		FVector LookDirection = FVector::OneVector;
		FVector TargetLocation;
		if (OriginToHead.Size() < LightSeeker.DistanceToBeStraightToBurrow - 75.0)
		{
			FVector OutOfBurrow = LightSeeker.Origin.WorldRotation.ForwardVector * LightSeeker.DistanceToBeStraightToBurrow;
			TargetLocation = LightSeeker.Origin.WorldLocation + OutOfBurrow; 
			LookDirection = OutOfBurrow;
			if (LightSeeker.bDebugging)
				PrintToScreen("Chase " + TargetLocation, 0.0);
		}
		else
		{
			FVector HeadToBird = BirdLocation - LightSeeker.Head.WorldLocation;
			HeadToBird -= HeadToBird.GetSafeNormal() * LightSeeker.DesiredOffset;
			TargetLocation = LightSeeker.Head.WorldLocation + HeadToBird;
			LookDirection = BirdLocation - LightSeeker.Head.WorldLocation;
		}

		if (!bTriggeredSpeedInterpolation)
		{
			bTriggeredSpeedInterpolation = true;
			LightSeeker.ChaseSpeedTimeLike.PlayFromStart();
		}
		TargetingComp.SyncedDesiredHeadLocation.SetValue(TargetLocation);
		TargetingComp.SyncedDesiredHeadRotation.SetValue(FRotator::MakeFromXZ(LookDirection.GetSafeNormal(), LightSeeker.Origin.UpVector));
	}

	UFUNCTION()
	private void OnChaseSpeedUpdate(float Value)
	{
		TargetingComp.ChaseSpeedBoost = Value;
	}

	UFUNCTION()
	private void OnChaseSpeedFinished()
	{
		TargetingComp.ChaseSpeedBoost = 1.0;
	}
};