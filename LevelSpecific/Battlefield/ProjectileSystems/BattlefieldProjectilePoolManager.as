class ABattlefieldProjectilePoolManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY()
	TSubclassOf<ABattlefieldProjectile> ProjectileClass;

	TArray<ABattlefieldProjectile> AvailableProjectilePool;

	UPROPERTY(EditAnywhere)
	int ObjectCount = 50;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0; i < ObjectCount; i++)
		{
			ABattlefieldProjectile NewProjectile = SpawnActor(ProjectileClass, ActorLocation);
			NewProjectile.AddActorDisable(this);
			NewProjectile.OwningManager = this;
			AvailableProjectilePool.Add(NewProjectile);
		}
	}

	UFUNCTION()
	void ActivateProjectile(FBattlefieldProjectileParams ProjectileParams, FVector Location, FRotator Rotation)
	{
		if (AvailableProjectilePool.Num() > 0)
		{
			ABattlefieldProjectile ActivatedProjectile;

			for (ABattlefieldProjectile Projectile : AvailableProjectilePool)
			{
				if (Projectile.IsActorDisabled())
				{
					ActivatedProjectile = Projectile;
					break;
				}
			}

			if (ActivatedProjectile == nullptr)
			{
				ABattlefieldProjectile NewProjectile = SpawnActor(ProjectileClass, ActorLocation);
				NewProjectile.Params = ProjectileParams;
				NewProjectile.ActorLocation = Location;
				NewProjectile.ActorRotation = Rotation;
				NewProjectile.OwningManager = this;
				NewProjectile.ActivateProjectile(ProjectileParams.SpawningActor);				
			}
			else
			{
				ActivatedProjectile.RemoveActorDisable(this);
				ActivatedProjectile.Params = ProjectileParams;
				ActivatedProjectile.ActorLocation = Location;
				ActivatedProjectile.ActorRotation = Rotation;		
				ActivatedProjectile.ActivateProjectile(ProjectileParams.SpawningActor);
				AvailableProjectilePool.RemoveSingleSwap(ActivatedProjectile);		
			}
		}
		else
		{
			ABattlefieldProjectile NewProjectile = SpawnActor(ProjectileClass, ActorLocation);
			NewProjectile.Params = ProjectileParams;
			NewProjectile.ActorLocation = Location;
			NewProjectile.ActorRotation = Rotation;
			NewProjectile.OwningManager = this;
			NewProjectile.ActivateProjectile(ProjectileParams.SpawningActor);	
		}
	}

	UFUNCTION()
	void DeactivateProjectile(ABattlefieldProjectile Projectile)
	{
		AvailableProjectilePool.Add(Projectile);
		Projectile.AddActorDisable(this);
	}
}

class ASmallLaserPoolManager : ABattlefieldProjectilePoolManager
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}

class AMediumLaserPoolManager : ABattlefieldProjectilePoolManager
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}

class ALargeLaserPoolManager : ABattlefieldProjectilePoolManager
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}

class ALargeAlienPlasmaPoolManager : ABattlefieldProjectilePoolManager
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}