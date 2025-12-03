struct FGravityBikeSplineBoostActivateParams
{
	float TimeToBoost;
}

class UGravityBikeSplineBoostCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineBoostComponent BoostComp;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
		Movement = MoveComp.SetupMovementData(UGravityBikeSplineMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineBoostActivateParams& Params) const
	{
		if(!BoostComp.ForceBoost.IsEmpty())
			return true;

		if(Time::GameTimeSeconds > BoostComp.BoostUntilTime)
			return false;

		Params.TimeToBoost = BoostComp.TimeToBoost;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BoostComp.ForceBoost.IsEmpty())
			return false;

		if(ActiveDuration > BoostComp.TimeToBoost)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineBoostActivateParams Params)
	{
		UGravityBikeSplineEventHandler::Trigger_OnBoostStart(GravityBike);

		GravityBike.AnimationData.bIsBoosting = true;

		BoostComp.TimeToBoost = Params.TimeToBoost;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnBoostEnd(GravityBike);

		GravityBike.AnimationData.bIsBoosting = false;
		GravityBike.AnimationData.BoostAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GravityBike.AnimationData.BoostAlpha = BoostComp.GetBoostFactor();
	}
}