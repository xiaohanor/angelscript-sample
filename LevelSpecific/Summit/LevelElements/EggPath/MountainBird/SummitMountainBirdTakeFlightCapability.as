class USummitMountainBirdTakeFlightCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UBasicAIDestinationComponent DestComp;

	AAISummitMountainBird MountainBird;	

	FRuntimeFloatCurve Speed;	
	default Speed.AddDefaultKey(0.0, 0.25);
	default Speed.AddDefaultKey(0.1, 0.5);
	default Speed.AddDefaultKey(0.25, 0.9);	
	default Speed.AddDefaultKey(1.0, 0.9);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.1);
	default Rotation.AddDefaultKey(0.1, 0.15);
	//default Rotation.AddDefaultKey(1.0, 0.2);
	default Rotation.AddDefaultKey(1.0, 1.0);


	FHazeRuntimeSpline Spline;
	
	bool bHasValidSpline = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		MountainBird = Cast<AAISummitMountainBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::TakeFlight)
			return false;
		if (MountainBird.EscapeLocation == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bHasValidSpline)
		 	return true;
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::TakeFlight)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MountainBird.SetCurrentState(ESummitMountainBirdFlightState::TakeFlight);
		if (MountainBird.CurrentLandingSpot != nullptr)
			MountainBird.CurrentLandingSpot.Release();

		SummitMountainBird::Animations::PlayTakeOffAnimation(MountainBird);
		USummitMountainBirdEventHandler::Trigger_OnTakeOff(Owner);

		// Try set TargetLocation
		FVector TargetLocation;
		TargetLocation = MountainBird.EscapeLocation.ActorLocation;

		// Create runtimespline for move trajectory
		// This, currently, does not consider walls or other obstacles
		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(Owner.ActorLocation); // Start
		
		AHazePlayerCharacter Player = Game::GetClosestPlayer(Owner.ActorLocation);
		FVector FromPlayer = (Owner.ActorLocation - Player.ActorLocation).GetSafeNormal2D();
		Spline.AddPoint(Owner.ActorLocation + Owner.ActorForwardVector * 300 + FromPlayer * 300 + FVector(0,0,300)); // Start

		// If destination is further away, add some curvature
		FVector ToTargetLocation = (TargetLocation - Owner.ActorLocation);
		FVector InterPoint = Owner.ActorLocation + ToTargetLocation * 0.25;
		InterPoint.Z = Owner.ActorLocation.Z + (TargetLocation.Z - Owner.ActorLocation.Z) * 0.2; // Height offset
		Spline.AddPoint(InterPoint);
		
		FVector EndInterPoint = Owner.ActorLocation + ToTargetLocation * 0.75;
		EndInterPoint.Z = TargetLocation.Z + 100; // Height offset
		Spline.AddPoint(EndInterPoint);
		
		Spline.AddPoint(TargetLocation); // End
		
		//Spline.DrawDebugSpline(Duration = 10.0, Width = 2.0);
		//Debug::DrawDebugSphere(TargetLocation, 50, Duration = 10.0);
		
		DistanceAlongSpline = 0;
		bHasValidSpline = true;
		bHasStartedFlapAnimation = false;
		if (Spline.GetLength() < SMALL_NUMBER)
			bHasValidSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MountainBird.SetCurrentState(ESummitMountainBirdFlightState::Hover);
	}

	float DistanceAlongSpline = 0;
	bool bHasStartedFlapAnimation = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Follow spline
		if(!bHasValidSpline)
			return;

		if (ActiveDuration > MountainBird.TakeOffAnimation.SequenceLength && !bHasStartedFlapAnimation)
		{
			SummitMountainBird::Animations::PlayFlapAnimation(MountainBird);
			bHasStartedFlapAnimation = true;
		}

		DistanceAlongSpline += 2000 * Speed.GetFloatValue(DistanceAlongSpline/Spline.GetLength()) * DeltaTime; // TODO: speed setting

		if (DistanceAlongSpline > Spline.GetLength() - 50)
		{
			MountainBird.SetCurrentState(ESummitMountainBirdFlightState::Hover); // Will deactivate capability
			return;
		}

		float SplineAlpha = DistanceAlongSpline/Spline.GetLength();
		FVector NewLocation = Spline.GetLocation(SplineAlpha);
		FVector NewUpVector = Spline.GetUpDirection(SplineAlpha);
		FQuat QuatAtDistance = Spline.GetQuat(SplineAlpha);
		
		FQuat NewRotation;
		NewRotation = FQuat::Slerp(Owner.ActorRotation.Quaternion(), QuatAtDistance, Rotation.GetFloatValue(SplineAlpha));
		
		//Debug::DrawDebugCoordinateSystem(NewLocation, NewRotation.Rotator(), 100, 3, 0, true);
		
		Owner.SetActorLocationAndRotation(NewLocation, NewRotation);
	}
	
};