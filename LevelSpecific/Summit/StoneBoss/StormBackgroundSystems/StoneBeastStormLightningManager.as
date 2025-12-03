class AStoneBeastStormLightningManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "SkullAndBones";
	default Visual.SetWorldScale3D(FVector(20.0));
#endif

	UPROPERTY(EditAnywhere, Category = "Setup")
	float MinRadius = 30000.0;
	UPROPERTY(EditAnywhere, Category = "Setup")
	float MaxRadius = 80000.0;
	UPROPERTY(EditAnywhere, Category = "Setup")
	float MaxUpLightningOffset = 15000.0;

	UPROPERTY(EditAnywhere, Category = "Spawn")
	float MinSpawnRate = 0.75;
	UPROPERTY(EditAnywhere, Category = "Spawn")
	float MaxSpawnRate = 1.5;

	float SpawnTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugSphere(ActorLocation, MinRadius, 16, FLinearColor::Green, 250);
		// Debug::DrawDebugSphere(ActorLocation, MaxRadius, 16, FLinearColor::Red, 250);

		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnLightning();
			SpawnTime = Time::GameTimeSeconds + Math::RandRange(MinSpawnRate, MaxSpawnRate);
		}
	}

	void SpawnLightning()
	{
		FVector RandomDirection = FVector(Math::RandRange(-1.0, 1.0), Math::RandRange(-1.0, 1.0), 0);
		RandomDirection.Normalize();
		FVector SpawnLoc = ActorLocation + RandomDirection * Math::RandRange(MinRadius, MaxRadius);
		
		FStoneBeastStormLightingParams Params;
		Params.Location = SpawnLoc;
		UStoneBeastStormLightningEffectHandler::Trigger_SpawnLightning(this, Params);
	}
};