class ABattlefieldArtilleryManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ABattlefieldArtilleryFieldStart> ArtilleryPoints;

	UPROPERTY(EditAnywhere)
	TArray<ABattlefieldArtilleryMuzzleFlash> MuzzleFlashes;

	UPROPERTY(EditAnywhere)
	TArray<ABattlefieldSearchLights> SearchLights;

	float Rate = 0.2;
	float Time;
	int Index;
	float DelayHit = 1.0;

	float WaitTime;
	float WaitDuration = 3.5;

	bool bStart;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < WaitTime)
		{
			return;
		}

		if (!bStart)
		{
			bStart = true;

			float Delay = 0.1;

			for (ABattlefieldArtilleryMuzzleFlash Flash : MuzzleFlashes)
			{
				Flash.FireMuzzle(Delay);
				Delay += 0.1;
			}
		}

		if (Time::GameTimeSeconds > Time)
		{
			Time = Time::GameTimeSeconds + Rate;
			ArtilleryPoints[Index].ActivateArtilleryAttack(DelayHit);
			Index++;

			if (Index >= ArtilleryPoints.Num() - 1)
			{
				Index = 0;
				WaitTime = Time::GameTimeSeconds + WaitDuration;
				bStart = false;
				Print("STOP");
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_BeginShootFeedback() {}

	UFUNCTION()
	void StartAttacks()
	{
		for (ABattlefieldSearchLights Light : SearchLights)
			Light.StartSearchlight();
		
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void StopAttacks()
	{
		SetActorTickEnabled(false);
	}
}