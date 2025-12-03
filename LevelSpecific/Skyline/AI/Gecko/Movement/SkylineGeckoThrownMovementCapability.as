struct FGeckoThrownDeactivationParams
{
	bool bImpact = false;
}

class USkylineGeckoThrownMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 60; 
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UGravityWhippableComponent WhippableComp;
	UGravityWhipTargetComponent WhipTarget;
	UBasicAIDestinationComponent DestinationComp;
	UBasicAIAnimationComponent AnimComp;
	UWallclimbingComponent WallclimbingComp;

	USkylineGeckoSettings Settings;
	USimpleMovementData Movement;

	FVector PrevLocation;
	FHazeAcceleratedRotator AccUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);
		WhipTarget = UGravityWhipTargetComponent::Get(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		WallclimbingComp = UWallclimbingComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!WhippableComp.bThrown)
			return false;
	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGeckoThrownDeactivationParams& OutParams) const
	{
		if (MoveComp.HasAnyValidBlockingImpacts())
		{
			OutParams.bImpact = true;
			return true;
		}
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (!WhippableComp.bThrown)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.OverrideResolver(USkylineGeckoThrownMovementResolver, this);
		PrevLocation = Owner.ActorLocation;
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		AccUp.SnapTo(MoveComp.WorldUp.Rotation());
		AnimComp.RequestFeature(FeatureTagGecko::ThrownByWhip, EBasicBehaviourPriority::High, this);
		WhipTarget.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGeckoThrownDeactivationParams Params)
	{
		AnimComp.ClearFeature(this);
		MoveComp.ClearResolverOverride(USkylineGeckoThrownMovementResolver, this);
		if (Params.bImpact)
			WhippableComp.OnImpact.Broadcast();
		WhippableComp.bThrown = false;
		WhipTarget.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement, AccUp.AccelerateTo(GetTargetUp().Rotation(), 1.0, DeltaTime).Vector()))
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

	FVector GetTargetUp()
	{
		if (WallclimbingComp.DestinationUpVector.Get().IsZero())
			return MoveComp.WorldUp;
		return WallclimbingComp.DestinationUpVector.Get();	
	}

	void ComposeMovement(float DeltaTime)
	{	
		// Maintain velocity (no gravity or friction)
		FVector Velocity = MoveComp.Velocity;
		if (Velocity.IsNearlyZero())
			Velocity = Game::Zoe.ViewRotation.ForwardVector * 5000.0; // We really should not be able to stop until impact
		Movement.AddVelocity(Velocity);

		Movement.AddPendingImpulses();

		// Rotate to match wanted up vector
		if (MoveComp.WorldUp.DotProduct(Owner.ActorUpVector) < 0.99)
			MoveComp.RotateTowardsDirection(Owner.ActorForwardVector, Settings.TurnDuration, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugArrow(Owner.ActorLocation, Owner.ActorLocation - FVector(0.0, 0.0, 1000.0), 20, FLinearColor::Red, 5.0);
			Debug::DrawDebugSphere(Cast<AHazeCharacter>(Owner).Mesh.WorldLocation);
		}
#endif
	}
}

