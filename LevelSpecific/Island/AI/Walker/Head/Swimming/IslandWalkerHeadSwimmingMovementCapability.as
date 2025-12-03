class UIslandWalkerHeadSwimmingMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UHazeCrumbSyncedFloatComponent CrumbMeshPitchComp;
	UHazeOffsetComponent MeshRoot;
	AIslandWalkerArenaLimits Arena;

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerSettings Settings;
	UMovementGravitySettings GravitySettings;
	USweepingMovementData Movement;
	FVector CustomVelocity;
	FVector PrevLocation;

	float WobbleTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		CrumbMeshPitchComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, n"SyncedMeshPitch");
		MeshRoot = Cast<AHazeCharacter>(Owner).MeshOffsetComponent;
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		GravitySettings = UMovementGravitySettings::GetSettings(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (HeadComp.State != EIslandWalkerHeadState::Swimming)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (HeadComp.State != EIslandWalkerHeadState::Swimming)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		CrumbMeshPitchComp.Value = MeshRoot.WorldRotation.Pitch;
		CustomVelocity = FVector::ZeroVector;
		PrevLocation = Owner.ActorLocation;

		// No gravity unless behaviours want it
		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		WobbleTimer += DeltaTime;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
			CrumbMeshPitchComp.Value = MoveComp.AccRotation.Value.Pitch;
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			MoveComp.AccRotation.Value.Pitch = CrumbMeshPitchComp.Value;
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);

		// Pitch mesh and wobble a bit in roll
		FRotator MeshRotation = MeshRoot.WorldRotation;
		MeshRotation.Pitch = Math::ClampAngle(MoveComp.AccRotation.Value.Pitch, -40.0, 40.0);
		MeshRotation.Roll = Settings.HeadWobbleRollAmplitude * Math::Sin(WobbleTimer * Settings.HeadWobbleRollFrequency);
		MeshRoot.SetWorldRotation(MeshRotation);
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DeltaTime < SMALL_NUMBER)
			return;

		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity;
		FVector OwnLoc = Owner.ActorLocation;	
				
		if (DestinationComp.HasDestination())
		{
			FVector Destination = DestinationComp.Destination;
			if (!OwnLoc.IsWithinDist(Destination, 20.0))				
			{
				// Accelerate towards destination
				FVector DestDir = (Destination - OwnLoc).GetSafeNormal();
				Velocity += DestDir * DestinationComp.Speed * DeltaTime;
			}
		}

		// Apply friction
		float Friction = Settings.HeadFriction;
		float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);
		Velocity *= FrictionFactor;

		// Wobble 
		FVector Wobble;
		Wobble += Owner.ActorForwardVector * Settings.HeadWobbleAmplitude.X * 0.25 * Math::Sin(WobbleTimer * Settings.HeadWobbleFrequency.X);
		Wobble += Owner.ActorRightVector * Settings.HeadWobbleAmplitude.Y * 0.25 * Math::Sin(WobbleTimer * Settings.HeadWobbleFrequency.Y);
		Wobble += Owner.ActorUpVector * Settings.HeadWobbleAmplitude.Z * 0.25 * Math::Sin(WobbleTimer * Settings.HeadWobbleFrequency.Z);
		Wobble *= DeltaTime * 30.0; 
		CustomVelocity += Wobble;

		// Apply custom acceleration
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= FrictionFactor;
		Velocity += CustomVelocity;

		bool bBelowFloor = !HeadComp.MovementFloor.IsDefaultValue() && (OwnLoc.Z < HeadComp.MovementFloor.Get());
		if (bBelowFloor) 
		{
			Velocity.Z = Math::Max(0.0, Velocity.Z);
			Movement.AddDeltaFromMoveToPositionWithCustomVelocity(FVector(OwnLoc.X, OwnLoc.Y, HeadComp.MovementFloor.Get()), FVector::ZeroVector);
		}
		else
		{
			// Above invisible floor, fall freely
			Movement.AddGravityAcceleration();
		}

		// If we have gravity, apply buoyancy
		if ((GravitySettings.GravityScale > 0.0) && (Arena != nullptr))
		{
			// Head is mostly box shaped, so use linear buoyancy
			float SubmergedAlpha = Math::Clamp(Arena.GetFloodedSubmergedDepth(Owner) / Settings.HeadSwimmingMaxBuoyancyDepth, 0.0, 1.0);
			if (SubmergedAlpha > SMALL_NUMBER)
				Movement.AddAcceleration(FVector::UpVector * Settings.HeadSwimmingMaxBuoyancy * SubmergedAlpha * GravitySettings.GravityScale);
		}

		Movement.AddVelocity(Velocity);

		Movement.AddPendingImpulses();

		// Turn towards focus or neck forward if none
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.HeadTurnDuration, DeltaTime, Movement, true);
		else if (HeadComp.NeckCableOrigin.ForwardVector.GetSafeNormal2D().DotProduct(Owner.ActorForwardVector) < 0.99)
			MoveComp.RotateTowardsDirection(HeadComp.NeckCableOrigin.ForwardVector, Settings.HeadTurnDuration, DeltaTime, Movement, true);
		else 
			MoveComp.StopRotating(4.0, DeltaTime, Movement, true);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
		}
#endif
	}
}
