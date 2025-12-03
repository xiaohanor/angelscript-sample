class UGravityBikeSplineWaterTrailCapability : UHazeCapability
{
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
		if(!GravityBike.Settings.bUseWaterTrail)
			return false;

		if(!MoveComp.IsOnAnyGround())
			return false;

		if(MoveComp.GroundContact.ImpactNormal.DotProduct(FVector::UpVector) < -0.1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GravityBike.Settings.bUseWaterTrail)
			return true;

		if(!MoveComp.IsOnAnyGround())
			return true;

		if(MoveComp.GroundContact.ImpactNormal.DotProduct(FVector::UpVector) < -0.1)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnWaterTrailStart(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGravityBikeSplineEventHandler::Trigger_OnWaterTrailEnd(GravityBike);
	}
}