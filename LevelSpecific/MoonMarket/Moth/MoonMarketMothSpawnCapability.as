class UMoonMarketMothSpawnCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketMoth Moth;

	float SpawnTime;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Moth = Cast<AMoonMarketMoth>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Moth.bHasSpawned)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Time::GameTimeSeconds > SpawnTime)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketMothEventHandler::Trigger_OnMothStartAppearing(Moth);
		SpawnTime = Time::GameTimeSeconds + 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMoonMarketMothEventHandler::Trigger_OnMothStopAppearing(Moth);
		Moth.FinishSpawning();
	}
};