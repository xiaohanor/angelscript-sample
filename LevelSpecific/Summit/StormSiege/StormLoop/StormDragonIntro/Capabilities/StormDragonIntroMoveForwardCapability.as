class UStormDragonIntroMoveForwardCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonIntroMoveForwardCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormDragonIntro StormDragon;
	float TotalTimeToReachpoint;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonIntro>(Owner);
		TotalTimeToReachpoint = StormDragon.TimeToReachPoint + StormDragon.AdditionaDelayToReachpoint;
		Speed = (StormDragon.ActorLocation - StormDragon.TargetPoint.ActorLocation).Size() / TotalTimeToReachpoint;
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
		StormDragon.ActorLocation = Math::VInterpConstantTo(StormDragon.ActorLocation, StormDragon.TargetPoint.ActorLocation, DeltaTime, Speed);
		PrintToScreen("StormDragon.ActorLocation: " + StormDragon.ActorLocation);
	}
}