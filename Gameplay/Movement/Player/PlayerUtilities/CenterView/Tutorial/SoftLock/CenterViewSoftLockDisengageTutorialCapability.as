class UCenterViewSoftLockDisengageTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CapabilityTags::CenterView);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 110;

	UCenterViewTutorialPlayerComponent TutorialComp;
	UCenterViewPlayerComponent CenterViewComp;

	bool bShowingTutorial = false;

	const float ShowTutorialDelay = 0.5;

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

		if(!CenterView::bShowSoftLockDisengageTutorial)
			return false;

		if(!Player.IsAnyCapabilityActive(CameraTags::CenterViewTarget))
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

		if(!CenterView::bShowSoftLockDisengageTutorial)
			return true;

		if(!Player.IsAnyCapabilityActive(CameraTags::CenterViewTarget))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bShowingTutorial)
			Player.RemoveTutorialPromptByInstigator(this);

		bShowingTutorial = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bShowingTutorial && ActiveDuration > ShowTutorialDelay)
		{
			Player.ShowTutorialPrompt(TutorialComp.SoftLockDisengageTutorialPrompt, this);
			bShowingTutorial = true;
		}
	}
};