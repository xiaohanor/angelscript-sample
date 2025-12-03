class UIslandWalkerHeadHatchDamageCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Damage");
	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandWalkerHeadHatchHealthBarComponent HealthBar;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerPhaseComponent WalkerPhaseComp;
	UIslandWalkerHeadHatchDetachedComponent DetachedHatch;
	TArray<UIslandWalkerHeadHatchInteractionComponent> Interactions;
	AIslandWalkerHeadStumpTarget Stump;
	UIslandWalkerSettings Settings;
	bool bWasDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		// Add component to walker head if you want health bar for hatch
		HealthBar = UIslandWalkerHeadHatchHealthBarComponent::Get(Owner);
		if (HealthBar != nullptr)
			HealthBar.Hide(this);

		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		DetachedHatch = UIslandWalkerHeadHatchDetachedComponent::Get(Owner);
		Owner.GetComponentsByClass(Interactions);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
		Stump.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
	}

	UFUNCTION()
	private void OnTakeDamage(AHazePlayerCharacter Shooter, float RemainingHealth)
	{
		if (!IsActive())
			return;

		if (RemainingHealth < SMALL_NUMBER)
		{
			HeadComp.HatchIntegrity = 0.0;
			if (!bWasDestroyed)
			{
				// Trigger exposion but keep hatch so player have something to hold on to
				UIslandWalkerHeadEffectHandler::Trigger_OnDestroyHatch(Owner, FIslandWalkerDestroyHatchParams(DetachedHatch));
			}
			bWasDestroyed = true;
		}
		else
		{
			HeadComp.HatchIntegrity = RemainingHealth / Settings.HeadCrashHealthThreshold;
		}

		if (HealthBar != nullptr)
			HealthBar.ModifyHealth(HeadComp.HatchIntegrity);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		for (UIslandWalkerHeadHatchInteractionComponent Interaction : Interactions)
		{	
			if ((Interaction.State != EWalkerHeadHatchInteractionState::Open) &&
				(Interaction.State != EWalkerHeadHatchInteractionState::Shooting))
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		for (UIslandWalkerHeadHatchInteractionComponent Interaction : Interactions)
		{	
			if ((Interaction.State != EWalkerHeadHatchInteractionState::Open) &&
				(Interaction.State != EWalkerHeadHatchInteractionState::Shooting))
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkerPhaseComp = UIslandWalkerPhaseComponent::Get(HeadComp.NeckCableOrigin.Owner);

		if (HealthBar != nullptr)
			HealthBar.Show(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HealthBar != nullptr)
			HealthBar.Hide(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HealthBar != nullptr)
			HealthBar.Update(DeltaTime);
	}
};