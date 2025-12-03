class USanctuaryCompanionAviationAttackTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default DebugCategory = AviationCapabilityTags::Aviation;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (AviationComp.AviationState != EAviationState::Attacking)
			return false;

		if (DeactiveDuration < 10.0)
			return false;
		
		return false; // We don't use this anymore
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;

		if (AviationComp.AviationState != EAviationState::Attacking)
			return true;
		
		if (AviationComp.bIsAttackTutorialComplete && ActiveDuration > 3.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(AviationComp.PromptAttack, this);
		AviationComp.bIsAttackTutorialComplete = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(ActionNames::PrimaryLevelAbility))
			AviationComp.bIsAttackTutorialComplete = true;
	}
}