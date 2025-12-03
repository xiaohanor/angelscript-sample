struct FTundraGnatClimbingMovementParams
{
	UTundraGnatHostComponent HostComp;
	FVector StartOffset;
	UTundraGnatEntryScenepointComponent Scenepoint;	
}

class UTundraGnatClimbingMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"ClimbingMovement");	
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50; // Before regular movement
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UTundraGnatComponent GnatComp;
	UTundraGnatHostComponent HostComp;
	UTundraGnatSettings Settings;
	UTeleportingMovementData Movement;
	UHazeCrumbSyncedVectorComponent SyncedUpVector;

    FVector CustomVelocity;
	FVector PrevLocation;
	FName CurrentBone = NAME_None;
	UTundraGnatEntryScenepointComponent Scenepoint;
	int NextWaypointIndex;
	bool bLocalMovement = false;

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
	bool ShouldActivate(FTundraGnatClimbingMovementParams& Params) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (GnatComp.ClimbScenepoint == nullptr)
			return false;
		if (GnatComp.Host == nullptr)
			return false;
		UTundraGnatHostComponent HostComponent = UTundraGnatHostComponent::Get(GnatComp.Host);
		if (HostComponent == nullptr)
			return false;
		Params.HostComp = HostComponent;
		Params.Scenepoint = GnatComp.ClimbScenepoint;
		Params.StartOffset = GnatComp.ClimbScenepoint.WorldTransform.InverseTransformPosition(GnatComp.ClimbLoc);
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (GnatComp.ClimbBone.IsNone())
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraGnatClimbingMovementParams Params)
	{
		HostComp = Params.HostComp;
		HostComp.Mesh = UHazeSkeletalMeshComponentBase::Get(HostComp.Owner);
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;

		Scenepoint = Params.Scenepoint;
		CurrentBone = HostComp.Mesh.GetSocketBoneName(Scenepoint.AttachSocketName);
		SyncedUpVector.Value = HostComp.Mesh.GetSocketRotation(CurrentBone).UpVector;

		// Movement system attach to climb socket
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(HostComp.Mesh, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal, CurrentBone);

		bLocalMovement = true;
		MoveComp.bResolveMovementLocally.Apply(true, this, EInstigatePriority::Normal);

		NextWaypointIndex = 0;
		FVector StartLoc = Scenepoint.WorldTransform.TransformPosition(Params.StartOffset);
		RecreateSpline(StartLoc, Scenepoint.WorldRotation, CurrentBone);
		GnatComp.bHasStartedClimbing = true;

		UTundraGnatEffectEventHandler::Trigger_OnClimbEntry(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
		if (bLocalMovement)
			MoveComp.bResolveMovementLocally.Clear(this);
		bLocalMovement = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// This is set in ResolveMovement, so will lag one frame behind
		if(!MoveComp.PrepareMove(Movement, SyncedUpVector.Value.GetSafeNormal()))
			return;

		if(HasControl() || bLocalMovement)
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
		GnatComp.ClimbLoc = Owner.ActorLocation;

		if (HasControl() || bLocalMovement) 
		{
			if (GnatComp.ClimbDistAlongSpline > GnatComp.ClimbSpline.Length - Settings.AtDestinationRange)
			{
				if (CurrentBone != n"Hips")
				{
					// We're at the joint of a leg, set up a new spline to parent bone
					FName NextBone = HostComp.Mesh.GetParentBone(CurrentBone);
					RecreateSpline(Owner.ActorLocation, Owner.ActorRotation, NextBone);
					MoveComp.FollowComponentMovement(HostComp.Mesh, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal, CurrentBone);
				}
			}

			// Use local movement until we've reached last bone of climb. When this occurs we're not visible so a janky transition is fine
			// We do not want to crumb sync this as there are lots of gnapes climbing.
			if (bLocalMovement && (CurrentBone == n"Hips"))
			{
				bLocalMovement = false;
				MoveComp.bResolveMovementLocally.Clear(this);
			}
		}

		PrevLocation = Owner.ActorLocation;

#if EDITOR 		
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugString(Owner.ActorLocation + FVector(0.0, 0.0, 500.0), "" + GnatComp.ClimbBone + " " + Math::RoundToInt(100.0 * GnatComp.ClimbDistAlongSpline / Math::Max(GnatComp.ClimbSpline.Length, 1.0)) + "%", Scale = 2.0);

			FTransform BoneTransform = HostComp.Mesh.GetSocketTransform(GnatComp.ClimbBone);
			TArray<FVector> SplineLocs;
			GnatComp.ClimbSpline.GetLocations(SplineLocs, 50);
			FVector Prev = BoneTransform.TransformPosition(SplineLocs[0]);	
			for (int i = 1; i < SplineLocs.Num(); i++)
			{
				FVector Loc = BoneTransform.TransformPosition(SplineLocs[i]);
				Debug::DrawDebugLine(Prev, Loc, FLinearColor::Purple, 5.0);	
				Prev = Loc;
			}

			int i = 0;
			for (FVector Loc : GnatComp.ClimbSpline.Points)
			{
				FVector WorldLoc = BoneTransform.TransformPosition(Loc);
				Debug::DrawDebugSphere(WorldLoc, 5, 4, FLinearColor::Yellow, 5);
				Debug::DrawDebugLine(WorldLoc, WorldLoc + BoneTransform.TransformVector(GnatComp.ClimbSpline.UpDirections[i]) * 100.0, FLinearColor::Yellow, 3);
				i++;
			}

			Debug::DrawDebugSphere(Owner.ActorLocation, 100, 4, FLinearColor::Red, 20);
			Debug::DrawDebugLine(Owner.ActorLocation, HostComp.Owner.ActorLocation, FLinearColor::Red, 20);

			FTundraGnatCapsule Cap = HostComp.GetClosestCapsule(Owner.ActorLocation);
			Debug::DrawDebugCapsule(Cap.Transform.Location, Cap.Halfheight + Cap.Radius, Cap.Radius, Cap.Transform.Rotator(), FLinearColor::Yellow, 10);
		}
#endif
	}

	void RecreateSpline(FVector StartWorldLocation, FRotator StartWorldRotation, FName Bone)
	{
		TArray<FVector> Points;
		TArray<FVector> UpDirs;

		// Set starting local location, updir and tangent
		FTransform BoneTransform = HostComp.Mesh.GetSocketTransform(Bone);
		Points.Add(BoneTransform.InverseTransformPosition(StartWorldLocation));
		UpDirs.Add(BoneTransform.InverseTransformVector(StartWorldRotation.UpVector));
		GnatComp.ClimbSpline.SetCustomEnterTangentPoint(Points[0] - BoneTransform.InverseTransformVector(StartWorldRotation.ForwardVector) * 100.0);

		for (; NextWaypointIndex < Scenepoint.Waypoints.Num(); NextWaypointIndex++)
		{
			if (Scenepoint.Waypoints[NextWaypointIndex].AttachSocketName != Bone)
				break;
			Points.Add(Scenepoint.Waypoints[NextWaypointIndex].RelativeLocation);
			UpDirs.Add(Scenepoint.Waypoints[NextWaypointIndex].RelativeRotation.UpVector);
		}

		GnatComp.ClimbSpline.SetPointsAndUpDirections(Points, UpDirs);
		GnatComp.ClimbDistAlongSpline = 0.0;
		CurrentBone = Bone;
		GnatComp.ClimbBone = Bone;
	}

	void ComposeMovement(float DeltaTime)
	{	
		// Follow spline exactly (note that spline is in climb socket space)
		float ClimbSpeed = Settings.ClimbMoveSpeed;
		GnatComp.ClimbDistAlongSpline += ClimbSpeed * DeltaTime;
		FVector SplineLocalLoc;
		FQuat SplineLocalRot;
		GnatComp.ClimbSpline.GetLocationAndQuatAtDistance(GnatComp.ClimbDistAlongSpline, SplineLocalLoc, SplineLocalRot);
		FTransform SocketTransform = HostComp.Mesh.GetSocketTransform(GnatComp.ClimbBone);
		FVector WorldLoc = SocketTransform.TransformPosition(SplineLocalLoc); 
		FQuat WorldRot = SocketTransform.TransformRotation(SplineLocalRot); 
		FVector WorldDir = WorldRot.ForwardVector;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(WorldLoc, WorldRot.ForwardVector * ClimbSpeed);		

		FRotator Rotation;
		Rotation = MoveComp.GetRotationTowardsDirection(WorldDir, 0.2, DeltaTime);
		Movement.SetRotation(Rotation);

		// Set up vector (will lag one frame behind)
		SyncedUpVector.Value = WorldRot.UpVector;
	}
}
