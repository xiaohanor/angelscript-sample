UCLASS(Abstract)
class USkylineInnerCityLaunchLauncherEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseLid()
	{
	}

};	
class ASkylineInnerCityLaunchLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LaunchPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineInnerCityLaunchProjectile> ProjectileClass;

	UPROPERTY(DefaultComponent)
	USceneComponent LidRoot;
 
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent, Attach = LidRoot)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent)
	UArrowComponent LidLauncDirection;

	UPROPERTY(EditInstanceOnly)
	float SpawnRate = 2.2;

	UPROPERTY(EditAnywhere)
	float LaunchSpeed = 15000.0;

	float TimeToSpawn = 0.0;
	bool bLaunchCooldown = true;

	int IdentifierInt;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike Timelike;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		Timelike.BindUpdate(this, n"HandleAnimationUpdate");
		Timelike.BindFinished(this, n"HandeLidOpenAnimation");

	}

	UFUNCTION()
	private void HandeLidOpenAnimation()
	{
		if(!Timelike.IsReversed() && BoxCollision.IsOverlappingActor(Game::Zoe))
			Game::Zoe.ApplyKnockdown(LidLauncDirection.GetForwardVector() * 1500.0, 2.0);
	}

	UFUNCTION()
	private void HandleAnimationUpdate(float CurrentValue)
	{
		LidRoot.SetRelativeRotation(FRotator(60.0 * CurrentValue, 0.0, 0.0));
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
			Timelike.Play();

			Timer::SetTimer(this, n"Launch", 0.2);
	}


	UFUNCTION()
	void Launch()
	{
		if(!bLaunchCooldown)
			return;
		
		BP_Launch();
		InterfaceComp.TriggerActivate();
		bLaunchCooldown = false;
		AActor SpawnedActor = SpawnActor(ProjectileClass,LaunchPoint.WorldLocation,LaunchPoint.WorldRotation, bDeferredSpawn = true);
		ASkylineInnerCityLaunchProjectile Projectile = Cast<ASkylineInnerCityLaunchProjectile>(SpawnedActor);
		Projectile.LaunchImpulse = LaunchPoint.UpVector * LaunchSpeed;
		Projectile.MakeNetworked(this, n"LaunchedProjectile", IdentifierInt);
		IdentifierInt++;
		FinishSpawningActor(Projectile);
		Projectile.OnExpire.AddUFunction(this, n"HandleResetCooldown");
		USkylineInnerCityLaunchLauncherEventHandler::Trigger_OnHit(this); 
		Timer::SetTimer(this, n"CloseLid", 0.5);
	}


	UFUNCTION(BlueprintEvent)
	void BP_Launch(){}

	UFUNCTION()
	private void CloseLid()
	{
		Timelike.Reverse();
		USkylineInnerCityLaunchLauncherEventHandler::Trigger_OnCloseLid(this);
	}

	UFUNCTION()
	private void HandleResetCooldown()
	{
		bLaunchCooldown = true;
		
	}
};