class UGravityBikeFreeTutorialThrottleCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GravityBikeFreeTutorial");
	default CapabilityTags.Add(n"GravityBikeFreeTutorialThrottle");

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeTutorialUserComponent TutorialComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (IsActioning(ActionNames::Accelerate))
			return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (IsActioning(ActionNames::Accelerate))
			return true;

		return Super::ShouldDeactivate();;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TutorialComp = UGravityBikeFreeTutorialUserComponent::Get(Owner);
		DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);

		Player.ShowTutorialPromptWorldSpace(TutorialComp.PromptThrottle, this, Owner.RootComponent, TutorialComp.AttachOffset, TutorialComp.ScreenSpaceOffset);
//		Player.ShowTutorialPrompt(TutorialComp.PromptThrottle, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};