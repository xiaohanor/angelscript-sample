class UCenterViewHoldToCenterTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CapabilityTags::CenterView);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UCenterViewTutorialPlayerComponent TutorialComp;
	UCenterViewPlayerComponent CenterViewComp;

	bool bHasActivated = false;
	float StartCenterTime = -1;

	const float ResetDuration = 4;
	const float DisappearDelay = 0.5;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TutorialComp = UCenterViewTutorialPlayerComponent::Get(Player);
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CenterView::GetTargetMode() != ECenterViewTargetMode::HoldToCenter)
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
		if(CenterView::GetTargetMode() != ECenterViewTargetMode::HoldToCenter)
			return true;

		if(!TutorialComp.ShouldShowTutorial(true))
			return true;

		if(StartCenterTime > 0 && Time::GetRealTimeSince(StartCenterTime) > DisappearDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasActivated = true;
		StartCenterTime = -1;

		Player.ShowTutorialPrompt(TutorialComp.HoldToCenterTutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(StartCenterTime < 0 && Player.IsAnyCapabilityActive(CameraTags::CenterViewRotation))
			StartCenterTime = Time::RealTimeSeconds;
	}
};