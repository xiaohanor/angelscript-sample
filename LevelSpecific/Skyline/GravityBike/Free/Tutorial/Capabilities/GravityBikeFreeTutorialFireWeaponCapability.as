class UGravityBikeFreeTutorialFireWeaponCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GravityBikeFreeTutorial");
	default CapabilityTags.Add(n"GravityBikeFreeTutorialFireWeapon");

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeTutorialUserComponent TutorialComp;
	UGravityBikeWeaponUserComponent WeaponUserComp;

	bool bUsingGamepad;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto CheckWeaponUserComp = UGravityBikeWeaponUserComponent::Get(Owner);
		if (CheckWeaponUserComp == nullptr)
			return false;

		if (!CheckWeaponUserComp.HasChargeForEquippedWeapon())
			return false;

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
		bUsingGamepad = Player.IsUsingGamepad();

		TutorialComp = UGravityBikeFreeTutorialUserComponent::Get(Owner);
		DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);
		WeaponUserComp = UGravityBikeWeaponUserComponent::Get(Owner);

		if (Player.IsUsingGamepad())
			TutorialComp.PromptFireWeapon.Action = ActionNames::SecondaryLevelAbility;
		else
			TutorialComp.PromptFireWeapon.Action = ActionNames::PrimaryLevelAbility;

		Player.ShowTutorialPromptWorldSpace(TutorialComp.PromptFireWeapon, this, Owner.RootComponent, TutorialComp.AttachOffset, TutorialComp.ScreenSpaceOffset);
//		Player.ShowTutorialPrompt(TutorialComp.PromptFireWeapon, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bUsingGamepad != Player.IsUsingGamepad())
		{
			if (Player.IsUsingGamepad())
				TutorialComp.PromptFireWeapon.Action = ActionNames::SecondaryLevelAbility;
			else
				TutorialComp.PromptFireWeapon.Action = ActionNames::PrimaryLevelAbility;

			Player.RemoveTutorialPromptByInstigator(this);
			Player.ShowTutorialPromptWorldSpace(TutorialComp.PromptFireWeapon, this, Owner.RootComponent, TutorialComp.AttachOffset, TutorialComp.ScreenSpaceOffset);

			bUsingGamepad = Player.IsUsingGamepad();
		}
	}
};