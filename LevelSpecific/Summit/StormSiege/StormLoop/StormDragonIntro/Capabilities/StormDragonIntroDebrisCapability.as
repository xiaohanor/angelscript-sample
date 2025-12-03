class UStormDragonIntroDebrisCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonIntroDebrisCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormDragonIntro StormDragon;

	int AttackCount;
	TArray<int> PreviousAttackedPoints;
	float AttackTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonIntro>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return false;

		if (!StormDragon.bRunDebrisAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return true;

		if (!StormDragon.bRunDebrisAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousAttackedPoints.Empty();
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
			AttackTime = Time::GameTimeSeconds + StormDragonIntroAttackSettings::DebrisSpawnRate;
			
			int Index = Math::RandRange(0, StormDragon.DebrisPoints.Num() - 1);

			while (PreviousAttackedPoints.Contains(Index))
			{
				Index = Math::RandRange(0, StormDragon.DebrisPoints.Num() - 1);
			}

			StormDragon.SpawnDebris(Index);
			AttackCount++;

			if (AttackCount >= StormDragon.MaxDebrisAttackCount)
				StormDragon.bRunDebrisAttack = false;
		}
	}
}
