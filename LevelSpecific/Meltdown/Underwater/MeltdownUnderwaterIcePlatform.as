class AMeltdownUnderwaterIcePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY()
	float PlatformDuration = 20.0;
	UPROPERTY()
	float Speed = 300.0;

	private float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer > PlatformDuration)
		{
			DestroyActor();
			return;
		}

		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;
	}

	UFUNCTION()
	void DeathEvent()
	{
		DestroyActor();
	}
};