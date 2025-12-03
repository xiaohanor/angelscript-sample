class USanctuaryLavamoleShowHealthbarCapability : UHazeCapability
{
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default TickGroup = EHazeTickGroup::Gameplay;
	AAISanctuaryLavamole Lavamole;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		Lavamole.HealthBar.SetPlayerVisibility(EHazeSelectPlayer::None);
		// Lavamole.HealthComp.TakeDamage(KINDA_SMALL_NUMBER, EDamageType::Default, Lavamole);
		// SanctuaryCentipedeDevToggles::WhackaMoles.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SanctuaryCentipedeDevToggles::Mole::TearCoopMoles.IsEnabled())
			return false;
		if (Lavamole.bIsUnderground)
			return false;
		if (Lavamole.HealthComp.GetCurrentHealth() > Lavamole.HealthComp.MaxHealth - KINDA_SMALL_NUMBER)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Lavamole.bIsUnderground)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Lavamole.HealthBar.SetPlayerVisibility(EHazeSelectPlayer::Both);
		Lavamole.HealthBar.SnapBarToHealth();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Lavamole.HealthBar.SetPlayerVisibility(EHazeSelectPlayer::None);
	}
};