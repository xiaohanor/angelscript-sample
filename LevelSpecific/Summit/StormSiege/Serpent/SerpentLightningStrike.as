class ASerpentLightningStrike : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float LifeTime = 1.5;
	float FireTime;
	float FireRate = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeTime += Time::GameTimeSeconds;

		FStormSiegeLightningStrikeParams Params;
		Params.Start = ActorLocation;
		FVector EndPoint = ActorLocation + ActorUpVector * 10000.0;
		Params.End = EndPoint;
		Params.BeamWidth = 2.0;
		UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(this, Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;

			FStormSiegeLightningStrikeParams Params;
			Params.Start = ActorLocation;
			FVector EndPoint = ActorLocation + ActorUpVector * 15000.0;
			Params.End = EndPoint;
			Params.BeamWidth = 2.0;
			UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(this, Params);
		}

		if (Time::GameTimeSeconds > LifeTime)
			DestroyActor();
	}
};