class USerpentHeadTransitionMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 60;

	ASerpentHead SerpentHead;
	FTransform TargetTransform;
	USerpentMovementSettings MovementSettings;
	float RotationSpeed;
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

		if (SerpentHead.SerpentMovementState != ESerpentMovementState::TransitionToSpline)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SerpentHead.bIsActive)
			return true;

		if (SerpentHead.SerpentMovementState != ESerpentMovementState::TransitionToSpline)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetTransform = SerpentHead.CurrentSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(SerpentHead.ActorLocation);

		float Distance = TargetTransform.Location.Distance(SerpentHead.ActorLocation);
		RotationSpeed = Distance / MovementSettings.BaseMovementSpeed; 
		ActorRotation.SnapTo(SerpentHead.ActorQuat);
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MoveAmount = SerpentHead.MovementSpeed;
		if (SerpentHead.bRubberbanding)
			MoveAmount += SerpentHead.RubberbandSpeed;
		
		FVector TargetLocation = Math::VInterpConstantTo(SerpentHead.ActorLocation, TargetTransform.Location, DeltaTime, MoveAmount);
		FQuat HeadRotation = ActorRotation.AccelerateTo(TargetTransform.Rotation, RotationSpeed, DeltaTime);

		SerpentHead.SetActorLocationAndRotation(TargetLocation, HeadRotation);
		if(TargetLocation.Distance(TargetTransform.Location) < KINDA_SMALL_NUMBER)
		{
			SerpentHead.CompleteSplineTransition();
		}
	}
};