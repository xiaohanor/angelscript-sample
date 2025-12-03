class ASkylineTrafficTrafficLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FOnSkylineTrafficCarStartDriving OnStartedDriving;

	UPROPERTY()
	FOnSkylineTrafficCarStartBreaking OnStartedBreaking;

	UPROPERTY(EditAnywhere)
	TArray<ASkylineInnerCityTrafficCar> TrafficCars;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;


	float RedDuration = 11.0;

	float GreenDuration = 18.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GoGreen();
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleOnActivated");
	}


	UFUNCTION()
	private void HandleOnActivated(AActor Caller)
	{
		Timer::SetTimer(this, n"GoRed", 3.0);
	}

	UFUNCTION()
	private void GoGreen()
	{
		BP_GoGreen();
		Timer::SetTimer(this, n"StartDrivingDelay", 1.0, false);
	}

	UFUNCTION()
	private void StartDrivingDelay()
	{
			
		OnStartedDriving.Broadcast();
		InterfaceComp.TriggerActivate();
		for(auto Car : TrafficCars)
		{
				Car.ShouldStart();
		}
	
		//Timer::SetTimer(this, n"GoRed", GreenDuration);
	}

	UFUNCTION()
	private void GoRed()
	{
		BP_GoRed();
		OnStartedBreaking.Broadcast();
		InterfaceComp.TriggerDeactivate();
		for(auto Car : TrafficCars)
		{
				Car.ShouldBreak();
		}
	
		Timer::SetTimer(this, n"GoGreen", RedDuration);
	}

	UFUNCTION(BlueprintEvent)
	void BP_GoGreen()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_GoRed()
	{
	}
};