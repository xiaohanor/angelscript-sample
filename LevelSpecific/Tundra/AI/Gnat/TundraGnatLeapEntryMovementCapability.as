struct FGnapeLeapEntryParams
{
	AActor Target;
	USceneComponent HostAttachComp;
	FVector TargetOffset;
}

class UTundraGnatLeapEntryMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"ClimbingMovement");	
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40; // Before regular movement
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UTundraGnatComponent GnapeComp;
	UTundraGnatSettings Settings;
	UTeleportingMovementData Movement;
	USceneComponent FollowComp;

	FVector PrevLocation;
	FVector StartOffset;
	FVector TargetOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		GnapeComp = UTundraGnatComponent::Get(Owner);
		Settings = UTundraGnatSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGnapeLeapEntryParams& OutParams) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (GnapeComp.LeapEntryTarget == nullptr)
			return false;
		OutParams.Target = GnapeComp.LeapEntryTarget;
		OutParams.TargetOffset = Math::GetRandomPointInCircle_XY().GetClampedToSize(0.5, 1.0) * Settings.LeapEntryTargetLandingDistance;	
		OutParams.HostAttachComp = GnapeComp.LeapEntryTarget.AttachmentRoot;
		ATundraWalkingStick WalkingStick = Cast<ATundraWalkingStick>(GnapeComp.Host);
		if (WalkingStick != nullptr)
			OutParams.HostAttachComp = WalkingStick.HostComp.Body;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (GnapeComp.bHasCompletedEntry)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGnapeLeapEntryParams Params)
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		Owner.TeleportActor(RespawnComp.SpawnParameters.Location, RespawnComp.SpawnParameters.Rotation, this);

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;

		GnapeComp.LeapEntryTarget = Params.Target;
		TargetOffset = Params.TargetOffset;
		GnapeComp.Host = Params.HostAttachComp.Owner;
		FollowComp = Params.HostAttachComp;

		// Movement system attach to climb socket
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(FollowComp, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal);

		GnapeComp.LeapAlpha = 0.0;
		StartOffset = FollowComp.WorldTransform.InverseTransformPosition(Owner.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// This is set in ResolveMovement, so will lag one frame behind
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
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);;
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, TundraGnatTags::Leaping);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (!Owner.ActorLocation.IsWithinDist(GnapeComp.LeapEntryTarget.ActorLocation, 100.0))
			MoveComp.RotateTowardsDirection(GnapeComp.LeapEntryTarget.ActorLocation - Owner.ActorLocation, 2.0, DeltaTime, Movement);

		FVector StartLocation = FollowComp.WorldTransform.TransformPosition(StartOffset);
		FVector Destination = GnapeComp.LeapEntryTarget.ActorLocation + TargetOffset;
		FVector Control = (StartLocation + Destination) * 0.5; 
		Control.Z += 4000.0;

		GnapeComp.LeapAlpha += DeltaTime / Settings.LeapEntryDuration;
		if (GnapeComp.LeapAlpha > 1.0)
			GnapeComp.LeapAlpha = 1.0;
		FVector CurveLoc = BezierCurve::GetLocation_1CP(StartLocation, Control, Destination, GnapeComp.LeapAlpha);

		Movement.AddDelta(CurveLoc - Owner.ActorLocation);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			BezierCurve::DebugDraw_1CP(StartLocation, Control, Destination, FLinearColor::Purple, 10.0);
		}
#endif
	}
}
