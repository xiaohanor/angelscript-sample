class USanctuaryDarkPortalCompanionCentipedeFollowCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"FlyingMovement");
	default CapabilityTags.Add(n"BlockedDuringIntro");	

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20; // No player control should be available
	default DebugCategory = CapabilityTags::Movement;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	UPlayerCentipedeComponent CentipedeComp;
	USanctuaryDarkPortalCompanionSettings Settings;
	UTeleportingMovementData Movement;
	
	FHazeAcceleratedFloat AccFollowDuration;
	FHazeAcceleratedVector AccWorldLocation;
	FHazeAcceleratedRotator AccWorldRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (CentipedeComp != nullptr)
			return;
		if (CompanionComp.Player == nullptr)
			return;
		CentipedeComp = UPlayerCentipedeComponent::Get(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsValid(CentipedeComp))
			return false;
		if (!CentipedeComp.IsCentipedeActive())
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != EDarkPortalCompanionState::Follow)
			return false;
		if (CompanionComp.Player.IsPlayerDead())
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(CentipedeComp))
			return true;
		if (!CentipedeComp.IsCentipedeActive())
			return true;
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (CompanionComp.State != EDarkPortalCompanionState::Follow)
			return true;
		if (CompanionComp.Player.IsPlayerDead())
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = EDarkPortalCompanionState::Follow;

		// No obstruction avoidance or free flying events needed
		Owner.BlockCapabilities(n"ObstructionAvoidance", this);
		Owner.BlockCapabilities(n"FreeFlyingEvent", this);

		// Player should not be able to control companion
		CompanionComp.Player.BlockCapabilitiesExcluding(DarkPortal::Tags::DarkPortal, DarkPortal::Tags::DarkPortalActiveDuringIntro, this);			

		// We must detach before commencing move
		CompanionComp.Detach();

		AccWorldLocation.SnapTo(Owner.ActorLocation, MoveComp.Velocity);
		AccWorldRotation.SnapTo(Owner.ActorRotation);
		AccFollowDuration.SnapTo(5.0);

		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::Follow, EBasicBehaviourPriority::Medium, this);

		UDarkPortalEventHandler::Trigger_OnCompanionFollowCentipedeStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimComp.ClearFeature(this);
		Owner.UnblockCapabilities(n"ObstructionAvoidance", this);
		Owner.UnblockCapabilities(n"FreeFlyingEvent", this);
		CompanionComp.Player.UnblockCapabilities(DarkPortal::Tags::DarkPortal, this);			
		UDarkPortalEventHandler::Trigger_OnCompanionFollowCentipedeStop(Owner);
	}

	FVector GetDestination() const
	{
		FTransform Transform;
		Transform.Location = CompanionComp.Player.Mesh.GetSocketLocation(Settings.CentipedeFollowSocket);
		Transform.Rotation = FQuat::MakeFromZX(CompanionComp.Player.ActorUpVector, CompanionComp.Player.ViewRotation.ForwardVector);
		return Transform.TransformPositionNoScale(Settings.CentipedeFollowOffset);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Crumbed regular movement
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
		AccFollowDuration.AccelerateTo(Settings.CentipedeFollowDuration, 5.0, DeltaTime);
		AccWorldLocation.AccelerateTo(GetDestination(), AccFollowDuration.Value, DeltaTime);
		FRotator TargetRotation = CompanionComp.Player.ActorRotation;
		AccWorldRotation.AccelerateTo(TargetRotation, Settings.TurnDuration, DeltaTime);
		Movement.AddDelta(AccWorldLocation.Value - Owner.ActorLocation);
		Movement.SetRotation(AccWorldRotation.Value);
	}
};