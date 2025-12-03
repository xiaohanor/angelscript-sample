class UNightQueenConjurerAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NightQueenConjurerAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenGemConjurer GemConjurer;

	float SpawnDuration = 1.5;
	float SpawnTime;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GemConjurer = Cast<ANightQueenGemConjurer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if ((Game::Mio.ActorLocation - GemConjurer.ActorLocation).Size() > GemConjurer.DistanceActivation)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if ((Game::Mio.ActorLocation - GemConjurer.ActorLocation).Size() > GemConjurer.DistanceActivation)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnDuration;
			GemConjurer.SpawnSword();
		}
	}	
} 