class UMagnetDroneTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UMagnetDroneTutorialComponent TutorialComp;
	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttractionComponent AttractionComp;

	USceneComponent TutorialAttachment;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TutorialComp = UMagnetDroneTutorialComponent::Get(Player);
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TutorialComp.ShouldShowTutorial())
			return false;

		if(!AttractAimComp.HasValidAimTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AttractionComp.IsAttracting())
			return true;

		if(!TutorialComp.ShouldShowTutorial())
			return true;

		if(!AttractAimComp.HasValidAimTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TutorialAttachment = USceneComponent::Create(Player);
		TutorialAttachment.SetAbsolute(true, true, true);

		Player.ShowTutorialPromptWorldSpace(
			TutorialComp.TutorialPrompt,
			this,
			TutorialAttachment,
			FVector::ZeroVector
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		TutorialAttachment.DestroyComponent(Player);
		TutorialAttachment = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!AttractAimComp.HasValidAimTarget())
			return;
		
		TutorialAttachment.SetWorldLocation(AttractAimComp.AimData.GetTargetLocation());
	}
};