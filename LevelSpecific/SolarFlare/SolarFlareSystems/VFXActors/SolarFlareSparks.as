enum ESolarFlareSparksType
{
	Outward,
	Directional
}

class ASolarFlareSparks : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(3.0));
#endif

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ReactionComp;

	UPROPERTY(Category = Settings, EditAnywhere)
	ESolarFlareSparksType Type;

	UPROPERTY(Category = Settings, EditAnywhere)
	float MinRate = 1.0;

	UPROPERTY(Category = Settings, EditAnywhere)
	float MaxRate = 4.0;

	UPROPERTY(Category = Settings, EditAnywhere)
	float SpriteSizeMultiplier = 1.0;

	UPROPERTY(Category = Settings, EditAnywhere)
	float VelocityMultiplier = 1.0;

	float SparkTime;
	float SparkDuration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SparkTime = Time::GameTimeSeconds + Math::RandRange(MinRate, MaxRate);
		ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SparkTime)
		{
			ActivateSparks(Math::RandRange(MinRate, MaxRate));
		}
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		ActivateSparks(Math::RandRange(MinRate, MaxRate));
	}

	void ActivateSparks(float Time)
	{
		SparkTime = Time::GameTimeSeconds + Time;
		FOnSolarFlareSparksActivatedParams Params;
		Params.Type = Type;
		Params.Location = ActorLocation;
		Params.Rotation = ActorRotation;
		Params.SpriteSizeMultiplier = SpriteSizeMultiplier;
		Params.VelocityMultiplier = VelocityMultiplier;
		USolarFlareSparksEffectHandler::Trigger_OnSparkActivate(this, Params);
	}
}