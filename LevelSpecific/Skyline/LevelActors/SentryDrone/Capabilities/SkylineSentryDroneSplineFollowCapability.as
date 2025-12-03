class USkylineSentryDroneSplineFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneSplineFollow");
	default CapabilityTags.Add(n"SkylineDroneMovement");

	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	ASkylineSentryDrone SentryDrone;

	USkylineSentryDroneSettings Settings;

	float DistanceOnSpline = 0.0;

	float Direction = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USkylineSentryDroneSettings::GetSettings(Owner);

		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();

		SentryDrone = Cast<ASkylineSentryDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SentryDrone.Spline == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SentryDrone.Spline == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"SkylineDroneHover", this);
		Owner.BlockCapabilities(n"SkylineDroneLookAt", this);

		DistanceOnSpline = SentryDrone.Spline.GetClosestSplineDistanceToWorldLocation(SentryDrone.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SkylineDroneHover", this);
		Owner.UnblockCapabilities(n"SkylineDroneLookAt", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DistanceOnSpline += Settings.SplineFollowSpeed * Direction * DeltaTime;

		if (DistanceOnSpline < 0.0 || DistanceOnSpline >= SentryDrone.Spline.SplineLength)
		{
			if (SentryDrone.Spline.IsClosedLoop())
				DistanceOnSpline -= SentryDrone.Spline.SplineLength * Direction;
			else
			{
				Direction *= -1.0;
			//	SentryDrone.bShouldStabilize = true;
			}
		}

		FTransform TransformAtDistance = SentryDrone.Spline.GetWorldTransformAtSplineDistance(DistanceOnSpline);

		SentryDrone.MoveToTarget(TransformAtDistance.Location, this);
	}
}