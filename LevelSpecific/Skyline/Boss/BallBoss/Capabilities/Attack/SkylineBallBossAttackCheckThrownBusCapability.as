class USkylineBallBossAttackCheckThrownBusCapability : USkylineBallBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BallBoss.bHasThrownBus;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}
}