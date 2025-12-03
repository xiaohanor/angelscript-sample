class UStoneDragonTestHomingMissilesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASerpentBossAttackPrototypeManager Manager;

	AHazePlayerCharacter TargetPlayer;

	float AttackRate = 6.0;
	float AttackTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<ASerpentBossAttackPrototypeManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Manager.bAttacksActive)
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
		TargetPlayer = Game::Zoe;
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
			FVector TargetLoc = (TargetPlayer.ActorLocation + Manager.ActorLocation) / 2;
			
			FVector Direction = (TargetPlayer.ActorLocation - Manager.ActorLocation).GetSafeNormal();
			TargetLoc = Manager.ActorLocation + Direction * 2000.0;
			Manager.SpawnHomingMissilesAttack(TargetLoc, TargetPlayer);
		}
	}
};