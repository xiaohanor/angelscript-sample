
class UPlayerDeathCapability : UHazePlayerCapability
{
	// Note: Does not have 'Death' tag. We don't want to interrupt death, just prevent it.
	// See UPlayerHealthComponent::CanDie()

	default DebugCategory = n"PlayerHealth";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 101;

	UPlayerHealthSettings HealthSettings;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HealthComp.bIsDead)
			return false;
		if (HealthComp.bHasFinishedDying)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HealthComp.bIsDead)
			return true;
		if (HealthComp.bHasFinishedDying)
			return true;
		if (ActiveDuration > HealthComp.DeathEffectDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDeathEffect::Trigger_Died(Player);
		UPlayerDamageEffectHandler::Trigger_PlayerDied(Player, HealthComp.DeathImpactData);
		HealthComp.StartDying();

		// Print(f"{HealthComp.DeathImpactData.ForceScale=}");
		// Print(f"{HealthComp.DeathImpactData.ImpactLocation=}");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HealthComp.FinishDying();
		UDeathEffect::Trigger_FinishedDying(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};