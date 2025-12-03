event void FOnSkylineTrafficCarStartDriving();
event void FOnSkylineTrafficCarStartBreaking();

class ASkylineTrafficCar : AHazeActor
{
	default AddActorTag(FlyingCarTags::FlyingCarTraffic);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float Speed = 5000.0;

	UPROPERTY()
	float AccelerationDuration = 4.0;

	UPROPERTY()
	float RetardationDuration = 8.0;

	float CurrentAcceleration = 4.0;

	UPROPERTY()
	int Laps = 3;
	int CurrentLap = 0;

	UPROPERTY()
	float ForwardDistanceToTeleport = 10000.0;

	UPROPERTY()
	float BackwardSpawnDistance = 5000.0;

	UPROPERTY()
	FOnSkylineTrafficCarStartDriving OnStartedDriving;

	UPROPERTY()
	FOnSkylineTrafficCarStartBreaking OnStartedBreaking;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ListenToActor;

	UPROPERTY(EditInstanceOnly)
	float StartDrivingDelay = 0.5;

	FHazeAcceleratedFloat AcceleratedForwardDistance;

	float TargetForwardDistance = 0.0;

	bool bDriving = false;

	FVector StartActorLocation;

	ASkylineHighwayCarDynamic DynamicCar;
	AHazePrefabActor CarPrefabActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartActorLocation = ActorLocation;

		auto TrafficCar = Cast<ASkylineTrafficCar>(ListenToActor);
		if (TrafficCar != nullptr)
		{
			TrafficCar.OnStartedDriving.AddUFunction(this, n"HandleListenActorStartDriving");
			TrafficCar.OnStartedBreaking.AddUFunction(this, n"HandleListenActorStartBreaking");

		}

		auto TrafficLight = Cast<ASkylineTrafficTrafficLight>(ListenToActor);
		if (TrafficLight != nullptr)
		{
			TrafficLight.OnStartedDriving.AddUFunction(this, n"HandleListenActorStartDriving");
			TrafficLight.GreenDuration = (ForwardDistanceToTeleport + BackwardSpawnDistance) / Speed * Laps;
			TrafficLight.OnStartedBreaking.AddUFunction(this, n"HandleListenActorStartBreaking");
		}

		//Find dynamic car
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto AttachedActor : AttachedActors)
		{
			auto AttachedCar = Cast<ASkylineHighwayCarDynamic>(AttachedActor);
			if (AttachedCar != nullptr)
			{
				DynamicCar = AttachedCar;

				TArray<AActor> DynamicCarAttachedActors;
				DynamicCar.GetAttachedActors(DynamicCarAttachedActors);

				for (auto DynamicCarAttachedActor : DynamicCarAttachedActors)
				{
					auto AttachedPrefabCar = Cast<AHazePrefabActor>(DynamicCarAttachedActor);

					if (AttachedPrefabCar != nullptr)
					{
						CarPrefabActor = AttachedPrefabCar;
					}
				}
			}
		}
	}


	UFUNCTION()
	private void HandleListenActorStartDriving()
	{
		Timer::SetTimer(this, n"StartDriving", StartDrivingDelay);
	}

	UFUNCTION()
	private void HandleListenActorStartBreaking()
	{
		Timer::SetTimer(this, n"StartBreaking", 0.00001);
	}

	UFUNCTION()
	private void StartDriving()
	{
		OnStartedDriving.Broadcast();
		bDriving = true;
		CurrentLap = 0;
		CurrentAcceleration = AccelerationDuration;

		USkylineTrafficCarEventHandler::Trigger_OnStartDriving(CarPrefabActor);		
	}

	UFUNCTION()
	private void StartBreaking()
	{
		OnStartedBreaking.Broadcast();
		USkylineTrafficCarEventHandler::Trigger_OnStartedBreaking(CarPrefabActor);	
	}

	UFUNCTION()
	private void StopDriving()
	{
		bDriving = false;
		TargetForwardDistance = 0.0;
		CurrentAcceleration = RetardationDuration;

		USkylineTrafficCarEventHandler::Trigger_OnStopDriving(CarPrefabActor);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDriving)
		{
			bool bTargetWasLessThanZero = TargetForwardDistance < 0.0;

			TargetForwardDistance += Speed * DeltaSeconds;

			if (TargetForwardDistance > ForwardDistanceToTeleport)
			{
				TargetForwardDistance -= ForwardDistanceToTeleport + BackwardSpawnDistance;

				float Target = AcceleratedForwardDistance.Value - (ForwardDistanceToTeleport + BackwardSpawnDistance);
				float Velocity = AcceleratedForwardDistance.Velocity;
				AcceleratedForwardDistance.SnapTo(Target, Velocity);

				//if (DynamicCar != nullptr)
				//	FauxPhysics::ResetFauxPhysicsInternalState(DynamicCar);

				USkylineTrafficCarEventHandler::Trigger_OnTeleportToStartLocation(CarPrefabActor);
			}

			if (bTargetWasLessThanZero && TargetForwardDistance > 0.0)
				CurrentLap++;

			if (CurrentLap >= Laps)
				StopDriving();
		}

		AcceleratedForwardDistance.AccelerateTo(TargetForwardDistance, CurrentAcceleration, DeltaSeconds);
		FVector Location = StartActorLocation + ActorForwardVector * AcceleratedForwardDistance.Value;
		SetActorLocation(Location);
	}
};

class USkylineTrafficCarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnStartDriving() {}

	UFUNCTION(BlueprintEvent)
	void OnStartedBreaking() {}

	UFUNCTION(BlueprintEvent)
	void OnStopDriving() {}

	UFUNCTION(BlueprintEvent)
	void OnTeleportToStartLocation() {}
}