struct FStoneBeastCritterMoveAlongSplineParams
{
	UHazeSplineComponent Spline;
	bool bFollowForwards = true;
}

// Based on UBasicAIClimbAlongSplineMovementCapability
// Move along spline while changing movement up vector to match spline up.
// Note that users of this need to handle having a weird movement up when spline movement is done.
class USummitStoneBeastCritterMoveAlongSplineMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"WallclimbingMovement");	
	default CapabilityTags.Add(n"SplineMovement");	

	default DebugCategory = CapabilityTags::Movement;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50; // Before regular movement

	AAISummitStoneBeastCritter Critter;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIMovementSettings MoveSettings;
	UPathfollowingSettings PathingSettings;
	UTeleportingMovementData Movement;

	FVector CustomVelocity;
	FVector PrevLocation;
	FVector DecalLocation;

	float SpeedMultiplier = 1.15;
	float DamageRadius = 160.0;

	bool bCanMove;
	bool bUseCrawlSplineEntrance = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();

		Critter = Cast<AAISummitStoneBeastCritter>(Owner);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FStoneBeastCritterMoveAlongSplineParams& OutParams) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (DestinationComp.FollowSpline == nullptr)
			return false;
		OutParams.Spline = DestinationComp.FollowSpline;
		OutParams.bFollowForwards = DestinationComp.bFollowSplineForwards;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (DestinationComp.FollowSpline == nullptr)
			return true;
		if (Critter.HealthComp.IsDead())
			return true;
		if (Critter == nullptr)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FStoneBeastCritterMoveAlongSplineParams Params)
	{
		DestinationComp.FollowSpline = Params.Spline;
		DestinationComp.bFollowSplineForwards = Params.bFollowForwards;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		
		// Assume we start at beginning of spline for now
		DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, 0.0, DestinationComp.bFollowSplineForwards);

		USceneComponent ParentActorComponent = Owner.RootComponent.AttachParent;		
		
		if (ParentActorComponent == nullptr && RespawnComp.Spawner != nullptr)
			ParentActorComponent = RespawnComp.Spawner.RootComponent.AttachParent;

		if (ParentActorComponent != nullptr)
		{
			Owner.DetachRootComponentFromParent();
			MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);			
			MoveComp.FollowComponentMovement(ParentActorComponent, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal);			
		}

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseLine();
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActors(TListedActors<AAISummitStoneBeastCritter>().Array);
		
		FVector End = DestinationComp.FollowSpline.GetWorldLocationAtSplineDistance(DestinationComp.FollowSpline.SplineLength);
		FVector Start = End + FVector::UpVector * 200.0;
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);
		
		if (Hit.bBlockingHit)
		{
			DecalLocation = Hit.ImpactPoint;
		}
		else
		{
			DecalLocation = End;
		}

		bUseCrawlSplineEntrance = USummitStoneBeastCritterSettings::GetSettings(Owner).bUseCrawlSplineEntrance;
		if (!bUseCrawlSplineEntrance)
			Critter.ActivateDecal(DecalLocation);

		Critter.OnAIDie.AddUFunction(this, n"OnAIDie");
	}

	UFUNCTION()
	private void OnAIDie()
	{
		if (!bUseCrawlSplineEntrance)
			Critter.DeactivateDecal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
		USummitStoneBeastCritterEffectHandler::Trigger_OnLand(Owner);
		DamagePlayerOnLanding();
		if (!bUseCrawlSplineEntrance)
			Critter.DeactivateDecal();
		bCanMove = false;
		Critter.OnAIDie.UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, GetCurrentUpVector()))
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

		DamagePlayerOnLanding();
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	FVector GetCurrentUpVector()
	{
		if (HasControl())
		{
			return DestinationComp.FollowSplinePosition.WorldUpVector;	
		}
		else
		{
			FHazeSyncedActorPosition CrumbPos = MoveComp.GetCrumbSyncedPosition();
			return CrumbPos.WorldRotation.UpVector;		
		}
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector MoveDir = Owner.ActorForwardVector;
		FVector Velocity = MoveComp.Velocity - CustomVelocity;

		// Accelerate along spline
		FVector SplineDir = DestinationComp.FollowSplinePosition.WorldForwardVector;
		Velocity += SplineDir * DestinationComp.Speed * SpeedMultiplier * DeltaTime;
		Velocity -= Velocity * MoveSettings.AirFriction * DeltaTime;

		// Move along spline
		FVector PrevLocAlongSpline = DestinationComp.FollowSplinePosition.WorldLocation;
		float SplineSpeed = SplineDir.DotProduct(Velocity);
		DestinationComp.FollowSplinePosition.Move(SplineSpeed * DeltaTime);
		Movement.AddDelta(DestinationComp.FollowSplinePosition.WorldLocation - PrevLocAlongSpline);

		// Adjust spline-orthogonal velocity
		FVector OrthogonalVelocity = Velocity.ConstrainToPlane(SplineDir);
		OrthogonalVelocity -= OrthogonalVelocity * MoveSettings.SplineCaptureBrakeFriction * DeltaTime;
		Movement.AddVelocity(OrthogonalVelocity);
		MoveDir = SplineDir; // TODO: factor in orthogonal velocity!
		
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of spline
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else 
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}

	void DamagePlayerOnLanding()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Distance = (Player.ActorLocation - Owner.ActorLocation).Size();
			if (Distance <= DamageRadius)
			{
				FVector Move = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				Move += FVector(0, 0, 0.65);
				Move.Normalize();
				Move *= 500.0;
				Player.DamagePlayerHealth(0.5);
				FKnockdown KnockDown;
				KnockDown.Duration = 1.0;
				KnockDown.Move = Move;
				Player.ApplyKnockdown(KnockDown);
			}
		}
	}

	float GetDistancePercentage() const
	{
		if (DestinationComp.FollowSpline == nullptr)
			return 0;
		
		return DestinationComp.FollowSplinePosition.CurrentSplineDistance / DestinationComp.FollowSpline.SplineLength;
	}
}
