struct FTundraGnatMovementParams
{
	UTundraGnatHostComponent HostComp;
}

class UTundraGnatMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UTundraGnatComponent GnatComp;
	UTundraGnatHostComponent HostComp;
	UPlayerMovementComponent PlayerMoveComp;
	UTundraGnatSettings Settings;
	USweepingMovementData Movement;
	FHazeAcceleratedRotator AccUp;

    FVector CustomVelocity;
	FVector PrevLocation;
	FTransform PreviousHostTransform;

	bool bHasLeapt = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		GnatComp = UTundraGnatComponent::GetOrCreate(Owner);
		Settings = UTundraGnatSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraGnatMovementParams& OutParams) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (GnatComp.Host == nullptr)
			return false;
		UTundraGnatHostComponent HostComponent = UTundraGnatHostComponent::Get(GnatComp.Host);
		if (HostComponent == nullptr)
			return false;
		OutParams.HostComp = HostComponent;
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
	void OnActivated(FTundraGnatMovementParams Params)
	{
		HostComp = Params.HostComp;
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		AccUp.SnapTo(Owner.ActorUpVector.Rotation());
		PreviousHostTransform = HostComp.WorldTransform;
		bHasLeapt = false;

		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		if (HostComp.Body != nullptr)
			MoveComp.FollowComponentMovement(HostComp.Body, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal);
		else 
			MoveComp.FollowComponentMovement(HostComp.Mesh, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal, n"Hips");
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
		AccUp.AccelerateTo(FVector::UpVector.Rotation(), Settings.UpDirectionChangeDuration, DeltaTime);

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
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (GnatComp.bFleeingLeap)
		{
			ComposeFleeingLeap(DeltaTime);
			return;
		}

		FVector GroundUp = FVector::UpVector;
		FVector OwnLoc = Owner.ActorLocation;
		FVector BaseVelocity = MoveComp.Velocity - CustomVelocity;
		FVector VerticalVelocity = BaseVelocity.ProjectOnTo(GroundUp);
		FVector HorizontalVelocity = BaseVelocity - VerticalVelocity;
		FVector Destination = DestinationComp.Destination;

		// Note that destination is in world space from one frame ago, so if host moves quickly we need to compensate
		FVector LocalDest = PreviousHostTransform.InverseTransformPosition(Destination);
		Destination = HostComp.WorldTransform.TransformPosition(LocalDest);

		FVector ToDest = (Destination - OwnLoc).ConstrainToPlane(GroundUp);
		float DestDist = ToDest.Size();
		FVector DestDir = Owner.ActorForwardVector;
		if (DestDist > 1.0)
			DestDir = ToDest / DestDist;

		bool bIsAtDestination = OwnLoc.IsWithinDist(Destination, Settings.AtDestinationRange);

		if (DestinationComp.HasDestination() && !bIsAtDestination)
		{
			FVector MoveDir = DestDir; 
			HorizontalVelocity = MoveDir * DestinationComp.Speed;
		}
		else
		{
			// No destination, latch onto walking stick and let friction slow us to a stop
			FTundraGnatCapsule Ground = HostComp.GetClosestCapsule(Owner.ActorLocation);
			Movement.AddAcceleration((Ground.GetCenterLocation(Owner.ActorLocation) - Owner.ActorLocation).GetSafeNormal() * 2000.0); 
			DestinationComp.ReportStopping();
		}

		// Gravity
		Movement.AddAcceleration(-GroundUp * Settings.Gravity);

		// Apply friction
		float FrictionFactor = Math::Pow(Math::Exp(-Settings.Friction), DeltaTime);
		HorizontalVelocity *= FrictionFactor; 
		if (MoveComp.IsOnAnyGround())
			VerticalVelocity *= FrictionFactor;

		BaseVelocity = HorizontalVelocity + VerticalVelocity;
		Movement.AddVelocity(BaseVelocity);

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= FrictionFactor;
		Movement.AddVelocity(CustomVelocity);

		Movement.AddPendingImpulses();

		// Look at destination when moving, focus otherwise or stop rotating
		FRotator Rotation;
		if (DestinationComp.Focus.IsValid())
			Rotation = MoveComp.GetRotationTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime);
		else if (DestinationComp.HasDestination() && !bIsAtDestination)
			Rotation = MoveComp.GetRotationTowardsDirection(ToDest.GetSafeNormal(), Settings.TurnDuration, DeltaTime);
		else  
			Rotation = MoveComp.GetStoppedRotation(5.0, DeltaTime);
		Movement.SetRotation(Rotation);

		PreviousHostTransform = HostComp.WorldTransform;

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Destination, OwnLoc, FLinearColor::LucBlue);	
			Debug::DrawDebugLine(OwnLoc, OwnLoc + GroundUp * 400, FLinearColor::Red, 4);	
			Debug::DrawDebugLine(OwnLoc, OwnLoc + AccUp.Value.Vector() * 300, FLinearColor::Gray, 6);	
			Debug::DrawDebugLine(OwnLoc, OwnLoc + DestDir * 100, FLinearColor::Red, 4);	
			Debug::DrawDebugLine(OwnLoc, OwnLoc + HorizontalVelocity, FLinearColor::Yellow, 4);	
			Debug::DrawDebugLine(OwnLoc, OwnLoc + BaseVelocity, FLinearColor::Green, 4);	
		}
#endif
	}

	void ComposeFleeingLeap(float DeltaTime)
	{
		FVector BaseVelocity = MoveComp.Velocity - CustomVelocity;

		if (!bHasLeapt)
		{
			bHasLeapt = true;
			BaseVelocity += GnatComp.FleeingLeapImpulse;
			GnatComp.FleeingLeapImpulse = FVector::ZeroVector;

			MoveComp.UnFollowComponentMovement(this);
			MoveComp.ClearFollowEnabledOverride(this);

			BaseVelocity += HostComp.Owner.ActorVelocity;
		}			

		Movement.AddAcceleration(-FVector::UpVector * Settings.Gravity);	
		Movement.AddVelocity(BaseVelocity);

		// Air drag for nicer trajectory once we've leapt off the walking stick
		if (bHasLeapt)
			BaseVelocity *= Math::Pow(Math::Exp(-0.25), DeltaTime);

		MoveComp.RotateTowardsDirection(BaseVelocity, 2.0, DeltaTime, Movement);

		PreviousHostTransform = HostComp.WorldTransform;
	}
}
