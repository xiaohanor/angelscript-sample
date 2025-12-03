class UIslandJetpackShieldotronTakeOffBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	UIslandJetpackShieldotronComponent JetpackComp;

	FRuntimeFloatCurve Speed;	
	default Speed.AddDefaultKey(0.0, 0.1);
	default Speed.AddDefaultKey(0.5, 1.0);
	default Speed.AddDefaultKey(1.0, 0.1);


	FHazeRuntimeSpline Spline;
	
	bool bHasValidSpline = false;
	float CooldownTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JetpackComp = UIslandJetpackShieldotronComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		//if (TargetComp.Target.GetDistanceTo(Owner) < 5000)
		//	return false;
		if (JetpackComp.CurrentFlyState != EIslandJetpackShieldotronFlyState::IsTakingOff)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!bHasValidSpline)
			return true;
		if (CooldownTime > Time::GameTimeSeconds)
			return true;
		if (JetpackComp.CurrentFlyState != EIslandJetpackShieldotronFlyState::IsTakingOff)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		Super::OnActivated();
		// Create runtimespline
		// This does not consider walls or other obstacles
		FVector TargetLocation = Owner.ActorLocation + FVector(200, 0, 600);
		FVector ToTarget = (TargetLocation - Owner.ActorLocation);
		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(Owner.ActorLocation);
		FVector InterPoint = Owner.ActorLocation + ToTarget * 0.75;
		InterPoint.Z = Owner.ActorLocation.Z + (TargetLocation.Z - Owner.ActorLocation.Z) * 0.66;
		Spline.AddPoint(InterPoint);		
		Spline.AddPoint(TargetLocation);
		//Spline.DrawDebugSpline(Duration = 10.0);
		//Debug::DrawDebugSphere(TargetLocation, Duration = 10.0);
		DistanceAlongSpline = 0;
		bHasValidSpline = true;
		if (Spline.GetLength() < SMALL_NUMBER)
			bHasValidSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		JetpackComp.SetCurrentFlyState(EIslandJetpackShieldotronFlyState::IsAirBorne);
	}

	float DistanceAlongSpline = 0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: remove temp debug lines
		// if (Droid.RiderActor.TargetingComponent.HasValidTarget())
		// 	Droid.DestinationComp.MoveTowardsIgnorePathfinding(Waypoint.ActorLocation, 500);
		// Droid.DestinationComp.MoveTowardsIgnorePathfinding(Droid.RiderActor.TargetingComponent.Target.ActorLocation, 500);

		// Follow spline
		if(!bHasValidSpline)
			return;

		DistanceAlongSpline += 1500 * Speed.GetFloatValue(DistanceAlongSpline/Spline.GetLength()) * DeltaTime; // TODO: setting

		if (DistanceAlongSpline > Spline.GetLength() - 50)
		{
			CooldownTime = Time::GameTimeSeconds + 1.0; // Will deactivate capability
			return;
		}

		float SplineAlpha = DistanceAlongSpline/Spline.GetLength();
		FVector NewLocation = Spline.GetLocation(SplineAlpha);		
		FVector NewUpVector = Spline.GetUpDirection(SplineAlpha);
		FQuat QuatAtDistance = Spline.GetQuat(SplineAlpha);
		//FQuat CurrentRotation = FQuat::Slerp(QuatAtDistance, FQuat::MakeFromZX(NewUpVector, QuatAtDistance.ForwardVector), SplineAlpha); // TODO: simplify
		
		Owner.SetActorLocation(NewLocation);
	}
};