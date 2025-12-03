struct FLightBirdInvestigateAttachedParams
{
	USceneComponent TargetComp;
}

class USanctuaryLightBirdCompanionInvestigateAttachedCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdInvestigate);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20; // Before all regular behaviour
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryLightBirdCompanionSettings Settings;

	FLightBirdInvestigationDestination Destination;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccRelativeLocation;
	FVector RelativeTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLightBirdInvestigateAttachedParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false; // Wait one tick after movement before activating this
		if (CompanionComp.State != ELightBirdCompanionState::InvestigatingAttached)
			return false;
		OutParams.TargetComp = CompanionComp.InvestigationDestination.Get().TargetComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CompanionComp.State != ELightBirdCompanionState::InvestigatingAttached)
			return true;
		if (CompanionComp.InvestigationDestination.Get() != Destination)
			return true; // Found a new shiny thing or lost the current one
		if (!Destination.bOverridePlayerControl)
		{
			if (CompanionComp.UserComp.State != ELightBirdState::Hover)
				return true; // Player want us to do something else!
			if (CompanionComp.UserComp.bWantsRecall)
				return true; // Git back 'ere
		}
		if (UPlayerHealthComponent::Get(CompanionComp.Player).bIsDead)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLightBirdInvestigateAttachedParams Params)
	{
		CompanionComp.State = ELightBirdCompanionState::InvestigatingAttached;

		Destination = CompanionComp.InvestigationDestination.Get();
		Destination.TargetComp = Params.TargetComp; // Set component on remote

		if (!Destination.IsValid())
		{
			// Attach target has become invalid after end of launch but before this was activated. 
			// Revert to follow state, then deactivate
			CompanionComp.State = ELightBirdCompanionState::Follow;
			return;
		}

		CompanionComp.Illuminators.Add(this);
		if (Destination.bAutoIlluminate)
			CompanionComp.ForceIlluminators.Add(this);

		CompanionComp.Attach(Destination.TargetComp);
		AccRelativeLocation.SnapTo(Owner.ActorRelativeLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		
		AnimComp.RequestFeature(LightBirdCompanionAnimTags::InvestigateAttached, EBasicBehaviourPriority::Medium, this);

		ULightBirdEventHandler::Trigger_InvestigateAttachStarted(Owner);
		ULightBirdEventHandler::Trigger_InvestigateAttachStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == ELightBirdCompanionState::InvestigatingAttached)
			CompanionComp.State = ELightBirdCompanionState::LaunchExit;
		CompanionComp.Illuminators.RemoveSingleSwap(this);
		CompanionComp.ForceIlluminators.RemoveSingleSwap(this);

		// We only investigate something once
		if (CompanionComp.InvestigationDestination.Get() == Destination)
			CompanionComp.InvestigationDestination.Clear(CompanionComp.InvestigationDestination.GetCurrentInstigator());

		CompanionComp.Detach();

		AnimComp.ClearFeature(this);

		ULightBirdEventHandler::Trigger_InvestigateAttachStopped(Owner);
		ULightBirdEventHandler::Trigger_InvestigateAttachStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.SetActorVelocity(FVector::ZeroVector);
		if (!IsValid(Owner.AttachParentActor))
			return;

		AccRelativeLocation.AccelerateTo(RelativeTargetLoc, 3.0, DeltaTime);
		Owner.SetActorRelativeLocation(AccRelativeLocation.Value);

		if (Destination.bUseObjectRotation)
		{
			const float LerpDuration = 2.0;
			float SnapSoonAlpha = Math::Saturate(1.0 - (ActiveDuration / LerpDuration));
			if (SnapSoonAlpha < KINDA_SMALL_NUMBER)
				AccRotation.SnapTo(Destination.TargetComp.WorldRotation);
			else
				AccRotation.AccelerateTo(Destination.TargetComp.WorldRotation, SnapSoonAlpha * LerpDuration, DeltaTime);
			Owner.ActorRotation = AccRotation.Value;
		}
		else // default behavior, look towards player
		{
			FRotator ToPlayerRot = (CompanionComp.Player.FocusLocation - Owner.ActorLocation).Rotation();
			if (FRotator::NormalizeAxis(ToPlayerRot.Yaw - Owner.ActorRotation.Yaw) > Settings.LaunchAttachedYawThreshold)
				AccRotation.AccelerateTo(ToPlayerRot, 2.0, DeltaTime);
			Owner.ActorRotation = AccRotation.Value;
		}
	}
};