class UCenterViewHardLockDisengageTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CapabilityTags::CenterView);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 110;

	UCenterViewTutorialPlayerComponent TutorialComp;
	UCenterViewPlayerComponent CenterViewComp;

	bool bShowingTutorial = false;

	const float ShowTutorialDelay = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TutorialComp = UCenterViewTutorialPlayerComponent::Get(Player);
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CenterView::GetTargetMode() != ECenterViewTargetMode::HardLock)
			return false;

		if(!TutorialComp.ShouldShowTutorial(!CenterView::bAlwaysShowHardLockTutorial))
			return false;

		if(!Player.IsAnyCapabilityActive(CameraTags::CenterViewTarget))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CenterView::GetTargetMode() != ECenterViewTargetMode::HardLock)
			return true;

		if(!TutorialComp.ShouldShowTutorial(!CenterView::bAlwaysShowHardLockTutorial))
			return true;

		if(!Player.IsAnyCapabilityActive(CameraTags::CenterViewTarget))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
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
			Player.ShowTutorialPrompt(TutorialComp.HardLockDisengageTutorialPrompt, this);
			bShowingTutorial = true;
		}
	}
};