class UGravityBikeFreeTutorialJumpCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GravityBikeFreeTutorial");
	default CapabilityTags.Add(n"GravityBikeFreeTutorialJump");

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeTutorialUserComponent TutorialComp;
	UGravityBikeFreeJumpComponent JumpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Super::ShouldDeactivate();;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TutorialComp = UGravityBikeFreeTutorialUserComponent::Get(Owner);
		DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);

		JumpComp = UGravityBikeFreeJumpComponent::Get(DriverComp.GetGravityBike());

		Player.ShowTutorialPromptWorldSpace(TutorialComp.PromptJump, this, Owner.RootComponent, TutorialComp.AttachOffset, TutorialComp.ScreenSpaceOffset);
//		Player.ShowTutorialPrompt(TutorialComp.PromptJump, this);
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