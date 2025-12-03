class UHoverPerchHitObstacleBoostCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 75;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHoverPerchActor HoverPerch;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverPerch = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HoverPerch.PostDestroyObstacleBoostDurationRemaining == 0.0)
			return false;

		if(HoverPerch.GrindSpeedMultiplierAfterDestroyedObstacle == 1.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HoverPerch.PostDestroyObstacleBoostDurationRemaining == 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HoverPerch.InstigatedGrindSpeedMultiplier.ApplyMultiplier(HoverPerch.GrindSpeedMultiplierAfterDestroyedObstacle, this);

		SpeedEffect::RequestSpeedEffect(HoverPerch.PlayerLocker, 1.0, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HoverPerch.InstigatedGrindSpeedMultiplier.ClearMultiplier(this);

		SpeedEffect::ClearSpeedEffect(HoverPerch.PlayerLocker, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HoverPerch.PostDestroyObstacleBoostDurationRemaining -= DeltaTime;
		HoverPerch.PostDestroyObstacleBoostDurationRemaining = Math::Max(0.0, HoverPerch.PostDestroyObstacleBoostDurationRemaining);
	}
}