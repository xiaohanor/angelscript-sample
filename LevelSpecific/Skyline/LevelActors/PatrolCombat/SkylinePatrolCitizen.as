class ASkylinePatrolCitizen : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Target;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	AHazeActorSpawnerBase Spawner;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AEnforcerRifleProjectile> ProjectileClass;

	TArray<AAISkylineEnforcerPatrol> Enforcers;

	int ShotsTaken = 0;
	int ShotsToDie = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spawner.OnPostSpawn.AddUFunction(this, n"HandleSpawn");
		Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		Activate();		
	}

	UFUNCTION()
	private void HandleSpawn(AHazeActor SpawnedActor)
	{
//		Spawner.OnPostSpawn.Unbind(this, n"HandleSpawn");
		auto Enforcer = Cast<AAISkylineEnforcerPatrol>(SpawnedActor);
		Enforcers.Add(Enforcer);
	}

	void Activate()
	{
		Timer::SetTimer(this, n"GetShot", 0.1, true);
	}

	UFUNCTION()
	void GetShot()
	{
		if (ShotsTaken >= ShotsToDie)
			return;

		for (auto Enforcer : Enforcers)
		{
			FVector Start = Enforcer.WeaponWielder.Weapon.ActorLocation;
			FVector End = Target.WorldLocation;
//			Debug::DrawDebugLine(Start, End, FLinearColor::Red, 15.0, 0.1);

			auto Projectile = SpawnActor(ProjectileClass, Start);
			FVector Direction = (End - Start).SafeNormal;
			Projectile.ProjectileComp.Launcher = Enforcer;
			Projectile.ProjectileComp.LaunchingWeapon = UEnforcerWeaponComponent::Get(Enforcer);
			Projectile.OwnerWeaponComp = UEnforcerWeaponComponent::Get(Enforcer.WeaponWielder.Weapon);
			Projectile.ProjectileComp.Launch(Direction * 2000.0, Direction.Rotation());
		}

		ShotsTaken++;

		if (ShotsTaken >= ShotsToDie)
		{
			BP_Die();
//			DestroyActor();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Die() { }

	UFUNCTION(DevFunction)
	void DevCitizenDie()
	{
		Activate();
	}
};