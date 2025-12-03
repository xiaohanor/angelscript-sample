class USanctuaryLightBirdShieldDarknessDamageCapability : UHazePlayerCapability
{
	//default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SanctuaryDarknessDamage");
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryLightBirdShieldUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsActive)
			return false;

	//	if (UserComp.DarknessAmount < 0.0 + SMALL_NUMBER)
	//		return false;
		if (!Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsActive)
			return true;

		if (UserComp.DarknessAmount < 0.0 + SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FadeOutFullscreen(this, FadeOutTime = 2.0);
		PlayerHealth::TriggerGameOver();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (UserComp.DarknessAmount >= 1.0)
	// 	{
	// 		Player.KillPlayer();
	// 		FadeOutFullscreen(this, FadeOutTime = 2.0);
	// 		PlayerHealth::TriggerGameOver();
	// 	}
	// }
};