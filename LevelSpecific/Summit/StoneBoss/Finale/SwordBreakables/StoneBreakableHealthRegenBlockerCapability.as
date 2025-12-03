class UStoneBreakableHealthRegenBlockerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UStoneBreakableHealthRegenComponent RegenComp;
	UBasicAIHealthComponent AIHealthComp;
	UBasicAIHealthBarComponent HealthBarComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RegenComp = UStoneBreakableHealthRegenComponent::Get(Owner);
		AIHealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RegenComp.IsRegenEnabled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RegenComp.IsRegenEnabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!Owner.IsCapabilityTagBlocked(n"StoneBreakableRegen"))
		{
			Owner.BlockCapabilities(n"StoneBreakableRegen", this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Owner.IsCapabilityTagBlocked(n"StoneBreakableRegen"))
		{
			Owner.UnblockCapabilities(n"StoneBreakableRegen", this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > RegenComp.RegenDisableDuration)
			RegenComp.EnableRegen();
	}
};