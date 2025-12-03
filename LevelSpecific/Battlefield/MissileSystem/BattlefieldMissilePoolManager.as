class ABattlefieldMissilePoolManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	TSubclassOf<ABattlefieldMissile> MissileClass;

	TArray<ABattlefieldMissile> AvailableProjectilePool;

	UPROPERTY()
	int ObjectCount = 10;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0; i < ObjectCount; i++)
		{
			ABattlefieldMissile NewMissile = SpawnActor(MissileClass, ActorLocation);
			NewMissile.AddActorDisable(this);
			NewMissile.OwningManager = this;
			AvailableProjectilePool.Add(NewMissile);
		}
	}

	UFUNCTION()
	void ActivateMissile(FBattlefieldMissileParams MissileParams, FVector Location, FRotator Rotation, AActor SpawningActor)
	{
		if (AvailableProjectilePool.Num() > 0)
		{
			ABattlefieldMissile ActivatedMissile;

			for (ABattlefieldMissile Missile : AvailableProjectilePool)
			{
				if (Missile.IsActorDisabled())
				{
					ActivatedMissile = Missile;
					break;
				}
			}

			ActivatedMissile.RemoveActorDisable(this);
			ActivatedMissile.Params = MissileParams;
			ActivatedMissile.ActorLocation = Location;
			ActivatedMissile.ActorRotation = Rotation;	
			ActivatedMissile.SpawningActor = SpawningActor;	
			ActivatedMissile.DirToTarget = (MissileParams.TargetActor.ActorLocation - Location).GetSafeNormal();
			ActivatedMissile.ActivateMissile(MissileParams);	
			AvailableProjectilePool.Remove(ActivatedMissile);		
		}
		else
		{
			ABattlefieldMissile NewMissile = SpawnActor(MissileClass, ActorLocation);
			NewMissile.Params = MissileParams;
			NewMissile.ActorLocation = Location;
			NewMissile.ActorRotation = Rotation;		
			NewMissile.SpawningActor = SpawningActor;	
			NewMissile.OwningManager = this;	
			NewMissile.DirToTarget = (MissileParams.TargetActor.ActorLocation - Location).GetSafeNormal();
			NewMissile.ActivateMissile(MissileParams);	
		}
	}

	UFUNCTION()
	void DeactivateMissile(ABattlefieldMissile Missile)
	{
		AvailableProjectilePool.Add(Missile);
		Missile.AddActorDisable(this);
	}
}