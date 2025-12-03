class USanctuaryCompanionAviationRidePlayerTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::AviationReady);
	default DebugCategory = AviationCapabilityTags::AviationReady;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UInfuseEssencePlayerComponent InfuseEssenceComp;
	bool bCompletedTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		InfuseEssenceComp = UInfuseEssencePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.bIsRideReady)
			return false;

		if (Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;

		if (AviationComp.GetIsAviationActive())
			return true;

		if (bCompletedTutorial)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(AviationComp.PromptRide, this);
		bCompletedTutorial = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!Player.IsPlayerDead())
			bCompletedTutorial = true;
		Player.RemoveTutorialPromptByInstigator(this);
	}
}