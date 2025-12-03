class UCoastJetskiObstacleAvoidanceBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastJetskiSettings Settings;
	UCoastJetskiComponent JetskiComp;
	UHazeSplineComponent Spline;
	float WithinBoundsDuration;
	float StuckDuration;
	FVector StuckLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastJetskiSettings::GetSettings(Owner);
		JetskiComp = UCoastJetskiComponent::GetOrCreate(Owner);
	}

	bool ShouldAvoidObstacles(float Buffer = 0.0) const
	{
		// Avoid if we're at or coming up on a choke point
		if (JetskiComp.IsAtChokepoint(3000.0) || 
			JetskiComp.IsAtChokepoint(3000.0, Settings.ObstacleAvoidanceSplineLookahead))
			return true;

		// Avoid if we're outside splines
		if (!JetskiComp.IsInsideAnySpline(Buffer))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!JetskiComp.RailPosition.IsValid())
			return false;
		if (!ShouldAvoidObstacles())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (WithinBoundsDuration > Settings.ObstacleAvoidanceStopDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		WithinBoundsDuration = 0.0;
		StuckDuration = 0.0;
		StuckLocation = Owner.ActorLocation;
		Spline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		JetskiComp.TrainFollowSpeedAdjustment.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update spline we're moving along
		FSplinePosition SplinePos = JetskiComp.GetCurrentSplinePosition(Spline);
		if (!SplinePos.IsValid() || (SplinePos.CurrentSplineDistance > SplinePos.CurrentSpline.SplineLength - Settings.ObstacleAvoidanceSplineLookahead))
			SplinePos = JetskiComp.GetBestSplinePosition(Settings.ObstacleAvoidanceSplineLookahead);
		Spline = SplinePos.CurrentSpline;
		if (!SplinePos.IsValid())
		{
			Cooldown.Set(0.5);
			return;
		}

		// Swerve hard towards the spline when outisde of spline scale bounds, then follow along spline at more sedate pace when within
		FTransform LookAheadPos = SplinePos.CurrentSpline.GetWorldTransformAtSplineDistance(SplinePos.CurrentSplineDistance + Settings.ObstacleAvoidanceSplineLookahead);
		float SideOffset = SplinePos.WorldRightVector.DotProduct(Owner.ActorLocation - SplinePos.WorldLocation);
		float Width = LookAheadPos.Scale3D.Y * CoastJetskiSpline::WidthScale;
		float SideAlpha = Math::Min(Math::Abs(SideOffset) / Width, 1.0);

		// When well ahead of target we favor hard turns to stay near spline. When behind we accelerate forwards to catch up.
		float AheadDist = Settings.EngageDistanceAheadOfPlayer; 
		FVector RailDir = JetskiComp.RailPosition.WorldForwardVector;
		if (TargetComp.HasValidTarget())
			AheadDist = RailDir.DotProduct(Owner.ActorLocation - TargetComp.Target.ActorLocation);
		float AheadAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.5, 1.0) * Settings.EngageDistanceAheadOfPlayer, FVector2D(0.0, 1.0), AheadDist);

		FVector Destination = Math::Lerp(LookAheadPos.Location, SplinePos.WorldLocation, Math::Max(SideAlpha, AheadAlpha)); 

		// If we're behind target, gain extra speed along rail. If well ahead, reduce train following speed instead
		float BehindDist = (TargetComp.HasValidTarget() ? RailDir.DotProduct(TargetComp.Target.ActorLocation - Owner.ActorLocation) : 0.0);
		if (BehindDist > 0.0)
			JetskiComp.TrainFollowSpeedAdjustment.Apply(Math::Min(Settings.EngageBehindExtraSpeed, BehindDist * 0.5), this, EInstigatePriority::Low);
		else 		
			JetskiComp.TrainFollowSpeedAdjustment.Apply(AheadAlpha * -2000.0, this, EInstigatePriority::Low);

		// Adjust acceleration to how far we are within spline bounds and 
		// what velocity towards spline we've currently built up
		float SpeedTowardsSpline = SplinePos.WorldRightVector.DotProduct(Owner.ActorVelocity) * -Math::Sign(SideOffset);
		float AccFactor = 1.0;
		if (SpeedTowardsSpline > 0.0)
		{
			float WithinDist = Width - Math::Abs(SideOffset);
			AccFactor = SideAlpha * Math::GetMappedRangeValueClamped(FVector2D(800.0, 400.0), FVector2D(0.0, 1.0), WithinDist);
			float SpeedLimit = 600.0 - Math::Min(400.0, WithinDist); 
			if (SpeedTowardsSpline > SpeedLimit)
				AccFactor *= SpeedLimit / SpeedTowardsSpline;
		}

		DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.ObstacleAvoidanceMoveSpeed * AccFactor);

		// When we've been well within bounds for a while we stop avoiding collisions
		if (!ShouldAvoidObstacles(500.0))
			WithinBoundsDuration += DeltaTime;
		else
			WithinBoundsDuration = 0.0;

		// Check if stuck 
		StuckLocation.Z = Owner.ActorLocation.Z;
		if (Owner.ActorLocation.IsWithinDist(StuckLocation, 1000.0))
		{
		 	StuckDuration += DeltaTime;
			if ((StuckDuration > 0.5) && 
			 	!SceneView::IsInView(Game::Mio, Owner.ActorLocation) &&
			 	!SceneView::IsInView(Game::Zoe, Owner.ActorLocation))
			 	CrumbWatsonTeleport(SplinePos.WorldLocation);
		}
		else
		{
			StuckLocation = Owner.ActorLocation;
			StuckDuration = 0.0;
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, SplinePos.WorldLocation, FLinearColor::Yellow, 5);
			Debug::DrawDebugLine(Destination, Destination + FVector(0,0,400), FLinearColor::Green, 3);
			Debug::DrawDebugLine(SplinePos.WorldLocation, LookAheadPos.Location, FLinearColor::Green, 3);
			//Debug::DrawDebugString(Owner.ActorLocation + SplinePos.WorldForwardVector * 400.0, "Side: " + SideAlpha + " Behind: " + AheadAlpha, FLinearColor::Yellow, 0.0, 2.0);
			FVector Side = SplinePos.WorldRightVector * SplinePos.WorldScale3D.Y * 100.0;
			FVector PrevLeft = SplinePos.WorldLocation - Side;
			FVector PrevRight = SplinePos.WorldLocation + Side;
			for (float d = 200.0; d < Settings.ObstacleAvoidanceSplineLookahead + 100.0; d += 200.0)
			{
				FTransform p = SplinePos.CurrentSpline.GetWorldTransformAtSplineDistance(SplinePos.CurrentSplineDistance + d);
				Side = p.Rotation.RightVector * p.Scale3D.Y * 100.0;
				Debug::DrawDebugLine(PrevLeft, p.Location - Side + p.Rotation.ForwardVector * 200, FLinearColor::Blue, 20, 0.0);
				Debug::DrawDebugLine(PrevRight, p.Location + Side + p.Rotation.ForwardVector * 200, FLinearColor::Blue, 20, 0.0);
				PrevLeft = p.Location - Side + p.Rotation.ForwardVector * 200;
				PrevRight = p.Location + Side + p.Rotation.ForwardVector * 200;
			}
		}
#endif
	}

//	UFUNCTION(CrumbFunction)
	void CrumbWatsonTeleport(FVector Location)
	{
		StuckDuration = 0.0;
		Owner.TeleportActor(Location, Owner.ActorRotation, this);
	}
}
