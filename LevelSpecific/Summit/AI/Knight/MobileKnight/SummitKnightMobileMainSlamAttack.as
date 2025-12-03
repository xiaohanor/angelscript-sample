class USummitKnightMobileMainSlamAttackBehaviour : USummitKnightMobileStartSlamAttackBehaviour
{
	USummitKnightMobileMainSlamAttackBehaviour(bool bSummonObstacles)
	{
		bSpawnObstacles = bSummonObstacles;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthThreshold = Settings.HealthThresholdMainSlam;
	}

	int GetNumObstaclesToSpawn() const override
	{
		return Settings.MainSlamNumObstacles;		
	}

}

