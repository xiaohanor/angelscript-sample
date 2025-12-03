class UGravityBikeSplineBoostFOVCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::Camera);

	default TickGroup = EHazeTickGroup::Gameplay;
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
	bool ShouldActivate() const
	{
		if(!BoostComp.IsBoosting())
			return false;

		if(GravityBike.IsMovementLockedToSpline())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BoostComp.IsBoosting())
			return true;

		if(GravityBike.IsMovementLockedToSpline())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UCameraSettings::GetSettings(GravityBike.GetDriver()).FOV.ApplyAsAdditive(BoostComp.Settings.BoostFOVAdditive, this, 0.5, EHazeCameraPriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(GravityBike.GetDriver()).FOV.Clear(this, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BoostComp.BoostFOVCurve == nullptr)
			return;

		const float BoostAlpha = BoostComp.GetBoostFactor();
		const float FOVFactor = BoostComp.BoostFOVCurve.GetFloatValue(ActiveDuration / BoostComp.Settings.MaxBoostTime);
		const float FOVAlpha = BoostAlpha * FOVFactor;

		UCameraSettings::GetSettings(GravityBike.GetDriver()).FOV.SetManualFraction(FOVAlpha, this);
	}
}