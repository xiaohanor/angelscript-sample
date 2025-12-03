class AMoonMarketClockTowerLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeverRoot;

	FRotator StartingRot;

	bool bRotateOn;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingRot = LeverRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRotateOn)
			LeverRoot.RelativeRotation = Math::RInterpConstantTo(LeverRoot.RelativeRotation, FRotator(0,0, 30), DeltaSeconds, 70.0);
		else	
			LeverRoot.RelativeRotation = Math::RInterpConstantTo(LeverRoot.RelativeRotation, StartingRot, DeltaSeconds, 70.0);
	}

	UFUNCTION()
	void PullLever()
	{
		bRotateOn = true;
	}

	UFUNCTION()
	void ResetLever()
	{
		bRotateOn = false;
	}
};