class ASkylineBallBossThrowableMotorcycleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotatingRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetLocationComp;

	UPROPERTY()
	float RotatingSpeed = 90.0;
	float MovementSpeed;

	UPROPERTY()
	float DownwardSpawnOffset = 5000.0;

	UPROPERTY()
	float ThrowInterval = 1.0;

	UPROPERTY()
	int MotorcycleAmount = 10;

	ASkylineBallBoss BallBoss;

	AHazePlayerCharacter TargetedPlayer;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossThrowableMotorcycle> MotorcycleClass;

	TArray<ASkylineBallBossThrowableMotorcycle> Motorcycles;
	int MotorcycleIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		float Radius = TargetLocationComp.WorldLocation.Distance(RotatingRoot.WorldLocation);
		MovementSpeed = Radius * PI * RotatingSpeed / 360.0;

		BallBoss = Cast<ASkylineBallBoss>(AttachParentActor);

		TargetedPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotatingRoot.SetRelativeRotation(FRotator(0.0, 0.0, -RotatingSpeed * Time::GameTimeSeconds));
		//SetActorRotation(FRotator(0.0, 0.0, 180.0));
	}

	UFUNCTION()
	void Activate()
	{
		Timer::SetTimer(this, n"SpawnMotorcycle", 360 / RotatingSpeed / MotorcycleAmount, true);
	}

	UFUNCTION()
	private void SpawnMotorcycle()
	{
		FVector SpawnLocation = RotatingRoot.WorldLocation - FVector::UpVector * DownwardSpawnOffset;
		
		auto Motorcycle = Cast<ASkylineBallBossThrowableMotorcycle>
			(SpawnActor(MotorcycleClass, SpawnLocation, TargetLocationComp.WorldRotation, bDeferredSpawn = true));
		
		Motorcycle.Manager = this;
		Motorcycle.BallBoss = BallBoss;
		Motorcycle.TargetedPlayer = TargetedPlayer;

		TargetedPlayer = TargetedPlayer.OtherPlayer;
		
		float Distance = TargetLocationComp.WorldLocation.Distance(SpawnLocation);
		float Duration = Distance / MovementSpeed;

		Duration *= 0.7;

		Motorcycle.SpawnTimeLike.Duration = Duration;

		FinishSpawningActor(Motorcycle);

		Motorcycle.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);

		Motorcycles.Add(Motorcycle);

		if (Motorcycles.Num() >= MotorcycleAmount)
		{
			Timer::ClearTimer(this, n"SpawnMotorcycle");
			Timer::SetTimer(this, n"IgniteBike", 0.15, true, 0.9);
		}
	}

	UFUNCTION()
	private void ActivateMotorcycle()
	{
		if (Motorcycles.Num() <= 0)
		{
			Timer::ClearTimer(this, n"ActivateMotorcycle");
			return;
		}

		Motorcycles[Motorcycles.Num() -1].Activate();
		Motorcycles.RemoveAt(Motorcycles.Num() -1);

		//Timer::SetTimer(this, n"ActivateMotorcycle", ThrowInterval);
	}

	UFUNCTION()
	private void IgniteBike()
	{
		if (MotorcycleIndex >= Motorcycles.Num())
		{
			Timer::ClearTimer(this, n"IgniteBike");
			Timer::SetTimer(this, n"ActivateMotorcycle", ThrowInterval, true);
			return;
		}
		Motorcycles[Motorcycles.Num() - MotorcycleIndex - 1].Ignite();
		MotorcycleIndex++;
	}
};