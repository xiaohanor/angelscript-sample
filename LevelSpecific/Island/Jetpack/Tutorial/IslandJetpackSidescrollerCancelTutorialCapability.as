class UIslandJetpackSidescrollerCancelTutorialCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandJetpackComponent JetpackComp;
	UIslandJetpackSettings Settings;

	USceneComponent TutorialAttachRoot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		Settings = UIslandJetpackSettings::GetSettings(Player);

		TutorialAttachRoot = USceneComponent::Create(Player);
		TutorialAttachRoot.bAbsoluteRotation = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		TutorialAttachRoot.DestroyComponent(TutorialAttachRoot);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsOverlappingTutorialVolume())
			return false;

		if(JetpackComp == nullptr)
			return false;

		if(!JetpackComp.bThrusterIsOn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsOverlappingTutorialVolume())
			return true;

		if(JetpackComp == nullptr)
			return true;

		if(!JetpackComp.bThrusterIsOn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPromptWorldSpace(Settings.CancelPrompt, this, AttachComponent = TutorialAttachRoot, AttachOffset = Settings.CancelPromptOffset);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(JetpackComp == nullptr)
			JetpackComp = UIslandJetpackComponent::Get(Player);
	}
};