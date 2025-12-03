class UStormDragonIntroMagicAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonIntroMagicAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormDragonIntro StormDragon;

	float AttackRate = 1.0;
	float WaitDuration = 1.5;
	int MaxAttackCount = 3;

	int AttackCount;
	float AttackTime;
	float WaitTime;

	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonIntro>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Time::GameTimeSeconds < StormDragon.DelayTime)
			return false;

		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > WaitTime)
		{
			if (Time::GameTimeSeconds > AttackTime)
			{
				AttackTime = Time::GameTimeSeconds + AttackRate;
				AttackCount++;
				StormDragon.SpawnMagicAttack(TargetPlayer);
			}

			if (AttackCount > MaxAttackCount)
			{
				WaitTime = Time::GameTimeSeconds + WaitDuration;
				AttackCount = 0;
				TargetPlayer = TargetPlayer.OtherPlayer;
			}
		}
	}	
}