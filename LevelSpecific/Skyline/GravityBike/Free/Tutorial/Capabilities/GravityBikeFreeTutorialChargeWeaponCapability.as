class UGravityBikeFreeTutorialChargeWeaponCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GravityBikeFreeTutorial");
	default CapabilityTags.Add(n"GravityBikeFreeTutorialChargeWeapon");

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeTutorialUserComponent TutorialComp;
	UGravityBikeWeaponUserComponent WeaponUserComp;

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

		WeaponUserComp = UGravityBikeWeaponUserComponent::Get(Owner);

		Player.ShowTutorialPromptWorldSpace(TutorialComp.PromptChargeWeapon, this, Owner.RootComponent, TutorialComp.AttachOffset, TutorialComp.ScreenSpaceOffset);
//		Player.ShowTutorialPrompt(TutorialComp.PromptChargeWeapon, this);
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