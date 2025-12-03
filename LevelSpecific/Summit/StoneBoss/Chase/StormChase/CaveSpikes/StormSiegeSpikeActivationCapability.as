class UStormSiegeSpikeActivationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStormSiegeRockSpikes RockSpike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RockSpike = Cast<AStormSiegeRockSpikes>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!RockSpike.bCheckActivationDistances)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!RockSpike.bCheckActivationDistances)
			return true;

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
		float PlayerDistance = RockSpike.Spline.GetClosestSplineDistanceToWorldLocation((Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2);

		// PrintToScreen("PlayerDistance: " + PlayerDistance);
		// PrintToScreen("ActivationDistance: " +RockSpike.ActivationDistance);

		if (PlayerDistance > RockSpike.ActivationDistance)
		{
			RockSpike.ActivateFallingSpikes();
			RockSpike.bCheckActivationDistances = false;
		}
	}
};