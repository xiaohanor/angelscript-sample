class UGravityBikeWeaponNoChargePromptCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityBikeWeaponNoChargePrompt");

	UGravityBikeWeaponUserComponent WeaponComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WeaponComp.HasEquipWeapon())
			return false;

		if (WeaponComp.HasChargeForEquippedWeapon())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WeaponComp.HasEquipWeapon())
			return true;

		if (WeaponComp.HasChargeForEquippedWeapon())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt Prompt;
		Prompt.DisplayType = ETutorialPromptDisplay::TextOnly;
		Prompt.Text = WeaponComp.NoChargePromptText;
		Player.ShowTutorialPrompt(Prompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		if (WeaponComp.HasEquipWeapon() && WeaponComp.HasChargeForEquippedWeapon())
		{
			FTutorialPrompt Prompt;
			Prompt.DisplayType = ETutorialPromptDisplay::Action;
			Prompt.Action = ActionNames::SecondaryLevelAbility;
			Prompt.Text = WeaponComp.FirePromptText;
			Prompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
			Player.ShowTutorialPrompt(Prompt, this);
		}
	}
}