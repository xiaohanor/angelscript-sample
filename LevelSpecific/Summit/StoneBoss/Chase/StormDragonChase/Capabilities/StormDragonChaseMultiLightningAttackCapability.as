class UStormDragonChaseMultiLightningAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonChaseMultiLightningAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormDragonChase StormDragon;
	
	float FireRate = 0.08;
	float FireTime;

	int Index; 

	bool bShouldDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonChase>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StormDragon.bActivateLightningAttack)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bShouldDeactivate)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bShouldDeactivate = false;
		StormDragon.bActivateLightningAttack = false;
		Index = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;
			
			FStormSiegeLightningStrikeParams LightningParams;
			LightningParams.Start = StormDragon.Mesh.WorldLocation + FVector(0.0, 0.0, 1500.0);
			LightningParams.End = StormDragon.LightningPoints[Index].ActorLocation;
			FStormSiegeRockImpactParams RockParams;
			RockParams.Location = StormDragon.LightningPoints[Index].ActorLocation;
			RockParams.Direction = StormDragon.LightningPoints[Index].ActorForwardVector;

			UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(StormDragon, LightningParams);
			UStormSiegeLightningEffectsHandler::Trigger_RockImpact(StormDragon, RockParams);

			Index++;

			Game::Mio.PlayWorldCameraShake(StormDragon.LightningCameraShake, this, StormDragon.LightningPoints[Index].ActorLocation, 10000.0, 40000.0);
			Game::Zoe.PlayWorldCameraShake(StormDragon.LightningCameraShake, this, StormDragon.LightningPoints[Index].ActorLocation, 10000.0, 40000.0);

			if (Index >= StormDragon.LightningPoints.Num() - 1)
				bShouldDeactivate = true;
		}
	}
}