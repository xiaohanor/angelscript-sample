enum EBattlefieldProjectileType
{
	SmallLaser,
	MediumLaser,
	LargeLaser,
	LargePlasma
}

event void FOnBattlefieldProjectileFiredProjectile();
event void FOnBattlefieldProjectileStartFire();
event void FOnBattlefieldProjectileEndFire();

class UBattlefieldProjectileComponent : UBattlefieldAttackComponent
{
	UPROPERTY()
	FOnBattlefieldProjectileStartFire OnBattlefieldProjectileStartFire;
	UPROPERTY()
	FOnBattlefieldProjectileEndFire OnBattlefieldProjectileEndFire;
	UPROPERTY()
	FOnBattlefieldProjectileFiredProjectile OnBattlefieldProjectileFiredProjectile;
 
	UPROPERTY()
	bool bAutoBehaviour = true;

	UPROPERTY(EditAnywhere)
	float DelayFire = 0.0;

	UPROPERTY(EditAnywhere)
	int VolleyCount = 1;

	UPROPERTY(EditAnywhere)
	float FireRate = 0.5;

	UPROPERTY(EditAnywhere)
	float WaitDuration = 2.0;

	float FireTime;
	float WaitTime;

	int CurrentVolley;

	UPROPERTY(EditAnywhere)
	FBattlefieldProjectileParams ProjectileParams;

	UPROPERTY()
	bool bUseRandomDelay;

	UPROPERTY(meta = (EditCondition = "!bUseRandomDelay", EditConditionHides))
	float RandomDelayMin = 0.5;

	UPROPERTY(meta = (EditCondition = "!bUseRandomDelay", EditConditionHides))
	float RandomDelayMax = 5.0;

	ABattlefieldProjectilePoolManager PoolManager;

	bool bResetVolleyCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileParams.SpawningActor = Owner;

		switch (ProjectileParams.Type)
		{
			case EBattlefieldProjectileType::SmallLaser:
				PoolManager = TListedActors<ASmallLaserPoolManager>().GetSingle();
				break;
			case EBattlefieldProjectileType::MediumLaser:
				PoolManager = TListedActors<AMediumLaserPoolManager>().GetSingle();
				break;
			case EBattlefieldProjectileType::LargeLaser:
				PoolManager = TListedActors<ALargeLaserPoolManager>().GetSingle();
				break;
			case EBattlefieldProjectileType::LargePlasma:
				PoolManager = TListedActors<ALargeAlienPlasmaPoolManager>().GetSingle();
				break;
		}

		if (!bAutoBehaviour)
		{
			SetComponentTickEnabled(false);
		}
		else
		{
			WaitTime = Time::GameTimeSeconds + DelayFire;

			if (bUseRandomDelay)
				WaitTime += Math::RandRange(RandomDelayMin, RandomDelayMax);
		}

	}

	//Only if auto behaviour is true
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < WaitTime)
		{
			return;
		}
		else if (!bResetVolleyCount)
		{
			bResetVolleyCount = true;
			CurrentVolley = 0;
			OnBattlefieldProjectileStartFire.Broadcast();
		}

		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;
			AutoSpawnProjectile();

			CurrentVolley++;

			if (CurrentVolley >= VolleyCount)
			{
				WaitTime = Time::GameTimeSeconds + WaitDuration;
				bResetVolleyCount = false;
			}

			OnBattlefieldProjectileEndFire.Broadcast();
		}
	}

	UFUNCTION()
	void AutoSpawnProjectile()
	{
		FOnBattleFieldOnProjectileFiredParams Params;
		Params.Location = WorldLocation;
		Params.Rotation = WorldRotation;
		UBattleFieldProjectileEffectHandler::Trigger_OnProjectileFired(Cast<AHazeActor>(Owner), Params);
		PoolManager.ActivateProjectile(ProjectileParams, WorldLocation, WorldRotation);

		OnBattlefieldProjectileFiredProjectile.Broadcast();
	} 

	UFUNCTION()
	void ManualSpawnProjectile(FVector Direction)
	{
		FOnBattleFieldOnProjectileFiredParams Params;
		Params.Location = WorldLocation;
		Params.Rotation = Direction.Rotation();
		UBattleFieldProjectileEffectHandler::Trigger_OnProjectileFired(Cast<AHazeActor>(Owner), Params);
		PoolManager.ActivateProjectile(ProjectileParams, WorldLocation, Direction.Rotation());
		
		OnBattlefieldProjectileFiredProjectile.Broadcast();
	}

	UFUNCTION()
	void ActivateAutoFire(float Delay)
	{
		WaitTime = Time::GameTimeSeconds + Delay;
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateAutoFire()
	{
		SetComponentTickEnabled(false);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(WorldLocation, WorldLocation + ForwardVector * 60000.0, FLinearColor::Red, 50);		
	}
#endif
}