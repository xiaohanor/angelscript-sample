class USerpentHeadSplineMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 60;

	ASerpentHead SerpentHead;
	USerpentMovementSettings MovementSettings;
	FHazeAcceleratedQuat ActorRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SerpentHead = Cast<ASerpentHead>(Owner);
		MovementSettings = USerpentMovementSettings::GetSettings(SerpentHead);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SerpentHead.bIsActive)
			return false;

		if (SerpentHead.SerpentMovementState != ESerpentMovementState::UseSpline)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SerpentHead.bIsActive)
			return true;

		if (SerpentHead.SerpentMovementState != ESerpentMovementState::UseSpline)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ActorRotation.SnapTo(SerpentHead.ActorQuat);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TotalSpeed = SerpentHead.MovementSpeed;

		if (SerpentHead.bRubberbanding)
			TotalSpeed += SerpentHead.RubberbandSpeed;
		
		float MoveDistance = TotalSpeed * DeltaTime;

		bool bCouldMove = SerpentHead.CurrentSplinePosition.Move(MoveDistance);

		FVector HeadLocation = SerpentHead.CurrentSplinePosition.WorldLocation;
		FQuat HeadRotationTarget = SerpentHead.CurrentSplinePosition.WorldRotation;
		FQuat HeadRotation = ActorRotation.AccelerateTo(HeadRotationTarget, 1.5, DeltaTime);
		
		SerpentHead.SetActorLocationAndRotation(HeadLocation, HeadRotation);

		if(!bCouldMove)
		{
			if (SerpentHead.HasNextSplineAvailable() && SerpentHead.bCanTransitionToSplines)
				SerpentHead.TransitionToNextSpline();
			else
				SerpentHead.SerpentMovementState = ESerpentMovementState::Stopped;
		}
	}
};