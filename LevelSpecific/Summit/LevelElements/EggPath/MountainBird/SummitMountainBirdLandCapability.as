class USummitMountainBirdLandCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UBasicAIDestinationComponent DestComp;

	AAISummitMountainBird MountainBird;	

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);


	FHazeRuntimeSpline Spline;
	
	bool bHasValidSpline = false;
	float CooldownTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		MountainBird = Cast<AAISummitMountainBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::Hover)
			return;

		// Check for valid landing spot.
		for (ASummitMountainBirdLandingSpot LandingSpot : TListedActors<ASummitMountainBirdLandingSpot>())
		{
			// Check within max range
			float Dist = LandingSpot.ActorLocation.Dist2D(Owner.ActorLocation);
			if (LandingSpot.ActorLocation.DistSquared2D(Owner.ActorLocation) > 3000 * 3000)
				continue;

			// Check not within min range
			if (LandingSpot.ActorLocation.DistSquared2D(Owner.ActorLocation) < 1000 * 1000)
				continue;

			// Check below current height
			const float LandingDecent = 500.0;
			if (LandingSpot.ActorLocation.Z > Owner.ActorLocation.Z - LandingDecent)
				continue;

			// Check in proper angle for landing
			float Deg = 45;
			FVector ToLandingSpot = (LandingSpot.ActorLocation - Owner.ActorLocation).GetSafeNormal2D(); 
			if (ToLandingSpot.DotProduct(Owner.ActorForwardVector.GetSafeNormal2D()) < Math::Cos(Math::DegreesToRadians(Deg)))
				continue;

			MountainBird.CurrentLandingSpot = LandingSpot;
			MountainBird.CurrentLandingSpot.Claim(Owner);
			MountainBird.SetCurrentState(ESummitMountainBirdFlightState::Land); // Activates behaviour
			break;
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			DebugDraw();
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::Land)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::Land)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MountainBird.SetCurrentState(ESummitMountainBirdFlightState::Land);

		// Try set TargetLocation
		FVector TargetLocation = MountainBird.CurrentLandingSpot.ActorLocation;
		//TargetLocation = MountainBird.HomeLocation;

		// Create runtimespline for move trajectory
		// This, currently, does not consider walls or other obstacles
		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(Owner.ActorLocation); // Start

		// remember to make first point on land path spline a bit in forward direction of bird
		FVector FirstPoint = Owner.ActorLocation + Owner.ActorForwardVector * 250;
		FirstPoint.Z -= 100; 
		Spline.AddPoint(FirstPoint);

		// Check if we need to turn around to get there.
		FVector ToTargetLocation = (TargetLocation - Owner.ActorLocation);
		if (ToTargetLocation.DotProduct(Owner.ActorForwardVector) < 0)
		{
			FVector TurnPoint = Owner.ActorLocation + Owner.ActorForwardVector * 1000; // turn radius
			TurnPoint.Z -= 400; // Add some drop

			// Closest turn to the left?
			if (ToTargetLocation.DotProduct(Owner.ActorRightVector) < 0)
			{
				TurnPoint += Owner.ActorRightVector * -500; // Add point to forward left
				Spline.AddPoint(TurnPoint);				
			}
			else
			{
				TurnPoint += Owner.ActorRightVector * 500; // Add point to forward right
				Spline.AddPoint(TurnPoint);
			}

			FVector TurnPointToTargetLocation = (TargetLocation - TurnPoint);
			FVector Midway = TurnPointToTargetLocation * 0.5;
			// TODO: smoothen out turn.


			Spline.AddPoint(TurnPoint);
		}
		
		// Add some height curvature
		FVector InterPoint = Owner.ActorLocation + ToTargetLocation * 0.25;
		InterPoint.Z = Owner.ActorLocation.Z + (TargetLocation.Z - Owner.ActorLocation.Z) * 0.33; // Height offset
		Spline.AddPoint(InterPoint);		
		
		Spline.AddPoint(TargetLocation); // End
		
		//Spline.DrawDebugSpline(Duration = 10.0, Width = 2.0);
		//Debug::DrawDebugSphere(TargetLocation, 50, Duration = 10.0);
		
		DistanceAlongSpline = 0;
		bHasValidSpline = true;
		if (Spline.GetLength() < SMALL_NUMBER)
			bHasValidSpline = false;
		
		SplineAlpha = 0.0;
		bHasStartedLandAnimation = false;
		bHasStartedGlideAnimation = false;
		USummitMountainBirdEventHandler::Trigger_OnLandingStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SummitMountainBird::Animations::PlayIdleAnimation(MountainBird); // TODO: move to idle capability
		MountainBird.SetCurrentState(ESummitMountainBirdFlightState::Idle); // Will deactivate capability
		USummitMountainBirdEventHandler::Trigger_OnLandingFinished(Owner);
	}

	float DistanceAlongSpline = 0;
	float SplineAlpha = 0.0;
	bool bHasStartedLandAnimation = false;
	bool bHasStartedGlideAnimation = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float CurrentSpeed = 1000;
		if (SplineAlpha > 0.7)
			CurrentSpeed = Math::Max(1000 * (1 - (SplineAlpha - 0.7)), 400);

		DistanceAlongSpline += CurrentSpeed * DeltaTime; // TODO: speed setting, and scale speed

		if (DistanceAlongSpline > Spline.GetLength()) // TODO: fix dist
		{			
			MountainBird.SetCurrentState(ESummitMountainBirdFlightState::Idle); // Will deactivate capability
			DistanceAlongSpline = Spline.GetLength();
		}

		SplineAlpha = DistanceAlongSpline/Spline.GetLength();
		
		
		if (SplineAlpha > 0.2 && !bHasStartedGlideAnimation)
		{
			SummitMountainBird::Animations::PlayGlideAnimation(MountainBird);
			bHasStartedGlideAnimation = true;
		}
		else if (SplineAlpha > 0.725 && !bHasStartedLandAnimation)
		{
			SummitMountainBird::Animations::PlayLandAnimation(MountainBird);
			bHasStartedLandAnimation = true;
			USummitMountainBirdEventHandler::Trigger_OnLandingBreakForGroundImpact(Owner);
		}
		FVector NewLocation = Spline.GetLocation(SplineAlpha);		
		FVector NewUpVector = Spline.GetUpDirection(SplineAlpha);
		FQuat QuatAtDistance = Spline.GetQuat(SplineAlpha);

		// Hack for smoothing out rotation in the beginning of the spline.
		FQuat NewRotation;
		if (SplineAlpha < 0.10)
			NewRotation = FQuat::Slerp(Owner.ActorRotation.Quaternion(), FQuat::MakeFromZX(NewUpVector, QuatAtDistance.ForwardVector), Rotation.GetFloatValue(SplineAlpha));
		else
			NewRotation = FQuat::Slerp(QuatAtDistance, FQuat::MakeFromZX(NewUpVector, QuatAtDistance.ForwardVector), Rotation.GetFloatValue(SplineAlpha));
		
		Owner.SetActorLocationAndRotation(NewLocation, NewRotation);
	}

#if EDITOR
	void DebugDraw()
	{
		TArray<FSummitMountainBirdDebugDraw> DebugDraws;		
		for (ASummitMountainBirdLandingSpot LandingSpot : TListedActors<ASummitMountainBirdLandingSpot>())
		{
			DebugDraws.Add(FSummitMountainBirdDebugDraw());
			DebugDraws.Last().SphereLocation = LandingSpot.ActorLocation;
			DebugDraws.Last().SphereColor = FLinearColor::Gray;
			// Check within max range
			float Dist = LandingSpot.ActorLocation.Dist2D(Owner.ActorLocation);
			DebugDraws.Last().StringLocation = LandingSpot.ActorCenterLocation + FVector(0,0,100);
			DebugDraws.Last().StringText = "" + Dist;

			if (LandingSpot.ActorLocation.DistSquared2D(Owner.ActorLocation) > 3000 * 3000)
				continue;
			DebugDraws.Last().SphereColor = FLinearColor::Blue;			

			// Check not within min range
			if (LandingSpot.ActorLocation.DistSquared2D(Owner.ActorLocation) < 1000 * 1000)
				continue;
			DebugDraws.Last().SphereColor = FLinearColor::Purple;

			// Check below current height
			const float LandingDecent = 500.0;
			if (LandingSpot.ActorLocation.Z > Owner.ActorLocation.Z - LandingDecent)
				continue;
			DebugDraws.Last().SphereColor = FLinearColor::Red;

			// Check in proper angle for landing
			float Deg = 45;
			FVector ToLandingSpot = (LandingSpot.ActorLocation - Owner.ActorLocation).GetSafeNormal2D(); 
			if (ToLandingSpot.DotProduct(Owner.ActorForwardVector.GetSafeNormal2D()) < Math::Cos(Math::DegreesToRadians(Deg)))
				continue;

			DebugDraws.Last().SphereColor = FLinearColor::Green;
			break;
		}

		for (FSummitMountainBirdDebugDraw Draw : DebugDraws)
		{
			Draw.Draw();
		}
	}
#endif

};


#if EDITOR
struct FSummitMountainBirdDebugDraw
{
	FLinearColor SphereColor;
	FVector SphereLocation;
	
	FVector StringLocation;
	FString StringText;

	void Draw(float _Duration = 0.5) const
	{
		Debug::DrawDebugString(StringLocation, StringText);
		Debug::DrawDebugSphere(SphereLocation, LineColor = SphereColor, Duration = _Duration);
	}
}
#endif