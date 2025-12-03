struct FDarkPortalInvestigateAttachedParams
{
	USceneComponent TargetComp;
}

class USanctuaryDarkPortalCompanionInvestigateAttachedCapability : UHazeCapability
{
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalInvestigate);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 20; // Before all regular behaviour
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryDarkPortalCompanionSettings Settings;

	FDarkPortalInvestigationDestination Destination;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccRelativeLocation;
	FVector RelativeTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner); 
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDarkPortalInvestigateAttachedParams& OutParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false; // Wait one tick after movement before activating this
		if (CompanionComp.State != EDarkPortalCompanionState::InvestigatingAttached)
			return false;
		OutParams.TargetComp = CompanionComp.InvestigationDestination.Get().TargetComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CompanionComp.State != EDarkPortalCompanionState::InvestigatingAttached)
			return true;
		if (CompanionComp.InvestigationDestination.Get() != Destination)
			return true; // Found a new shiny thing or lost the current one
		if (!Destination.bOverridePlayerControl) 
		{
			if ((CompanionComp.UserComp.Portal.State != EDarkPortalState::Absorb) && (CompanionComp.UserComp.Portal.State != EDarkPortalState::Recall))	
				return true; // Player want us to do something else!
			if (CompanionComp.UserComp.bWantsRecall)
				return true;
		}
		if (UPlayerHealthComponent::Get(CompanionComp.Player).bIsDead)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDarkPortalInvestigateAttachedParams Params)
	{
		CompanionComp.State = EDarkPortalCompanionState::InvestigatingAttached;

		Destination = CompanionComp.InvestigationDestination.Get();
		Destination.TargetComp = Params.TargetComp; // Set component on remote

		if (!Destination.IsValid())
		{
			// Attach target has become invalid after end of launch but before this was activated. 
			// Revert to follow state, then deactivate
			CompanionComp.State = EDarkPortalCompanionState::Follow;
			return;
		}

		CompanionComp.Attach(Destination.TargetComp);
		AccRelativeLocation.SnapTo(Owner.ActorRelativeLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		
		AnimComp.RequestFeature(DarkPortalCompanionAnimTags::InvestigateAttached, EBasicBehaviourPriority::Medium, this);

		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateAttachStarted(Owner);
		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateAttachStarted(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (CompanionComp.State == EDarkPortalCompanionState::InvestigatingAttached)
			CompanionComp.State = EDarkPortalCompanionState::PortalExit;

		// We only investigate something once
		if (CompanionComp.InvestigationDestination.Get() == Destination)
			CompanionComp.InvestigationDestination.Clear(CompanionComp.InvestigationDestination.GetCurrentInstigator());

		CompanionComp.Detach();

		AnimComp.ClearFeature(this);

		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateAttachStopped(Owner);
		UDarkPortalEventHandler::Trigger_OnCompanionInvestigateAttachStopped(CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.SetActorVelocity(FVector::ZeroVector);
		if (!IsValid(Owner.AttachParentActor))
			return;

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
		else
		{
			AccRelativeLocation.AccelerateTo(RelativeTargetLoc, 3.0, DeltaTime);
			Owner.SetActorRelativeLocation(AccRelativeLocation.Value);
			FRotator ToPlayerRot = (CompanionComp.Player.FocusLocation - Owner.ActorLocation).Rotation();
			if (FRotator::NormalizeAxis(ToPlayerRot.Yaw - Owner.ActorRotation.Yaw) > Settings.AtPortalYawThreshold)
				AccRotation.AccelerateTo(ToPlayerRot, 2.0, DeltaTime);
			Owner.ActorRotation = AccRotation.Value;
		}
	}
};