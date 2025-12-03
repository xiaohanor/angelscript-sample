class USanctuaryLightBirdCompanionLanternAttachedCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdLantern);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryLightBirdCompanionSettings Settings;
	UBasicAIAnimationComponent AnimComp; 

	FHazeAcceleratedVector AccRelativeLocation;
	FHazeAcceleratedRotator AccRelativeRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false; // Wait one tick after movement before activating this
		if (CompanionComp.State != ELightBirdCompanionState::LanternAttached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CompanionComp.UserComp.State != ELightBirdState::Lantern)
			return true;
		if (CompanionComp.State != ELightBirdCompanionState::LanternAttached)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.State = ELightBirdCompanionState::LanternAttached;
		CompanionComp.Illuminators.Add(this);

		CompanionComp.Attach(CompanionComp.Player.Mesh, Settings.LanternSocket);
		AccRelativeLocation.SnapTo(Owner.ActorRelativeLocation);
		AccRelativeRotation.SnapTo(Owner.ActorRelativeRotation);

		AnimComp.RequestFeature(LightBirdCompanionAnimTags::LanternAttached, EBasicBehaviourPriority::Medium, this);

		ULightBirdEventHandler::Trigger_LanternAttachedStarted(Owner);
		ULightBirdEventHandler::Trigger_LanternAttachedStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == ELightBirdCompanionState::LanternAttached)
			CompanionComp.State = ELightBirdCompanionState::Follow;
		CompanionComp.Illuminators.RemoveSingleSwap(this);

		CompanionComp.Detach();

		AnimComp.ClearFeature(this);

		// Launch up and away
		FVector LaunchDir = Owner.ActorUpVector * 0.5 - CompanionComp.Player.ActorRightVector * 0.5;
		CompanionComp.ApplyFollowImpulse(LaunchDir * 500.0);

		ULightBirdEventHandler::Trigger_LanternAttachedStopped(Owner);
		ULightBirdEventHandler::Trigger_LanternAttachedStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.SetActorVelocity(CompanionComp.Player.ActorVelocity + CompanionComp.PlayerGroundVelocity.Value);
		AccRelativeLocation.AccelerateTo(FVector::ZeroVector, 1.0, DeltaTime);
		AccRelativeRotation.AccelerateTo(FRotator::ZeroRotator, 3.0, DeltaTime);
		Owner.SetActorRelativeLocation(AccRelativeLocation.Value);
		Owner.SetActorRelativeRotation(AccRelativeRotation.Value);
	}
};