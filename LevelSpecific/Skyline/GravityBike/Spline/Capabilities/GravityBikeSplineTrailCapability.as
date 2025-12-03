class UGravityBikeSplineTrailCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
    default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GravityBike.IsBoosting())
			return false;

		if(!MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GravityBike.IsBoosting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnForwardStart(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnForwardEnd(GravityBike);
	}
}