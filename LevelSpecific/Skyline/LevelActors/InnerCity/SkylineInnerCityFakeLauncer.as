
class ASkylineInnerCityFakeLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LaunchPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineInnerCityFakeGarbage> ProjectileClass;
 
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	float SpawnRate = 2.2;

	float LaunchSpeed;

	int IdentifierInt;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Launch();
	}


	UFUNCTION()
	void Launch()
	{
		LaunchSpeed = Math::RandRange(70000, 90000);
		AActor SpawnedActor = SpawnActor(ProjectileClass,LaunchPoint.WorldLocation,LaunchPoint.WorldRotation, bDeferredSpawn = true);
		ASkylineInnerCityFakeGarbage Projectile = Cast<ASkylineInnerCityFakeGarbage>(SpawnedActor);
		Projectile.LaunchImpulse = LaunchPoint.UpVector * LaunchSpeed;
		Projectile.MakeNetworked(this, n"LaunchedProjectile", IdentifierInt);
		IdentifierInt++;
		FinishSpawningActor(Projectile);
		
		
	}


};