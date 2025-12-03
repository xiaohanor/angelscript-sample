class USanctuaryCompanionAviationInitiateAttackTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default DebugCategory = AviationCapabilityTags::Aviation;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		AviationComp.OnAviationStopped.AddUFunction(this, n"ResetTutorial");
	}

	UFUNCTION()
	private void ResetTutorial(AHazePlayerCharacter AviationPlayer)
	{
		AviationComp.bIsInitiateAttackTutorialComplete = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!AviationComp.bCanInitiatingAttackingTarget)
			return false;

		if (!CompanionAviation::bRequireInitiateAttackPrompt)
			return false;

		if (AviationComp.bIsInitiateAttackTutorialComplete)
			return false;

		if (DeactiveDuration < AviationComp.Settings.InitiateAttackWindowDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!AviationComp.bCanInitiatingAttackingTarget)
			return true;

		if (AviationComp.bIsInitiateAttackTutorialComplete)
			return true;

		if (ActiveDuration > AviationComp.Settings.InitiateAttacTutorialWidgetDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AviationComp.bIsInitiateAttackTutorialComplete = false;
		Player.ShowTutorialPrompt(AviationComp.PromptInitiateAttack, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AviationComp.bIsInitiateAttackTutorialComplete = true;
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AviationComp.AviationState == EAviationState::Attacking)
			AviationComp.bIsInitiateAttackTutorialComplete = true;
	}
}