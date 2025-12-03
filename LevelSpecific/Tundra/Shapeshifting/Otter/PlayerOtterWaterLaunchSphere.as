event void FOnLaunch();

UCLASS(Abstract)
class ATundraPlayerOtterWaterLaunchSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FOnLaunch OnLaunched;

	UPROPERTY(DefaultComponent, Attach=Root)
	USphereComponent SphereComponent;

	UPROPERTY(EditAnywhere)
	FVector LocalImpulseToApply = FVector(0.0, 0.0, 2000.0);

	UPROPERTY(EditAnywhere)
	float StartMagneticSpeed = 200.0;

	UPROPERTY(EditAnywhere)
	float MagneticAcceleration = 10000.0;

	UPROPERTY(EditAnywhere)
	float LaunchDelay = 0.5;

	UPROPERTY(EditAnywhere)
	private bool bWaterLaunchSphereActive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bWaterLaunchSphereActive)
		{
			auto ContainerComponent = UTundraPlayerOtterWaterLaunchSphereContainer::GetOrCreate(Game::Mio);
			ContainerComponent.LaunchSpheres.AddUnique(this);
		}
		else
		{
			OnDeactivateLaunchSphere();
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto ContainerComponent = UTundraPlayerOtterWaterLaunchSphereContainer::GetOrCreate(Game::Mio);
		ContainerComponent.LaunchSpheres.RemoveSingleSwap(this);
	}

	UFUNCTION()
	void ActivateLaunchSphere()
	{
		if(bWaterLaunchSphereActive)
			return;

		bWaterLaunchSphereActive = true;
		auto ContainerComponent = UTundraPlayerOtterWaterLaunchSphereContainer::GetOrCreate(Game::Mio);
		ContainerComponent.LaunchSpheres.AddUnique(this);

		OnActivateLaunchSphere();
	}

	UFUNCTION()
	void DeactivateLaunchSphere()
	{
		if(!bWaterLaunchSphereActive)
			return;

		bWaterLaunchSphereActive = false;
		auto ContainerComponent = UTundraPlayerOtterWaterLaunchSphereContainer::GetOrCreate(Game::Mio);
		ContainerComponent.LaunchSpheres.RemoveSingleSwap(this);

		OnDeactivateLaunchSphere();
	}

	UFUNCTION(BlueprintEvent)
	void OnActivateLaunchSphere()
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnDeactivateLaunchSphere()
	{
	}

	UFUNCTION()
	void Launch()
	{
		OnLaunched.Broadcast();
	}
}

class UTundraPlayerOtterWaterLaunchSphereContainer : UActorComponent
{
	TArray<ATundraPlayerOtterWaterLaunchSphere> LaunchSpheres;
}