UCLASS(Abstract)
class APrisonBossWaveSlashActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WaveRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bLaunched = false;
	FVector ForwardDirection;

	float CurrentLifeTime = 0.0;
	float MaxLifeTime = 5.0;

	bool bDamagedZoe = false;
	bool bDamagedMio = false;

	/*Relevant for audio interests */
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp; 

	UPROPERTY(DefaultComponent)	
	UAICharacterAudioCrowdControlComponent CrowdControlComp;	

	void LaunchWave(FVector Dir, float Height)
	{
		bDamagedMio = false;
		bDamagedZoe = false;

		CurrentLifeTime = 0.0;

		ForwardDirection = Dir;
		bLaunched = true;

		SetActorTickEnabled(true);

		UPrisonBossWaveSlashEffectEventHandler::Trigger_Launch(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bLaunched)
			return;

		FVector DeltaMove = ForwardDirection * PrisonBoss::WaveSlashProjectileMoveSpeed * DeltaTime;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseBoxShape(FVector(20.0, 20.0, 275.0), ActorQuat);

		FHitResultArray HitResults;
		HitResults = Trace.QueryTraceMulti(ActorLocation, ActorLocation + DeltaMove);

		for (FHitResult Hit : HitResults.BlockHits)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if (Player != nullptr)
			{
				if (Player.IsMio() && !bDamagedMio)
				{
					DamagePlayer(Player);
					bDamagedMio = true;
				}
				if (Player.IsZoe() && !bDamagedZoe)
				{
					DamagePlayer(Player);
					bDamagedZoe = true;
				}
			}
		}

		FVector Loc = ActorLocation + DeltaMove;
		SetActorLocation(Loc);

		AddActorLocalRotation(FRotator(0.0 * DeltaTime, 0.0, PrisonBoss::WaveSlashProjectileRotationSpeed * DeltaTime));

		CurrentLifeTime += DeltaTime;
		if (CurrentLifeTime >= MaxLifeTime)
			Destroy();
	}

	void DamagePlayer(AHazePlayerCharacter Player)
	{
		Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(ActorForwardVector, 2.0), DamageEffect, DeathEffect);
	}

	void Destroy()
	{
		bLaunched = false;
		UPrisonBossWaveSlashEffectEventHandler::Trigger_Dissipate(this);
		DestroyActor();
	}
}