struct FCritterLatchOnMovementParams
{
	USkeletalMeshComponent LatchOnToMesh = nullptr;
	FName LatchOnToSocket = NAME_None;
}

class USummitCritterLatchOnMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USummitCritterComponent CritterComp;
	UBasicAIHealthComponent HealthComp;
	UTeleportingMovementData Movement;

	USkeletalMeshComponent LatchOnToMesh = nullptr;
	FName LatchOnToSocket = NAME_None;
	FVector PrevLocation;

	float JumpStartTime = 0.5;
	FHazeAcceleratedRotator AccUp;
	FVector JumpLoc;
	float JumpAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		CritterComp = USummitCritterComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();

		auto AnimInstance = Cast<UAnimInstanceSummitClimbingCritter>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
		TArray<FHazeAnimNotifyStateGatherInfo> ActionInfo;
		if (AnimInstance.GrabStart.Sequence.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionInfo) && (ActionInfo.Num() > 0))
			JumpStartTime = ActionInfo[0].TriggerTime;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCritterLatchOnMovementParams& OutParams) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (CritterComp.LatchOnToMesh == nullptr)
			return false;
		OutParams.LatchOnToMesh = CritterComp.LatchOnToMesh;
		OutParams.LatchOnToSocket = CritterComp.LatchOnToSocket;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (CritterComp.LatchOnToMesh == nullptr)
			return true;
		if (HealthComp.IsDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCritterLatchOnMovementParams Params)
	{
		LatchOnToMesh = Params.LatchOnToMesh;
		LatchOnToSocket = Params.LatchOnToSocket;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		AccUp.SnapTo(Owner.ActorUpVector.Rotation());
		PrevLocation = Owner.ActorLocation;
		JumpLoc = Owner.ActorLocation;
		JumpAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCompleteLatchOn()
	{
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(LatchOnToMesh, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal, LatchOnToSocket);
		CritterComp.CompleteLatchOn();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Update upvector
		AccUp.AccelerateTo(LatchOnToMesh.Owner.ActorUpVector.Rotation(), 1.0, DeltaTime);
		if(!MoveComp.PrepareMove(Movement, AccUp.Value.Vector()))
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

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DeltaTime == 0.0)
			return;

		// Move towards socket location at given speed
		FVector TargetLoc = LatchOnToMesh.GetSocketLocation(LatchOnToSocket);
		if (ActiveDuration < JumpStartTime)
		{
			JumpLoc = Owner.ActorLocation;
		}
		else if (JumpAlpha < 1.0 - SMALL_NUMBER)
		{
			// Jumping to target
			float JumpDistance = Math::Max(1.0, JumpLoc.Dist2D(TargetLoc));
			JumpAlpha += (CritterComp.LatchOnSpeed / JumpDistance) * DeltaTime;
			FVector JumpApex = (JumpLoc + TargetLoc) * 0.5 + FVector(0.0, 0.0, 400.0);
			FVector CurveLoc = BezierCurve::GetLocation_1CP(JumpLoc, JumpApex, TargetLoc, JumpAlpha);
			Movement.AddDeltaFromMoveToPositionWithCustomVelocity(CurveLoc, (CurveLoc - Owner.ActorLocation) / DeltaTime);
		}
		else
		{
			// At target, latch on
			if (!CritterComp.bLatchOnComplete)
				CrumbCompleteLatchOn();
		}

		// Align with jump direction
		FRotator Rotation = MoveComp.GetRotationTowardsDirection((TargetLoc - JumpLoc), 1.0, DeltaTime);
		Movement.SetRotation(Rotation);
	}
}
