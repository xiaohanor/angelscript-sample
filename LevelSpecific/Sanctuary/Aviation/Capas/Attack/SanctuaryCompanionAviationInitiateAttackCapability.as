class USanctuaryCompanionAviationInitiateAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	bool bWillAttackTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		AviationDevToggles::Phase1::Phase1AutoInitateAttack.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return false;

		if (AviationComp.AviationState != EAviationState::InitAttack)
			return false;

		if (!CompanionAviation::bRequireInitiateAttackPrompt)
			return false;

		if (!IsActioning(AviationComp.PromptInitiateAttack.Action) && !AviationDevToggles::Phase1::Phase1AutoInitateAttack.IsEnabled())
			return false;

		if (!AviationComp.HasDestination())
			return false;

		if (AviationComp.bHasInitiatedAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AviationComp.bCanInitiatingAttackingTarget = false;
		AviationComp.bHasInitiatedAttack = true;
	}
};

