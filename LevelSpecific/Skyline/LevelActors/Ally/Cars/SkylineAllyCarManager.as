class ASkylineAllyCarManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<ASkylineAllyDrivingCar> CarPool;

	UPROPERTY(EditInstanceOnly)
	ASkylineAllyCrashingCar CrashingCar;

	UPROPERTY(EditInstanceOnly)
	ASkylineAllyChargableCar ChargableCar;

	UPROPERTY(EditAnywhere)
	float MinActivateDelay = 0.5;

	UPROPERTY(EditAnywhere)
	float MaxActivateDelay = 8.0;

	bool bDeactivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChargableCar.OnCarCrash.AddUFunction(this, n"HandleCarFullyCharged");

		if (!bDeactivated)
			Timer::SetTimer(this, n"ActivateCar", 1.0);
	}

	UFUNCTION()
	private void HandleCarFullyCharged()
	{
		Timer::ClearTimer(this, n"ActivateCar");
		CrashingCar.Activate();
	}

	UFUNCTION()
	void ActivateCar()
	{
		ASkylineAllyDrivingCar ActivatedCar;

		for (auto Car : CarPool)
		{
			if (!Car.bDriving)
			{
				ActivatedCar = Car;
				break;
			}
		}

		int RandInt = Math::RandRange(0, CarPool.Num() -1);

		PrintToScreen("int = " + RandInt, 3.0);

		auto RandCar = CarPool[RandInt];
		if (!RandCar.bDriving)
			ActivatedCar = RandCar;

		if (ActivatedCar != nullptr)
			ActivatedCar.Activate();

		Timer::SetTimer(this, n"ActivateCar", Math::RandRange(MinActivateDelay, MaxActivateDelay));
	}

	UFUNCTION()
	void StartDisabled()
	{
		Timer::ClearTimer(this, n"ActivateCar");
		bDeactivated = true;
		CrashingCar.StartCrashed();
	}
};