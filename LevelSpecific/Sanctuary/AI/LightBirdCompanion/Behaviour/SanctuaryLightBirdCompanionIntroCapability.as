class USanctuaryLightBirdCompanionIntroCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"Companion");
	default CapabilityTags.Add(n"Intro");
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryLightBirdCompanionComponent CompanionComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryLightBirdCompanionSettings Settings;
	bool bIsPreparing = false;
	bool bHasReachedPlayer = false;
	float CompleteTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Settings = USanctuaryLightBirdCompanionSettings::GetSettings(Owner);
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
		CompanionComp.Player.BlockCapabilitiesExcluding(LightBird::Tags::LightBird, LightBird::Tags::LightBirdActiveDuringIntro, this);			
		Owner.AddActorVisualsBlock(this);
		Owner.AddActorCollisionBlock(this);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.BlockCapabilities(n"BlockedDuringIntro", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player can now control companion
		CompanionComp.Player.UnblockCapabilities(LightBird::Tags::LightBird, this);			
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