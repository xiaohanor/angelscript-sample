class UGravityBikeSplineAutoSteerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineAutoSteerComponent AutoSteerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
		AutoSteerComp = UGravityBikeSplineAutoSteerComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(AutoSteerComp.Settings.IsDefaultValue())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AutoSteerComp.Settings.IsDefaultValue())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AutoSteerComp.bIsAutoSteering = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AutoSteerComp.bIsAutoSteering = false;
	}
};