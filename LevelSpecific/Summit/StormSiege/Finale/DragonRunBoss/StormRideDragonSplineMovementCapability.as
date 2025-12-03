class UStormRideDragonSplineMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormRideDragonSplineMovementCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	
	AStormRideDragon StormDragon;
	UHazeSplineComponent SplineComp;
	FSplinePosition SplineData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormRideDragon>(Owner);
		if(StormDragon.Spline != nullptr)
			SplineComp = UHazeSplineComponent::Get(StormDragon.Spline);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplineComp == nullptr)
			return false;
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
		SplineData = SplineComp.GetClosestSplinePositionToWorldLocation(StormDragon.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplineData.Move(StormDragon.MoveSpeed * DeltaTime);
		StormDragon.ActorLocation = SplineData.WorldLocation + StormDragon.OffsetMovement;
		StormDragon.ActorRotation = SplineData.WorldRotation.Rotator();
	}
}