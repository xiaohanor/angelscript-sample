class USummitBallistaWeightedPlatformCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitBallista Ballista;

	FHazeAcceleratedVector AccelVec;
	FVector TargetLocation;
	FVector StartLocation;
	FVector RelativeOffset = FVector(0,0,-55);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ballista = Cast<ASummitBallista>(Owner);
		StartLocation = Ballista.WeightedPlatformRoot.RelativeLocation;
		AccelVec.SnapTo(StartLocation);
		TargetLocation = StartLocation + RelativeOffset;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
		if (Ballista.bHasWeight)
		{
			FVector DeltaToTarget = TargetLocation - AccelVec.Value;
			AccelVec.AccelerateTo(TargetLocation, 1.0, DeltaTime);
			if(DeltaToTarget.IsNearlyZero(5)
			&& Ballista.bBasketLoweringSoundPlaying)
			{
				USummitBallistaEventHandler::Trigger_OnCartStoppedLowering(Ballista);
				Ballista.bBasketLoweringSoundPlaying = false;
			}
		}
		else
		{
			FVector DeltaToStart = StartLocation - AccelVec.Value;
			AccelVec.AccelerateTo(StartLocation, 1.0, DeltaTime);
			if(DeltaToStart.IsNearlyZero(5)
			&& Ballista.bBasketRaisingSoundPlaying)
			{
				USummitBallistaEventHandler::Trigger_OnCartStoppedRaising(Ballista);
				Ballista.bBasketRaisingSoundPlaying = false;
			}
		}

		Ballista.WeightedPlatformRoot.RelativeLocation = AccelVec.Value;

		// PrintToScreen(f"{AccelVec.Value=}");
	}
};