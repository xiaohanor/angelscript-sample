class USkylineBallBossAttackSlidingCarAppearCapability : USkylineBallBossChildCapability
{
	ESkylineBallBossAttacker Attacker;

	USkylineBallBossAttackSlidingCarAppearCapability(ESkylineBallBossAttacker AttackerEnum)
	{
		Attacker = AttackerEnum;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
		if (BallBoss.Attackers.Contains(Attacker))
		{
			auto SlidingCar =  Cast<ASkylineBallBossSlidingCar>(BallBoss.Attackers[Attacker]);

			if (SlidingCar != nullptr)
				SlidingCar.Appear();
		}
	}
}