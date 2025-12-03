class UStoneDragonTestProximitySpellCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASerpentBossAttackPrototypeManager Manager;

	AHazePlayerCharacter TargetPlayer;

	float AttackRate = 6.0;
	float OffsetTime = 3.0;
	float AttackTime;

	float CanActivateTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<ASerpentBossAttackPrototypeManager>(Owner);
		CanActivateTimer = Time::GameTimeSeconds + OffsetTime;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Manager.bAttacksActive)
			return false;


		if (Time::GameTimeSeconds < CanActivateTimer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Manager.bAttacksActive)
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
		if (Time::GameTimeSeconds > AttackTime)
		{
			AttackTime = Time::GameTimeSeconds + AttackRate;
			TargetPlayer = TargetPlayer.OtherPlayer;
			Manager.SpawnProximitySpell(TargetPlayer.ActorLocation);
		}
	}
};