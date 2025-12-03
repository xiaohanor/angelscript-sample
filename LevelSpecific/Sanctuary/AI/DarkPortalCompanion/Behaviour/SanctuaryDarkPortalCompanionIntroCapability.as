class USanctuaryDarkPortalCompanionIntroCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"Companion");
	default CapabilityTags.Add(n"Intro");
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryDarkPortalCompanionSettings Settings;
	bool bIsPreparing = false;
	bool bHasReachedPlayer = false;
	float CompleteTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CompanionComp.UserComp.bIsIntroducing)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.bIsControlledByCutscene)
			return true;

		if (!CompanionComp.UserComp.bIsIntroducing && (ActiveDuration > CompleteTime))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Hide companion and disable player capabilities
		bIsPreparing = true;
		bHasReachedPlayer = false;
		CompleteTime = BIG_NUMBER;
		CompanionComp.Player.BlockCapabilitiesExcluding(DarkPortal::Tags::DarkPortal, DarkPortal::Tags::DarkPortalActiveDuringIntro, this);			
		Owner.AddActorVisualsBlock(this);
		Owner.AddActorCollisionBlock(this);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.BlockCapabilities(n"BlockedDuringIntro", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player can now control companion
		CompanionComp.Player.UnblockCapabilities(DarkPortal::Tags::DarkPortal, this);			
		if (bIsPreparing)
			StopPreparing();	

		Owner.UnblockCapabilities(n"BlockedDuringIntro", this);
		AnimComp.ClearFeature(this);
	}

	private void StopPreparing()
	{
		bIsPreparing = false;
		Owner.RemoveActorVisualsBlock(this);
		Owner.RemoveActorCollisionBlock(this);
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
	}
};