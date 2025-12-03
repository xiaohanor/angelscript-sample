class USkylineGeckoConstrainAttackMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"ConstrainAttackMovement");	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;

	USkylineGeckoComponent GeckoComp;
	UPathfollowingMoveToComponent MoveToComp;
	UPathfollowingSettings PathingSettings;
	USkylineGeckoSettings Settings;	

	USimpleMovementData Movement;

	FVector PrevLocation;
	FVector Destination;
	FHazeAcceleratedVector AccDestination;
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
		GeckoComp = USkylineGeckoComponent::Get(Owner);
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
		if (!GeckoComp.bShouldConstrainAttackLeap.Get())
			return false;
	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if ((CurveAlpha > 0.25) && MoveComp.HasAnyValidBlockingImpacts())
			return true;
		if ((CurveAlpha > 0.99) && !GeckoComp.bShouldConstrainAttackLeap.Get())
			return true;
		if ((CurveAlpha > 0.99) && (MoveComp.Velocity.Z > 0.0)) // Never continue on an upwards ballistic trajectory
			return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		Destination = DestinationComp.Destination;
		AccDestination.SnapTo(Destination);
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
		if(!MoveComp.PrepareMove(Movement))
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

	void ComposeMovement(float DeltaTime)
	{	
		if (DestinationComp.HasDestination())
		{
			Destination = DestinationComp.Destination;
			Speed = DestinationComp.Speed;
		}

		float CurveDist = CurveStart.Distance(AccDestination.Value);
		if (CurveDist < SMALL_NUMBER)
			CurveAlpha = 1.0;
		else 
			CurveAlpha = Math::Min(1.0, CurveAlpha + (Speed * DeltaTime / CurveDist));

		if (CurveAlpha < 1.0)
		{
			AccDestination.AccelerateTo(Destination, 0.5, DeltaTime);
			//FVector CurveControl = CurveStart * (1.0 - ApexFraction) + Destination * ApexFraction;
			//CurveControl.Z = Math::Max(CurveStart.Z, Destination.Z) + Math::Max(CurveDist * 0.5, 200.0); // TODO: Calculate this properly
			//FVector NewLoc = BezierCurve::GetLocation_1CP(CurveStart, CurveControl, Destination, CurveAlpha);
			FVector CurveControl = CurveStart * (1.0 - ApexFraction) + AccDestination.Value * ApexFraction;
			CurveControl.Z = Math::Max(CurveStart.Z, AccDestination.Value.Z) + Math::Max(CurveDist * 0.5, 200.0); // TODO: Calculate this properly
			FVector NewLoc = BezierCurve::GetLocation_1CP(CurveStart, CurveControl, AccDestination.Value, CurveAlpha);
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
			// if (MoveComp.Velocity.Z < 0.0)
			// 	Movement.AddVelocity(MoveComp.Velocity);			
			
			// Hacky match player's fall
			Movement.AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(Destination, Owner.ActorForwardVector, FVector::ZeroVector);
			Movement.AddGravityAcceleration();

			// if (DestinationComp.Focus.IsValid())
			// 	MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement);
			// else 
			// 	MoveComp.StopRotating(5.0, DeltaTime, Movement);
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (false || Owner.bHazeEditorOnlyDebugBool)
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

