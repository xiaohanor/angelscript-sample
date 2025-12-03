class ABattlefieldMissileBatchActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ABattlefieldMissileActor> MissileActors;

	UPROPERTY(EditAnywhere)
	float FireRate = 0.25;

	float FireTime;

	int CurrentCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FireTime -= DeltaSeconds;

		if (FireTime <= 0.0)
		{
			if (CurrentCount >= MissileActors.Num() - 1)
			{
				SetActorTickEnabled(false);
			}
			
			FireTime = FireRate;
			MissileActors[CurrentCount].ActivateMissile();
			CurrentCount++;
		}
	}

	UFUNCTION()
	void ActivateMissileBarrage()
	{
		CurrentCount = 0;
		SetActorTickEnabled(true);
	}
};