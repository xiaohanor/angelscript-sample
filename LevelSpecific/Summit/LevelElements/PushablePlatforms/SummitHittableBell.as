class ASummitHittableBell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttackComp;

	FVector StartLocation;
	float ShakeSpeed = 25;
	float ShakeAmount = 30.0;

	float ForwardMultiplier = 1.0;
	UPROPERTY()
	float Amplitude = 0.0;

	bool bForwardOpposite;
	bool bHaveChanged;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		StartLocation = MeshRoot.RelativeLocation;
		TailAttackComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ShakeOffset = Math::Sin(Time::GameTimeSeconds * ShakeSpeed) * ShakeAmount;

		if (ShakeOffset < 0.0 && !bForwardOpposite && !bHaveChanged)
		{
			ForwardMultiplier = -1.0;
			bForwardOpposite = true;
			bHaveChanged = true;
		}
		else if (ShakeOffset < 0.0 && bForwardOpposite && !bHaveChanged)
		{
			ForwardMultiplier = 1.0;
			bForwardOpposite = false;
			bHaveChanged = true;
		}

		if (bHaveChanged && ShakeOffset > 0.0)
		{
			bHaveChanged = false;
		}

		FVector RightOffset = MeshRoot.RightVector * ShakeOffset;
		FVector ForwardOffset = MeshRoot.ForwardVector * ShakeOffset * ForwardMultiplier;
		MeshRoot.RelativeLocation = StartLocation + (RightOffset + ForwardOffset) * Amplitude;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		BP_StartShake();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartShake() {}

};