class UGravityBikeSplineThrottleForceFeedbackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSpline Bike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bike = Cast<AGravityBikeSpline>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Bike.GetImmediateThrottle() < 0.1)
			return false;

		if(Bike.IsAirborne.Get())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Bike.GetImmediateThrottle() < 0.1)
			return true;

		if(Bike.IsAirborne.Get())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnThrottleForceFeedbackStart(Bike);
		Bike.AnimationData.bIsThrottling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnThrottleForceFeedbackStopped(Bike);
		Bike.AnimationData.bIsThrottling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};