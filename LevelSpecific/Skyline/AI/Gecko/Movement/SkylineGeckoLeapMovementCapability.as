class USkylineGeckoLeapMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"LeapMovement");	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80; 
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;

	UWallclimbingComponent WallclimbingComp;
	USkylineGeckoComponent GeckoComp;
	UPathfollowingMoveToComponent MoveToComp;
	UWallclimbingPathfollowingSettings WallPathfollowingSettings;
	UPathfollowingSettings PathingSettings;
	USkylineGeckoSettings Settings;
	FHazeAcceleratedRotator AccUp;

	USimpleMovementData Movement;

	FVector PrevLocation;
	FVector Destination;
	float Speed;

	FVector CurveStart;
	float ApexFraction;
	float CurveAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		MoveToComp = UPathfollowingMoveToComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		WallclimbingComp = UWallclimbingComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		WallPathfollowingSettings = UWallclimbingPathfollowingSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!DestinationComp.HasDestination())
			return false;
		if (!GeckoComp.bShouldLeap.Get())
			return false;
		if (DestinationComp.Destination.IsWithinDist(Owner.ActorLocation, 10.0))
			return false; // Do not leap very short distances or we might repeat after landing
	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if ((CurveAlpha > 0.25) && MoveComp.HasAnyValidBlockingImpacts())
			return true;
		if ((CurveAlpha > 0.99) && !GeckoComp.bShouldLeap.Get())
			return true;
		if ((CurveAlpha > 0.99) && (MoveComp.Velocity.Z > 0.0)) // Never continue on an upwards ballistic trajectory
			return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		WallclimbingComp.Path.Reset();
		PrevLocation = Owner.ActorLocation;
		AccUp.SnapTo(MoveComp.WorldUp.Rotation());
		Destination = DestinationComp.Destination;
		Speed = DestinationComp.Speed;
		CurveStart = Owner.ActorLocation;
		ApexFraction = 0.5; // TODO: Calculate properly
		CurveAlpha = 0.0; 
		GeckoComp.bIsLeaping.Apply(true, this);
		MoveToComp.ResetPath();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GeckoComp.bIsLeaping.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, AccUp.AccelerateTo(GetTargetUp().Rotation(), 1.0, DeltaTime).Vector()))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	FVector GetTargetUp()
	{
		if (WallclimbingComp.DestinationUpVector.Get().IsZero())
			return FVector::UpVector;
		return WallclimbingComp.DestinationUpVector.Get();	
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DestinationComp.HasDestination())
		{
			Destination = DestinationComp.Destination;
			Speed = DestinationComp.Speed;
		}

		float CurveDist = CurveStart.Distance(Destination);
		if (CurveDist < SMALL_NUMBER)
			CurveAlpha = 1.0;
		else 
			CurveAlpha = Math::Min(1.0, CurveAlpha + (Speed * DeltaTime / CurveDist));

		if (CurveAlpha < 1.0)
		{
			FVector CurveControl = CurveStart * (1.0 - ApexFraction) + Destination * ApexFraction;
			CurveControl.Z = Math::Max(CurveStart.Z, Destination.Z) + Math::Max(CurveDist * 0.5, 600.0); // TODO: Calculate this properly
			FVector NewLoc = BezierCurve::GetLocation_1CP(CurveStart, CurveControl, Destination, CurveAlpha);
			Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, (NewLoc - Owner.ActorLocation) / DeltaTime);

			// Turn towards focus or match direction with jump
			if (DestinationComp.Focus.IsValid())
				MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement);
			else 
				MoveComp.RotateTowardsDirection(Destination - CurveStart, Settings.TurnDuration, DeltaTime, Movement, true);
		}
		else
		{
			// Continue ballistic trajectory until we hit something as long as we're falling
			if (MoveComp.Velocity.Z < 0.0)
				Movement.AddVelocity(MoveComp.Velocity);
			Movement.AddGravityAcceleration();

			if (DestinationComp.Focus.IsValid())
				MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement);
			else 
				MoveComp.StopRotating(5.0, DeltaTime, Movement);
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector CurveControl = CurveStart * (1.0 - ApexFraction) + Destination * ApexFraction;
			CurveControl.Z = Math::Max(CurveStart.Z, Destination.Z) + CurveDist * 0.5; // TODO: Calculate this properly
			Debug::DrawDebugLine(Destination, Destination + FVector(0,0,200), FLinearColor::Red);
			Debug::DrawDebugLine(CurveStart, CurveStart + FVector(0,0,200), FLinearColor::Green);
			Debug::DrawDebugLine(CurveControl, CurveControl + FVector(0,0,200), FLinearColor::Yellow);
			BezierCurve::DebugDraw_1CP(CurveStart, CurveControl, Destination, FLinearColor::Yellow, 5.0);			
		}
#endif
	}
}

