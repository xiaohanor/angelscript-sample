class USolarFlareTriggerShieldEnergyRecoveryCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USolarFlareTriggerShieldEnergyWidget Widget;
	USolarFlareTriggerShieldComponent UserComp;
	UPlayerHealthComponent HealthComp;

	float RecoveryAmount = 0.27;

	bool bRanOut;
	bool bStartedNewAction;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USolarFlareTriggerShieldComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnFinishDying.AddUFunction(this, n"OnFinishDying");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bHasTriggerShield)
			return false;

		if (IsActioning(ActionNames::PrimaryLevelAbility) && !UserComp.bEnergyWasDepleted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bHasTriggerShield)
			return true;
		
		if (IsActioning(ActionNames::PrimaryLevelAbility) && !UserComp.bEnergyWasDepleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// if (!UserComp.bEnergyWasDepleted)
		// 	UserComp.AddPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// UserComp.RemovePrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UserComp.AlterShieldEnergy(RecoveryAmount * DeltaTime);

		if (UserComp.GetShieldEnergy() >= 1 && UserComp.bEnergyWasDepleted)
		{
			// UserComp.AddPrompt(Player);
			UserComp.SetNotDepleted();
		}
	}

	//Keep in mind that this calls even when trigger shield is not active - best to move into a sheet later and start/stop when applicable
	UFUNCTION()
	private void OnFinishDying()
	{
		UserComp.SetShieldEnergy(1.0);
	}
};