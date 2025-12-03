class AMeltdownCarFish : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FishRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarRoot;

	UPROPERTY(EditAnywhere)
	float FishSpeed = 300.0;

	UPROPERTY(EditAnywhere)
	float CarSpeed = 1500.0;

	float SplineProgress = 0.0;
	bool bCarActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		CarRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	void Activate()
	{
		SetActorTickEnabled(true);
	}

	private void ActivateCar()
	{
		CarRoot.SetWorldLocation(FishRoot.WorldLocation + FVector::ForwardVector * 500000);
		CarRoot.SetHiddenInGame(false, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplineProgress += FishSpeed * DeltaSeconds;

		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(SplineProgress);
		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(SplineProgress);
		FishRoot.SetWorldLocationAndRotation(Location + FVector::ForwardVector * -500000.0, Rotation);

		if (!bCarActivated)
			CarRoot.SetWorldLocation(Location);
		else
			CarRoot.AddRelativeLocation(FVector::ForwardVector * CarSpeed * DeltaSeconds);

		if (CarRoot.RelativeLocation.X > 0.0 && !bCarActivated)
		{
			ActivateCar();
			bCarActivated = true;
		}

		PrintToScreen("FishSpeed = " + FishSpeed);
	}
};