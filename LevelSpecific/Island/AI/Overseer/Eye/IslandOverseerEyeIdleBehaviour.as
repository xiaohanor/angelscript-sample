
class UIslandOverseerEyeIdleBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	AAIIslandOverseerEye Eye;
	UIslandOverseerEyeSettings Settings;
	UHazeSplineComponent Spline;
	FSplinePosition StartSplinePosition;
	bool bArrived;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		Settings = UIslandOverseerEyeSettings::GetSettings(Owner);
		Spline = Eye.EyesComp.IdleSplineActor.Spline;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!Eye.Active)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bArrived = false;
		float Distance = 0;
		if(!Eye.bBlue)
			Distance = Spline.SplineLength;
		StartSplinePosition = FSplinePosition(Spline, Distance, true);	
		Eye.Speed = 900;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MidLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		FVector Forward = (MidLocation - Eye.ActorLocation).ConstrainToPlane(Eye.Boss.ActorForwardVector);
		DestinationComp.RotateInDirection(Forward);

		if(!bArrived)
		{
			Eye.AccSpeed.AccelerateTo(Eye.Speed, 0.5, DeltaTime);
			DestinationComp.MoveTowardsIgnorePathfinding(StartSplinePosition.WorldLocation, Eye.Speed);
			if(Owner.ActorLocation.PointsAreNear(StartSplinePosition.WorldLocation, 50))
			{
				bArrived = true;
				Eye.Speed = 200;
				DestinationComp.FollowSplinePosition = StartSplinePosition;
			}
			return;
		}

		Eye.AccSpeed.AccelerateTo(Eye.Speed, 2, DeltaTime);
		DestinationComp.MoveAlongSpline(Spline, Eye.AccSpeed.Value);
	}
}