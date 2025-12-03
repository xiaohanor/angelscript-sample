class ASolarFlareSpaceLiftSpinningCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	USolarFlareFireWaveReactionComponent ReactionComp;

	UPROPERTY()
	float ImpulseForce = 128000.0;

	int BreakCount;
	int MaxBreakCount = 2;

	float SpeedMultiplier = 1.0;

	bool bCanBreak;
	bool bBroken;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ReactionComp.OnSolarFlareImpact.AddUFunction(this, n"OnSolarFlareImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(0.0, 0.0, 35.0 * SpeedMultiplier * DeltaSeconds));
	}

	UFUNCTION()
	private void OnSolarFlareImpact()
	{
		if (bBroken)
			return;

		if (!bCanBreak)
			return;

		BreakCount++;
		BP_ActivateBReak(BreakCount);
		SpeedMultiplier = 1.5;

		if (BreakCount >= MaxBreakCount)
			bBroken = true;
	}

	UFUNCTION()
	void ActivateBreakMode()
	{
		bCanBreak = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateBReak(int index = 0) {}
}