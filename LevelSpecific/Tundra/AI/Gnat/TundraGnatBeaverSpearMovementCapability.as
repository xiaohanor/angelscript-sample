struct FGnatBeaverSpearEntryParams
{
	ATundraBeaverSpear Spear;
	AActor Host;
}

class UTundraGnatBeaverSpearMovementCapability : UHazeCapability
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
	UTundraGnatComponent GnatComp;
	UTundraGnatSettings Settings;
	UTeleportingMovementData Movement;
	UHazeCrumbSyncedVectorComponent SyncedUpVector;
	ATundraBeaverSpear Spear;
	float DistAlongSpline;

	FVector PrevLocation;
	FVector PrevSpearLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		GnatComp = UTundraGnatComponent::GetOrCreate(Owner);
		Settings = UTundraGnatSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
		SyncedUpVector = UHazeCrumbSyncedVectorComponent::GetOrCreate(Owner, n"SyncedClimbUpVector");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGnatBeaverSpearEntryParams& OutParams) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (GnatComp.PassengerOnBeaverSpear == nullptr)
			return false;
		OutParams.Spear = Cast<ATundraBeaverSpear>(GnatComp.PassengerOnBeaverSpear);		
		OutParams.Host = OutParams.Spear.WalkingStickRef;		
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (GnatComp.PassengerOnBeaverSpear == nullptr)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGnatBeaverSpearEntryParams Params)
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;

		Spear = Params.Spear;
		GnatComp.PassengerOnBeaverSpear = Params.Spear;
		GnatComp.Host = Params.Host;

		// Movement system attach to climb socket
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(Spear.SpearMesh, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal);

		// Teleport to the start of climb spline
		GnatComp.ClimbDistAlongSpline = 0.0;
		PrevSpearLoc = Spear.SpearMesh.WorldLocation;
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
		if(!MoveComp.PrepareMove(Movement, GetUpVector()))
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

	FVector GetUpVector()
	{
		if (HasControl())
		{
			if (GnatComp.ClimbSpline.Points.Num() == 0)
				return Owner.ActorUpVector;
			FRotator SplineRot = GnatComp.ClimbSpline.GetRotationAtDistance(GnatComp.ClimbDistAlongSpline);
			return SplineRot.UpVector;
		}
		else
		{
			FHazeSyncedActorPosition CrumbPos = MoveComp.GetCrumbSyncedPosition();
			return CrumbPos.WorldRotation.UpVector;		
		}
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (GnatComp.ClimbSpline.Points.Num() == 0)
			return;

		FVector Velocity = FVector::ZeroVector;
		if (DestinationComp.HasDestination())
		{
			GnatComp.ClimbDistAlongSpline += DestinationComp.Speed * DeltaTime;
			if (GnatComp.ClimbDistAlongSpline > GnatComp.ClimbSpline.Length)
				GnatComp.ClimbDistAlongSpline = GnatComp.ClimbSpline.Length;
			
			FVector Dir = GnatComp.ClimbSpline.GetRotationAtDistance(GnatComp.ClimbDistAlongSpline).Vector();
			if (GnatComp.ClimbDistAlongSpline < GnatComp.ClimbSpline.Length - 0.01)
				Velocity = Dir * DestinationComp.Speed;

			MoveComp.RotateTowardsDirection(Dir, 0.5, DeltaTime, Movement);
		}

		FVector SplineLoc = GnatComp.ClimbSpline.GetLocationAtDistance(GnatComp.ClimbDistAlongSpline);
		SplineLoc += (Spear.SpearMesh.WorldLocation - PrevSpearLoc); // Spline loc is from last frame, spear may be moving fast
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(SplineLoc, Velocity);
		PrevSpearLoc = Spear.SpearMesh.WorldLocation;
	}
}
