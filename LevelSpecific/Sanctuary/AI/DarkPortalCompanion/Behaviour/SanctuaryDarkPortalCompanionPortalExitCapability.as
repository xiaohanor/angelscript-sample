class USanctuaryDarkPortalCompanionPortalExitCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110; // Start same tick when launch attached deactivates

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryDarkPortalCompanionSettings Settings;
	USimpleMovementData Movement;
	
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != EDarkPortalCompanionState::PortalExit)
			return false; 	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CompanionComp.State != EDarkPortalCompanionState::PortalExit)
			return true;
		if (ActiveDuration > Settings.PortalExitDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = EDarkPortalCompanionState::PortalExit;

		// We must detach before commencing move
		CompanionComp.Detach();

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);

		FVector Offset = Settings.PortalExitOffset;
		if (Owner.ActorForwardVector.DotProduct(CompanionComp.LastPortalTransform.Rotation.RightVector) < 0.0)
			Offset.Y *= -1.0;
		Destination = CompanionComp.LastPortalTransform.TransformPosition(Offset); 
		
		// Align mesh with portal out vector
		CompanionComp.TargetMeshPitch.Apply(CompanionComp.LastPortalTransform.Rotator().Pitch, this, EInstigatePriority::Normal);

		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::PortalExit, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == EDarkPortalCompanionState::PortalExit)
			CompanionComp.State = EDarkPortalCompanionState::Follow;

		AnimComp.ClearFeature(this);
		CompanionComp.TargetMeshPitch.Clear(this);
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
		// Initial burst of acceleration towards target location
		FVector Velocity = MoveComp.Velocity;
		if (ActiveDuration < Settings.PortalExitDuration * 0.2)
		{
			FVector Direction = (Destination - Owner.ActorLocation).GetSafeNormal();
			float Acceleration = Settings.PortalExitAcceleration; 
			Velocity += Direction * Acceleration * DeltaTime;
		}

		// Apply friction
		float IntegratedFriction = Math::Exp(-Settings.AirFriction);
		Velocity *= Math::Pow(IntegratedFriction, DeltaTime);
		Movement.AddVelocity(Velocity);		

		// Rotate towards player
		FRotator ToPlayerRot = (CompanionComp.Player.FocusLocation - Owner.ActorLocation).Rotation();
		if (FRotator::NormalizeAxis(ToPlayerRot.Yaw - Owner.ActorRotation.Yaw) > Settings.AtPortalYawThreshold)
			MoveComp.RotateTowardsDirection(ToPlayerRot.ForwardVector, Settings.PortalExitDuration, DeltaTime, Movement);
		else
			MoveComp.StopRotating(4.0, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(Destination, 20, 4, FLinearColor::Purple);		
#endif
	}
};