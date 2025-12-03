class USkylineGeckoOverturnedMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 70; 
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	USkylineGeckoComponent GeckoComp;
	UBasicAIDestinationComponent DestinationComp;

	USkylineGeckoSettings Settings;
	USimpleMovementData Movement;

	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!GeckoComp.bOverturned)
			return false;
	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (!GeckoComp.bOverturned)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrevLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, FVector::UpVector)) // Fall in world space
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

	void ComposeMovement(float DeltaTime)
	{	
		// Just fall down in world space without friction
		FVector Velocity = MoveComp.Velocity;
		Velocity -= FVector::UpVector * 982.0 * 3.0 * DeltaTime;

		// Horizontal friction so we don't fly away 
		float Friction = Math::GetMappedRangeValueClamped(FVector2D(0.0, Settings.OverturnedDuration * 0.5), FVector2D(Settings.AirFriction, Settings.GroundFriction), ActiveDuration);
		float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);
		Velocity.X *= FrictionFactor;
		Velocity.Y *= FrictionFactor;

		Movement.AddVelocity(Velocity);
		
		Movement.AddPendingImpulses();

		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.OverturnedGravityChangeDuration, DeltaTime, Movement, true);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + MoveComp.WorldUp * 400.0, FLinearColor::Green, 3.0);
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorUpVector * 300.0, FLinearColor::Yellow, 3.0);
			Debug::DrawDebugArrow(Owner.ActorLocation, Owner.ActorLocation - FVector(0.0, 0.0, 200.0), 20, FLinearColor::Red, 5.0);
			Debug::DrawDebugSphere(Cast<AHazeCharacter>(Owner).Mesh.WorldLocation, 20.0);
		}
#endif
	}
}

