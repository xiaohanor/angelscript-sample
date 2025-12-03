struct FBattlefieldProjectileParams
{
	AActor SpawningActor;

	UPROPERTY()
	float LifeTime = 2.0;

	UPROPERTY()
	float Speed = 15000.0;

	UPROPERTY()
	bool bShouldTrace = false;

	UPROPERTY()
	bool bShouldHaveProjectileSoundDef = false;

	UPROPERTY()
	EBattlefieldProjectileType Type;
}

class ABattlefieldProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	//Replace with niagara
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent System;

	ABattlefieldProjectilePoolManager OwningManager;

	FBattlefieldProjectileParams Params;

	AActor SpawningActor;

	UFUNCTION(BlueprintPure)
	bool ShouldAttachSoundDef() const
	{
		return Params.bShouldHaveProjectileSoundDef;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Trace for hits

		ActorLocation += ActorForwardVector * Params.Speed * DeltaSeconds;

		if(Params.bShouldTrace)
		{
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.UseLine();
			TraceSettings.IgnoreActor(this);
			TraceSettings.IgnoreActor(SpawningActor);

			FVector End = ActorLocation + ActorForwardVector * 500.0;
			FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, End);

			if (Hit.bBlockingHit)
			{
				FOnBattleFieldOnProjectileImpactParams ProjParams;
				ProjParams.Location = Hit.ImpactPoint;
				ProjParams.Normal = Hit.ImpactNormal;
				UBattleFieldProjectileEffectHandler::Trigger_OnProjectileImpact(this, ProjParams);
				UBattlefieldProjectileResponseComponent Response = UBattlefieldProjectileResponseComponent::Get(Hit.Actor);
				
				if (Response != nullptr)
				{
					FBattleFieldProjectileImpactResponseParams ResponseParams;
					ResponseParams.ImpactPoint = Hit.ImpactPoint;
					ResponseParams.ImpactDirection = ActorForwardVector;
					Response.TriggerProjectileImpact(ResponseParams);
				}
				DeactivateProjectile();
			}
		}
	
		if (Time::GameTimeSeconds > Params.LifeTime)
		{
			DeactivateProjectile();
		}
	}

	void ActivateProjectile(AActor Spawner)
	{
		AddOrRemoveSoundDef();

		FOnBattleFieldOnProjectileFiredParams ProjParams;
		ProjParams.Location = ActorLocation;
		ProjParams.Rotation = ActorRotation;
		ProjParams.Type = Params.Type;
		UBattleFieldProjectileEffectHandler::Trigger_OnProjectileFired(this, ProjParams);
		Params.LifeTime += Time::GameTimeSeconds;
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintEvent)
	void AddOrRemoveSoundDef() {}

	void DeactivateProjectile()
	{
		SetActorTickEnabled(false);
		OwningManager.DeactivateProjectile(this);
	}
}