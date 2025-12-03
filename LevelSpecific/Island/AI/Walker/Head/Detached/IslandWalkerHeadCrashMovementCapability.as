class UIslandWalkerHeadCrashMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UHazeOffsetComponent MeshRoot;

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerSettings Settings;
	UTeleportingMovementData Movement;
	FVector PrevLocation;

	FVector CurveStart;
	FVector CurveStartTangent;
	FVector CurveHeightControl;
	float CurveAlpha = 0.0;

	FVector CrashOffset;
	const float CrashOffsetForward = -500.0;
	const float CrashOffsetHeight = 200.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		MeshRoot = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (HeadComp.CrashSite == nullptr)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (HeadComp.CrashSite == nullptr)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;

		CrashOffset = (HeadComp.CrashDestination - Owner.ActorLocation).GetSafeNormal2D() * CrashOffsetForward;
		CrashOffset.Z = CrashOffsetHeight;

		CurveStart = Owner.ActorLocation;
		CurveStartTangent = MoveComp.Velocity;
		if (CurveStartTangent.IsNearlyZero(1.0))
			CurveStartTangent = Owner.ActorForwardVector;

		// Rise a bit before crashing down
		FVector ToDest = HeadComp.CrashDestination - CurveStart;
		CurveHeightControl = CurveStart + ToDest * 0.5;
		CurveHeightControl.Z = HeadComp.CrashDestination.Z + Settings.HeadCrashControlHeight + CrashOffset.Z;

		CurveAlpha = 0.0;
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

		// Straighten out pitch and roll
		FRotator MeshRotation = MeshRoot.WorldRotation;
		MeshRotation.Pitch = Math::Lerp(MeshRotation.Pitch, 0.0, DeltaTime * 0.7);
		MeshRotation.Roll = Math::Lerp(MeshRotation.Roll, 0.0, DeltaTime * 0.7);
		MeshRoot.SetWorldRotation(MeshRotation);
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DeltaTime < SMALL_NUMBER)
			return;

		CurveAlpha = Math::Min(1.0, CurveAlpha + DeltaTime / Math::Max(HeadComp.CrashDuration, 0.1));
		FVector NewLoc = BezierCurve::GetLocation_2CP(CurveStart, CurveStart + CurveStartTangent, CurveHeightControl, HeadComp.CrashDestination + CrashOffset, CurveAlpha);
		Movement.AddDeltaFromMoveTo(NewLoc);

		// Turn towards destination
		MoveComp.RotateTowardsDirection(HeadComp.CrashDestination - CurveStart, Settings.HeadTurnDuration, DeltaTime, Movement, true);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			BezierCurve::DebugDraw_2CP(CurveStart, CurveStart + CurveStartTangent, CurveHeightControl, HeadComp.CrashDestination + CrashOffset, FLinearColor::Yellow, 10.0);
		}
#endif
	}
}
