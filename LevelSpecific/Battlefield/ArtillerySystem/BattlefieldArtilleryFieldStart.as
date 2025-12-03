class ABattlefieldArtilleryFieldStart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComp;
	default ArrowComp.SetWorldScale3D(FVector(50.0));

	UPROPERTY(EditAnywhere)
	TArray<ABattlefieldArtilleryMuzzleFlash> MuzzleFlashes;

	UPROPERTY()
	TSubclassOf<ABattlefieldArtilleryAttack> ArtilleryAttackClass;

	//Visualize This Later
	UPROPERTY()
	float MaxDistance = 72000.0;
	float CurrentDistance;
	
	UPROPERTY()
	float Speed = 30000.0;

	UPROPERTY()
	float AttackRate = 0.25;
	float AttackTime; 

	float RandomRightOffset = 4000.0;

	float WaitTime;
	float WaitDuration = 1.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < WaitTime)
			return;

		if (Time::GameTimeSeconds > AttackTime)
		{
			AttackTime = Time::GameTimeSeconds + AttackRate;
			float RandomRight = Math::RandRange(-RandomRightOffset, RandomRightOffset);
			FVector AttackLoc = ActorLocation + ActorForwardVector * CurrentDistance;
			AttackLoc += ActorRightVector * RandomRight;
			SpawnActor(ArtilleryAttackClass, AttackLoc);
		}

		CurrentDistance += Speed * DeltaSeconds;

		if (CurrentDistance >= MaxDistance)
		{
			SetActorTickEnabled(false);
			CurrentDistance = 0.0;
		}
	}

	UFUNCTION()
	void ActivateArtilleryAttack(float Delay)
	{
		WaitTime = Time::GameTimeSeconds + Delay;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateArtilleryAttack()
	{
		SetActorTickEnabled(false);
	}
}