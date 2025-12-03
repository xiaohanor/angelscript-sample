class UGravityBikeSplineSteeringCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);

    default TickGroup = EHazeTickGroup::Input;
    default TickGroupOrder = 100;

    AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineSteeringComponent SteeringComp;
	UGravityBikeSplineAutoSteerComponent AutoSteerComp;
	float PreviousSteeringDir;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
		SteeringComp = GravityBike.SteeringComp;
		AutoSteerComp = UGravityBikeSplineAutoSteerComponent::Get(GravityBike);
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
		SteeringComp.AccSteering.SnapTo(0);

		if(HasControl())
			GravityBike.SnapTurnReferenceRotation(GravityBike.ActorQuat);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(HasControl())
		{
			TickControl(DeltaTime);
		}
		else
		{
			TickRemote(DeltaTime);
		}
    }

	void TickControl(float DeltaTime)
	{
		if(GravityBike.SplineLockComp.HasActiveSplineLock())
		{
        	SteeringComp.AccSteering.AccelerateTo(0, GravityBike.Settings.SteeringReturnDuration, DeltaTime);
			return;
		}

        float Steering = GravityBike.Input.GetSteering();

		if(AutoSteerComp != nullptr)
			AutoSteerComp.TryApplyAutoSteer(Steering);

		const bool bIsSteering = Math::Abs(Steering) > 0.2;

        if(!SteeringComp.bCenterSteering.Get() && !bIsSteering)
            return;

        float SteeringDuration = GravityBike.Settings.SteeringDuration;
        if(!bIsSteering)
            SteeringDuration = GravityBike.Settings.SteeringReturnDuration;

        SteeringDuration /= SteeringComp.SteeringMultiplier.Get();

        SteeringComp.AccSteering.AccelerateTo(Steering, SteeringDuration, DeltaTime);

		if(Math::Abs(SteeringComp.AccSteering.Value) > KINDA_SMALL_NUMBER)
			PreviousSteeringDir = Math::Sign(SteeringComp.AccSteering.Value);

		if(Math::Abs(PreviousSteeringDir) > KINDA_SMALL_NUMBER)
		{
			FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
			TraceSettings.UseSphereShape(GravityBike.Sphere.SphereRadius - 5);
			FVector SteeringDirection = GravityBike.GetSplineRight() * PreviousSteeringDir;
			const FHitResult Hit = TraceSettings.QueryTraceSingle(
				GravityBike.Sphere.WorldLocation,
				GravityBike.Sphere.WorldLocation + SteeringDirection * (GravityBike.Sphere.SphereRadius)
			);

			if(Hit.IsValidBlockingHit() && Hit.ImpactNormal.GetAngleDegreesTo(FVector::UpVector) > 70)
			{
				// It's a wall!
				MoveComp.SetSteeringWallHit(Hit);
			}
		}
	}

	void TickRemote(float DeltaTime)
	{
        float Steering = GravityBike.Input.GetSteering();

		const bool bIsSteering = Math::Abs(Steering) > 0.2;

        if(!SteeringComp.bCenterSteering.Get() && !bIsSteering)
            return;

        float SteeringDuration = GravityBike.Settings.SteeringDuration;
        if(!bIsSteering)
            SteeringDuration = GravityBike.Settings.SteeringReturnDuration;

        SteeringDuration /= SteeringComp.SteeringMultiplier.Get();

        SteeringComp.AccSteering.AccelerateTo(Steering, SteeringDuration, DeltaTime);
	}
}