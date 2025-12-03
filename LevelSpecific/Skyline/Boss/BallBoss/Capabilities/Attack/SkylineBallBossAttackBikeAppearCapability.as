class USkylineBallBossAttackBikeAppearCapability : USkylineBallBossChildCapability
{
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
		for (auto KeyVal : BallBoss.Attackers)
		{
			ASkylineBallBossMotorcycle Bike = Cast<ASkylineBallBossMotorcycle>(KeyVal.Value);
			if (Bike != nullptr)
				Bike.Appear();
		}
	}
}