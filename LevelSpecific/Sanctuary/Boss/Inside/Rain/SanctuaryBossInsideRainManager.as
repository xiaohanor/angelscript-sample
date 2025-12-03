class ASanctuaryBossInsideRainManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossInsideRainProjectile> ProjectileClass;

	UPROPERTY()
	int ProjectileAmount = 3;

	UPROPERTY()
	float ProjectileDelay = 0.2;

	UPROPERTY()
	float ProjectileWaveMinDelay = 4.0;

	UPROPERTY()
	float ProjectileWaveMaxDelay = 8.0;

	bool bIsZoeRainActive = false;
	bool bIsMioRainActive = false;

	int SpawnedZoeProjectiles = 0;
	int SpawnedMioProjectiles = 0;


	UFUNCTION()
	void Activate(AHazePlayerCharacter Player)
	{
		if (Player == Game::Mio && !bIsMioRainActive)
		{
			bIsMioRainActive = true;
			Timer::SetTimer(this, n"SpawnProjectileMio", Math::RandRange(0.0, 5.0));
		}

		if (Player == Game::Zoe && !bIsZoeRainActive)
		{
			bIsZoeRainActive = true;
			Timer::SetTimer(this, n"SpawnProjectileZoe", Math::RandRange(0.0, 5.0));
		}
	}

	UFUNCTION()
	void Deactivate(AHazePlayerCharacter Player)
	{
		if (Player == Game::Mio && bIsMioRainActive)
		{
			bIsMioRainActive = false;
			Timer::ClearTimer(this, n"SpawnProjectileMio");
		}

		if (Player == Game::Zoe && bIsZoeRainActive)
		{
			bIsZoeRainActive = false;
			Timer::ClearTimer(this, n"SpawnProjectileZoe");
		}
	}

	UFUNCTION()
	private void SpawnProjectileZoe()
	{
		AHazePlayerCharacter Player = Game::Zoe;

		//Find impact location
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		Trace.IgnorePlayers();

		auto HitResult = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - Player.ActorUpVector * 2000.0);

		FVector SpawnLocation;

		if (HitResult.bBlockingHit)
			SpawnLocation = HitResult.ImpactPoint;

		else 
			SpawnLocation = Player.ActorLocation;
		

		auto SpawnedProjectile = SpawnActor(ProjectileClass, SpawnLocation, Player.ActorRotation);

		SpawnedProjectile.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		
		SpawnedZoeProjectiles++;

		if (bIsZoeRainActive)
		{
			if (SpawnedZoeProjectiles < ProjectileAmount)
				Timer::SetTimer(this, n"SpawnProjectileZoe", ProjectileDelay);
			else
			{
				SpawnedZoeProjectiles = 0;
				Timer::SetTimer(this, n"SpawnProjectileZoe", Math::RandRange(ProjectileWaveMinDelay, ProjectileWaveMaxDelay));
			}	
		}	
	}

	UFUNCTION()
	private void SpawnProjectileMio()
	{
		AHazePlayerCharacter Player = Game::Mio;

		//Find impact location
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		Trace.IgnorePlayers();

		auto HitResult = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - Player.ActorUpVector * 2000.0);

		FVector SpawnLocation;

		if (HitResult.bBlockingHit)
			SpawnLocation = HitResult.ImpactPoint;

		else 
			SpawnLocation = Player.ActorLocation;
		

		auto SpawnedProjectile = SpawnActor(ProjectileClass, SpawnLocation, Player.ActorRotation);

		SpawnedProjectile.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		
		SpawnedMioProjectiles++;

		if (bIsMioRainActive)
		{
			if (SpawnedMioProjectiles < ProjectileAmount)
				Timer::SetTimer(this, n"SpawnProjectileMio", ProjectileDelay);
			else
			{
				SpawnedMioProjectiles = 0;
				Timer::SetTimer(this, n"SpawnProjectileMio", Math::RandRange(ProjectileWaveMinDelay, ProjectileWaveMaxDelay));
			}	
		}	
	}
};