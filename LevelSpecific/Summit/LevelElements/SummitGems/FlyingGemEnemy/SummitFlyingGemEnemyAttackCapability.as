class USummitFlyingGemEnemyAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SummitFlyingGemEnemyAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASummitFlyingGemEnemy Sieger;

	bool bSendToOppositePlayer;
	bool bIsAttacking;

	bool bSendToMio;
	float AttackTime;
	float AttackInterval = 6.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sieger = Cast<ASummitFlyingGemEnemy>(Owner);
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
		if (!Sieger.bProjectileAttacks)
			return;
		if (Time::GameTimeSeconds > AttackTime)
		{
			AHazePlayerCharacter Target = Game::Mio;
			Sieger.SpawnProjectile(Target);
			AttackTime = Time::GameTimeSeconds + AttackInterval;
		}
	}
}