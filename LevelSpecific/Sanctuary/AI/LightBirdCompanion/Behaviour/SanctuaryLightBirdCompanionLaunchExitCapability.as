class USanctuaryLightBirdCompanionLaunchExitCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110; // Start same tick when launch attached deactivates

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryLightBirdCompanionSettings Settings;
	USimpleMovementData Movement;
	
	FVector Destination;
	FHazeAcceleratedFloat AccFriction;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != ELightBirdCompanionState::LaunchExit)
			return false; 	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CompanionComp.State != ELightBirdCompanionState::LaunchExit)
			return true;
		if (ActiveDuration > Settings.LaunchExitDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = ELightBirdCompanionState::LaunchExit;

		// We must detach before commencing move
		CompanionComp.Detach();

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		AccFriction.SnapTo(Settings.AirFriction);

		FRotator FromPlayerRot = (Owner.ActorLocation - CompanionComp.Player.FocusLocation).Rotation();
		Destination = Owner.ActorLocation;
		Destination += FromPlayerRot.RotateVector(Settings.LaunchExitOffset); 

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::LaunchExit, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == ELightBirdCompanionState::LaunchExit)
			CompanionComp.State = ELightBirdCompanionState::Follow;

		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();

		MoveComp.ApplyMove(Movement);
	}

	void ComposeMovement(float DeltaTime)
	{
		// Initial burst of acceleration towards target location, then brake. 
		// Exact positioning is not necessary, but we should stay in view.
		FVector Velocity = MoveComp.Velocity;
		if (ActiveDuration < Settings.LaunchExitDuration * 0.2)
		{
			FVector Direction = (Destination - Owner.ActorLocation).GetSafeNormal();
			float Acceleration = Settings.LaunchExitAcceleration; 
			Velocity += Direction * Acceleration * DeltaTime;
		}
		if (Owner.ActorLocation.IsWithinDist(Destination, 1000.0))
			AccFriction.AccelerateTo(12.0, Settings.LaunchExitDuration, DeltaTime);	

		// Apply friction
		float IntegratedFriction = Math::Exp(-AccFriction.Value);
		Velocity *= Math::Pow(IntegratedFriction, DeltaTime);
		Movement.AddVelocity(Velocity);		

		// Rotate towards player
		FRotator ToPlayerRot = (CompanionComp.Player.FocusLocation - Owner.ActorLocation).Rotation();
		if (FRotator::NormalizeAxis(ToPlayerRot.Yaw - Owner.ActorRotation.Yaw) > Settings.LaunchAttachedYawThreshold)
			MoveComp.RotateTowardsDirection(ToPlayerRot.ForwardVector, Settings.LaunchExitDuration, DeltaTime, Movement);
		else
			MoveComp.StopRotating(4.0, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(Destination, 20, 4, FLinearColor::Yellow);		
#endif
	}
};