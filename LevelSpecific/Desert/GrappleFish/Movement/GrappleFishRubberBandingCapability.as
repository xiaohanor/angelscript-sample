class UDesertGrappleFishRubberBandingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	ADesertGrappleFish GrappleFish;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleFish = Cast<ADesertGrappleFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return true;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
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
		float SplineDist = GrappleFish.AutoPilotSplinePosition.CurrentSplineDistance;
		float OtherSharkSplineDist = GrappleFish.OtherFish.AutoPilotSplinePosition.CurrentSplineDistance;
		float DistanceDiff = Math::Abs(OtherSharkSplineDist - SplineDist);
		float DesiredSpeed = 0;
		FVector2D CloseRubberBandRange = FVector2D(0, GrappleFishMovement::IdealSharkDistance);
		FVector2D FarRubberBandRange = FVector2D(GrappleFishMovement::IdealSharkDistance, GrappleFishMovement::IdealSharkDistance * 1.25);

		const float MinSpeed = GrappleFishMovement::MinRubberbandAdditiveMoveSpeed;
		const float MaxSpeed = GrappleFishMovement::MaxRubberbandAdditiveMoveSpeed;

		if (SplineDist > OtherSharkSplineDist)
		{
			if (DistanceDiff <= GrappleFishMovement::IdealSharkDistance)
			{
				DesiredSpeed = Math::GetMappedRangeValueClamped(CloseRubberBandRange, FVector2D(MaxSpeed, 0), DistanceDiff);
			}
			else
			{
				DesiredSpeed = Math::GetMappedRangeValueClamped(FarRubberBandRange, FVector2D(0, MinSpeed), DistanceDiff);
			}
		}
		else
		{
			if (DistanceDiff <= GrappleFishMovement::IdealSharkDistance)
			{
				DesiredSpeed = Math::GetMappedRangeValueClamped(CloseRubberBandRange, FVector2D(MinSpeed, 0), DistanceDiff);
			}
			else
			{
				DesiredSpeed = Math::GetMappedRangeValueClamped(FarRubberBandRange, FVector2D(0, MaxSpeed), DistanceDiff);
			}
		}
		GrappleFish.RubberbandAdditiveSpeed = DesiredSpeed;
	}
};