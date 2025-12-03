class UStoneBreakableHealthRegenCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"StoneBreakableRegen");

	default TickGroup = EHazeTickGroup::Gameplay;
	
	UStoneBreakableHealthRegenComponent RegenComp;
	UBasicAIHealthComponent AIHealthComp;
	UBasicAIHealthBarComponent HealthBarComp;
	AStoneBreakableActor StoneBreakable;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBreakable = Cast<AStoneBreakableActor>(Owner);
		RegenComp = UStoneBreakableHealthRegenComponent::Get(Owner);
		AIHealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// PrintToScreen(f"{AIHealthComp.GetHealthFraction()=}");
		float HealthFraction = AIHealthComp.GetHealthFraction();
		if (HealthFraction < 1.0)
		{
			AIHealthComp.SetCurrentHealth(AIHealthComp.CurrentHealth + (RegenComp.RegenRatePerSecond * DeltaTime));
			HealthBarComp.SnapBarToHealth();
			StoneBreakable.UpdateHealthVisual(HealthFraction);
		}
	}
};