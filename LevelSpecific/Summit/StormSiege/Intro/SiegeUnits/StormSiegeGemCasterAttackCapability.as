class UStormSiegeGemCasterAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormSiegeGemCasterAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASummitStormSiegeGemCaster SiegeGemCaster;

	float AttackTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SiegeGemCaster = Cast<ASummitStormSiegeGemCaster>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SiegeGemCaster.GetAvailablePlayers().Num() == 0)
			return false;

		if (Time::GameTimeSeconds < AttackTime)
			return false;

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
		AttackTime = Time::GameTimeSeconds + SiegeGemCaster.WaitDuration;

		if (SiegeGemCaster.GetAvailablePlayers().Num() < 2)
			SiegeGemCaster.SpawnAttack(SiegeGemCaster.GetAvailablePlayers()[0]);
		else
			SiegeGemCaster.SpawnAttack(SiegeGemCaster.GetClosestPlayer());
	}
}