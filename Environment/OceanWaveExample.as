class AOceanWaveExample : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.WorldScale3D = FVector(1);

	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorHeight;

	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorRaycast;

	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid00;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid10;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid20;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid30;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid01;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid11;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid21;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid31;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid02;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid12;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid22;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid32;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid03;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid13;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid23;
	UPROPERTY(DefaultComponent)
    USceneComponent InstigatorGrid33;

	TArray<USceneComponent> Instigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Raycast once every second
		Timer::SetTimer(this, n"Raycast", 1.0, true);
		Instigators.Add(InstigatorGrid00);
		Instigators.Add(InstigatorGrid10);
		Instigators.Add(InstigatorGrid20);
		Instigators.Add(InstigatorGrid30);
		Instigators.Add(InstigatorGrid01);
		Instigators.Add(InstigatorGrid11);
		Instigators.Add(InstigatorGrid21);
		Instigators.Add(InstigatorGrid31);
		Instigators.Add(InstigatorGrid02);
		Instigators.Add(InstigatorGrid12);
		Instigators.Add(InstigatorGrid22);
		Instigators.Add(InstigatorGrid32);
		Instigators.Add(InstigatorGrid03);
		Instigators.Add(InstigatorGrid13);
		Instigators.Add(InstigatorGrid23);
		Instigators.Add(InstigatorGrid33);
	}

	UFUNCTION()
	void Raycast()
	{
		// Make a "request" for a raycast, which we then poll for the result of in Tick()
		Debug::DrawDebugLine(InstigatorRaycast.GetWorldLocation(), InstigatorRaycast.GetWorldLocation() + InstigatorRaycast.GetForwardVector() * 10000.0, FLinearColor::Blue, 50.0);
		OceanWaves::RequestWaveDataRaycast(InstigatorRaycast, InstigatorRaycast.GetWorldLocation(), InstigatorRaycast.GetForwardVector());
	}

	void DebugDrawHit(FWaveData Hit)
	{
		Debug::DrawDebugPoint(Hit.PointOnWave, 50.0, FLinearColor::Purple);
		Debug::DrawDebugLine(Hit.PointOnWave, Hit.PointOnWave + Hit.PointOnWaveNormal * 300.0, FLinearColor::Blue, 100.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Spam requests on tick, making it possible to use the returned value immedietly. Note it will be delayed by a couple frames.
		OceanWaves::RequestWaveData(InstigatorHeight, InstigatorHeight.GetWorldLocation());
		FWaveData HeightHit = OceanWaves::GetLatestWaveData(InstigatorHeight);
		DebugDrawHit(HeightHit);
		
		//for (int X = 0; X < 4; X++)
		//{
		//	for (int Y = 0; Y < 4; Y++)
		//	{
		//		OceanWaves::RequestWaveData(Instigators[X*4+Y], InstigatorHeight.GetWorldLocation() + FVector(X, Y, 0) * 500);
		//		FWaveData Hit = OceanWaves::GetLatestWaveData(Instigators[X*4+Y]);
		//		DebugDrawHit(Hit);
		//	}
		//}
		
		// Get the current delay, useful for compensating for the sampling delay.
		int DelayFrames = OceanWaves::GetCurrentDelayInFrames();
		float DelaySeconds = OceanWaves::GetCurrentDelayInSeconds();
		Print(f"Delay | Frames: {DelayFrames}, Seconds: {DelaySeconds:.3}");

		FWaveData RayHit;
		// This function returns true for one frame when the hit data becomes available.
		// If you call GetWaveData or GetWaveDataRaycast every frame, it will always return true for that instigator.
		if(OceanWaves::IsWaveDataReady(InstigatorRaycast))
		{
			DebugDrawHit(OceanWaves::GetLatestWaveData(InstigatorRaycast));
		}
	}
};