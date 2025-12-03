class USummitHittablePlatformMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitLargeHittablePlatform Platform;
	FSplinePosition SplinePosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ASummitLargeHittablePlatform>(Owner);
		auto SplineComp = Platform.SplineActor.Spline;
		SplinePosition = SplineComp.GetSplinePositionAtSplineDistance(0);
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
		Platform.Force -= Platform.GetLoseForceAmount() * DeltaTime;
		Platform.Force = Math::Clamp(Platform.Force, -Platform.ImpactForce, Platform.ImpactForce);
		SplinePosition.Move(Platform.Force * DeltaTime);
		Platform.ActorLocation = SplinePosition.WorldLocation;

		if (Platform.Force < 0 && SplinePosition.GetCurrentSplineDistance() == 0)
		{
			if (Math::Abs(Platform.Force) > 100.0)
				Platform.Force = Math::Abs(Platform.Force * 0.25); 
			else
				Platform.Force = 0.0;
		}
	}
};