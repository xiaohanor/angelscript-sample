class UIslandWalkerHeadEscapeMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UHazeCrumbSyncedFloatComponent CrumbMeshPitchComp;
	UHazeOffsetComponent MeshRoot;
	UIslandWalkerPhaseComponent WalkerPhaseComp;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerSettings Settings;
	USweepingMovementData Movement;
	FVector PrevLocation;
	FVector CustomVelocity;
	
	bool bAtSpline = false;
	UHazeSplineComponent CurSpline;
	FVector MoveToSplineStart;
	FVector MoveToSplineStartControl;
	FVector MoveToSplineEndControl;
	float MoveToSplineDistance;
	float MoveToSplineAlpha;

	float WobbleTimer = 0.0;
	FHazeAcceleratedFloat AccSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		WalkerPhaseComp = UIslandWalkerPhaseComponent::Get(HeadComp.NeckCableOrigin.Owner);
		CrumbMeshPitchComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner);
		MeshRoot = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (HeadComp.State != EIslandWalkerHeadState::Escape)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (HeadComp.State != EIslandWalkerHeadState::Escape)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		CrumbMeshPitchComp.Value = MeshRoot.WorldRotation.Pitch;
		PrevLocation = Owner.ActorLocation;
		bAtSpline = false;
		CurSpline = nullptr;

		// No gravity unless behaviours want it
		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
		MeshRoot.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		WobbleTimer += DeltaTime;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
			CrumbMeshPitchComp.Value = MoveComp.AccRotation.Value.Pitch;
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			MoveComp.AccRotation.Value.Pitch = CrumbMeshPitchComp.Value;
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);

		// Wobble a bit in roll
		FRotator MeshRotation = MeshRoot.WorldRotation;
		MeshRotation.Roll = MoveComp.AccRotation.Value.Roll + (Settings.HeadWobbleRollAmplitude * Math::Sin(WobbleTimer * Settings.HeadWobbleRollFrequency));
		MeshRoot.SetWorldRotation(MeshRotation);
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DeltaTime < SMALL_NUMBER)
			return;

		if (DestinationComp.FollowSpline == nullptr)
		{
			bAtSpline = false;
			CurSpline = nullptr;
		}
		else if (DestinationComp.FollowSpline != CurSpline)
		{
			StartNewSplineMove(DestinationComp.FollowSpline);
		}

		if (bAtSpline)
			ComposeMoveAlongSpline(DeltaTime);
		else if (CurSpline != nullptr)
			ComposeMoveToSpline(DeltaTime);
		else 
			ComposeMoveToDestination(DeltaTime);
	}

	void StartNewSplineMove(UHazeSplineComponent NewSpline)
	{
		bAtSpline = false;
		CurSpline = NewSpline;
		AccSpeed.SnapTo(MoveComp.Velocity.Size());
		if (CurSpline == nullptr)
			return;

		DestinationComp.FollowSplinePosition = CurSpline.GetSplinePositionAtSplineDistance(HeadComp.HeadEscapeStartDistanceAlongSpline); 
		MoveToSplineAlpha = 0.0;
		MoveToSplineStart = Owner.ActorLocation;
		MoveToSplineStartControl = MoveToSplineStart + Owner.ActorVelocity;
		MoveToSplineEndControl = DestinationComp.FollowSplinePosition.WorldLocation - DestinationComp.FollowSplinePosition.WorldForwardVector * Settings.HeadEscapeSpeed;
		MoveToSplineDistance = BezierCurve::GetLength_2CP(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation);
	}

	void ComposeMoveAlongSpline(float DeltaTime)
	{
		float Speed = AccSpeed.AccelerateTo(Settings.HeadEscapeSpeed, 5.0, DeltaTime);
		DestinationComp.FollowSplinePosition.Move(Speed * DeltaTime);
		FVector NewLoc = DestinationComp.FollowSplinePosition.WorldLocation;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, DestinationComp.FollowSplinePosition.WorldForwardVector * Speed);
		Movement.SetRotation(MoveComp.AccRotation.AccelerateTo(DestinationComp.FollowSplinePosition.WorldRotation.Rotator(), Settings.HeadEscapeTurnDuration, DeltaTime));

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(NewLoc, NewLoc + DestinationComp.FollowSplinePosition.WorldUpVector * 400.0, FLinearColor::DPink, 5.0);		
			CurSpline.DrawDebug(200, FLinearColor::Purple, 5.0);
		}
#endif
	}

	void ComposeMoveToSpline(float DeltaTime)
	{
		MoveToSplineDistance = BezierCurve::GetLength_2CP(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation);
		float Speed = AccSpeed.AccelerateTo(Settings.HeadEscapeSpeed, 5.0, DeltaTime);
		MoveToSplineAlpha += (Speed * DeltaTime / Math::Max(0.1, MoveToSplineDistance));
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation, MoveToSplineAlpha);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, (NewLoc - Owner.ActorLocation) / Math::Max(0.01, DeltaTime));

		FQuat CurveRot = (NewLoc - Owner.ActorLocation).ToOrientationQuat();
		FQuat TargetRot = FQuat::Slerp(CurveRot, DestinationComp.FollowSplinePosition.WorldRotation, Math::Square(MoveToSplineAlpha));
		Movement.SetRotation(MoveComp.AccRotation.AccelerateTo(TargetRot.Rotator(), Settings.HeadEscapeTurnDuration * 2.0, DeltaTime));

		if (MoveToSplineAlpha > 1.0)
		{
			bAtSpline = true;	

			// Added this escaping phase change in the last section to help audio / Pussel
			if (WalkerPhaseComp.Phase == EIslandWalkerPhase::Swimming)
			{
				WalkerPhaseComp.Phase = EIslandWalkerPhase::Escaping;
			}
		}
				

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector PrevLoc = MoveToSplineStart;
			const float Interval = 0.01;
			for (float f = Interval; f < 1.0 + SMALL_NUMBER; f += Interval)
			{
				FVector Loc = BezierCurve::GetLocation_2CP(MoveToSplineStart, MoveToSplineStartControl, MoveToSplineEndControl, DestinationComp.FollowSplinePosition.WorldLocation, f);
				Debug::DrawDebugLine(PrevLoc, Loc, FLinearColor::Yellow, 5.0);
				PrevLoc = Loc;
			}
			CurSpline.DrawDebug(200, FLinearColor::Purple, 5.0);
		}
#endif
	}

	void ComposeMoveToDestination(float DeltaTime)
	{
		FVector Velocity = MoveComp.Velocity;
		FVector OwnLoc = Owner.ActorLocation;	

		if (DestinationComp.HasDestination())
		{
			FVector Destination = DestinationComp.Destination;
			if (!OwnLoc.IsWithinDist(Destination, 20.0))				
			{
				// Accelerate towards destination
				FVector DestDir = (Destination - OwnLoc).GetSafeNormal();
				Movement.AddAcceleration(DestDir * DestinationComp.Speed);
			}
		}

		// Apply friction
		Velocity *= Math::Pow(Math::Exp(-Settings.HeadFriction), DeltaTime);

		Movement.AddVelocity(Velocity);
		Movement.AddGravityAcceleration();

		// Turn towards focus or neck forward if none
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.HeadTurnDuration, DeltaTime, Movement, true);
		else if (HeadComp.NeckCableOrigin.ForwardVector.GetSafeNormal2D().DotProduct(Owner.ActorForwardVector) < 0.99)
			MoveComp.RotateTowardsDirection(HeadComp.NeckCableOrigin.ForwardVector, Settings.HeadTurnDuration, DeltaTime, Movement, true);
		else 
			MoveComp.StopRotating(4.0, DeltaTime, Movement, true);
	}	
}
