class UStormFallDragonSplineMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormFallDragonSplineMovementCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	
	AStormFallDragonSplineMover StormDragon;
	UHazeSplineComponent SplineComp;
	FSplinePosition SplineData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormFallDragonSplineMover>(Owner);
		SplineComp = UHazeSplineComponent::Get(StormDragon.Spline);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StormDragon.bActive)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!StormDragon.bActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineData = SplineComp.GetClosestSplinePositionToWorldLocation(StormDragon.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplineData.Move(StormDragon.MoveSpeed * DeltaTime);
		StormDragon.ActorLocation = SplineData.WorldLocation;
		StormDragon.ActorRotation = SplineData.WorldRotation.Rotator();
	}
}