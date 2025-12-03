class UCenterViewSoftLockTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CapabilityTags::CenterView);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UCenterViewTutorialPlayerComponent TutorialComp;
	UCenterViewPlayerComponent CenterViewComp;

	bool bHasActivated = false;

	const float ResetDuration = 4;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TutorialComp = UCenterViewTutorialPlayerComponent::Get(Player);
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CenterView::GetTargetMode() != ECenterViewTargetMode::SoftLock)
			return false;

		if(!TutorialComp.ShouldShowTutorial(true))
			return false;

		if(bHasActivated && DeactiveDuration < ResetDuration)
			return false;

		if(Player.IsAnyCapabilityActive(CameraTags::CenterViewRotation))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CenterView::GetTargetMode() != ECenterViewTargetMode::SoftLock)
			return true;

		if(!TutorialComp.ShouldShowTutorial(true))
			return true;

		if(Player.IsAnyCapabilityActive(CameraTags::CenterViewRotation))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasActivated = true;

		Player.ShowTutorialPrompt(TutorialComp.SoftLockTutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
};