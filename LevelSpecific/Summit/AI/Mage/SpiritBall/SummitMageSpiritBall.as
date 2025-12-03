class ASummitMageSpiritBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SpiritBallSystem;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailComp;

	UPROPERTY(DefaultComponent)
	USummitMagePlateComponent PlateComp;

	float Speed = 2500.0;
	float LifeTime = 0.0;
	float LifeDuration = 6.0;

	bool bLanded;
	float DonutIntervalTime;

	TArray<AActor> IgnoreActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		IgnoreActors.Add(this);
		FSummitSpiritBallParams Params;
		Params.Location = ActorLocation;
		USummitSpiritBallEffectHandler::Trigger_MuzzleFlash(this, Params);

		LifeTime = Time::GetGameTimeSeconds();

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		TailComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		AddActorCollisionBlock(this);
		JoinTeam(n"SummitActiveSpiritBall");
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		// Take and release a token to trigger a cooldown
		UGentlemanComponent GentComp = UGentlemanComponent::GetOrCreate(Game::Zoe);
		USummitMageSettings Settings = USummitMageSettings::GetSettings(ProjectileComp.Launcher);
		GentComp.ClaimToken(SummitMageTags::SpiritBallToken, this, int(Settings.SpiritBallGentlemanCost));
		GentComp.ReleaseToken(SummitMageTags::SpiritBallToken, this, Settings.SpiritBallTokenCooldown);

		LeaveTeam(n"SummitActiveSpiritBall");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = FHitResult();
		Data.HitResult.Location = Params.HitLocation;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
		ProjectileComp.Expire();		
	}

	UFUNCTION()
	private void OnReset()
	{
		LifeTime = Time::GetGameTimeSeconds();
		bLanded = false;
		DonutIntervalTime = 0;
		AddActorCollisionBlock(this);
		JoinTeam(n"SummitActiveSpiritBall");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bLanded)
		{
			USummitMageSettings MageSettings =  USummitMageSettings::GetSettings(ProjectileComp.Launcher);
			if(Time::GetGameTimeSince(DonutIntervalTime) < MageSettings.SpiritBallDonutIntervalDuration)
				return;
			SpawnDonut();
			DonutIntervalTime = Time::GetGameTimeSeconds();
			return;
		}

		if (Time::GetGameTimeSince(LifeTime) > LifeDuration)
		{
			ProjectileComp.Expire();
		}

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaSeconds, Hit));
		if (Hit.bBlockingHit)
		{
			// PlayerHit(Hit);
			FSummitSpiritBallParams Params;
			Params.Location = ActorLocation;
			USummitSpiritBallEffectHandler::Trigger_Impact(this, Params);
			bLanded = true;
			DonutIntervalTime = Time::GetGameTimeSeconds();
			RemoveActorCollisionBlock(this);
		}

		SetActorRotation(ProjectileComp.Velocity.Rotation());
	}

	// void PlayerHit(FHitResult Hit)
	// {
	// 	AActor HitActor = Hit.Actor;
	// 	ATeenDragon Dragon = Cast<ATeenDragon>(Hit.Actor);
	// 	if(Dragon != nullptr)
	// 		HitActor = Dragon.Player;

	// 	auto DragonComp = UPlayerTailTeenDragonComponent::Get(HitActor);
	// 	if(DragonComp != nullptr && DragonComp.IsRolling())
	// 	{
	// 		FSummitSpiritBallParams Params;
	// 		Params.Location = ActorLocation;
	// 		USummitSpiritBallEffectHandler::Trigger_Shatter(this, Params);
	// 	}
	// 	else
	// 	{
	// 		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(HitActor);
	// 		if (PlayerHealthComp != nullptr)
	// 			PlayerHealthComp.DamagePlayer(0.2, nullptr, nullptr);
	// 	}
	// }

	void SpawnDonut()
	{
		USummitMageDonutComponent DonutComp = USummitMageDonutComponent::Get(ProjectileComp.Launcher);
		ASummitMageDonut Donut = SpawnActor(DonutComp.DonutClass, ActorLocation + ActorUpVector * 25, bDeferredSpawn = true);
		Donut.Owner = this;
		FinishSpawningActor(Donut);
	}
}