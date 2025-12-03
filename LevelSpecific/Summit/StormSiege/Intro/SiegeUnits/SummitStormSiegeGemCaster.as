class ASummitStormSiegeGemCaster : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttackOrigin;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormSiegeGemCasterAttackCapability");

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeTargetableComponent TailTargetableComp;

	UPROPERTY()
	TSubclassOf<ASummitMagicTrajectoryProjectile> ProjectileClass;

	UPROPERTY()
	float AggressionRange = 40500.0;

	float WaitDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnSummitGemDestroyed.AddUFunction(this, n"OnGemDestroyed");
	}

	UFUNCTION()
	private void OnGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		TailTargetableComp.Disable(this);
	}

	void SpawnAttack(AHazeActor Target)
	{
		ASummitMagicTrajectoryProjectile Proj = SpawnActor(ProjectileClass, AttackOrigin.WorldLocation, bDeferredSpawn = true);
		Proj.IgnoreActors.Add(this);
		Proj.TargetLocation = Target.ActorLocation;
		Proj.Speed = 13000.0;
		Proj.Gravity = 10.0;
		FinishSpawningActor(Proj);	
	}

	TArray<AHazePlayerCharacter> GetAvailablePlayers()
	{
		TArray<AHazePlayerCharacter> AvailPlayers;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if ((Player.ActorLocation - ActorLocation).Size() < AggressionRange)
				AvailPlayers.Add(Player);
		}

		return AvailPlayers;
	}

	AHazePlayerCharacter GetClosestPlayer()
	{
		return GetDistanceTo(Game::Mio) < GetDistanceTo(Game::Zoe) ? Game::Mio : Game::Zoe;
	}
}