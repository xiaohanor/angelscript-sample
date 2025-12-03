class UPrisonGuardMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAIDestinationComponent DestinationComp;
	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UHazeCrumbSyncedPrisonGuardMovementComponent CrumbGuardMovementComp;
	UHazeCharacterSkeletalMeshComponent Mesh;
	UPrisonGuardAnimationComponent GuardAnimComp;
	UPathfollowingMoveToComponent PathfollowingComp;
	UPrisonGuardSettings Settings;
	USimpleMovementData Movement;

	FVector PrevLocation;
	float MovingDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); 
		CrumbGuardMovementComp = UHazeCrumbSyncedPrisonGuardMovementComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		GuardAnimComp = UPrisonGuardAnimationComponent::Get(Owner);
		PathfollowingComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		Settings = UPrisonGuardSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		UPathfollowingSettings::SetAtWaypointRange(Owner, Settings.StepLength, this, EHazeSettingsPriority::Gameplay);
		UPathfollowingSettings::SetAtDestinationRange(Owner, Settings.StepLength, this, EHazeSettingsPriority::Gameplay);
		MovingDuration = 0.0;

		// We want to be able to extract root motion, but want to apply it ourselves.
		Mesh.bAllowedToAutoApplyRootMotion = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearSettingsByInstigator(this);
		Mesh.bAllowedToAutoApplyRootMotion = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			// Resolve how we want to move and set animation control variables accordingly
			GuardAnimComp.Request = GetMovementRequest();
			CrumbGuardMovementComp.SetValue(FPrisonGuardMovementData(GuardAnimComp.Request));
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Retrieve unreliably synced request, some glitches should be fine
			GuardAnimComp.Request = CrumbGuardMovementComp.Value.AnimRequest;	

			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);;
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;

		if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::Move)
			MovingDuration += DeltaTime;
		else
			MovingDuration = 0.0;
	}

	EPrisonGuardAnimationRequest GetMovementRequest()
	{
		if (GuardAnimComp.HasActionRequest())
			return GuardAnimComp.Request;

		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = PathfollowingComp.GetPathfindingDestination();

		FVector WantedDir = Owner.ActorForwardVector;
		if (DestinationComp.HasDestination())
			WantedDir = (Destination - OwnLoc).GetSafeNormal2D(); // When moving we need to turn along path
		else if (DestinationComp.Focus.IsValid())
			WantedDir = (DestinationComp.Focus.GetFocusLocation() - OwnLoc).GetSafeNormal2D(); // Not moving, we can turn toward focus
		
		float FwdDot = Owner.ActorForwardVector.DotProduct(WantedDir);

		// Stop to turn if within ~46 degrees when moving, ~23 degrees if already stopped
		float TurnLimit = (GuardAnimComp.Request == EPrisonGuardAnimationRequest::Move) ? 0.69 : 0.92; 
		if (FwdDot < TurnLimit) 
		{
			// Turn!
			bool bRight = Owner.ActorRightVector.DotProduct(WantedDir) > 0.0;
			if (FwdDot > 0.37) // ~68 degrees
				return (bRight ? EPrisonGuardAnimationRequest::TurnRight45 : EPrisonGuardAnimationRequest::TurnLeft45);
			if (FwdDot > -0.39) // ~113 degrees
				return (bRight ? EPrisonGuardAnimationRequest::TurnRight90 : EPrisonGuardAnimationRequest::TurnLeft90);
			if (FwdDot > -0.98) // ~158 degrees
				return (bRight ? EPrisonGuardAnimationRequest::TurnRight135 : EPrisonGuardAnimationRequest::TurnLeft135);
			return (bRight ? EPrisonGuardAnimationRequest::TurnRight180 : EPrisonGuardAnimationRequest::TurnLeft180);
		}
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(PathfollowingComp.FinalDestination, Settings.StepLength)) 
		{
			// Move ahead
			return EPrisonGuardAnimationRequest::Move;
		}
		return EPrisonGuardAnimationRequest::Stop;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = PathfollowingComp.GetPathfindingDestination();
			
		// Fall down
		Movement.AddVelocity(MoveComp.Velocity.ProjectOnTo(Owner.ActorUpVector));
		Movement.AddGravityAcceleration();

		// Root motion based movement and rotation
		TArray<FHazePlayingAnimationData> Animations;
		Mesh.GetCurrentlyPlayingAnimations(Animations);
		FTransform RootMotion = FTransform::Identity;
		for (FHazePlayingAnimationData AnimData : Animations)
		{
			FHazeLocomotionTransform AnimRootMotion;
			if (AnimData.Sequence.ExtractRootMotion(AnimData.CurrentPosition, AnimData.CurrentPosition + DeltaTime, AnimRootMotion))
				RootMotion *= FTransform(AnimRootMotion.DeltaRotation, AnimRootMotion.DeltaTranslation);
		}

		// Only ever move on navmesh!
		FVector RootMotionDelta = Mesh.WorldTransform.TransformVector(RootMotion.Location) * GuardAnimComp.MovementPlayRate;
		FVector PathLoc;
		if (Pathfinding::FindNavmeshLocation(Owner.ActorLocation + RootMotionDelta, 40.0, 80.0, PathLoc))
		{
			FVector Delta = PathLoc - Owner.ActorLocation;
			Delta.Z = RootMotionDelta.Z;
			Movement.AddDelta(Delta);
		}
		
		// Allow some turning while moving
		if ((MovingDuration > Settings.MovingMinDurationBeforeTurning) && !OwnLoc.IsWithinDist(Destination, Settings.StepLength * 0.5))
		{
			FVector DestDir = (Destination - OwnLoc).GetSafeNormal2D();
			if (Owner.ActorForwardVector.DotProduct(DestDir) < 0.98)
			{
				float TurnYaw = Settings.MovingTurnRate;
				if (Owner.ActorRightVector.DotProduct(DestDir) < 0.0)
					TurnYaw *= -1.0;
				Movement.SetRotation(Owner.ActorRotation.Compose(FRotator(0.0, TurnYaw * DeltaTime, 0.0)));
			}
		}
		else
		{
			// Rotation from rootmotion
			Movement.SetRotation(Owner.ActorQuat * RootMotion.Rotation);

			//HACK since rotational rootmotion does not seem to work
			if (RootMotion.Rotation.IsIdentity())
			{
				float HackDeltaYaw = 0.0;
				if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnLeft45)
					HackDeltaYaw = (-45.0 / 0.7) * DeltaTime;
				else if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnLeft90)
					HackDeltaYaw = (-90.0 / 0.7) * DeltaTime;
				else if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnLeft135)
					HackDeltaYaw = (-135.0 / 0.93) * DeltaTime;
				else if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnLeft180)
					HackDeltaYaw = (-180.0 / 0.93) * DeltaTime;
				else if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnRight45)
					HackDeltaYaw = (45.0 / 0.7) * DeltaTime;
				else if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnRight90)
					HackDeltaYaw = (90.0 / 0.7) * DeltaTime;
				else if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnRight135)
					HackDeltaYaw = (135.0 / 0.93) * DeltaTime;
				else if (GuardAnimComp.Request == EPrisonGuardAnimationRequest::TurnRight180)
					HackDeltaYaw = (180.0 / 0.93) * DeltaTime;
				if (HackDeltaYaw != 0.0)
					Movement.SetRotation(Owner.ActorRotation.Compose(FRotator(0.0, HackDeltaYaw, 0.0)));
			}
		}
	}
}

struct FPrisonGuardMovementData
{
	FPrisonGuardMovementData(EPrisonGuardAnimationRequest Anim)
	{
		AnimRequest = Anim;
	}

	EPrisonGuardAnimationRequest AnimRequest;
}	

class UHazeCrumbSyncedPrisonGuardMovementComponent : UHazeCrumbSyncedStructComponent
{
	private FPrisonGuardMovementData Data;

	const FPrisonGuardMovementData& GetValue() property
	{
		GetCrumbValueStruct(Data);
		return Data;
	}

	void SetValue(FPrisonGuardMovementData NewValue) property
	{
		SetCrumbValueStruct(NewValue);
	}
	
	void InterpolateValues(FPrisonGuardMovementData& OutValue, FPrisonGuardMovementData A, FPrisonGuardMovementData B, float64 Alpha)
	{
		// Discrete steps
		OutValue.AnimRequest = B.AnimRequest;
	}
}