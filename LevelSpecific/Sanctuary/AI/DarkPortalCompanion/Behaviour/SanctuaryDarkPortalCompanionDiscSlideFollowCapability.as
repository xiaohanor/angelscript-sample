struct FDarkPortalCompanionDiscSlideFollowParams
{
	bool bTeleport;
	FVector Destination;
}

class USanctuaryDarkPortalCompanionDiscSlideFollowCapability : UHazeCapability
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
	USlidingDiscPlayerComponent SlidingDiscComp;
	USanctuaryDarkPortalCompanionSettings Settings;
	UTeleportingMovementData Movement;
	
	FVector Destination;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedVector Offset;
	FHazeAcceleratedVector DiscVelocity;

	UHazeCrumbSyncedActorPositionComponent CrumbSyncedPositionComp;
	float EndInWaterDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		Movement = MoveComp.SetupTeleportingMovementData();
		CrumbSyncedPositionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner);
		Offset.SnapTo(Settings.DiscSlideFollowOffset);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SlidingDiscComp != nullptr)
			return;
		if (CompanionComp.Player == nullptr)
			return;
		SlidingDiscComp = USlidingDiscPlayerComponent::Get(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDarkPortalCompanionDiscSlideFollowParams& OutParams) const
	{
		if (!IsValid(SlidingDiscComp))
			return false;
		if (!SlidingDiscComp.bIsSliding)
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (CompanionComp.State != EDarkPortalCompanionState::Follow)
			return false;
		if (CompanionComp.Player.IsPlayerDead())
			return false;
		OutParams.Destination = GetDestination();
		OutParams.bTeleport = false;
		UFadeManagerComponent FadeManager = UFadeManagerComponent::Get(CompanionComp.Player);
		if ((FadeManager != nullptr) && FadeManager.bIsFadingFromLoading)
			OutParams.bTeleport = true;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(SlidingDiscComp))
			return true;
		if (!SlidingDiscComp.bIsSliding)
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
	void OnActivated(FDarkPortalCompanionDiscSlideFollowParams Params)
	{
		CompanionComp.State = EDarkPortalCompanionState::Follow;

		// No obstruction avoidance or free flying events needed
		Owner.BlockCapabilities(n"ObstructionAvoidance", this);
		Owner.BlockCapabilities(n"FreeFlyingEvent", this);

		// Player should not be able to control companion
		CompanionComp.Player.BlockCapabilitiesExcluding(DarkPortal::Tags::DarkPortal, DarkPortal::Tags::DarkPortalActiveDuringIntro, this);			

		// We must detach before commencing move
		CompanionComp.Detach();

		if (Params.bTeleport)
			Owner.TeleportActor(Params.Destination, Owner.ActorRotation, this);

		Destination = Params.Destination;
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		DiscVelocity.SnapTo(CompanionComp.Player.AttachParentActor.ActorVelocity);	

		MoveComp.bResolveMovementLocally.Apply(true, this, EInstigatePriority::Normal);
		EndInWaterDuration = 0.0;

		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::Follow, EBasicBehaviourPriority::Medium, this);
		UDarkPortalEventHandler::Trigger_OnCompanionFollowSlidingDiscStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimComp.ClearFeature(this);
		Owner.UnblockCapabilities(n"ObstructionAvoidance", this);
		Owner.UnblockCapabilities(n"FreeFlyingEvent", this);
		CompanionComp.Player.UnblockCapabilities(DarkPortal::Tags::DarkPortal, this);			
		MoveComp.bResolveMovementLocally.Clear(this);
		UDarkPortalEventHandler::Trigger_OnCompanionFollowSlidingDiscStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Crumbed regular movement
		if(!MoveComp.PrepareMove(Movement))
			return;

		ComposeMovement(DeltaTime);

		MoveComp.ApplyMove(Movement);
	}

	void UpdateOffset(float DeltaTime)
	{
		FVector TargetOffset = Settings.DiscSlideFollowOffset;
		Offset.AccelerateTo(TargetOffset, 5.0, DeltaTime);		
	}

	FVector GetDestination() const
	{
		FTransform Transform = CompanionComp.Player.AttachParentActor.ActorTransform;
		Transform.Rotation = FQuat::MakeFromZX(FVector::UpVector, CompanionComp.Player.ActorForwardVector);
		return Transform.TransformPositionNoScale(Offset.Value);
	}

	void ComposeMovement(float DeltaTime)
	{
		if (CompanionComp.Player.AttachParentActor == nullptr)
		{
			// Player has detached (can happen on remote side for a short while after player death)
			// Slowly come to a stop
			Movement.AddVelocity(MoveComp.Velocity * Math::Pow(Math::Exp(-1.0), DeltaTime));
			return;
		}

		UpdateOffset(DeltaTime);
		Destination = GetDestination();
		AccLocation.Value = Owner.ActorLocation;
		AccLocation.AccelerateTo(Destination, 3.0, DeltaTime);
		if (!HasControl() && (SlidingDiscComp != nullptr) && SlidingDiscComp.bInWaterSwitchSegment)
		{
			// We're about to end disc slide, adjust towards synced location for smoother transition
			EndInWaterDuration += DeltaTime;
			float Alpha = Math::EaseIn(0.0, 1.0, Math::Min(EndInWaterDuration * 0.25, 1.0), 3.0);
			AccLocation.Value = Math::Lerp(AccLocation.Value, CrumbSyncedPositionComp.Position.WorldLocation, Alpha);
		}
		Movement.AddDelta(AccLocation.Value - Owner.ActorLocation);

		DiscVelocity.AccelerateTo(CompanionComp.Player.AttachParentActor.ActorVelocity, 0.5, DeltaTime);
		Movement.AddVelocity(DiscVelocity.Value);

		// Align with player forward
		MoveComp.RotateTowardsDirection(CompanionComp.Player.ActorForwardVector, Settings.TightFollowTurnDuration, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Destination, 20.0, 4, FLinearColor::Green);
		}
#endif
	}
};