
class UPlayerHealthRegenerationCapability : UHazePlayerCapability
{
	default DebugCategory = n"PlayerHealth";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerHealthComponent HealthComp;
	UPlayerHealthSettings HealthSettings;

	float GameTimeLastRegeneration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HealthComp.bIsDead)
			return false;

		if (Math::IsNearlyEqual(HealthComp.Health.CurrentHealth, 1.0))
			return false;

		// During cutscenes we regenerate without waiting for the timer
		if (!Player.bIsControlledByCutscene)
		{
			if (!HealthSettings.bRegenerateHealth)
				return false;

			if (Player.IsCapabilityTagBlocked(n"HealthRegeneration"))
				return false;

			if (Time::GetGameTimeSince(HealthComp.Health.GameTimeAtMostRecentDamage) < HealthSettings.RegenerationDelay)
				return false;

			if (Time::GetGameTimeSince(HealthComp.Health.GameTimeAtMostRecentHeal) < HealthSettings.RegenerationDelay)
				return false;

			if (Time::GetGameTimeSince(GameTimeLastRegeneration) < HealthSettings.RegenerationDelay)
				return false;
		}

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GameTimeLastRegeneration = Time::GetGameTimeSeconds();
		HealthComp.Health.Regenerate();
		HealthComp.BroadcastHealthUpdated();

		UPlayerDamageEffectHandler::Trigger_HealthRegenerated(Player);
	}
};