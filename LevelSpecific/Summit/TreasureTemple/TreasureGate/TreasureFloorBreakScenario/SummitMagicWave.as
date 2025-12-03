class ASummitMagicWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDeathTriggerComponent DeathBox;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem FireWavePoof;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> RollingCamShake;

	float MinDistance = 550.0;
	float MagicMaxDistance = 15500.0;

	float Speed = 3500.0;

	FVector StartLocation;
	
	bool bHasStartedFading;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Game::Mio.PlayWorldCameraShake(RollingCamShake, this, ActorLocation, 1500.0, 8000.0, Scale = 0.8);
		Game::Zoe.PlayWorldCameraShake(RollingCamShake, this, ActorLocation, 1500.0, 8000.0, Scale = 0.8);
		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;

		float Distance = (StartLocation - ActorLocation).Size();

		if (Distance > MagicMaxDistance)
		{
			Game::Mio.StopCameraShakeByInstigator(this);
			Game::Zoe.StopCameraShakeByInstigator(this);
			USummitMagicWaveEffectHandler::Trigger_OnMagicWaveDespawned(this);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(FireWavePoof, ActorLocation, ActorRotation);
			DestroyActor();		
		}
	}
}