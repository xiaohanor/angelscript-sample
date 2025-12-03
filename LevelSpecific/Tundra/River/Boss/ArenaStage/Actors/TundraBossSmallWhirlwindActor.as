class ATundraBossSmallWhirlwindActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EffectRoot;

	UPROPERTY(DefaultComponent, Attach = EffectRoot)
	UNiagaraComponent WhirlwindVFX;
	default WhirlwindVFX.bAutoActivate = false;

	UPROPERTY(EditInstanceOnly)
	ATundraBossWhirlwindActor WhirlwindActor;

	UPROPERTY()
	UNiagaraSystem HitPlayerVFX;
	UPROPERTY()
	UNiagaraSystem FadeAwayVFX;

	UPROPERTY()
	TSubclassOf<UDamageEffect> SmallWhirlwindDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> SmallWhirlwindDeathEffect;

	float MoveLerpTimer = 0;
	float MoveLerpTimerDuration = 10;
	FVector StartingLoc;
	float SpawnTimeStamp;
	bool bShouldDamagePlayer = false;
	//Used for audio
	float HitPlayerTimeStamp = 0;
	
	FVector CurrentDirection;
	FVector LocLastTick;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachToComponent(WhirlwindActor.MeshRoot, AttachmentRule = EAttachmentRule::KeepWorld);
	}

	void SpawnSmallWhirlwind(float RandomYLoc)
	{
		FVector Loc = WhirlwindActor.SmallWhirlwindSpawnLocation.WorldLocation;
		Loc.Y = RandomYLoc;
		SetActorLocation(Loc);
		WhirlwindVFX.Activate(true);
		bShouldDamagePlayer = true;

		MoveLerpTimer = 0;
		StartingLoc = ActorRelativeLocation;
		SetActorTickEnabled(true);
		SpawnTimeStamp = Time::GameTimeSeconds;
		HitPlayerTimeStamp = 0;
	}

	void DespawnSmallWhirlwind()
	{
		Timer::SetTimer(this, n"DespawnTimer", 3);
		bShouldDamagePlayer = false;
		WhirlwindVFX.Deactivate();
		Niagara::SpawnOneShotNiagaraSystemAttached(FadeAwayVFX, EffectRoot);
	}

	UFUNCTION()
	void DespawnTimer()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MoveLerpTimer += DeltaSeconds;
		//SetActorRelativeLocation(Math::Lerp(StartingLoc, FVector(0, 0, 50), Math::Saturate(MoveLerpTimer/MoveLerpTimerDuration)));

		if(MoveLerpTimer >= MoveLerpTimerDuration)
			DespawnSmallWhirlwind();

		CurrentDirection = (ActorLocation - LocLastTick) / DeltaSeconds;
		LocLastTick = ActorLocation;
		
		if(Time::GameTimeSeconds > SpawnTimeStamp + 0.5 && bShouldDamagePlayer)
			CollisionCheck(85);
	}

	void CollisionCheck(float SphereRadius)
	{
		for(auto Player : Game::Players)
		{
			FHazeShapeSettings CapsuleSettings = FHazeShapeSettings::MakeCapsule(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight);
			float DistToCapsule = CapsuleSettings.GetWorldDistanceToShape(Player.CapsuleComponent.WorldTransform, ActorLocation + FVector(0, 0, 100));

			if(DistToCapsule < SphereRadius)
			{
				FPlayerDeathDamageParams DeathParams;
				DeathParams.ImpactDirection = CurrentDirection.GetSafeNormal();
				DeathParams.ForceScale = 5;
				Player.DamagePlayerHealth(0.33, DeathParams, SmallWhirlwindDamageEffect, SmallWhirlwindDeathEffect);
				Niagara::SpawnOneShotNiagaraSystemAtLocation(HitPlayerVFX, ActorLocation - FVector(0, 0, 100));
				DespawnSmallWhirlwind();
				Player.ApplyKnockdown(CurrentDirection.GetSafeNormal() * 500, 0.75, Cooldown = 2);
				HitPlayerTimeStamp = Time::GameTimeSeconds;
			}
		}
	}
};