class UStoneBeastTailSegmentReturnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AStoneBeastTailSegment TailSegment;

	FTransform StartTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailSegment = Cast<AStoneBeastTailSegment>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TailSegment.bIsControllingActor)
			return false;

		if (TailSegment.bIsActive)
			return false;

		if (!TailSegment.bIsReturning)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TailSegment.bIsActive)
			return true;

		if (!TailSegment.bIsReturning)
			return true;

		if (ActiveDuration >= TailSegment.CurrentStopDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartTransform = TailSegment.SegmentTransform;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TailSegment.bIsReturning = false;
		FVector NewLocation = TailSegment.OriginalTransform.Location;
		FQuat NewRotation = TailSegment.OriginalTransform.Rotation;
		TailSegment.SetSegmentLocationAndRotation(NewLocation, NewRotation.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / Math::Max(TailSegment.CurrentStopDuration, MIN_flt));
		FVector NewLocation = Math::Lerp(StartTransform.Location, TailSegment.OriginalTransform.Location, Alpha);
		FQuat NewRotation = FQuat::Slerp(StartTransform.Rotation, TailSegment.OriginalTransform.Rotation, Alpha);
		TailSegment.SetSegmentLocationAndRotation(NewLocation, NewRotation.Rotator());
	}
};