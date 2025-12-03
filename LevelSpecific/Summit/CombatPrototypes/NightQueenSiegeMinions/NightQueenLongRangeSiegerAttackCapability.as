class UNightQueenLongRangeSiegerAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NightQueenLongRangeSiegerAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenLongRangeSieger Sieger;

	bool bSendToOppositePlayer;
	bool bIsAttacking;

	int AttackCount;
	int MaxAttackCount = 5;

	bool bSendToMio;
	float AttackTime;
	float AttackInterval = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sieger = Cast<ANightQueenLongRangeSieger>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Sieger.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Sieger.bIsActive)
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
		if (Time::GameTimeSeconds > AttackTime)
		{
			AHazePlayerCharacter Target = bSendToMio ? Game::Mio : Game::Zoe;
			Sieger.SpawnProjectile(Target);
			bSendToMio = !bSendToMio;
			AttackTime = Time::GameTimeSeconds + AttackInterval;
		}
	}
}